"""Image quality assessment and enhancement pipeline.

Pipeline: Quality Check → Enhancement → Ready for face detection/embedding.
Handles low resolution, blur, noise, poor lighting automatically.
"""

from __future__ import annotations

import os
import urllib.request
from dataclasses import dataclass, field

import cv2
import numpy as np

from config import (
    BLUR_THRESHOLD,
    BRIGHTNESS_HIGH,
    BRIGHTNESS_LOW,
    CLAHE_CLIP_LIMIT,
    CLAHE_GRID_SIZE,
    MIN_IMAGE_DIM,
    NOISE_THRESHOLD,
    SHARPEN_STRENGTH,
    SUPER_RES_MODEL_PATH,
    SUPER_RES_MODEL_URL,
    SUPER_RES_SCALE,
    get_logger,
)

log = get_logger("preprocessing")

# ---------------------------------------------------------------------------
# Quality report
# ---------------------------------------------------------------------------

@dataclass
class QualityReport:
    blur_score: float = 0.0        # Laplacian variance (higher = sharper)
    brightness: float = 0.0        # Mean intensity 0-255
    noise_sigma: float = 0.0       # Estimated noise level
    resolution: tuple[int, int] = (0, 0)  # (height, width)
    is_blurry: bool = False
    is_dark: bool = False
    is_bright: bool = False
    is_noisy: bool = False
    is_low_res: bool = False
    usable: bool = True
    issues: list[str] = field(default_factory=list)
    enhancements_applied: list[str] = field(default_factory=list)


# ---------------------------------------------------------------------------
# Quality assessment
# ---------------------------------------------------------------------------

def assess_quality(frame: np.ndarray) -> QualityReport:
    """Assess image quality and return a detailed report."""
    report = QualityReport()
    h, w = frame.shape[:2]
    report.resolution = (h, w)

    gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY) if len(frame.shape) == 3 else frame

    # Blur detection via Laplacian variance
    report.blur_score = float(cv2.Laplacian(gray, cv2.CV_64F).var())
    report.is_blurry = report.blur_score < BLUR_THRESHOLD

    # Brightness
    report.brightness = float(gray.mean())
    report.is_dark = report.brightness < BRIGHTNESS_LOW
    report.is_bright = report.brightness > BRIGHTNESS_HIGH

    # Noise estimation (median absolute deviation of high-pass filter)
    report.noise_sigma = _estimate_noise(gray)
    report.is_noisy = report.noise_sigma > NOISE_THRESHOLD

    # Resolution check
    report.is_low_res = min(h, w) < MIN_IMAGE_DIM

    # Compile issues
    if report.is_blurry:
        report.issues.append(f"blurry (score={report.blur_score:.1f})")
    if report.is_dark:
        report.issues.append(f"too dark (brightness={report.brightness:.0f})")
    if report.is_bright:
        report.issues.append(f"too bright (brightness={report.brightness:.0f})")
    if report.is_noisy:
        report.issues.append(f"noisy (sigma={report.noise_sigma:.1f})")
    if report.is_low_res:
        report.issues.append(f"low resolution ({w}x{h})")

    report.usable = len(report.issues) <= 2  # reject if 3+ problems
    return report


def _estimate_noise(gray: np.ndarray) -> float:
    """Estimate noise sigma using Median Absolute Deviation on Laplacian."""
    h, w = gray.shape
    # Use a small Laplacian kernel for noise estimation
    laplacian = cv2.Laplacian(gray, cv2.CV_64F)
    sigma = float(np.median(np.abs(laplacian)) * 1.4826 / np.sqrt(2))
    return sigma


# ---------------------------------------------------------------------------
# Enhancement functions
# ---------------------------------------------------------------------------

def enhance_image(frame: np.ndarray, report: QualityReport | None = None) -> tuple[np.ndarray, QualityReport]:
    """Enhance image based on quality assessment. Returns (enhanced_frame, report)."""
    if report is None:
        report = assess_quality(frame)

    enhanced = frame.copy()

    # 1. Super-resolution for low-res images
    if report.is_low_res:
        enhanced = _apply_super_resolution(enhanced)
        report.enhancements_applied.append("super_resolution")
        log.debug("Applied super resolution (%dx%d -> %dx%d)",
                  frame.shape[1], frame.shape[0],
                  enhanced.shape[1], enhanced.shape[0])

    # 2. Noise reduction (before sharpening to avoid amplifying noise)
    if report.is_noisy:
        enhanced = _denoise(enhanced)
        report.enhancements_applied.append("denoise")
        log.debug("Applied noise reduction (sigma=%.1f)", report.noise_sigma)

    # 3. Lighting correction
    if report.is_dark or report.is_bright:
        enhanced = _fix_lighting(enhanced)
        report.enhancements_applied.append("lighting_correction")
        log.debug("Applied lighting correction (brightness=%.0f)", report.brightness)

    # 4. Deblurring / sharpening
    if report.is_blurry:
        enhanced = _sharpen(enhanced)
        report.enhancements_applied.append("sharpening")
        log.debug("Applied sharpening (blur_score=%.1f)", report.blur_score)

    return enhanced, report


# ---------------------------------------------------------------------------
# Super resolution
# ---------------------------------------------------------------------------

_sr_model = None


def _get_sr_model():
    """Lazy-load OpenCV DNN Super Resolution model."""
    global _sr_model
    if _sr_model is not None:
        return _sr_model

    try:
        sr = cv2.dnn_superres.DnnSuperResImpl.create()
    except AttributeError:
        log.warning("cv2.dnn_superres not available; falling back to bicubic upscale")
        return None

    if not os.path.exists(SUPER_RES_MODEL_PATH):
        log.info("Downloading EDSR super-resolution model (~5 MB)...")
        try:
            os.makedirs(os.path.dirname(SUPER_RES_MODEL_PATH), exist_ok=True)
            urllib.request.urlretrieve(SUPER_RES_MODEL_URL, SUPER_RES_MODEL_PATH)
            log.info("Model downloaded to %s", SUPER_RES_MODEL_PATH)
        except Exception as e:
            log.warning("Could not download SR model: %s; using bicubic", e)
            return None

    sr.readModel(SUPER_RES_MODEL_PATH)
    sr.setModel("edsr", SUPER_RES_SCALE)
    _sr_model = sr
    return _sr_model


def _apply_super_resolution(frame: np.ndarray) -> np.ndarray:
    """Upscale image using EDSR super-resolution or fallback to LANCZOS4."""
    sr = _get_sr_model()
    if sr is not None:
        try:
            return sr.upsample(frame)
        except Exception as e:
            log.warning("SR model failed: %s; using bicubic fallback", e)

    # Fallback: high-quality interpolation
    h, w = frame.shape[:2]
    return cv2.resize(frame, (w * SUPER_RES_SCALE, h * SUPER_RES_SCALE),
                      interpolation=cv2.INTER_LANCZOS4)


# ---------------------------------------------------------------------------
# Noise reduction
# ---------------------------------------------------------------------------

def _denoise(frame: np.ndarray) -> np.ndarray:
    """Reduce noise using Non-Local Means Denoising."""
    return cv2.fastNlMeansDenoisingColored(frame, None, h=10, hForColoredComponents=10,
                                           templateWindowSize=7, searchWindowSize=21)


# ---------------------------------------------------------------------------
# Lighting correction
# ---------------------------------------------------------------------------

def _fix_lighting(frame: np.ndarray) -> np.ndarray:
    """Fix poor lighting using CLAHE on the L channel of LAB color space."""
    lab = cv2.cvtColor(frame, cv2.COLOR_BGR2LAB)
    l_chan, a_chan, b_chan = cv2.split(lab)
    clahe = cv2.createCLAHE(clipLimit=CLAHE_CLIP_LIMIT, tileGridSize=CLAHE_GRID_SIZE)
    l_chan = clahe.apply(l_chan)
    lab = cv2.merge([l_chan, a_chan, b_chan])
    return cv2.cvtColor(lab, cv2.COLOR_LAB2BGR)


# ---------------------------------------------------------------------------
# Sharpening (deblurring)
# ---------------------------------------------------------------------------

def _sharpen(frame: np.ndarray) -> np.ndarray:
    """Sharpen image using unsharp masking."""
    gaussian = cv2.GaussianBlur(frame, (0, 0), sigmaX=3)
    sharpened = cv2.addWeighted(frame, 1.0 + SHARPEN_STRENGTH, gaussian,
                                -SHARPEN_STRENGTH, 0)
    return np.clip(sharpened, 0, 255).astype(np.uint8)

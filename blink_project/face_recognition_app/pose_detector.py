"""Head pose estimation and eye-blink detection from face landmarks.

Uses two methods:
  1. solvePnP with 68-point 3D landmarks (accurate yaw/pitch/roll)
  2. 5-point landmark ratio fallback (fast, approximate yaw)

Also provides Eye Aspect Ratio (EAR) computation for blink detection.
"""

from __future__ import annotations

from dataclasses import dataclass

import cv2
import numpy as np

from config import (
    FACE_3D_MODEL_POINTS,
    LEFT_EYE_INDICES,
    LIVENESS_BLINK_EAR_THRESHOLD,
    POSE_CENTER_MAX_YAW,
    POSE_SIDE_MAX_YAW,
    POSE_SIDE_MIN_YAW,
    RIGHT_EYE_INDICES,
    SOLVEPNP_LANDMARK_INDICES,
    get_logger,
)

log = get_logger("pose")


@dataclass
class PoseResult:
    yaw: float = 0.0       # negative = turned left (from camera), positive = right
    pitch: float = 0.0     # negative = looking down, positive = up
    roll: float = 0.0      # head tilt
    label: str = "unknown"  # "center", "left", "right", "unknown"
    ear_left: float = 0.0  # left eye aspect ratio
    ear_right: float = 0.0
    ear_avg: float = 0.0
    blink: bool = False


# ---------------------------------------------------------------------------
# Pose estimation
# ---------------------------------------------------------------------------

def estimate_pose_solvepnp(
    landmarks_68: np.ndarray,
    frame_shape: tuple[int, int],
) -> tuple[float, float, float]:
    """Estimate yaw, pitch, roll using solvePnP with 68-point landmarks.

    Args:
        landmarks_68: shape (68, 2) or (68, 3) — only first 2 dims used.
        frame_shape: (height, width) of the frame.

    Returns:
        (yaw, pitch, roll) in degrees.
    """
    h, w = frame_shape
    image_points = np.array(
        [landmarks_68[i][:2] for i in SOLVEPNP_LANDMARK_INDICES],
        dtype=np.float64,
    )

    focal_length = w
    camera_matrix = np.array([
        [focal_length, 0, w / 2],
        [0, focal_length, h / 2],
        [0, 0, 1],
    ], dtype=np.float64)
    dist_coeffs = np.zeros((4, 1))

    success, rvec, tvec = cv2.solvePnP(
        FACE_3D_MODEL_POINTS, image_points, camera_matrix, dist_coeffs,
        flags=cv2.SOLVEPNP_ITERATIVE,
    )
    if not success:
        return 0.0, 0.0, 0.0

    rmat, _ = cv2.Rodrigues(rvec)
    # Decompose rotation matrix to Euler angles
    sy = np.sqrt(rmat[0, 0] ** 2 + rmat[1, 0] ** 2)
    if sy > 1e-6:
        pitch = float(np.degrees(np.arctan2(-rmat[2, 0], sy)))
        yaw = float(np.degrees(np.arctan2(rmat[1, 0], rmat[0, 0])))
        roll = float(np.degrees(np.arctan2(rmat[2, 1], rmat[2, 2])))
    else:
        pitch = float(np.degrees(np.arctan2(-rmat[2, 0], sy)))
        yaw = 0.0
        roll = float(np.degrees(np.arctan2(-rmat[1, 2], rmat[1, 1])))

    return yaw, pitch, roll


def estimate_yaw_from_kps(kps: np.ndarray) -> float:
    """Fast yaw estimate from 5-point landmarks (fallback method).

    kps: shape (5, 2) — [left_eye, right_eye, nose, left_mouth, right_mouth]
    Returns approximate yaw in degrees.
    """
    left_eye, right_eye, nose = kps[0], kps[1], kps[2]
    eye_mid_x = (left_eye[0] + right_eye[0]) / 2.0
    eye_dist = float(np.linalg.norm(right_eye - left_eye))
    if eye_dist < 1e-6:
        return 0.0
    offset = (nose[0] - eye_mid_x) / eye_dist
    return float(np.clip(offset * 90.0, -60.0, 60.0))


# ---------------------------------------------------------------------------
# Pose classification
# ---------------------------------------------------------------------------

def classify_yaw(yaw: float) -> str:
    """Classify yaw angle into center / left / right / unknown."""
    abs_yaw = abs(yaw)
    if abs_yaw <= POSE_CENTER_MAX_YAW:
        return "center"
    elif POSE_SIDE_MIN_YAW <= abs_yaw <= POSE_SIDE_MAX_YAW:
        return "left" if yaw < 0 else "right"
    elif abs_yaw > POSE_SIDE_MAX_YAW:
        return "unknown"  # too extreme
    else:
        return "unknown"  # transition zone


# ---------------------------------------------------------------------------
# Eye Aspect Ratio (blink detection)
# ---------------------------------------------------------------------------

def _ear(eye_pts: np.ndarray) -> float:
    """Compute Eye Aspect Ratio from 6 landmark points.

    Points order: outer_corner, upper_1, upper_2, inner_corner, lower_2, lower_1
    """
    v1 = float(np.linalg.norm(eye_pts[1] - eye_pts[5]))
    v2 = float(np.linalg.norm(eye_pts[2] - eye_pts[4]))
    h = float(np.linalg.norm(eye_pts[0] - eye_pts[3]))
    return (v1 + v2) / (2.0 * h + 1e-6)


def compute_ear(landmarks_68: np.ndarray) -> tuple[float, float, float]:
    """Compute left, right, and average EAR from 68-point landmarks.

    Returns (ear_left, ear_right, ear_avg).
    """
    pts = landmarks_68[:, :2]  # use x, y only
    left_eye = pts[LEFT_EYE_INDICES]
    right_eye = pts[RIGHT_EYE_INDICES]
    ear_l = _ear(left_eye)
    ear_r = _ear(right_eye)
    return ear_l, ear_r, (ear_l + ear_r) / 2.0


# ---------------------------------------------------------------------------
# Full pose analysis
# ---------------------------------------------------------------------------

def analyze_face(
    kps_5: np.ndarray | None = None,
    landmarks_68: np.ndarray | None = None,
    frame_shape: tuple[int, int] = (480, 640),
) -> PoseResult:
    """Full pose + blink analysis for a single face.

    Prefers 68-point landmarks (solvePnP) if available; falls back to 5-point.
    """
    result = PoseResult()

    # Pose
    if landmarks_68 is not None and landmarks_68.shape[0] >= 68:
        yaw, pitch, roll = estimate_pose_solvepnp(landmarks_68, frame_shape)
        result.yaw = yaw
        result.pitch = pitch
        result.roll = roll

        # EAR / blink
        ear_l, ear_r, ear_avg = compute_ear(landmarks_68)
        result.ear_left = ear_l
        result.ear_right = ear_r
        result.ear_avg = ear_avg
        result.blink = ear_avg < LIVENESS_BLINK_EAR_THRESHOLD

    elif kps_5 is not None and kps_5.shape[0] >= 5:
        result.yaw = estimate_yaw_from_kps(kps_5)

    result.label = classify_yaw(result.yaw)
    return result


def draw_pose_overlay(
    frame: np.ndarray,
    bbox: list[int],
    pose: PoseResult,
) -> np.ndarray:
    """Draw pose info on frame for UI feedback."""
    x1, y1, x2, y2 = bbox
    color = {
        "center": (0, 255, 0),
        "left": (255, 200, 0),
        "right": (0, 200, 255),
        "unknown": (128, 128, 128),
    }.get(pose.label, (128, 128, 128))

    cv2.rectangle(frame, (x1, y1), (x2, y2), color, 2)

    info = f"{pose.label.upper()} yaw={pose.yaw:.0f}"
    cv2.putText(frame, info, (x1, y2 + 18),
                cv2.FONT_HERSHEY_SIMPLEX, 0.5, color, 1)

    if pose.ear_avg > 0:
        ear_text = f"EAR={pose.ear_avg:.2f}"
        if pose.blink:
            ear_text += " BLINK"
        cv2.putText(frame, ear_text, (x1, y2 + 36),
                    cv2.FONT_HERSHEY_SIMPLEX, 0.45, (200, 200, 200), 1)
    return frame

"""Full face recognition pipeline with quality checks and pose analysis.

Enrollment:  Capture → Quality Check → Enhancement → Detect → Align → Embed → Store
Verification: Capture → Quality Check → Enhancement → Detect → Embed → Match → Decide
"""

from __future__ import annotations

from dataclasses import dataclass, field

import numpy as np

from config import MIN_FACE_SIZE_PX, get_logger
from face_embedder import FaceEmbedder, FaceEmbeddingResult
from face_matcher import FaceMatcher, MatchResult
from pose_detector import PoseResult
from preprocessing import QualityReport, assess_quality, enhance_image

log = get_logger("pipeline")


@dataclass
class FaceResult:
    bbox: list[int]
    det_score: float
    match: MatchResult
    quality: QualityReport
    pose: PoseResult | None = None
    embedding: np.ndarray | None = None
    rejected: bool = False
    reject_reason: str = ""


@dataclass
class PipelineResult:
    faces: list[FaceResult] = field(default_factory=list)
    quality: QualityReport | None = None
    enhanced: bool = False
    num_faces_detected: int = 0
    num_matched: int = 0
    num_unknown: int = 0
    num_low_confidence: int = 0
    num_rejected: int = 0
    frame_enhanced: np.ndarray | None = None


class FaceRecognitionPipeline:
    """Orchestrates the full recognition pipeline."""

    def __init__(self, embedder: FaceEmbedder, matcher: FaceMatcher):
        self.embedder = embedder
        self.matcher = matcher

    def process(self, bgr_frame: np.ndarray, enhance: bool = True) -> PipelineResult:
        """Run full verification pipeline on a single frame."""
        result = PipelineResult()

        # 1. Quality assessment
        quality = assess_quality(bgr_frame)
        result.quality = quality
        log.debug("Quality: blur=%.1f bright=%.0f noise=%.1f issues=%s",
                  quality.blur_score, quality.brightness, quality.noise_sigma,
                  quality.issues)

        # 2. Enhancement
        frame = bgr_frame
        if enhance and quality.issues:
            frame, quality = enhance_image(bgr_frame, quality)
            result.enhanced = True
            result.frame_enhanced = frame

        # 3. Face detection + embedding + pose
        emb_results = self.embedder.get_embeddings(frame)
        result.num_faces_detected = len(emb_results)

        if not emb_results:
            log.info("No faces detected in frame")
            return result

        # 4. Match each face
        for er in emb_results:
            face_w = er.bbox[2] - er.bbox[0]
            face_h = er.bbox[3] - er.bbox[1]

            if face_w < MIN_FACE_SIZE_PX or face_h < MIN_FACE_SIZE_PX:
                fr = FaceResult(
                    bbox=er.bbox, det_score=er.det_score, quality=quality,
                    match=MatchResult(matched=False, name=None, score=0.0, confidence="none"),
                    pose=er.pose, embedding=er.embedding,
                    rejected=True, reject_reason=f"face too small ({face_w}x{face_h}px)",
                )
                result.faces.append(fr)
                result.num_rejected += 1
                continue

            match = self.matcher.match(er.embedding)
            fr = FaceResult(
                bbox=er.bbox, det_score=er.det_score, quality=quality,
                match=match, pose=er.pose, embedding=er.embedding,
            )
            result.faces.append(fr)

            if match.matched and match.confidence == "high":
                result.num_matched += 1
                log.info("MATCH: %s (score=%.3f, angle=%s, confidence=high)",
                         match.name, match.score, match.best_angle)
            elif match.matched and match.confidence == "low":
                result.num_low_confidence += 1
                log.warning("LOW-CONFIDENCE: %s (score=%.3f)", match.name, match.score)
            else:
                result.num_unknown += 1
                log.info("UNKNOWN face (best_score=%.3f)", match.score)

        return result

    def process_for_registration(self, bgr_frame: np.ndarray
                                 ) -> tuple[FaceEmbeddingResult | None, QualityReport]:
        """Process a frame for registration: enhance, detect, return full result + quality."""
        quality = assess_quality(bgr_frame)
        frame = bgr_frame
        if quality.issues:
            frame, quality = enhance_image(bgr_frame, quality)

        face_result = self.embedder.get_single_result(frame)
        return face_result, quality

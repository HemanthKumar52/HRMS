"""ArcFace embedding extraction via insightface (buffalo_l model).

Exposes full face analysis results including:
- 512-d normalized embedding
- 5-point and 68-point 3D landmarks
- Pose estimation (yaw/pitch/roll)
- Eye Aspect Ratio for blink detection
"""

from __future__ import annotations

from dataclasses import dataclass

import numpy as np
from insightface.app import FaceAnalysis

from config import ARCFACE_MODEL_NAME, ARCFACE_DET_SIZE, ARCFACE_PROVIDERS, get_logger
from pose_detector import PoseResult, analyze_face

log = get_logger("embedder")


@dataclass
class FaceEmbeddingResult:
    embedding: np.ndarray          # 512-d normalized vector
    bbox: list[int]                # [x1, y1, x2, y2]
    det_score: float
    landmarks: np.ndarray | None = None      # (5, 2) keypoints
    landmarks_68: np.ndarray | None = None   # (68, 3) 3D landmarks
    pose: PoseResult | None = None           # yaw/pitch/roll + blink


class FaceEmbedder:
    """ArcFace embedding extraction with pose analysis and GPU auto-detection."""

    def __init__(self):
        log.info("Loading ArcFace model (%s) with providers: %s",
                 ARCFACE_MODEL_NAME, ARCFACE_PROVIDERS)
        self._app = FaceAnalysis(
            name=ARCFACE_MODEL_NAME,
            providers=ARCFACE_PROVIDERS,
        )
        self._app.prepare(ctx_id=0, det_size=ARCFACE_DET_SIZE)
        log.info("ArcFace model loaded. Detection size: %s", ARCFACE_DET_SIZE)

    def get_embeddings(self, bgr_frame: np.ndarray) -> list[FaceEmbeddingResult]:
        """Detect and embed all faces, including pose analysis.

        InsightFace internally performs:
        1. SCRFD face detection
        2. 5-point + 68-point landmark detection
        3. Face alignment via landmarks
        4. ArcFace embedding extraction (512-d)
        """
        faces = self._app.get(bgr_frame)
        h, w = bgr_frame.shape[:2]
        results = []

        for face in faces:
            emb = face.normed_embedding
            bbox = face.bbox.astype(int).tolist()
            score = float(face.det_score)
            kps = face.kps if hasattr(face, "kps") else None
            lm68 = face.landmark_3d_68 if hasattr(face, "landmark_3d_68") else None

            # Pose analysis
            pose = analyze_face(kps_5=kps, landmarks_68=lm68, frame_shape=(h, w))

            results.append(FaceEmbeddingResult(
                embedding=emb,
                bbox=bbox,
                det_score=score,
                landmarks=kps,
                landmarks_68=lm68,
                pose=pose,
            ))
        return results

    def get_single_embedding(self, bgr_frame: np.ndarray) -> np.ndarray | None:
        """Return embedding of the largest face, or None if no face found."""
        results = self.get_embeddings(bgr_frame)
        if not results:
            return None
        largest = max(
            results,
            key=lambda r: (r.bbox[2] - r.bbox[0]) * (r.bbox[3] - r.bbox[1]),
        )
        return largest.embedding

    def get_single_result(self, bgr_frame: np.ndarray) -> FaceEmbeddingResult | None:
        """Return full result for the largest face, or None."""
        results = self.get_embeddings(bgr_frame)
        if not results:
            return None
        return max(
            results,
            key=lambda r: (r.bbox[2] - r.bbox[0]) * (r.bbox[3] - r.bbox[1]),
        )

    def get_all_with_quality(self, bgr_frame: np.ndarray) -> list[FaceEmbeddingResult]:
        """Get embeddings filtering out low-confidence detections."""
        return [r for r in self.get_embeddings(bgr_frame) if r.det_score >= 0.5]

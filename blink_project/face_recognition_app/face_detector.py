"""Fast face detection using MediaPipe for real-time UI bounding box overlay."""

from __future__ import annotations

from dataclasses import dataclass

import cv2
import mediapipe as mp
import numpy as np

from config import MEDIAPIPE_MIN_DETECTION_CONFIDENCE, MEDIAPIPE_MODEL_SELECTION


@dataclass
class DetectedFace:
    bbox: tuple[int, int, int, int]  # (x, y, w, h) in pixels
    confidence: float


class FaceDetector:
    """Fast face detection using MediaPipe for UI bounding box drawing."""

    def __init__(self):
        self._detector = mp.solutions.face_detection.FaceDetection(
            min_detection_confidence=MEDIAPIPE_MIN_DETECTION_CONFIDENCE,
            model_selection=MEDIAPIPE_MODEL_SELECTION,
        )

    def detect(self, bgr_frame: np.ndarray) -> list[DetectedFace]:
        """Detect faces and return pixel-coordinate bounding boxes."""
        h, w = bgr_frame.shape[:2]
        rgb = cv2.cvtColor(bgr_frame, cv2.COLOR_BGR2RGB)
        results = self._detector.process(rgb)

        faces = []
        if results.detections:
            for det in results.detections:
                bb = det.location_data.relative_bounding_box
                x = max(0, int(bb.xmin * w))
                y = max(0, int(bb.ymin * h))
                bw = min(int(bb.width * w), w - x)
                bh = min(int(bb.height * h), h - y)
                conf = det.score[0] if det.score else 0.0
                faces.append(DetectedFace(bbox=(x, y, bw, bh), confidence=conf))
        return faces

    def close(self):
        self._detector.close()

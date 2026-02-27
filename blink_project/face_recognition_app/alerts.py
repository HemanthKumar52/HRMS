"""Unknown face alert handler with cooldown and logging."""

from __future__ import annotations

import os
import time

import cv2
import numpy as np

from config import ALERTS_DIR, ALERT_COOLDOWN_SECONDS, ensure_dirs, get_logger

log = get_logger("alerts")

_last_alert_time = 0.0


def handle_unknown_face(
    full_frame: np.ndarray,
    bbox: tuple[int, int, int, int],
    score: float,
):
    global _last_alert_time
    now = time.time()
    if now - _last_alert_time < ALERT_COOLDOWN_SECONDS:
        return
    _last_alert_time = now

    ensure_dirs()
    timestamp = time.strftime("%Y%m%d_%H%M%S")

    x, y, w, h = bbox
    fh, fw = full_frame.shape[:2]
    x1, y1 = max(0, x), max(0, y)
    x2, y2 = min(fw, x + w), min(fh, y + h)

    if x2 > x1 and y2 > y1:
        crop = full_frame[y1:y2, x1:x2]
        cv2.imwrite(os.path.join(ALERTS_DIR, f"unknown_{timestamp}_crop.jpg"), crop)

    annotated = full_frame.copy()
    cv2.rectangle(annotated, (x1, y1), (x2, y2), (0, 0, 255), 2)
    cv2.putText(annotated, f"UNKNOWN ({score:.2f})", (x1, y1 - 10),
                cv2.FONT_HERSHEY_SIMPLEX, 0.6, (0, 0, 255), 2)
    cv2.imwrite(os.path.join(ALERTS_DIR, f"unknown_{timestamp}_frame.jpg"), annotated)

    log.warning("Unknown face alert (score=%.3f) -> %s", score, ALERTS_DIR)

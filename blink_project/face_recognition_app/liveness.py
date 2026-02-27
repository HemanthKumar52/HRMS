"""Liveness / anti-spoofing via challenge-response.

Challenges the user to perform head movements (center → left → right)
and optionally blink, to reject static images and spoof attempts.
"""

from __future__ import annotations

import time
from dataclasses import dataclass, field
from enum import Enum

import cv2
import numpy as np

from config import (
    CAMERA_BACKEND, CAMERA_HEIGHT, CAMERA_INDEX, CAMERA_WIDTH,
    LIVENESS_BLINK_CONSEC_FRAMES, LIVENESS_CHALLENGE_TIMEOUT,
    LIVENESS_REQUIRE_BLINK, get_logger,
)
from face_embedder import FaceEmbedder
from pose_detector import PoseResult, analyze_face, draw_pose_overlay

log = get_logger("liveness")


class ChallengeStep(Enum):
    CENTER = "center"
    LEFT = "left"
    RIGHT = "right"
    BLINK = "blink"
    DONE = "done"
    FAILED = "failed"


CHALLENGE_INSTRUCTIONS = {
    ChallengeStep.CENTER: "Look STRAIGHT at the camera",
    ChallengeStep.LEFT:   "Slowly turn your head to the LEFT",
    ChallengeStep.RIGHT:  "Slowly turn your head to the RIGHT",
    ChallengeStep.BLINK:  "Blink your eyes (2-3 times)",
}

CHALLENGE_SEQUENCE = [ChallengeStep.CENTER, ChallengeStep.RIGHT, ChallengeStep.LEFT]


@dataclass
class LivenessResult:
    alive: bool = False
    steps_passed: list[str] = field(default_factory=list)
    steps_failed: list[str] = field(default_factory=list)
    blink_count: int = 0
    reason: str = ""


# ---------------------------------------------------------------------------
# Challenge-response liveness check (CLI / OpenCV)
# ---------------------------------------------------------------------------

def run_liveness_check_cli(
    embedder: FaceEmbedder,
    require_blink: bool = LIVENESS_REQUIRE_BLINK,
    timeout_per_step: float = LIVENESS_CHALLENGE_TIMEOUT,
) -> LivenessResult:
    """Run interactive liveness challenge via webcam (OpenCV window).

    Sequence: Center → Left → Right → (optional Blink)
    Returns LivenessResult.
    """
    result = LivenessResult()

    sequence = list(CHALLENGE_SEQUENCE)
    if require_blink:
        sequence.append(ChallengeStep.BLINK)

    cap = cv2.VideoCapture(CAMERA_INDEX, CAMERA_BACKEND)
    cap.set(cv2.CAP_PROP_FRAME_WIDTH, CAMERA_WIDTH)
    cap.set(cv2.CAP_PROP_FRAME_HEIGHT, CAMERA_HEIGHT)

    if not cap.isOpened():
        result.reason = "camera_unavailable"
        log.error("Liveness check failed: cannot open camera")
        return result

    blink_counter = 0
    blink_frame_count = 0

    for step in sequence:
        instruction = CHALLENGE_INSTRUCTIONS[step]
        print(f"[Liveness] {instruction}")
        step_start = time.time()
        step_passed = False

        while time.time() - step_start < timeout_per_step:
            ret, frame = cap.read()
            if not ret:
                continue

            display = frame.copy()
            emb_results = embedder.get_embeddings(frame)

            # HUD
            elapsed = time.time() - step_start
            remaining = max(0, timeout_per_step - elapsed)
            cv2.putText(display, instruction, (10, 30),
                        cv2.FONT_HERSHEY_SIMPLEX, 0.7, (0, 255, 255), 2)
            cv2.putText(display, f"Time: {remaining:.1f}s", (10, 60),
                        cv2.FONT_HERSHEY_SIMPLEX, 0.5, (200, 200, 200), 1)

            # Progress bar for passed steps
            for i, s in enumerate(result.steps_passed):
                cv2.putText(display, f"[PASS] {s}", (10, 90 + i * 22),
                            cv2.FONT_HERSHEY_SIMPLEX, 0.45, (0, 200, 0), 1)

            if not emb_results:
                cv2.putText(display, "No face detected", (10, frame.shape[0] - 20),
                            cv2.FONT_HERSHEY_SIMPLEX, 0.5, (0, 0, 255), 1)
                cv2.imshow("Liveness Check", display)
                if cv2.waitKey(1) & 0xFF == ord('q'):
                    break
                continue

            face = emb_results[0]
            # Analyze pose
            lm68 = None
            raw_faces = embedder._app.get(frame)
            if raw_faces and hasattr(raw_faces[0], 'landmark_3d_68'):
                lm68 = raw_faces[0].landmark_3d_68

            pose = analyze_face(
                kps_5=face.landmarks,
                landmarks_68=lm68,
                frame_shape=frame.shape[:2],
            )
            draw_pose_overlay(display, face.bbox, pose)

            # Check if challenge step is satisfied
            if step == ChallengeStep.CENTER and pose.label == "center":
                step_passed = True
            elif step == ChallengeStep.LEFT and pose.label == "left":
                step_passed = True
            elif step == ChallengeStep.RIGHT and pose.label == "right":
                step_passed = True
            elif step == ChallengeStep.BLINK:
                if pose.blink:
                    blink_frame_count += 1
                else:
                    if blink_frame_count >= LIVENESS_BLINK_CONSEC_FRAMES:
                        blink_counter += 1
                        cv2.putText(display, f"Blinks: {blink_counter}", (10, frame.shape[0] - 50),
                                    cv2.FONT_HERSHEY_SIMPLEX, 0.6, (0, 255, 0), 2)
                    blink_frame_count = 0
                if blink_counter >= 2:
                    step_passed = True

            if step_passed:
                # Flash green
                cv2.putText(display, "PASSED!", (frame.shape[1] // 2 - 60, frame.shape[0] // 2),
                            cv2.FONT_HERSHEY_SIMPLEX, 1.2, (0, 255, 0), 3)
                cv2.imshow("Liveness Check", display)
                cv2.waitKey(500)
                break

            cv2.imshow("Liveness Check", display)
            if cv2.waitKey(1) & 0xFF == ord('q'):
                result.reason = "cancelled"
                cap.release()
                cv2.destroyAllWindows()
                return result

        if step_passed:
            result.steps_passed.append(step.value)
            log.info("Liveness step PASSED: %s", step.value)
        else:
            result.steps_failed.append(step.value)
            log.warning("Liveness step FAILED: %s (timeout)", step.value)
            result.reason = f"timeout_on_{step.value}"
            break

    cap.release()
    cv2.destroyAllWindows()

    result.blink_count = blink_counter
    result.alive = len(result.steps_failed) == 0
    if result.alive:
        log.info("Liveness check PASSED (%d steps)", len(result.steps_passed))
    else:
        log.warning("Liveness check FAILED: %s", result.reason)
    return result


# ---------------------------------------------------------------------------
# Simplified liveness for Streamlit (validate multi-angle photos)
# ---------------------------------------------------------------------------

def validate_liveness_from_poses(poses: list[PoseResult]) -> LivenessResult:
    """Validate liveness from a sequence of pose results (e.g. from Streamlit captures).

    Requires at least one center, one left, and one right pose to be present.
    This rejects a single static photo submission.
    """
    result = LivenessResult()
    seen = set()
    for p in poses:
        if p.label in ("center", "left", "right"):
            seen.add(p.label)

    for angle in ["center", "left", "right"]:
        if angle in seen:
            result.steps_passed.append(angle)
        else:
            result.steps_failed.append(angle)

    result.alive = len(result.steps_failed) == 0
    if not result.alive:
        missing = ", ".join(result.steps_failed)
        result.reason = f"missing_angles: {missing}"
        log.warning("Liveness (photo) FAILED: missing %s", missing)
    else:
        log.info("Liveness (photo) PASSED: all angles present")
    return result

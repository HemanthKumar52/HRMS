"""Real-time face verification with liveness-aware pipeline.

Features:
- MediaPipe detection every frame for smooth UI
- ArcFace embedding + multi-angle matching every 3rd frame
- Pose overlay (yaw/pitch/roll) on every face
- Color-coded confidence: green=high, orange=low, red=unknown
- Liveness check integration via 'l' key
"""

from __future__ import annotations

import time

import cv2

from alerts import handle_unknown_face
from config import CAMERA_BACKEND, CAMERA_HEIGHT, CAMERA_INDEX, CAMERA_WIDTH, get_logger
from database import init_db
from face_detector import FaceDetector
from face_embedder import FaceEmbedder
from face_matcher import FaceMatcher
from liveness import run_liveness_check_cli
from pipeline import FaceRecognitionPipeline, FaceResult
from pose_detector import draw_pose_overlay

log = get_logger("verify")


def verify_realtime_cli(
    embedder: FaceEmbedder | None = None,
    threshold: float | None = None,
):
    """Run real-time face verification from webcam."""
    init_db()

    log.info("Loading models...")
    detector = FaceDetector()
    if embedder is None:
        embedder = FaceEmbedder()
    matcher = FaceMatcher(threshold=threshold) if threshold else FaceMatcher()
    matcher.load_from_db()
    pipeline = FaceRecognitionPipeline(embedder, matcher)

    if matcher.num_registered == 0:
        print("Warning: No faces registered. All faces will be UNKNOWN.")
        print("Register first: python main.py register --name <name>")

    cap = cv2.VideoCapture(CAMERA_INDEX, CAMERA_BACKEND)
    cap.set(cv2.CAP_PROP_FRAME_WIDTH, CAMERA_WIDTH)
    cap.set(cv2.CAP_PROP_FRAME_HEIGHT, CAMERA_HEIGHT)

    if not cap.isOpened():
        log.error("Could not open camera")
        return

    print("Verification running. Keys: 'q'=quit, 'r'=reload DB, 'l'=liveness check")

    frame_count = 0
    fps_start = time.time()
    fps_counter = 0
    fps_display = 0.0
    last_face_results: list[FaceResult] = []
    last_quality = ""

    while True:
        ret, frame = cap.read()
        if not ret:
            continue

        frame_count += 1
        fps_counter += 1
        elapsed = time.time() - fps_start
        if elapsed >= 1.0:
            fps_display = fps_counter / elapsed
            fps_counter = 0
            fps_start = time.time()

        # MediaPipe every frame
        detected = detector.detect(frame)

        # Full pipeline every 3rd frame
        if frame_count % 3 == 0:
            result = pipeline.process(frame, enhance=False)
            last_face_results = result.faces
            if result.quality:
                last_quality = ", ".join(result.quality.issues) if result.quality.issues else "Good"

            for fr in result.faces:
                if not fr.match.matched and not fr.rejected:
                    x1, y1, x2, y2 = fr.bbox
                    handle_unknown_face(frame, (x1, y1, x2 - x1, y2 - y1), fr.match.score)

        # --- Draw ---
        display = frame.copy()

        # Thin grey MediaPipe boxes
        for face in detected:
            x, y, w, h = face.bbox
            cv2.rectangle(display, (x, y), (x + w, y + h), (180, 180, 180), 1)

        # Pipeline results
        for fr in last_face_results:
            if fr.rejected:
                continue
            x1, y1, x2, y2 = fr.bbox
            m = fr.match

            if m.matched and m.confidence == "high":
                color = (0, 255, 0)
                label = f"{m.name} ({m.score:.2f})"
            elif m.matched and m.confidence == "low":
                color = (0, 200, 255)
                label = f"{m.name}? ({m.score:.2f})"
            else:
                color = (0, 0, 255)
                label = f"UNKNOWN ({m.score:.2f})"

            cv2.rectangle(display, (x1, y1), (x2, y2), color, 2)
            cv2.putText(display, label, (x1, y1 - 10),
                        cv2.FONT_HERSHEY_SIMPLEX, 0.6, color, 2)

            # Pose info below bbox
            if fr.pose:
                pose_text = f"{fr.pose.label} yaw={fr.pose.yaw:.0f}"
                cv2.putText(display, pose_text, (x1, y2 + 18),
                            cv2.FONT_HERSHEY_SIMPLEX, 0.4, (200, 200, 200), 1)
                if m.matched and m.angle_scores:
                    angles_text = " ".join(f"{a}:{s:.2f}" for a, s in m.angle_scores.items())
                    cv2.putText(display, angles_text, (x1, y2 + 36),
                                cv2.FONT_HERSHEY_SIMPLEX, 0.35, (180, 180, 180), 1)

        # HUD
        cv2.putText(display, f"FPS: {fps_display:.1f}", (10, 25),
                    cv2.FONT_HERSHEY_SIMPLEX, 0.6, (255, 255, 0), 2)
        cv2.putText(display, f"Registered: {matcher.num_registered}", (10, 50),
                    cv2.FONT_HERSHEY_SIMPLEX, 0.5, (255, 255, 255), 1)
        cv2.putText(display, f"Quality: {last_quality}", (10, 75),
                    cv2.FONT_HERSHEY_SIMPLEX, 0.45, (200, 200, 200), 1)
        cv2.putText(display, "q=quit  r=reload  l=liveness", (10, display.shape[0] - 10),
                    cv2.FONT_HERSHEY_SIMPLEX, 0.4, (150, 150, 150), 1)

        cv2.imshow("Face Verification", display)

        key = cv2.waitKey(1) & 0xFF
        if key == ord('q'):
            break
        elif key == ord('r'):
            matcher.load_from_db()
            print(f"Database reloaded. {matcher.num_registered} faces.")
        elif key == ord('l'):
            cap.release()
            cv2.destroyAllWindows()
            print("\n--- Starting Liveness Check ---")
            liveness = run_liveness_check_cli(embedder)
            if liveness.alive:
                print("Liveness PASSED!")
            else:
                print(f"Liveness FAILED: {liveness.reason}")
            # Reopen camera
            cap = cv2.VideoCapture(CAMERA_INDEX, CAMERA_BACKEND)
            cap.set(cv2.CAP_PROP_FRAME_WIDTH, CAMERA_WIDTH)
            cap.set(cv2.CAP_PROP_FRAME_HEIGHT, CAMERA_HEIGHT)

    cap.release()
    cv2.destroyAllWindows()
    detector.close()
    log.info("Verification stopped")

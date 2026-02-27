"""Face registration with guided multi-angle capture.

Guided enrollment: Center → Right → Left, validated by pose detection.
Stores per-angle embeddings for robust multi-angle matching.
"""

from __future__ import annotations

import time

import cv2
import numpy as np

from config import (
    CAMERA_BACKEND, CAMERA_HEIGHT, CAMERA_INDEX, CAMERA_WIDTH,
    CAPTURES_PER_ANGLE, MAX_EMBEDDINGS_PER_PERSON,
    REGISTRATION_INTERVAL_MS, REGISTRATION_NUM_CAPTURES,
    get_logger,
)
from database import (
    init_db, replace_all_embeddings, replace_angle_embeddings,
    count_embeddings, add_embedding,
)
from face_embedder import FaceEmbedder
from pose_detector import PoseResult, analyze_face, draw_pose_overlay, classify_yaw
from preprocessing import assess_quality, enhance_image

log = get_logger("register")

# Guided capture angle sequence: Center → Right → Left
GUIDED_ANGLES = [
    ("center", "Step 1: Look STRAIGHT at the camera"),
    ("right",  "Step 2: Slowly turn your head to the RIGHT (~30-45 deg)"),
    ("left",   "Step 3: Slowly turn your head to the LEFT (~30-45 deg)"),
]


# ---------------------------------------------------------------------------
# Guided multi-angle registration (CLI)
# ---------------------------------------------------------------------------

def register_face_guided_cli(name: str, embedder: FaceEmbedder | None = None) -> bool:
    """Guided multi-angle registration via webcam.

    Walks the user through Center → Left → Right, capturing embeddings
    per angle with pose validation.
    """
    init_db()
    if embedder is None:
        log.info("Loading face embedding model...")
        embedder = FaceEmbedder()

    cap = cv2.VideoCapture(CAMERA_INDEX, CAMERA_BACKEND)
    cap.set(cv2.CAP_PROP_FRAME_WIDTH, CAMERA_WIDTH)
    cap.set(cv2.CAP_PROP_FRAME_HEIGHT, CAMERA_HEIGHT)

    if not cap.isOpened():
        log.error("Could not open camera")
        return False

    target = CAPTURES_PER_ANGLE
    all_embeddings: list[np.ndarray] = []
    all_angles: list[str] = []
    all_quality: list[float] = []

    for angle_name, instruction in GUIDED_ANGLES:
        print(f"\n[{angle_name.upper()}] {instruction}")
        print(f"  Capturing {target} frames for this angle... Press 'q' to cancel.")

        captured = 0
        last_capture = 0.0
        interval = REGISTRATION_INTERVAL_MS / 1000.0

        while captured < target:
            ret, frame = cap.read()
            if not ret:
                continue

            display = frame.copy()
            now = time.time()

            # Get face + pose for live feedback
            results = embedder.get_embeddings(frame)

            # Draw HUD
            cv2.putText(display, f"Angle: {angle_name.upper()} [{captured}/{target}]",
                        (10, 30), cv2.FONT_HERSHEY_SIMPLEX, 0.7, (0, 255, 255), 2)
            cv2.putText(display, instruction, (10, 60),
                        cv2.FONT_HERSHEY_SIMPLEX, 0.5, (255, 255, 255), 1)

            # Show completed angles
            completed_text = " | ".join(
                f"{a}: {sum(1 for x in all_angles if x == a)}"
                for a, _ in GUIDED_ANGLES
            )
            cv2.putText(display, completed_text, (10, display.shape[0] - 15),
                        cv2.FONT_HERSHEY_SIMPLEX, 0.45, (200, 200, 200), 1)

            pose_ok = False
            if results:
                face = results[0]
                pose = face.pose
                draw_pose_overlay(display, face.bbox, pose)

                if pose and pose.label == angle_name:
                    pose_ok = True
                    # Green border when pose matches
                    cv2.rectangle(display, (5, 5),
                                  (display.shape[1] - 5, display.shape[0] - 5),
                                  (0, 255, 0), 3)
                else:
                    # Yellow border when pose doesn't match
                    current = pose.label if pose else "no face"
                    cv2.putText(display, f"Current pose: {current} (need: {angle_name})",
                                (10, 85), cv2.FONT_HERSHEY_SIMPLEX, 0.5, (0, 165, 255), 1)

                # Auto-capture when pose matches and interval elapsed
                if pose_ok and now - last_capture >= interval:
                    quality = assess_quality(frame)
                    proc_frame = frame
                    if quality.issues:
                        proc_frame, quality = enhance_image(frame, quality)

                    emb = embedder.get_single_embedding(proc_frame)
                    if emb is not None:
                        all_embeddings.append(emb)
                        all_angles.append(angle_name)
                        all_quality.append(quality.blur_score)
                        captured += 1
                        last_capture = now
                        print(f"    [{angle_name}] Captured {captured}/{target} "
                              f"(yaw={pose.yaw:.0f}, blur={quality.blur_score:.0f})")
            else:
                cv2.putText(display, "No face detected", (10, 85),
                            cv2.FONT_HERSHEY_SIMPLEX, 0.5, (0, 0, 255), 1)

            cv2.imshow("Guided Registration", display)
            key = cv2.waitKey(1) & 0xFF
            if key == ord('q'):
                print("Registration cancelled.")
                cap.release()
                cv2.destroyAllWindows()
                return False

    cap.release()
    cv2.destroyAllWindows()

    # Store all embeddings with angle labels
    replace_all_embeddings(name, all_embeddings, all_quality, all_angles)

    angle_summary = {}
    for a in all_angles:
        angle_summary[a] = angle_summary.get(a, 0) + 1
    summary = ", ".join(f"{a}={c}" for a, c in angle_summary.items())
    print(f"\nSuccessfully registered '{name}': {len(all_embeddings)} embeddings ({summary})")
    log.info("Guided registration complete for '%s': %s", name, summary)
    return True


# ---------------------------------------------------------------------------
# Simple registration (CLI, no pose guidance)
# ---------------------------------------------------------------------------

def register_face_cli(name: str, embedder: FaceEmbedder | None = None) -> bool:
    """Simple webcam registration (captures without pose guidance)."""
    init_db()
    if embedder is None:
        embedder = FaceEmbedder()

    cap = cv2.VideoCapture(CAMERA_INDEX, CAMERA_BACKEND)
    cap.set(cv2.CAP_PROP_FRAME_WIDTH, CAMERA_WIDTH)
    cap.set(cv2.CAP_PROP_FRAME_HEIGHT, CAMERA_HEIGHT)

    if not cap.isOpened():
        log.error("Could not open camera")
        return False

    target = REGISTRATION_NUM_CAPTURES
    print(f"Registering '{name}'. Look at the camera and slowly turn your head.")
    print(f"Capturing {target} frames... Press 'q' to cancel.")

    embeddings: list[np.ndarray] = []
    angles: list[str] = []
    quality_scores: list[float] = []
    last_capture = 0.0
    interval = REGISTRATION_INTERVAL_MS / 1000.0

    while len(embeddings) < target:
        ret, frame = cap.read()
        if not ret:
            continue

        now = time.time()
        display = frame.copy()
        cv2.putText(display, f"Registering: {name} [{len(embeddings)}/{target}]",
                    (10, 30), cv2.FONT_HERSHEY_SIMPLEX, 0.7, (0, 255, 0), 2)

        results = embedder.get_embeddings(frame)
        if results:
            face = results[0]
            if face.pose:
                draw_pose_overlay(display, face.bbox, face.pose)

        cv2.imshow("Register Face", display)

        if now - last_capture >= interval and results:
            quality = assess_quality(frame)
            proc = frame
            if quality.issues:
                proc, quality = enhance_image(frame, quality)

            emb = embedder.get_single_embedding(proc)
            if emb is not None:
                pose_label = results[0].pose.label if results[0].pose else "any"
                embeddings.append(emb)
                angles.append(pose_label)
                quality_scores.append(quality.blur_score)
                last_capture = now
                print(f"  Captured {len(embeddings)}/{target} (pose={pose_label})")

        if cv2.waitKey(1) & 0xFF == ord('q'):
            print("Cancelled.")
            cap.release()
            cv2.destroyAllWindows()
            return False

    cap.release()
    cv2.destroyAllWindows()

    replace_all_embeddings(name, embeddings, quality_scores, angles)
    print(f"Successfully registered '{name}' with {len(embeddings)} embeddings.")
    return True


# ---------------------------------------------------------------------------
# Batch registration from images
# ---------------------------------------------------------------------------

def register_face_from_images(
    name: str,
    image_paths: list[str],
    embedder: FaceEmbedder | None = None,
) -> bool:
    """Register from image files. Auto-detects pose angle per image."""
    init_db()
    if embedder is None:
        embedder = FaceEmbedder()

    embeddings: list[np.ndarray] = []
    angles: list[str] = []
    quality_scores: list[float] = []

    for path in image_paths:
        frame = cv2.imread(path)
        if frame is None:
            log.warning("Could not read %s", path)
            continue

        quality = assess_quality(frame)
        proc = frame
        if quality.issues:
            proc, quality = enhance_image(frame, quality)

        result = embedder.get_single_result(proc)
        if result is not None:
            pose_label = result.pose.label if result.pose else "any"
            embeddings.append(result.embedding)
            angles.append(pose_label)
            quality_scores.append(quality.blur_score)
            print(f"  {path}: pose={pose_label}, blur={quality.blur_score:.0f}")
        else:
            print(f"  {path}: no face found")

    if not embeddings:
        log.error("No valid embeddings for '%s'", name)
        return False

    replace_all_embeddings(name, embeddings, quality_scores, angles)
    angle_summary = {}
    for a in angles:
        angle_summary[a] = angle_summary.get(a, 0) + 1
    summary = ", ".join(f"{a}={c}" for a, c in angle_summary.items())
    print(f"Registered '{name}': {len(embeddings)} embeddings ({summary})")
    return True


def add_samples_to_existing(
    name: str,
    image_paths: list[str],
    embedder: FaceEmbedder | None = None,
) -> bool:
    """Add more sample embeddings to an already registered person."""
    init_db()
    if embedder is None:
        embedder = FaceEmbedder()

    current = count_embeddings(name)
    if current >= MAX_EMBEDDINGS_PER_PERSON:
        print(f"'{name}' already has {current} embeddings (max={MAX_EMBEDDINGS_PER_PERSON}).")
        return False

    added = 0
    for path in image_paths:
        if current + added >= MAX_EMBEDDINGS_PER_PERSON:
            break
        frame = cv2.imread(path)
        if frame is None:
            continue
        quality = assess_quality(frame)
        if quality.issues:
            frame, quality = enhance_image(frame, quality)
        result = embedder.get_single_result(frame)
        if result is not None:
            angle = result.pose.label if result.pose else "any"
            add_embedding(name, result.embedding, angle, quality.blur_score)
            added += 1
            print(f"  Added {path} (pose={angle})")

    print(f"Added {added} embeddings to '{name}' (total: {current + added})")
    return added > 0

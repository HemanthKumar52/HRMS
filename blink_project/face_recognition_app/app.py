"""Streamlit web UI for the Face Recognition System.

Pages: Dashboard, Register (guided multi-angle), Verify, Liveness, Manage.
"""

import time
import threading

import cv2
import numpy as np
import streamlit as st
from PIL import Image

from config import (
    ANGLES, COSINE_THRESHOLD, LOW_CONFIDENCE_THRESHOLD,
    CAMERA_INDEX, CAMERA_BACKEND, CAMERA_WIDTH, CAMERA_HEIGHT, CAPTURES_PER_ANGLE,
    ensure_dirs, ARCFACE_PROVIDERS,
)
from database import (
    init_db, list_names, delete_face, get_name_counts, get_angle_counts,
    total_embeddings, replace_all_embeddings, add_embedding, count_embeddings,
)
from face_embedder import FaceEmbedder
from face_matcher import FaceMatcher
from liveness import validate_liveness_from_poses
from pipeline import FaceRecognitionPipeline
from pose_detector import PoseResult, classify_yaw, analyze_face, draw_pose_overlay
from preprocessing import assess_quality, enhance_image


@st.cache_resource
def load_embedder():
    return FaceEmbedder()


def get_pipeline(threshold: float, low_threshold: float):
    embedder = load_embedder()
    matcher = FaceMatcher(threshold=threshold, low_threshold=low_threshold)
    matcher.load_from_db()
    return FaceRecognitionPipeline(embedder, matcher), matcher


def pil_to_bgr(pil_image: Image.Image) -> np.ndarray:
    return cv2.cvtColor(np.array(pil_image.convert("RGB")), cv2.COLOR_RGB2BGR)


def bgr_to_rgb(bgr: np.ndarray) -> np.ndarray:
    return cv2.cvtColor(bgr, cv2.COLOR_BGR2RGB)


# ---------------------------------------------------------------------------
# Quality display
# ---------------------------------------------------------------------------

def show_quality_report(quality):
    if quality is None:
        return
    c1, c2, c3, c4 = st.columns(4)
    c1.metric("Blur", f"{quality.blur_score:.0f}",
              delta="OK" if not quality.is_blurry else "Blurry",
              delta_color="normal" if not quality.is_blurry else "inverse")
    c2.metric("Brightness", f"{quality.brightness:.0f}",
              delta="OK" if not (quality.is_dark or quality.is_bright) else "Poor",
              delta_color="normal" if not (quality.is_dark or quality.is_bright) else "inverse")
    c3.metric("Noise", f"{quality.noise_sigma:.1f}",
              delta="OK" if not quality.is_noisy else "Noisy",
              delta_color="normal" if not quality.is_noisy else "inverse")
    c4.metric("Resolution", f"{quality.resolution[1]}x{quality.resolution[0]}")
    if quality.enhancements_applied:
        st.info(f"Enhancements: {', '.join(quality.enhancements_applied)}")


# ---------------------------------------------------------------------------
# Annotate + presence checklist
# ---------------------------------------------------------------------------

def annotate_and_collect(bgr_frame, pipeline_result, matcher):
    display = bgr_frame.copy()
    if pipeline_result.frame_enhanced is not None:
        display = pipeline_result.frame_enhanced.copy()

    matched_names = {}
    for fr in pipeline_result.faces:
        if fr.rejected:
            continue
        x1, y1, x2, y2 = fr.bbox
        m = fr.match
        if m.matched and m.confidence == "high":
            color, label = (0, 255, 0), f"{m.name} ({m.score:.2f})"
            matched_names[m.name] = (m.score, "high", m.best_angle)
        elif m.matched and m.confidence == "low":
            color, label = (0, 200, 255), f"{m.name}? ({m.score:.2f})"
            if m.name not in matched_names:
                matched_names[m.name] = (m.score, "low", m.best_angle)
        else:
            color, label = (0, 0, 255), f"UNKNOWN ({m.score:.2f})"
        cv2.rectangle(display, (x1, y1), (x2, y2), color, 2)
        cv2.putText(display, label, (x1, y1 - 10),
                    cv2.FONT_HERSHEY_SIMPLEX, 0.7, color, 2)
        # Pose label
        if fr.pose:
            cv2.putText(display, f"{fr.pose.label} yaw={fr.pose.yaw:.0f}",
                        (x1, y2 + 18), cv2.FONT_HERSHEY_SIMPLEX, 0.4, (200, 200, 200), 1)

    return bgr_to_rgb(display), matched_names


def show_presence_checklist(matched_names):
    all_names = list_names()
    if not all_names:
        return
    st.subheader("Attendance")
    for name in all_names:
        if name in matched_names:
            score, confidence, best_angle = matched_names[name]
            if confidence == "high":
                st.markdown(
                    f"<div style='padding:6px 10px; margin:3px 0; background:#d4edda; "
                    f"border-left:4px solid #28a745; border-radius:4px;'>"
                    f"<span style='color:#155724; font-size:1.1em;'>"
                    f"&#10004; <b>{name}</b> &mdash; Present "
                    f"(score: {score:.2f}, matched angle: {best_angle})</span></div>",
                    unsafe_allow_html=True)
            else:
                st.markdown(
                    f"<div style='padding:6px 10px; margin:3px 0; background:#fff3cd; "
                    f"border-left:4px solid #ffc107; border-radius:4px;'>"
                    f"<span style='color:#856404; font-size:1.1em;'>"
                    f"&#9888; <b>{name}</b> &mdash; Possible match "
                    f"(score: {score:.2f})</span></div>",
                    unsafe_allow_html=True)
        else:
            st.markdown(
                f"<div style='padding:6px 10px; margin:3px 0; background:#f8d7da; "
                f"border-left:4px solid #dc3545; border-radius:4px;'>"
                f"<span style='color:#721c24; font-size:1.1em;'>"
                f"&#10008; <b>{name}</b> &mdash; Absent</span></div>",
                unsafe_allow_html=True)

    present = sum(1 for _, (_, c, _) in matched_names.items() if c == "high")
    st.caption(f"{present}/{len(all_names)} confirmed present")


# ---------------------------------------------------------------------------
# Pages
# ---------------------------------------------------------------------------

def page_dashboard():
    st.header("Dashboard")
    counts = get_name_counts()
    total = total_embeddings()

    c1, c2, c3 = st.columns(3)
    c1.metric("People", len(counts))
    c2.metric("Embeddings", total)
    c3.metric("GPU", "CUDA" if "CUDA" in str(ARCFACE_PROVIDERS) else "CPU")

    if counts:
        st.subheader("Registered Faces")
        for name, count in counts.items():
            angle_info = get_angle_counts(name)
            breakdown = " | ".join(f"{a}: {c}" for a, c in angle_info.items())
            quality = "Good" if count >= 5 and len(angle_info) >= 2 else "Add more angles"
            st.progress(min(count / 15, 1.0),
                        text=f"**{name}** — {count} embeddings ({breakdown}) — {quality}")
    else:
        st.info("No faces registered. Go to Register page.")


def page_register():
    st.header("Register Face (Multi-Angle)")

    name = st.text_input("Name", placeholder="Enter name")
    if not name:
        st.info("Enter a name to begin registration.")
        return

    # Initialize session state for guided capture
    if "reg_step" not in st.session_state:
        st.session_state.reg_step = 0
        st.session_state.reg_embeddings = []
        st.session_state.reg_angles = []
        st.session_state.reg_qualities = []
        st.session_state.reg_poses = []

    st.divider()

    # --- Option 1: Upload images ---
    st.subheader("Option 1: Upload Images")
    st.caption("Upload 5-10 images with different angles (front, left profile, right profile)")
    uploaded = st.file_uploader("Upload face images", type=["jpg", "jpeg", "png", "bmp"],
                                accept_multiple_files=True)

    if uploaded and st.button("Register from Uploads", type="primary"):
        embedder = load_embedder()
        embeddings, angles, scores = [], [], []
        progress = st.progress(0)

        for i, f in enumerate(uploaded):
            bgr = pil_to_bgr(Image.open(f))
            quality = assess_quality(bgr)
            if quality.issues:
                bgr, quality = enhance_image(bgr, quality)

            result = embedder.get_single_result(bgr)
            if result is not None:
                angle = result.pose.label if result.pose else "any"
                embeddings.append(result.embedding)
                angles.append(angle)
                scores.append(quality.blur_score)
                st.success(f"{f.name}: pose=**{angle}**, yaw={result.pose.yaw:.0f}")
            else:
                st.warning(f"{f.name}: no face found")
            progress.progress((i + 1) / len(uploaded))

        if embeddings:
            replace_all_embeddings(name, embeddings, scores, angles)
            angle_counts = {}
            for a in angles:
                angle_counts[a] = angle_counts.get(a, 0) + 1
            summary = ", ".join(f"{a}={c}" for a, c in angle_counts.items())
            st.success(f"Registered **{name}**: {len(embeddings)} embeddings ({summary})")

            # Liveness validation
            unique_angles = set(angles)
            if all(a in unique_angles for a in ANGLES):
                st.success("All angles present — liveness validation PASSED")
            else:
                missing = [a for a in ANGLES if a not in unique_angles]
                st.warning(f"Missing angles: {', '.join(missing)}. "
                           f"Add images with these poses for better accuracy.")
        else:
            st.error("No valid embeddings found.")

    st.divider()

    # --- Option 2: Real-Time Auto-Capture ---
    st.subheader("Option 2: Live Camera Auto-Capture")
    st.caption("Click **Start Camera** below. The system will show a live video feed, "
               "detect your face angle in real time, and automatically capture when the "
               "correct pose is held steady for ~1 second.")

    needed = ["center", "right", "left"]
    captured_angles = set(st.session_state.reg_angles)
    remaining = [a for a in needed if a not in captured_angles]
    all_done = len(remaining) == 0

    # --- Live progress tracker ---
    label_map = {"center": "Center (straight)", "right": "Right side", "left": "Left side"}
    for a in needed:
        count = sum(1 for x in st.session_state.reg_angles if x == a)
        if a in captured_angles:
            st.markdown(
                f"<div style='padding:6px 10px; margin:3px 0; background:#d4edda; "
                f"border-left:4px solid #28a745; border-radius:4px;'>"
                f"<span style='color:#155724; font-size:1.05em;'>"
                f"&#10004; <b>{label_map[a]}</b> — {count} captured</span></div>",
                unsafe_allow_html=True)
        else:
            st.markdown(
                f"<div style='padding:6px 10px; margin:3px 0; background:#fff3cd; "
                f"border-left:4px solid #ffc107; border-radius:4px;'>"
                f"<span style='color:#856404; font-size:1.05em;'>"
                f"&#9203; <b>{label_map[a]}</b> — waiting</span></div>",
                unsafe_allow_html=True)

    if all_done:
        # All 3 angles captured — auto-save
        angle_counts = {}
        for a in st.session_state.reg_angles:
            angle_counts[a] = angle_counts.get(a, 0) + 1
        summary = ", ".join(f"{a}={c}" for a, c in angle_counts.items())

        replace_all_embeddings(
            name,
            st.session_state.reg_embeddings,
            st.session_state.reg_qualities,
            st.session_state.reg_angles,
        )

        st.success(f"Registered **{name}** — {len(st.session_state.reg_embeddings)} "
                   f"embeddings saved ({summary})")

        if st.session_state.reg_poses:
            liveness = validate_liveness_from_poses(st.session_state.reg_poses)
            if liveness.alive:
                st.success("Liveness PASSED — all 3 angles confirmed as real person")

        st.balloons()

        if st.button("Register Another Person"):
            st.session_state.reg_step = 0
            st.session_state.reg_embeddings = []
            st.session_state.reg_angles = []
            st.session_state.reg_qualities = []
            st.session_state.reg_poses = []
            st.rerun()
        return

    # Show which angle is needed next
    next_angle = remaining[0]
    hint_map = {"center": "Look STRAIGHT at the camera",
                "right": "Turn your head to the RIGHT",
                "left": "Turn your head to the LEFT"}
    st.info(f"**Next needed: {hint_map[next_angle]}** — hold steady for auto-capture")

    # --- Real-time video auto-capture ---
    if st.button("Start Camera", type="primary", key="start_cam"):
        _run_realtime_capture(name, needed, remaining, CAPTURES_PER_ANGLE)


def _run_realtime_capture(name: str, needed: list, remaining: list, target_per_angle: int):
    """Real-time video loop with auto-capture when correct angle is detected."""
    embedder = load_embedder()

    cap = cv2.VideoCapture(CAMERA_INDEX, CAMERA_BACKEND)
    cap.set(cv2.CAP_PROP_FRAME_WIDTH, CAMERA_WIDTH)
    cap.set(cv2.CAP_PROP_FRAME_HEIGHT, CAMERA_HEIGHT)

    if not cap.isOpened():
        st.error("Could not open camera. Check if another application is using it.")
        return

    label_map = {"center": "Center (straight)", "right": "Right side", "left": "Left side"}
    hint_map = {"center": "Look STRAIGHT at the camera",
                "right": "Turn your head to the RIGHT",
                "left": "Turn your head to the LEFT"}

    video_placeholder = st.empty()
    status_placeholder = st.empty()
    progress_placeholder = st.empty()

    # Auto-capture state
    hold_angle = None        # which angle is currently being held
    hold_start = 0.0         # when the hold started
    hold_required = 1.0      # seconds to hold for auto-capture
    captures_this_angle = 0
    last_capture_time = 0.0
    capture_interval = 0.3   # seconds between captures for same angle

    local_embeddings = list(st.session_state.reg_embeddings)
    local_angles = list(st.session_state.reg_angles)
    local_qualities = list(st.session_state.reg_qualities)
    local_poses = list(st.session_state.reg_poses)
    local_remaining = list(remaining)

    frame_count = 0
    stop_flag = False

    try:
        while not stop_flag and local_remaining:
            ret, frame = cap.read()
            if not ret:
                continue

            frame_count += 1
            display = frame.copy()
            now = time.time()

            current_needed = local_remaining[0] if local_remaining else None
            detected_angle = None
            detected_pose = None
            face_found = False

            # Run face detection + pose every frame
            results = embedder.get_embeddings(frame)

            if results:
                face = results[0]
                face_found = True
                x1, y1, x2, y2 = [int(v) for v in face.bbox]

                # Get pose
                if face.pose:
                    detected_pose = face.pose
                    detected_angle = face.pose.label
                    draw_pose_overlay(display, face.bbox, face.pose)

                    # Color the bbox based on whether angle matches needed
                    if detected_angle == current_needed:
                        cv2.rectangle(display, (x1, y1), (x2, y2), (0, 255, 0), 3)
                    elif detected_angle in local_remaining:
                        cv2.rectangle(display, (x1, y1), (x2, y2), (0, 255, 255), 2)
                    else:
                        cv2.rectangle(display, (x1, y1), (x2, y2), (0, 165, 255), 2)
                else:
                    cv2.rectangle(display, (x1, y1), (x2, y2), (180, 180, 180), 1)

            # --- HUD overlay ---
            h, w = display.shape[:2]

            # Current instruction
            if current_needed:
                instruction = hint_map.get(current_needed, "")
                cv2.putText(display, instruction, (10, 30),
                            cv2.FONT_HERSHEY_SIMPLEX, 0.7, (0, 255, 255), 2)

            # Show detected angle
            if detected_angle:
                angle_color = (0, 255, 0) if detected_angle == current_needed else (0, 165, 255)
                cv2.putText(display, f"Detected: {detected_angle} (yaw={detected_pose.yaw:.0f})",
                            (10, 60), cv2.FONT_HERSHEY_SIMPLEX, 0.5, angle_color, 1)
            elif not face_found:
                cv2.putText(display, "No face detected", (10, 60),
                            cv2.FONT_HERSHEY_SIMPLEX, 0.5, (0, 0, 255), 1)

            # --- Hold-to-capture logic ---
            if detected_angle and detected_angle in local_remaining:
                if hold_angle == detected_angle:
                    hold_duration = now - hold_start
                    # Draw hold progress bar
                    progress_frac = min(hold_duration / hold_required, 1.0)
                    bar_w = int(w * 0.6)
                    bar_x = (w - bar_w) // 2
                    bar_y = h - 40
                    cv2.rectangle(display, (bar_x, bar_y), (bar_x + bar_w, bar_y + 20),
                                  (100, 100, 100), -1)
                    cv2.rectangle(display, (bar_x, bar_y),
                                  (bar_x + int(bar_w * progress_frac), bar_y + 20),
                                  (0, 255, 0), -1)
                    cv2.putText(display, f"Hold steady... {hold_duration:.1f}s",
                                (bar_x, bar_y - 5),
                                cv2.FONT_HERSHEY_SIMPLEX, 0.5, (255, 255, 255), 1)

                    # Auto-capture when held long enough
                    if hold_duration >= hold_required and now - last_capture_time >= capture_interval:
                        quality = assess_quality(frame)
                        proc = frame
                        if quality.issues:
                            proc, quality = enhance_image(frame, quality)
                        emb = embedder.get_single_embedding(proc)
                        if emb is not None:
                            local_embeddings.append(emb)
                            local_angles.append(detected_angle)
                            local_qualities.append(quality.blur_score)
                            if detected_pose:
                                local_poses.append(detected_pose)
                            captures_this_angle += 1
                            last_capture_time = now

                            # Flash green border
                            cv2.rectangle(display, (5, 5), (w - 5, h - 5), (0, 255, 0), 6)
                            cv2.putText(display, f"CAPTURED! ({captures_this_angle}/{target_per_angle})",
                                        (w // 2 - 120, h // 2),
                                        cv2.FONT_HERSHEY_SIMPLEX, 0.8, (0, 255, 0), 2)

                            # Check if enough captures for this angle
                            angle_count = sum(1 for a in local_angles if a == detected_angle)
                            if angle_count >= target_per_angle:
                                local_remaining = [a for a in local_remaining if a != detected_angle]
                                captures_this_angle = 0
                                hold_angle = None
                                hold_start = 0.0
                else:
                    # New angle detected — reset hold timer
                    hold_angle = detected_angle
                    hold_start = now
                    captures_this_angle = sum(1 for a in local_angles if a == detected_angle)
            else:
                hold_angle = None
                hold_start = 0.0

            # Show completed angles in top-right
            y_offset = 25
            for a in needed:
                count = sum(1 for x in local_angles if x == a)
                if count >= target_per_angle:
                    txt = f"[DONE] {a}: {count}"
                    col = (0, 200, 0)
                elif count > 0:
                    txt = f"[{count}/{target_per_angle}] {a}"
                    col = (0, 255, 255)
                else:
                    txt = f"[wait] {a}"
                    col = (150, 150, 150)
                text_size = cv2.getTextSize(txt, cv2.FONT_HERSHEY_SIMPLEX, 0.45, 1)[0]
                cv2.putText(display, txt, (w - text_size[0] - 10, y_offset),
                            cv2.FONT_HERSHEY_SIMPLEX, 0.45, col, 1)
                y_offset += 22

            # Convert and display in Streamlit
            rgb = bgr_to_rgb(display)
            video_placeholder.image(rgb, channels="RGB", use_container_width=True)

            # Update status below video
            if local_remaining:
                next_a = local_remaining[0]
                remaining_text = ", ".join(f"**{label_map[a]}**" for a in local_remaining)
                status_placeholder.markdown(f"Remaining angles: {remaining_text}")
            else:
                status_placeholder.success("All angles captured!")
                break

            # Small delay to prevent CPU overload
            time.sleep(0.03)

    except Exception as e:
        st.error(f"Camera error: {e}")
    finally:
        cap.release()

    # Save results to session state
    st.session_state.reg_embeddings = local_embeddings
    st.session_state.reg_angles = local_angles
    st.session_state.reg_qualities = local_qualities
    st.session_state.reg_poses = local_poses

    # Clear video and rerun to show final result
    video_placeholder.empty()
    status_placeholder.empty()
    progress_placeholder.empty()

    if not local_remaining:
        st.rerun()
    else:
        st.warning("Camera stopped. Click **Start Camera** to continue.")


def page_verify():
    st.header("Verify Faces")
    threshold = st.session_state.get("threshold", COSINE_THRESHOLD)
    low_threshold = st.session_state.get("low_threshold", LOW_CONFIDENCE_THRESHOLD)
    pipeline, matcher = get_pipeline(threshold, low_threshold)

    if matcher.num_registered == 0:
        st.warning("No faces registered. Register faces first.")
        return

    st.subheader("Upload Image")
    uploaded = st.file_uploader("Upload a face image", type=["jpg", "jpeg", "png", "bmp"])
    if uploaded:
        bgr = pil_to_bgr(Image.open(uploaded))
        result = pipeline.process(bgr, enhance=True)
        show_quality_report(result.quality)

        if result.num_faces_detected > 0:
            annotated, matched_names = annotate_and_collect(bgr, result, matcher)
            st.image(annotated, caption="Verification Result", use_container_width=True)

            for fr in result.faces:
                if fr.rejected:
                    st.warning(f"Rejected: {fr.reject_reason}")
                    continue
                m = fr.match
                pose_info = f", pose={fr.pose.label}" if fr.pose else ""
                if m.matched and m.confidence == "high":
                    st.success(f"**{m.name}** — Confirmed (score: {m.score:.3f}, "
                               f"angle: {m.best_angle}{pose_info})")
                    if m.angle_scores:
                        st.caption(f"Per-angle scores: "
                                   + ", ".join(f"{a}={s:.3f}" for a, s in m.angle_scores.items()))
                elif m.matched and m.confidence == "low":
                    st.warning(f"**{m.name}** — Low confidence (score: {m.score:.3f}{pose_info})")
                else:
                    st.error(f"**Unknown** (score: {m.score:.3f}{pose_info})")

            show_presence_checklist(matched_names)
        else:
            st.warning("No face detected.")

    st.divider()
    st.subheader("Camera Capture")
    camera = st.camera_input("Take a photo for verification")
    if camera:
        bgr = pil_to_bgr(Image.open(camera))
        result = pipeline.process(bgr, enhance=True)
        show_quality_report(result.quality)

        if result.num_faces_detected > 0:
            annotated, matched_names = annotate_and_collect(bgr, result, matcher)
            st.image(annotated, caption="Verification Result", use_container_width=True)

            for fr in result.faces:
                if fr.rejected:
                    continue
                m = fr.match
                if m.matched and m.confidence == "high":
                    st.success(f"**{m.name}** — Confirmed (score: {m.score:.3f})")
                elif m.matched and m.confidence == "low":
                    st.warning(f"**{m.name}** — Low confidence (score: {m.score:.3f})")
                else:
                    st.error(f"**Unknown** (score: {m.score:.3f})")

            show_presence_checklist(matched_names)
        else:
            st.warning("No face detected.")


def page_manage():
    st.header("Manage Faces")
    counts = get_name_counts()

    if not counts:
        st.info("No faces registered.")
        return

    st.write(f"**{len(counts)} people, {total_embeddings()} total embeddings**")

    for name, count in counts.items():
        angle_info = get_angle_counts(name)
        breakdown = " | ".join(f"{a}: {c}" for a, c in angle_info.items())
        has_multi_angle = len(angle_info) >= 2
        quality_icon = "🟢" if count >= 5 and has_multi_angle else "🟡" if count >= 3 else "🔴"

        col1, col2, col3 = st.columns([4, 1, 1])
        col1.write(f"**{name}** — {count} embeddings ({breakdown})")
        col2.write(quality_icon)
        if col3.button("Delete", key=f"del_{name}"):
            delete_face(name)
            st.success(f"Deleted '{name}'.")
            st.rerun()


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main():
    st.set_page_config(page_title="Face Recognition System", layout="wide")
    ensure_dirs()
    init_db()

    st.sidebar.title("Face Recognition")
    page = st.sidebar.radio("Navigation",
                            ["Dashboard", "Register", "Verify", "Manage"])

    st.sidebar.divider()
    st.sidebar.subheader("Matching Thresholds")
    threshold = st.sidebar.slider("Confident", 0.30, 0.70, COSINE_THRESHOLD, 0.05,
                                  help="Above this = confirmed match (green)")
    low_threshold = st.sidebar.slider("Low-confidence", 0.20, 0.50,
                                      LOW_CONFIDENCE_THRESHOLD, 0.05,
                                      help="Between this and confident = uncertain (orange)")
    st.session_state["threshold"] = threshold
    st.session_state["low_threshold"] = low_threshold

    st.sidebar.divider()
    st.sidebar.caption(f"Providers: {', '.join(ARCFACE_PROVIDERS)}")
    st.sidebar.caption("Multi-angle matching: center + left + right")

    if page == "Dashboard":
        page_dashboard()
    elif page == "Register":
        page_register()
    elif page == "Verify":
        page_verify()
    elif page == "Manage":
        page_manage()


if __name__ == "__main__":
    main()

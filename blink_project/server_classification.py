"""
Server-side blink detection and frame classification module
Handles classification of frames as blinked or unblinked
"""

import cv2
import mediapipe as mp
import numpy as np
from ear_utils import eye_aspect_ratio
from spectacle_detection_cnn import SpectacleDetectionCNN

# Mediapipe Setup
BaseOptions = mp.tasks.BaseOptions
FaceLandmarker = mp.tasks.vision.FaceLandmarker
FaceLandmarkerOptions = mp.tasks.vision.FaceLandmarkerOptions
VisionRunningMode = mp.tasks.vision.RunningMode

options = FaceLandmarkerOptions(
    base_options=BaseOptions(model_asset_path='face_landmarker.task'),
    running_mode=VisionRunningMode.IMAGE,
    num_faces=3
)

face_landmarker = FaceLandmarker.create_from_options(options)

LEFT_EYE_INDICES = [33, 160, 158, 133, 153, 144]
RIGHT_EYE_INDICES = [362, 385, 387, 263, 373, 380]

# Minimum EAR difference between open and closed eyes to confirm a blink occurred.
# A real blink typically produces a 0.05-0.15 EAR drop, so 0.03 is very lenient.
MIN_BLINK_EAR_DROP = 0.03


def classify_frames(frame_list):
    """
    Classify a list of frames as blinked or unblinked using relative EAR.
    Instead of fixed thresholds, picks the frame with lowest EAR (blink)
    and highest EAR (open eyes). If the difference is large enough, liveness passes.

    Args:
        frame_list: List of OpenCV frames (BGR format)

    Returns:
        Dictionary with 'blinked', 'unblinked' lists and 'multiple_faces' flag
    """
    blinked_frames = []
    unblinked_frames = []

    # Collect EAR values for all frames with detected faces
    frame_ears = []
    no_face_count = 0
    multiple_faces_count = 0

    for frame_idx, frame in enumerate(frame_list):
        try:
            rgb_frame = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
            mp_image = mp.Image(image_format=mp.ImageFormat.SRGB, data=rgb_frame)
            results = face_landmarker.detect(mp_image)

            if not results.face_landmarks:
                no_face_count += 1
                continue

            # Multiple face check — only 1 face allowed
            if len(results.face_landmarks) > 1:
                multiple_faces_count += 1
                print(f"  WARNING: {len(results.face_landmarks)} faces detected in frame {frame_idx}")
                continue

            landmarks = results.face_landmarks[0]

            left_ear = eye_aspect_ratio(landmarks, LEFT_EYE_INDICES)
            right_ear = eye_aspect_ratio(landmarks, RIGHT_EYE_INDICES)
            ear = (left_ear + right_ear) / 2.0

            frame_ears.append({
                'frame': frame,
                'frame_idx': frame_idx,
                'ear': ear,
            })
        except Exception as e:
            print(f"Error classifying frame {frame_idx}:", e)
            continue

    # If majority of frames have multiple faces, flag it
    total_valid = len(frame_ears) + multiple_faces_count
    multiple_faces_detected = (
        multiple_faces_count > 0 and
        total_valid > 0 and
        multiple_faces_count >= total_valid * 0.3
    )

    if multiple_faces_detected:
        print(f"  MULTIPLE FACES: {multiple_faces_count}/{total_valid} frames have >1 face — REJECTED")
        return {
            'blinked': [],
            'unblinked': [],
            'multiple_faces': True,
            'multi_face_count': multiple_faces_count,
        }

    if not frame_ears:
        print(f"  WARNING: No faces detected in any of {len(frame_list)} frames ({no_face_count} no-face)")
        return {
            'blinked': [],
            'unblinked': [],
            'multiple_faces': False,
            'multi_face_count': multiple_faces_count,
        }

    # Debug: show EAR distribution
    ears = [f['ear'] for f in frame_ears]
    min_ear = min(ears)
    max_ear = max(ears)
    ear_drop = max_ear - min_ear
    print(f"  EAR stats: min={min_ear:.4f}, max={max_ear:.4f}, drop={ear_drop:.4f}, avg={sum(ears)/len(ears):.4f} ({len(ears)} faces, {no_face_count} no-face)")
    print(f"  EAR values: {[round(e, 4) for e in ears]}")
    print(f"  Blink detection: need drop > {MIN_BLINK_EAR_DROP} (got {ear_drop:.4f})")

    # Relative approach: pick lowest EAR as blink, highest as open
    # If the difference is large enough, a real blink occurred
    if ear_drop >= MIN_BLINK_EAR_DROP:
        best_closed = min(frame_ears, key=lambda f: f['ear'])
        best_open = max(frame_ears, key=lambda f: f['ear'])

        blinked_frames.append({**best_closed, 'type': 'blinked'})
        unblinked_frames.append({**best_open, 'type': 'unblinked'})

        print(f"  BLINK detected: EAR={best_closed['ear']:.4f} (frame {best_closed['frame_idx']})")
        print(f"  OPEN detected: EAR={best_open['ear']:.4f} (frame {best_open['frame_idx']})")
        print(f"  LIVENESS PASSED (drop={ear_drop:.4f})")
    else:
        print(f"  LIVENESS FAILED — no significant blink detected (drop={ear_drop:.4f} < {MIN_BLINK_EAR_DROP})")

    return {
        'blinked': blinked_frames,
        'unblinked': unblinked_frames,
        'multiple_faces': False,
        'multi_face_count': multiple_faces_count,
    }


def detect_spectacles_in_frame(frame):
    """
    Detect if spectacles are worn in the given frame using advanced CNN.
    
    Args:
        frame: OpenCV frame (BGR format)
    
    Returns:
        Dict with detection results
    """
    try:
        rgb_frame = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
        mp_image = mp.Image(image_format=mp.ImageFormat.SRGB, data=rgb_frame)
        
        results = face_landmarker.detect(mp_image)
        
        if not results.face_landmarks:
            return {'detected': False, 'confidence': 0.0}
        
        landmarks = results.face_landmarks[0]
        detection_result = SpectacleDetectionCNN.detect_spectacles(frame, landmarks)
        return detection_result
    
    except Exception as e:
        print(f"Error detecting spectacles:", e)
        return {'detected': False, 'confidence': 0.0}

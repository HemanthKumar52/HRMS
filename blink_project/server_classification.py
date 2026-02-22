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

EAR_THRESHOLD = 0.25
FULLY_OPEN_THRESHOLD = 0.37


def classify_frames(frame_list):
    """
    Classify a list of frames as blinked or unblinked based on EAR.
    
    Args:
        frame_list: List of OpenCV frames (BGR format)
    
    Returns:
        Dictionary with 'blinked' and 'unblinked' lists containing classified frames
    """
    blinked_frames = []
    unblinked_frames = []
    
    blinking = False
    blinked_saved = False
    unblinked_saved = False
    
    for frame_idx, frame in enumerate(frame_list):
        try:
            # Convert BGR to RGB for MediaPipe
            rgb_frame = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
            
            # Create MediaPipe image
            mp_image = mp.Image(image_format=mp.ImageFormat.SRGB, data=rgb_frame)
            
            # Get landmarks
            results = face_landmarker.detect(mp_image)
            
            if not results.face_landmarks:
                continue
            
            landmarks = results.face_landmarks[0]
            
            # Calculate EAR
            left_ear = eye_aspect_ratio(landmarks, LEFT_EYE_INDICES)
            right_ear = eye_aspect_ratio(landmarks, RIGHT_EYE_INDICES)
            ear = (left_ear + right_ear) / 2.0
            
            # BLINK DETECTION: Eyes closing
            if ear < EAR_THRESHOLD and not blinking and not blinked_saved:
                blinking = True
                blinked_frames.append({
                    'frame': frame,
                    'frame_idx': frame_idx,
                    'ear': ear,
                    'type': 'blinked'
                })
                blinked_saved = True
            
            # EYES OPEN: Eyes fully open
            if ear > FULLY_OPEN_THRESHOLD and blinking and not unblinked_saved:
                blinking = False
                unblinked_frames.append({
                    'frame': frame,
                    'frame_idx': frame_idx,
                    'ear': ear,
                    'type': 'unblinked'
                })
                unblinked_saved = True
            
            # Reset for next cycle
            if blinked_saved and unblinked_saved:
                blinked_saved = False
                unblinked_saved = False
                blinking = False
        
        except Exception as e:
            print(f"Error classifying frame {frame_idx}:", e)
            continue
    
    return {
        'blinked': blinked_frames,
        'unblinked': unblinked_frames
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

"""
Test script for improved spectacle detection CNN
"""

import cv2
import numpy as np
import mediapipe as mp
from spectacle_detection_cnn import SpectacleDetectionCNN

# Initialize MediaPipe FaceMesh
BaseOptions = mp.tasks.BaseOptions
FaceLandmarker = mp.tasks.vision.FaceLandmarker
FaceLandmarkerOptions = mp.tasks.vision.FaceLandmarkerOptions
VisionRunningMode = mp.tasks.vision.RunningMode

options = FaceLandmarkerOptions(
    base_options=BaseOptions(model_asset_path='face_landmarker.task'),
    running_mode=VisionRunningMode.IMAGE,
    num_faces=1
)

face_landmarker = FaceLandmarker.create_from_options(options)

def test_spectacle_detection_on_camera():
    """
    Test spectacle detection in real-time from camera
    """
    cap = cv2.VideoCapture(0)
    
    print("=" * 60)
    print("SPECTACLE DETECTION TEST")
    print("=" * 60)
    print("\nInstructions:")
    print("1. Look at the camera")
    print("2. Without glasses: Detection should show LOW scores")
    print("3. With glasses: Detection should show HIGH scores")
    print("4. Press 'q' to quit\n")
    
    while True:
        ret, frame = cap.read()
        if not ret:
            break
        
        frame = cv2.flip(frame, 1)
        h, w = frame.shape[:2]
        
        # Convert to RGB
        rgb_frame = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
        mp_image = mp.Image(image_format=mp.ImageFormat.SRGB, data=rgb_frame)
        
        # Detect face landmarks
        results = face_landmarker.detect(mp_image)
        
        if not results.face_landmarks:
            cv2.putText(frame, "No face detected", (20, 40), cv2.FONT_HERSHEY_SIMPLEX, 1, (0, 0, 255), 2)
        else:
            landmarks = results.face_landmarks[0]
            
            # Run spectacle detection
            detection_result = SpectacleDetectionCNN.detect_spectacles(frame, landmarks)
            
            # Extract scores
            detected = detection_result['detected']
            confidence = detection_result['confidence']
            frame_score = detection_result['frame_score']
            lens_score = detection_result['lens_score']
            symmetry_score = detection_result['symmetry_score']
            bridge_score = detection_result['bridge_score']
            
            # Display results
            bg_color = (0, 255, 0) if not detected else (0, 0, 255)
            text_color = (255, 255, 255)
            
            cv2.rectangle(frame, (10, 10), (w-10, h-10), bg_color, 3)
            
            y_offset = 40
            cv2.putText(frame, f"Spectacles: {'DETECTED' if detected else 'NOT DETECTED'}", 
                       (20, y_offset), cv2.FONT_HERSHEY_SIMPLEX, 1, (255, 0, 0) if detected else (0, 255, 0), 2)
            y_offset += 40
            
            cv2.putText(frame, f"Confidence: {confidence:.2f}", 
                       (20, y_offset), cv2.FONT_HERSHEY_SIMPLEX, 0.8, text_color, 1)
            y_offset += 35
            
            cv2.putText(frame, f"Frame Score: {frame_score:.2f}", 
                       (20, y_offset), cv2.FONT_HERSHEY_SIMPLEX, 0.7, text_color, 1)
            y_offset += 30
            
            cv2.putText(frame, f"Lens Score: {lens_score:.2f}", 
                       (20, y_offset), cv2.FONT_HERSHEY_SIMPLEX, 0.7, text_color, 1)
            y_offset += 30
            
            cv2.putText(frame, f"Symmetry Score: {symmetry_score:.2f}", 
                       (20, y_offset), cv2.FONT_HERSHEY_SIMPLEX, 0.7, text_color, 1)
            y_offset += 30
            
            cv2.putText(frame, f"Bridge Score: {bridge_score:.2f}", 
                       (20, y_offset), cv2.FONT_HERSHEY_SIMPLEX, 0.7, text_color, 1)
            y_offset += 30
            
            threshold = 0.40
            cv2.putText(frame, f"Threshold: {threshold:.2f}", 
                       (20, y_offset), cv2.FONT_HERSHEY_SIMPLEX, 0.7, (200, 200, 200), 1)
        
        cv2.imshow("Spectacle Detection Test", frame)
        
        key = cv2.waitKey(1) & 0xFF
        if key == ord('q'):
            break
    
    cap.release()
    cv2.destroyAllWindows()
    
    print("\n✓ Test completed")

if __name__ == "__main__":
    test_spectacle_detection_on_camera()

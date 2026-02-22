"""
Face comparison module using face_recognition library.
Compares a captured face against a stored reference face.
"""

import cv2
import numpy as np
import face_recognition

# Match threshold: face_recognition uses euclidean distance
# Lower distance = more similar. Standard threshold is 0.6
MATCH_THRESHOLD = 0.6


def compare_faces(captured_frame, reference_frame):
    """
    Compare two face images and determine if they are the same person.

    Args:
        captured_frame: OpenCV frame (BGR) of the captured face
        reference_frame: OpenCV frame (BGR) of the stored reference face

    Returns:
        dict with 'match' (bool), 'confidence' (float 0-1), 'error' (str or None)
    """
    try:
        # Convert BGR to RGB (face_recognition expects RGB)
        captured_rgb = cv2.cvtColor(captured_frame, cv2.COLOR_BGR2RGB)
        reference_rgb = cv2.cvtColor(reference_frame, cv2.COLOR_BGR2RGB)

        # Get face encodings (128-dimensional face descriptor)
        captured_encodings = face_recognition.face_encodings(captured_rgb)
        reference_encodings = face_recognition.face_encodings(reference_rgb)

        if not captured_encodings:
            return {
                'match': False,
                'confidence': 0.0,
                'error': 'No face detected in captured image'
            }

        if not reference_encodings:
            return {
                'match': False,
                'confidence': 0.0,
                'error': 'No face detected in reference image'
            }

        # Use the first face found in each image
        captured_encoding = captured_encodings[0]
        reference_encoding = reference_encodings[0]

        # Calculate euclidean distance between face encodings
        distance = face_recognition.face_distance(
            [reference_encoding], captured_encoding
        )[0]

        # Convert distance to confidence (0-1, higher = more similar)
        confidence = max(0.0, min(1.0, 1.0 - distance))

        # Determine match
        is_match = distance < MATCH_THRESHOLD

        return {
            'match': bool(is_match),
            'confidence': round(float(confidence), 4),
            'error': None
        }

    except Exception as e:
        print(f"Face comparison error: {e}")
        return {
            'match': False,
            'confidence': 0.0,
            'error': str(e)
        }

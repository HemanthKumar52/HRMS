"""
Face Classification Module — Inspired by MobileNetV2 Image Classification.
Classifies a captured face against a database of known employee faces.

Uses face_recognition library (dlib-based 128D face encodings) to perform
1-to-N face matching. Returns the best matching employee or 'not_found'.
"""

import cv2
import numpy as np
import base64
import face_recognition

# Match threshold: euclidean distance < this = same person
MATCH_THRESHOLD = 0.6


def decode_frame(frame_b64):
    """Decode a base64 image (with or without data URI prefix) to OpenCV frame."""
    try:
        if "," in frame_b64:
            img_bytes = base64.b64decode(frame_b64.split(",")[1])
        else:
            img_bytes = base64.b64decode(frame_b64)
        np_arr = np.frombuffer(img_bytes, np.uint8)
        frame = cv2.imdecode(np_arr, cv2.IMREAD_COLOR)
        return frame
    except Exception as e:
        print(f"Frame decode error: {e}")
        return None


def get_face_encoding(frame):
    """Extract 128D face encoding from an OpenCV frame."""
    rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
    encodings = face_recognition.face_encodings(rgb)
    if encodings:
        return encodings[0]
    return None


def classify_face(captured_frame_b64, employees):
    """
    Classify a captured face against a list of known employees.

    Args:
        captured_frame_b64: base64-encoded captured face image
        employees: list of dicts with 'id', 'name', 'facePhoto' (base64)

    Returns:
        dict with:
            'matched': bool — whether any match was found
            'employee_id': str or None — matched employee's ID
            'employee_name': str or None — matched employee's name
            'confidence': float — match confidence (0-1)
            'error': str or None
    """
    try:
        # Decode captured frame
        captured_frame = decode_frame(captured_frame_b64)
        if captured_frame is None:
            return {
                'matched': False,
                'employee_id': None,
                'employee_name': None,
                'confidence': 0.0,
                'error': 'Failed to decode captured frame'
            }

        # Get encoding for captured face
        captured_encoding = get_face_encoding(captured_frame)
        if captured_encoding is None:
            return {
                'matched': False,
                'employee_id': None,
                'employee_name': None,
                'confidence': 0.0,
                'error': 'No face detected in captured image'
            }

        best_match = None
        best_distance = float('inf')

        # Compare against each employee's stored face
        for emp in employees:
            emp_id = emp.get('id', '')
            emp_name = emp.get('name', '')
            face_photo_b64 = emp.get('facePhoto', '')

            if not face_photo_b64:
                continue

            ref_frame = decode_frame(face_photo_b64)
            if ref_frame is None:
                continue

            ref_encoding = get_face_encoding(ref_frame)
            if ref_encoding is None:
                continue

            # Calculate euclidean distance
            distance = face_recognition.face_distance(
                [ref_encoding], captured_encoding
            )[0]

            if distance < best_distance:
                best_distance = distance
                best_match = {
                    'id': emp_id,
                    'name': emp_name,
                }

        if best_match is None:
            return {
                'matched': False,
                'employee_id': None,
                'employee_name': None,
                'confidence': 0.0,
                'error': 'No valid reference faces found in database'
            }

        confidence = max(0.0, min(1.0, 1.0 - best_distance))
        is_match = best_distance < MATCH_THRESHOLD

        if is_match:
            return {
                'matched': True,
                'employee_id': best_match['id'],
                'employee_name': best_match['name'],
                'confidence': round(float(confidence), 4),
                'error': None
            }
        else:
            return {
                'matched': False,
                'employee_id': None,
                'employee_name': None,
                'confidence': round(float(confidence), 4),
                'error': None
            }

    except Exception as e:
        print(f"Face classification error: {e}")
        return {
            'matched': False,
            'employee_id': None,
            'employee_name': None,
            'confidence': 0.0,
            'error': str(e)
        }

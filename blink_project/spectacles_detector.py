import cv2
import numpy as np

def detect_spectacles(frame, landmarks):
    h, w, _ = frame.shape

    try:
        left_eye = landmarks[33]
        right_eye = landmarks[263]

        x1, y1 = int(left_eye.x * w), int(left_eye.y * h)
        x2, y2 = int(right_eye.x * w), int(right_eye.y * h)

        eye_region = frame[max(0, y1-25):min(h, y2+25),
                           max(0, x1-25):min(w, x2+25)]

        if eye_region.size == 0:
            return False

        gray = cv2.cvtColor(eye_region, cv2.COLOR_BGR2GRAY)

        edges = cv2.Canny(gray, 30, 100)
        edge_density = np.sum(edges) / edges.size

        contrast = gray.std()

        bright_pixels = np.sum(gray > 230)
        bright_ratio = bright_pixels / gray.size

        score = 0

        if edge_density > 6:
            score += 1

        if contrast < 25:
            score += 1

        if bright_ratio > 0.04:
            score += 1

        # Require at least TWO conditions to classify as glasses
        if score >= 2:
            return True

        return False

    except:
        return False

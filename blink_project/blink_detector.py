import cv2
import mediapipe as mp
import numpy as np
import time

from spectacles_detector import detect_spectacles
from face_counter import count_faces
from brightness_checker import check_brightness
from ear_utils import eye_aspect_ratio

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
FULLY_OPEN_THRESHOLD = 0.39

blinked_saved = False
unblinked_saved = False
blinking = False

# NEW TIMER VARIABLES
spectacle_timer_started = False
start_time = None
capture_allowed = False

cap = cv2.VideoCapture(0)

print("Press 'q' to quit")

while True:
    ret, frame = cap.read()
    if not ret:
        break

    frame = cv2.flip(frame, 1)
    rgb_frame = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)

    mp_image = mp.Image(image_format=mp.ImageFormat.SRGB, data=rgb_frame)
    results = face_landmarker.detect(mp_image)

    # ---- MULTI FACE CHECK ----
    faces = count_faces(results)

    if faces > 1:
        cv2.putText(frame, "Multiple faces detected. Only one allowed.",
                    (10, 40), cv2.FONT_HERSHEY_SIMPLEX, 0.7, (0, 0, 255), 2)
        cv2.imshow("Blink Detector", frame)
        if cv2.waitKey(1) & 0xFF == ord('q'):
            break
        continue

    if faces == 0:
        cv2.imshow("Blink Detector", frame)
        if cv2.waitKey(1) & 0xFF == ord('q'):
            break
        continue

    landmarks = results.face_landmarks[0]

    # ---- BRIGHTNESS CHECK ----
    brightness = check_brightness(frame)

    if brightness > 200:
        cv2.putText(frame, "Too Bright! Change position",
                    (10, 70), cv2.FONT_HERSHEY_SIMPLEX, 0.7, (0, 0, 255), 2)

    # ---- SPECTACLES LOGIC WITH TIMER ----
    if not capture_allowed:
        if start_time is None:
            start_time = time.time()

        elapsed = time.time() - start_time

        if elapsed < 5:
            cv2.putText(frame, "Kindly remove your spectacles if worn",
                    (10, 100), cv2.FONT_HERSHEY_SIMPLEX, 0.8, (0, 0, 255), 2)
        else:
            capture_allowed = True
            cv2.putText(frame, "Capturing Images...",
                    (10, 100), cv2.FONT_HERSHEY_SIMPLEX, 0.8, (0, 255, 0), 2)

    # ---- BLINK DETECTION (AFTER TIMER) ----
    if capture_allowed:

        left_ear = eye_aspect_ratio(landmarks, LEFT_EYE_INDICES)
        right_ear = eye_aspect_ratio(landmarks, RIGHT_EYE_INDICES)

        ear = (left_ear + right_ear) / 2.0

        if ear < EAR_THRESHOLD and not blinking and not blinked_saved:
            blinking = True
            cv2.imwrite("blinked.jpg", frame)
            blinked_saved = True
            print("Blinked image saved")

        elif ear > FULLY_OPEN_THRESHOLD and blinking and not unblinked_saved:
            blinking = False
            cv2.imwrite("unblinked.jpg", frame)
            unblinked_saved = True
            print("Unblinked image saved")

    # Exit after both images saved
    if blinked_saved and unblinked_saved:
        print("Both images captured successfully. Exiting.")
        break

    cv2.imshow("Blink Detector", frame)

    if cv2.waitKey(1) & 0xFF == ord('q'):
        break

cap.release()
cv2.destroyAllWindows()

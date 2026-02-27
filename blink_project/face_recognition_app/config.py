import os
import logging

import cv2

# ---------------------------------------------------------------------------
# Project root
# ---------------------------------------------------------------------------
PROJECT_DIR = os.path.dirname(os.path.abspath(__file__))

# ---------------------------------------------------------------------------
# Paths
# ---------------------------------------------------------------------------
DB_PATH = os.path.join(PROJECT_DIR, "data", "faces.db")
ALERTS_DIR = os.path.join(PROJECT_DIR, "data", "unknown_alerts")
LOG_DIR = os.path.join(PROJECT_DIR, "data", "logs")
MODELS_DIR = os.path.join(PROJECT_DIR, "data", "models")

# ---------------------------------------------------------------------------
# Image Quality Thresholds
# ---------------------------------------------------------------------------
MIN_FACE_SIZE_PX = 60
BLUR_THRESHOLD = 80.0
BRIGHTNESS_LOW = 40
BRIGHTNESS_HIGH = 220
NOISE_THRESHOLD = 15.0
MIN_IMAGE_DIM = 160

# ---------------------------------------------------------------------------
# Image Enhancement
# ---------------------------------------------------------------------------
SUPER_RES_SCALE = 4
SUPER_RES_MODEL_URL = (
    "https://github.com/Saafke/EDSR_Tensorflow/raw/master/models/EDSR_x4.pb"
)
SUPER_RES_MODEL_PATH = os.path.join(MODELS_DIR, "EDSR_x4.pb")
SHARPEN_STRENGTH = 1.5
CLAHE_CLIP_LIMIT = 2.0
CLAHE_GRID_SIZE = (8, 8)

# ---------------------------------------------------------------------------
# MediaPipe face detection (fast UI overlay)
# ---------------------------------------------------------------------------
MEDIAPIPE_MIN_DETECTION_CONFIDENCE = 0.5
MEDIAPIPE_MODEL_SELECTION = 1

# ---------------------------------------------------------------------------
# ArcFace / InsightFace
# ---------------------------------------------------------------------------
ARCFACE_MODEL_NAME = "buffalo_l"
ARCFACE_DET_SIZE = (640, 640)

def _get_providers():
    try:
        import onnxruntime as ort
        available = ort.get_available_providers()
        if "CUDAExecutionProvider" in available:
            return ["CUDAExecutionProvider", "CPUExecutionProvider"]
    except Exception:
        pass
    return ["CPUExecutionProvider"]

ARCFACE_PROVIDERS = _get_providers()

# ---------------------------------------------------------------------------
# Pose Detection & Multi-Angle
# ---------------------------------------------------------------------------
POSE_CENTER_MAX_YAW = 12.0      # |yaw| <= this → "center"
POSE_SIDE_MIN_YAW = 15.0        # |yaw| >= this → "left" or "right"
POSE_SIDE_MAX_YAW = 55.0        # |yaw| <= this → still usable
ANGLES = ["center", "left", "right"]
CAPTURES_PER_ANGLE = 5           # target captures per angle during guided enroll

# 3D model points for solvePnP head pose estimation (generic face model)
# Landmarks: nose tip(30), chin(8), left eye corner(36),
#            right eye corner(45), left mouth(48), right mouth(54)
import numpy as _np
FACE_3D_MODEL_POINTS = _np.array([
    (0.0,    0.0,    0.0),        # Nose tip
    (0.0, -330.0,  -65.0),        # Chin
    (-225.0, 170.0, -135.0),      # Left eye left corner
    (225.0,  170.0, -135.0),      # Right eye right corner
    (-150.0, -150.0, -125.0),     # Left mouth corner
    (150.0,  -150.0, -125.0),     # Right mouth corner
], dtype=_np.float64)
SOLVEPNP_LANDMARK_INDICES = [30, 8, 36, 45, 48, 54]

# ---------------------------------------------------------------------------
# Liveness / Anti-Spoofing
# ---------------------------------------------------------------------------
LIVENESS_CHALLENGE_TIMEOUT = 10.0   # seconds per challenge step
LIVENESS_BLINK_EAR_THRESHOLD = 0.21 # Eye Aspect Ratio below this = blink
LIVENESS_BLINK_CONSEC_FRAMES = 2    # consecutive frames to confirm blink
LIVENESS_REQUIRE_BLINK = False      # make blink optional by default

# EAR landmark indices (68-point landmark set)
LEFT_EYE_INDICES = [36, 37, 38, 39, 40, 41]
RIGHT_EYE_INDICES = [42, 43, 44, 45, 46, 47]

# ---------------------------------------------------------------------------
# Matching
# ---------------------------------------------------------------------------
COSINE_THRESHOLD = 0.45
LOW_CONFIDENCE_THRESHOLD = 0.35
ALERT_COOLDOWN_SECONDS = 5

# Multi-angle matching weights (used when multiple angle embeddings match)
ANGLE_WEIGHTS = {"center": 0.50, "left": 0.25, "right": 0.25, "any": 0.40}

# ---------------------------------------------------------------------------
# Camera
# ---------------------------------------------------------------------------
CAMERA_INDEX = 0
CAMERA_BACKEND = cv2.CAP_DSHOW   # DirectShow backend (fixes MSMF issues on Windows)
CAMERA_WIDTH = 640
CAMERA_HEIGHT = 480

# ---------------------------------------------------------------------------
# Registration
# ---------------------------------------------------------------------------
REGISTRATION_NUM_CAPTURES = 15
REGISTRATION_INTERVAL_MS = 300
MIN_EMBEDDINGS_PER_PERSON = 5
MAX_EMBEDDINGS_PER_PERSON = 30

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
def ensure_dirs():
    for d in [os.path.dirname(DB_PATH), ALERTS_DIR, LOG_DIR, MODELS_DIR]:
        os.makedirs(d, exist_ok=True)


def get_logger(name: str) -> logging.Logger:
    ensure_dirs()
    logger = logging.getLogger(name)
    if not logger.handlers:
        logger.setLevel(logging.DEBUG)
        fh = logging.FileHandler(
            os.path.join(LOG_DIR, "recognition.log"), encoding="utf-8"
        )
        fh.setLevel(logging.DEBUG)
        fh.setFormatter(logging.Formatter(
            "%(asctime)s | %(name)-18s | %(levelname)-7s | %(message)s"
        ))
        logger.addHandler(fh)
        ch = logging.StreamHandler()
        ch.setLevel(logging.INFO)
        ch.setFormatter(logging.Formatter("%(levelname)s: %(message)s"))
        logger.addHandler(ch)
    return logger

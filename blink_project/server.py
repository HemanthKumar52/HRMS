from flask import Flask, request, jsonify, render_template
import cv2
import numpy as np
import os
import datetime
import base64
import json
from server_classification import classify_frames, detect_spectacles_in_frame
try:
    import face_recognition
    from face_comparison import compare_faces
    from face_classifier import classify_face
    FACE_RECOGNITION_AVAILABLE = True
except ImportError:
    FACE_RECOGNITION_AVAILABLE = False
    print("WARNING: face_recognition library not found. Face verification will be disabled.")

app = Flask(__name__)

MAIN_FOLDER = "captured_images"
REGISTERED_FACES_DIR = "registered_faces"
ATTENDANCE_LOG = "attendance_log.json"

os.makedirs(MAIN_FOLDER, exist_ok=True)

session_name = datetime.datetime.now().strftime("session_%Y-%m-%d_%H-%M-%S")
SESSION_FOLDER = os.path.join(MAIN_FOLDER, session_name)
os.makedirs(SESSION_FOLDER, exist_ok=True)

print("Saving images to:", SESSION_FOLDER)

# --- Pre-load registered face encodings at startup ---
REGISTERED_EMPLOYEES = []

def load_registered_faces():
    """Load all registered face images and pre-compute their 128D encodings."""
    global REGISTERED_EMPLOYEES
    REGISTERED_EMPLOYEES = []

    if not FACE_RECOGNITION_AVAILABLE:
        print("face_recognition not available — skipping registered face loading.")
        return

    if not os.path.isdir(REGISTERED_FACES_DIR):
        print(f"WARNING: {REGISTERED_FACES_DIR}/ directory not found. No faces registered.")
        return

    for filename in os.listdir(REGISTERED_FACES_DIR):
        if not filename.lower().endswith(('.jpg', '.jpeg', '.png')):
            continue

        filepath = os.path.join(REGISTERED_FACES_DIR, filename)
        name = os.path.splitext(filename)[0]  # anish.jpg -> anish

        img = face_recognition.load_image_file(filepath)
        encodings = face_recognition.face_encodings(img)

        if encodings:
            REGISTERED_EMPLOYEES.append({
                'name': name,
                'encoding': encodings[0],
                'file': filename,
            })
            print(f"  Registered: {name} ({filename})")
        else:
            print(f"  SKIPPED (no face detected): {filename}")

    print(f"Loaded {len(REGISTERED_EMPLOYEES)} registered faces.")


def verify_face_against_registered(frame):
    """
    Compare a captured frame against all registered employees.

    Args:
        frame: OpenCV BGR image (unblinked face from liveness check)

    Returns:
        dict with matched, employee_name, confidence
    """
    if not REGISTERED_EMPLOYEES:
        return {'matched': False, 'employee_name': None, 'confidence': 0.0, 'error': 'No registered faces loaded'}

    rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
    encodings = face_recognition.face_encodings(rgb)

    if not encodings:
        return {'matched': False, 'employee_name': None, 'confidence': 0.0, 'error': 'No face detected in captured frame'}

    captured_encoding = encodings[0]

    # Compare against each registered employee
    registered_encodings = [emp['encoding'] for emp in REGISTERED_EMPLOYEES]
    distances = face_recognition.face_distance(registered_encodings, captured_encoding)

    best_idx = int(np.argmin(distances))
    best_distance = float(distances[best_idx])
    confidence = round(max(0.0, min(1.0, 1.0 - best_distance)), 4)
    is_match = best_distance < 0.6  # standard threshold

    if is_match:
        return {
            'matched': True,
            'employee_name': REGISTERED_EMPLOYEES[best_idx]['name'],
            'confidence': confidence,
            'error': None,
        }
    else:
        return {
            'matched': False,
            'employee_name': None,
            'confidence': confidence,
            'error': None,
        }


def log_attendance(employee_name, status, confidence, session):
    """Append an attendance entry to the JSON log file."""
    entry = {
        'timestamp': datetime.datetime.now().isoformat(),
        'employee': employee_name,
        'status': status,  # PRESENT or ABSENT
        'confidence': confidence,
        'session': session,
    }

    log = []
    if os.path.exists(ATTENDANCE_LOG):
        try:
            with open(ATTENDANCE_LOG, 'r') as f:
                log = json.load(f)
        except (json.JSONDecodeError, IOError):
            log = []

    log.append(entry)

    with open(ATTENDANCE_LOG, 'w') as f:
        json.dump(log, f, indent=2)

    print(f"  ATTENDANCE: {employee_name or 'UNKNOWN'} -> {status} (confidence: {confidence})")
    return entry


# ---- Routes ----

@app.route('/')
def home():
    return render_template('index.html')


@app.route('/completed')
def completed():
    return render_template('completed.html')


@app.route('/check_spectacles', methods=['POST'])
def check_spectacles():
    try:
        data = request.get_json()
        frame_b64 = data.get("frame", "")

        if not frame_b64:
            return jsonify({"detected": False, "confidence": 0.0})

        try:
            img_bytes = base64.b64decode(frame_b64.split(",")[1])
            npimg = np.frombuffer(img_bytes, np.uint8)
            frame = cv2.imdecode(npimg, cv2.IMREAD_COLOR)
            if frame is None:
                return jsonify({"detected": False, "confidence": 0.0})
        except Exception as e:
            print(f"Frame decode error: {e}")
            return jsonify({"detected": False, "confidence": 0.0})

        result = detect_spectacles_in_frame(frame)
        return jsonify({
            "detected": result['detected'],
            "confidence": float(result['confidence'])
        })

    except Exception as e:
        print(f"Spectacle detection error: {e}")
        return jsonify({"detected": False, "confidence": 0.0, "error": str(e)})


@app.route('/upload_nodes', methods=['POST'])
def upload_nodes():
    try:
        data = request.get_json()

        all_frames_b64 = data.get("all_frames", [])
        detection_cache = data.get("detection_cache", [])

        print(f"\n{'='*60}")
        print(f"Received {len(all_frames_b64)} frames, {len(detection_cache)} cache entries")

        if not all_frames_b64:
            return jsonify({"status": "failed", "error": "No frames received"})

        # 1. Decode all frames
        frame_list = []
        for i, frame_b64 in enumerate(all_frames_b64):
            try:
                img_bytes = base64.b64decode(frame_b64.split(",")[1])
                npimg = np.frombuffer(img_bytes, np.uint8)
                frame = cv2.imdecode(npimg, cv2.IMREAD_COLOR)
                if frame is not None:
                    frame_list.append(frame)
            except Exception as e:
                print(f"Error decoding frame {i}: {e}")
                continue

        print(f"Decoded {len(frame_list)} frames")

        # 2. Blink classification (liveness detection)
        print("Running blink classification...")
        classification_result = classify_frames(frame_list)

        blinked_frames = classification_result['blinked']
        unblinked_frames = classification_result['unblinked']

        liveness_passed = len(blinked_frames) > 0 and len(unblinked_frames) > 0
        print(f"Liveness: {len(blinked_frames)} blinked, {len(unblinked_frames)} unblinked -> {'PASS' if liveness_passed else 'FAIL'}")

        # 3. Save frames to disk
        blinked_folder = os.path.join(SESSION_FOLDER, "blinked")
        unblinked_folder = os.path.join(SESSION_FOLDER, "unblinked")
        os.makedirs(blinked_folder, exist_ok=True)
        os.makedirs(unblinked_folder, exist_ok=True)

        for i, item in enumerate(blinked_frames):
            cv2.imwrite(os.path.join(blinked_folder, f"blinked_{i+1}.jpg"), item['frame'])
        for i, item in enumerate(unblinked_frames):
            cv2.imwrite(os.path.join(unblinked_folder, f"unblinked_{i+1}.jpg"), item['frame'])

        if detection_cache:
            with open(os.path.join(SESSION_FOLDER, "detection_cache.json"), 'w') as f:
                json.dump(detection_cache, f, indent=2)

        # 4. Face verification (simultaneous with liveness)
        verification = {'matched': False, 'employee_name': None, 'confidence': 0.0, 'error': None}
        attendance_status = 'ABSENT'

        if liveness_passed and FACE_RECOGNITION_AVAILABLE:
            # Use the best unblinked frame (eyes open) for face matching
            best_frame = unblinked_frames[0]['frame']
            print("Running face verification against registered faces...")
            verification = verify_face_against_registered(best_frame)

            if verification['matched']:
                attendance_status = 'PRESENT'
                print(f"  MATCH: {verification['employee_name']} (confidence: {verification['confidence']})")
            else:
                print(f"  NO MATCH (best confidence: {verification['confidence']})")
        elif not liveness_passed:
            verification['error'] = 'Liveness check failed — no valid blink detected'
            print("  Skipping face verification — liveness failed")
        elif not FACE_RECOGNITION_AVAILABLE:
            verification['error'] = 'face_recognition library not installed'
            print("  Skipping face verification — library not available")

        # 5. Log attendance
        attendance_entry = log_attendance(
            employee_name=verification.get('employee_name'),
            status=attendance_status,
            confidence=verification.get('confidence', 0.0),
            session=session_name,
        )

        print(f"{'='*60}\n")

        return jsonify({
            "status": "success",
            "blinked": len(blinked_frames),
            "unblinked": len(unblinked_frames),
            "liveness": liveness_passed,
            "verification": {
                "matched": verification['matched'],
                "employee_name": verification.get('employee_name'),
                "confidence": verification.get('confidence', 0.0),
            },
            "attendance": attendance_entry,
        })

    except Exception as e:
        print(f"Upload Error: {e}")
        return jsonify({"status": "failed", "error": str(e)})


@app.route('/compare_face', methods=['POST'])
def compare_face_endpoint():
    try:
        if not FACE_RECOGNITION_AVAILABLE:
            return jsonify({"match": False, "confidence": 0.0, "error": "face_recognition library not installed"})

        data = request.get_json()
        captured_b64 = data.get("captured_frame", "")
        reference_b64 = data.get("reference_face", "")

        if not captured_b64 or not reference_b64:
            return jsonify({"match": False, "confidence": 0.0, "error": "Missing captured_frame or reference_face"})

        def decode(b64):
            raw = b64.split(",")[1] if "," in b64 else b64
            return cv2.imdecode(np.frombuffer(base64.b64decode(raw), np.uint8), cv2.IMREAD_COLOR)

        captured_frame = decode(captured_b64)
        reference_frame = decode(reference_b64)

        if captured_frame is None or reference_frame is None:
            return jsonify({"match": False, "confidence": 0.0, "error": "Failed to decode image(s)"})

        result = compare_faces(captured_frame, reference_frame)
        print(f"Face comparison: match={result['match']}, confidence={result['confidence']}")
        return jsonify(result)

    except Exception as e:
        print(f"Compare face error: {e}")
        return jsonify({"match": False, "confidence": 0.0, "error": str(e)})


@app.route('/classify_face', methods=['POST'])
def classify_face_endpoint():
    try:
        if not FACE_RECOGNITION_AVAILABLE:
            return jsonify({"matched": False, "employee_id": None, "employee_name": None, "confidence": 0.0, "error": "face_recognition library not installed"})

        data = request.get_json()
        captured_frame = data.get("captured_frame", "")
        employees = data.get("employees", [])

        if not captured_frame:
            return jsonify({"matched": False, "employee_id": None, "employee_name": None, "confidence": 0.0, "error": "Missing captured_frame"})
        if not employees:
            return jsonify({"matched": False, "employee_id": None, "employee_name": None, "confidence": 0.0, "error": "No employee faces provided"})

        result = classify_face(captured_frame, employees)
        print(f"Classification: matched={result['matched']}, employee={result.get('employee_name')}, confidence={result['confidence']}")
        return jsonify(result)

    except Exception as e:
        print(f"Classify face error: {e}")
        return jsonify({"matched": False, "employee_id": None, "employee_name": None, "confidence": 0.0, "error": str(e)})


@app.route('/attendance', methods=['GET'])
def get_attendance():
    """Return the full attendance log."""
    if not os.path.exists(ATTENDANCE_LOG):
        return jsonify([])
    try:
        with open(ATTENDANCE_LOG, 'r') as f:
            log = json.load(f)
        return jsonify(log)
    except Exception as e:
        return jsonify({"error": str(e)})


if __name__ == '__main__':
    print(f"\nSession folder: {SESSION_FOLDER}")
    print(f"Loading registered faces from {REGISTERED_FACES_DIR}/...")
    load_registered_faces()
    print()
    app.run(host='0.0.0.0', port=5000, debug=True)

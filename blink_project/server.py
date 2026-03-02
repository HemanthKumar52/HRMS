from flask import Flask, request, jsonify, render_template
import cv2
import numpy as np
import os
import datetime
import base64
import json
from server_classification import classify_frames, detect_spectacles_in_frame

# --- InsightFace-based face recognition ---
FACE_RECOGNITION_AVAILABLE = False
face_app = None

try:
    from insightface.app import FaceAnalysis
    face_app = FaceAnalysis(name='buffalo_l', providers=['CPUExecutionProvider'])
    face_app.prepare(ctx_id=0, det_size=(640, 640))
    FACE_RECOGNITION_AVAILABLE = True
    print("InsightFace loaded successfully (buffalo_l model).")
except Exception as e:
    print(f"WARNING: InsightFace not available: {e}. Face verification will be disabled.")

app = Flask(__name__)

MAIN_FOLDER = "captured_images"
REGISTERED_FACES_DIR = "registered_faces"
ATTENDANCE_LOG = "attendance_log.json"

os.makedirs(MAIN_FOLDER, exist_ok=True)

session_name = datetime.datetime.now().strftime("session_%Y-%m-%d_%H-%M-%S")
SESSION_FOLDER = os.path.join(MAIN_FOLDER, session_name)
os.makedirs(SESSION_FOLDER, exist_ok=True)

print("Saving images to:", SESSION_FOLDER)

# --- Pre-load registered face embeddings at startup ---
REGISTERED_EMPLOYEES = []


def load_registered_faces():
    """Load all registered face images and compute 512D InsightFace embeddings."""
    global REGISTERED_EMPLOYEES
    REGISTERED_EMPLOYEES = []

    if not FACE_RECOGNITION_AVAILABLE:
        print("InsightFace not available — skipping registered face loading.")
        return

    if not os.path.isdir(REGISTERED_FACES_DIR):
        print(f"WARNING: {REGISTERED_FACES_DIR}/ directory not found. No faces registered.")
        return

    for filename in os.listdir(REGISTERED_FACES_DIR):
        if not filename.lower().endswith(('.jpg', '.jpeg', '.png')):
            continue

        filepath = os.path.join(REGISTERED_FACES_DIR, filename)
        name = os.path.splitext(filename)[0]  # anish.jpg -> anish

        img = cv2.imread(filepath)
        if img is None:
            print(f"  SKIPPED (cannot read): {filename}")
            continue

        faces = face_app.get(img)

        if faces:
            REGISTERED_EMPLOYEES.append({
                'name': name,
                'embedding': faces[0].embedding,  # 512D normed vector
                'file': filename,
            })
            print(f"  Registered: {name} ({filename})")
        else:
            print(f"  SKIPPED (no face detected): {filename}")

    print(f"Loaded {len(REGISTERED_EMPLOYEES)} registered faces.")


def cosine_similarity(a, b):
    """Compute cosine similarity between two vectors."""
    return float(np.dot(a, b) / (np.linalg.norm(a) * np.linalg.norm(b)))


def verify_face_against_registered(frame):
    """
    Compare a captured frame against all registered employees using InsightFace.

    Args:
        frame: OpenCV BGR image

    Returns:
        dict with matched, employee_name, confidence, num_faces
    """
    if not REGISTERED_EMPLOYEES:
        return {'matched': False, 'employee_name': None, 'confidence': 0.0, 'num_faces': 0, 'error': 'No registered faces loaded'}

    faces = face_app.get(frame)

    if not faces:
        return {'matched': False, 'employee_name': None, 'confidence': 0.0, 'num_faces': 0, 'error': 'No face detected in captured frame'}

    if len(faces) > 1:
        return {'matched': False, 'employee_name': None, 'confidence': 0.0, 'num_faces': len(faces), 'error': 'multiple_faces_detected'}

    captured_embedding = faces[0].embedding

    # Compare against each registered employee using cosine similarity
    best_score = -1.0
    best_idx = -1

    for i, emp in enumerate(REGISTERED_EMPLOYEES):
        score = cosine_similarity(captured_embedding, emp['embedding'])
        if score > best_score:
            best_score = score
            best_idx = i

    # InsightFace cosine similarity threshold: 0.4 is a reasonable match threshold
    confidence = round(max(0.0, min(1.0, best_score)), 4)
    is_match = best_score >= 0.4

    if is_match:
        return {
            'matched': True,
            'employee_name': REGISTERED_EMPLOYEES[best_idx]['name'],
            'confidence': confidence,
            'num_faces': 1,
            'error': None,
        }
    else:
        return {
            'matched': False,
            'employee_name': None,
            'confidence': confidence,
            'num_faces': 1,
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


def decode_base64_frame(b64_str):
    """Decode a base64 string (with or without data URI prefix) to OpenCV BGR image."""
    raw_b64 = b64_str.split(",")[1] if "," in b64_str else b64_str
    img_bytes = base64.b64decode(raw_b64)
    npimg = np.frombuffer(img_bytes, np.uint8)
    return cv2.imdecode(npimg, cv2.IMREAD_COLOR)


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
            frame = decode_base64_frame(frame_b64)
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


@app.route('/verify_face', methods=['POST'])
def verify_face_endpoint():
    """
    Simple face verification — takes ONE base64 photo, compares against all
    registered employees, logs attendance, and returns the result.

    Expects JSON: { "frame": "data:image/jpeg;base64,..." }
    Returns: { status, matched, employee_name, confidence, attendance }
    """
    try:
        if not FACE_RECOGNITION_AVAILABLE:
            return jsonify({
                "status": "failed",
                "matched": False,
                "employee_name": None,
                "confidence": 0.0,
                "error": "Face recognition engine not available",
            })

        data = request.get_json()
        frame_b64 = data.get("frame", "")

        if not frame_b64:
            return jsonify({
                "status": "failed",
                "matched": False,
                "employee_name": None,
                "confidence": 0.0,
                "error": "No frame provided",
            })

        # Decode
        try:
            frame = decode_base64_frame(frame_b64)
            if frame is None:
                return jsonify({
                    "status": "failed",
                    "matched": False,
                    "employee_name": None,
                    "confidence": 0.0,
                    "error": "Failed to decode image",
                })
        except Exception as e:
            return jsonify({
                "status": "failed",
                "matched": False,
                "employee_name": None,
                "confidence": 0.0,
                "error": f"Image decode error: {e}",
            })

        # Save the captured frame
        os.makedirs(SESSION_FOLDER, exist_ok=True)
        timestamp = datetime.datetime.now().strftime("%H%M%S")
        cv2.imwrite(os.path.join(SESSION_FOLDER, f"verify_{timestamp}.jpg"), frame)

        # Verify against registered faces
        print(f"\n{'='*60}")
        print("Running face verification (single photo)...")
        verification = verify_face_against_registered(frame)

        # Check for multiple faces
        if verification.get('error') == 'multiple_faces_detected':
            print(f"  REJECTED: Multiple faces detected ({verification.get('num_faces')})")
            print(f"{'='*60}\n")
            return jsonify({
                "status": "failed",
                "matched": False,
                "employee_name": None,
                "confidence": 0.0,
                "error": "multiple_faces_detected",
                "message": "Multiple faces detected. Only one person should be in the frame.",
            })

        # Check for no face
        if verification.get('num_faces', 0) == 0:
            print(f"  NO FACE detected")
            print(f"{'='*60}\n")
            return jsonify({
                "status": "failed",
                "matched": False,
                "employee_name": None,
                "confidence": 0.0,
                "error": "No face detected in the photo. Please try again.",
            })

        attendance_status = 'PRESENT' if verification['matched'] else 'ABSENT'
        attendance_entry = log_attendance(
            employee_name=verification.get('employee_name'),
            status=attendance_status,
            confidence=verification.get('confidence', 0.0),
            session=session_name,
        )

        if verification['matched']:
            print(f"  MATCH: {verification['employee_name']} (confidence: {verification['confidence']})")
        else:
            print(f"  NO MATCH (best confidence: {verification['confidence']})")
        print(f"{'='*60}\n")

        return jsonify({
            "status": "success",
            "matched": verification['matched'],
            "employee_name": verification.get('employee_name'),
            "confidence": verification.get('confidence', 0.0),
            "attendance": attendance_entry,
        })

    except Exception as e:
        print(f"[VerifyFace] Error: {e}")
        return jsonify({
            "status": "failed",
            "matched": False,
            "employee_name": None,
            "confidence": 0.0,
            "error": str(e),
        })


@app.route('/compare_face', methods=['POST'])
def compare_face_endpoint():
    """Compare two face photos and return similarity."""
    try:
        if not FACE_RECOGNITION_AVAILABLE:
            return jsonify({"match": False, "confidence": 0.0, "error": "Face recognition engine not available"})

        data = request.get_json()
        captured_b64 = data.get("captured_frame", "")
        reference_b64 = data.get("reference_face", "")

        if not captured_b64 or not reference_b64:
            return jsonify({"match": False, "confidence": 0.0, "error": "Missing captured_frame or reference_face"})

        captured_frame = decode_base64_frame(captured_b64)
        reference_frame = decode_base64_frame(reference_b64)

        if captured_frame is None or reference_frame is None:
            return jsonify({"match": False, "confidence": 0.0, "error": "Failed to decode image(s)"})

        faces_cap = face_app.get(captured_frame)
        faces_ref = face_app.get(reference_frame)

        if not faces_cap or not faces_ref:
            return jsonify({"match": False, "confidence": 0.0, "error": "No face detected in one or both images"})

        score = cosine_similarity(faces_cap[0].embedding, faces_ref[0].embedding)
        confidence = round(max(0.0, min(1.0, score)), 4)
        is_match = score >= 0.4

        print(f"Face comparison: match={is_match}, confidence={confidence}")
        return jsonify({"match": is_match, "confidence": confidence})

    except Exception as e:
        print(f"Compare face error: {e}")
        return jsonify({"match": False, "confidence": 0.0, "error": str(e)})


@app.route('/classify_face', methods=['POST'])
def classify_face_endpoint():
    """Classify a captured face against a provided list of employee face photos."""
    try:
        if not FACE_RECOGNITION_AVAILABLE:
            return jsonify({"matched": False, "employee_id": None, "employee_name": None, "confidence": 0.0, "error": "Face recognition engine not available"})

        data = request.get_json()
        captured_frame_b64 = data.get("captured_frame", "")
        employees = data.get("employees", [])

        if not captured_frame_b64:
            return jsonify({"matched": False, "employee_id": None, "employee_name": None, "confidence": 0.0, "error": "Missing captured_frame"})
        if not employees:
            return jsonify({"matched": False, "employee_id": None, "employee_name": None, "confidence": 0.0, "error": "No employee faces provided"})

        captured_frame = decode_base64_frame(captured_frame_b64)
        if captured_frame is None:
            return jsonify({"matched": False, "employee_id": None, "employee_name": None, "confidence": 0.0, "error": "Failed to decode captured frame"})

        faces_cap = face_app.get(captured_frame)
        if not faces_cap:
            return jsonify({"matched": False, "employee_id": None, "employee_name": None, "confidence": 0.0, "error": "No face detected in captured frame"})

        captured_embedding = faces_cap[0].embedding

        best_score = -1.0
        best_emp = None

        for emp in employees:
            face_photo_b64 = emp.get('facePhoto', '')
            if not face_photo_b64:
                continue

            ref_frame = decode_base64_frame(face_photo_b64)
            if ref_frame is None:
                continue

            ref_faces = face_app.get(ref_frame)
            if not ref_faces:
                continue

            score = cosine_similarity(captured_embedding, ref_faces[0].embedding)
            if score > best_score:
                best_score = score
                best_emp = emp

        confidence = round(max(0.0, min(1.0, best_score)), 4)
        is_match = best_score >= 0.4 and best_emp is not None

        result = {
            "matched": is_match,
            "employee_id": best_emp.get('id') if is_match else None,
            "employee_name": best_emp.get('name') if is_match else None,
            "confidence": confidence,
        }

        print(f"Classification: matched={result['matched']}, employee={result.get('employee_name')}, confidence={result['confidence']}")
        return jsonify(result)

    except Exception as e:
        print(f"Classify face error: {e}")
        return jsonify({"matched": False, "employee_id": None, "employee_name": None, "confidence": 0.0, "error": str(e)})


@app.route('/check_duplicate_face', methods=['POST'])
def check_duplicate_face():
    """
    Check if a face already exists among registered employees.
    Expects JSON: { "face_photo": "data:image/jpeg;base64,...", "name": "optional name" }
    Returns: { duplicate: bool, existing_name: str|null, confidence: float }
    """
    try:
        if not FACE_RECOGNITION_AVAILABLE or not REGISTERED_EMPLOYEES:
            return jsonify({'duplicate': False, 'existing_name': None, 'confidence': 0.0})

        data = request.get_json()
        face_photo_b64 = data.get('face_photo', '')
        provided_name = data.get('name', '').strip()

        if not face_photo_b64:
            return jsonify({'duplicate': False, 'existing_name': None, 'confidence': 0.0, 'error': 'No photo provided'})

        frame = decode_base64_frame(face_photo_b64)
        if frame is None:
            return jsonify({'duplicate': False, 'existing_name': None, 'confidence': 0.0, 'error': 'Decode failed'})

        faces = face_app.get(frame)
        if not faces:
            return jsonify({'duplicate': False, 'existing_name': None, 'confidence': 0.0, 'error': 'No face detected'})

        captured_embedding = faces[0].embedding

        best_score = -1.0
        best_idx = -1

        for i, emp in enumerate(REGISTERED_EMPLOYEES):
            score = cosine_similarity(captured_embedding, emp['embedding'])
            if score > best_score:
                best_score = score
                best_idx = i

        confidence = round(max(0.0, min(1.0, best_score)), 4)
        is_duplicate = best_score >= 0.4
        existing_name = REGISTERED_EMPLOYEES[best_idx]['name'] if is_duplicate else None

        # If same person same name → not a conflict, it's an update
        if is_duplicate and provided_name and existing_name and provided_name.lower() == existing_name.lower():
            return jsonify({
                'duplicate': False,
                'same_person_update': True,
                'existing_name': existing_name,
                'confidence': confidence,
            })

        return jsonify({
            'duplicate': is_duplicate,
            'existing_name': existing_name,
            'confidence': confidence,
        })

    except Exception as e:
        print(f"[CheckDuplicate] Error: {e}")
        return jsonify({'duplicate': False, 'existing_name': None, 'confidence': 0.0, 'error': str(e)})


@app.route('/register_face', methods=['POST'])
def register_face():
    """
    Register a new employee face for recognition.
    Expects JSON: { "name": "FirstName LastName", "face_photo": "data:image/jpeg;base64,..." }
    Saves to registered_faces/ and hot-reloads the face registry.
    """
    try:
        data = request.get_json()
        name = data.get('name', '').strip()
        face_photo_b64 = data.get('face_photo', '')

        if not name:
            return jsonify({'success': False, 'error': 'Name is required'}), 400
        if not face_photo_b64:
            return jsonify({'success': False, 'error': 'Face photo is required'}), 400

        # Decode the base64 image
        try:
            frame = decode_base64_frame(face_photo_b64)
            if frame is None:
                return jsonify({'success': False, 'error': 'Failed to decode image'}), 400
        except Exception as e:
            return jsonify({'success': False, 'error': f'Image decode error: {e}'}), 400

        # Validate that a face is actually detectable in the photo
        if FACE_RECOGNITION_AVAILABLE:
            faces = face_app.get(frame)
            if not faces:
                return jsonify({'success': False, 'error': 'No face detected in the photo. Please retake.'}), 400

            # Check for duplicate face with DIFFERENT name
            if REGISTERED_EMPLOYEES:
                captured_embedding = faces[0].embedding

                best_score = -1.0
                best_idx = -1

                for i, emp in enumerate(REGISTERED_EMPLOYEES):
                    score = cosine_similarity(captured_embedding, emp['embedding'])
                    if score > best_score:
                        best_score = score
                        best_idx = i

                if best_score >= 0.4:
                    existing_name = REGISTERED_EMPLOYEES[best_idx]['name']
                    # Same face, different name → reject (duplicate person)
                    if existing_name.lower() != name.lower():
                        return jsonify({
                            'success': False,
                            'error': f'This face is already registered under "{existing_name}". Cannot register the same face with different details.',
                            'duplicate': True,
                            'existing_name': existing_name,
                        }), 409
                    # Same face, same name → allow (update)
                    print(f"[RegisterFace] Updating existing face for: {name}")

        # Save to registered_faces/ directory
        os.makedirs(REGISTERED_FACES_DIR, exist_ok=True)
        filename = f"{name}.jpg"
        filepath = os.path.join(REGISTERED_FACES_DIR, filename)
        cv2.imwrite(filepath, frame)
        print(f"[RegisterFace] Saved face photo: {filepath}")

        # Hot-reload all registered faces so new employee is immediately recognized
        load_registered_faces()

        return jsonify({
            'success': True,
            'name': name,
            'file': filename,
            'total_registered': len(REGISTERED_EMPLOYEES),
        })

    except Exception as e:
        print(f"[RegisterFace] Error: {e}")
        return jsonify({'success': False, 'error': str(e)}), 500


@app.route('/registered_faces', methods=['GET'])
def list_registered_faces():
    """Return the list of all registered employee names."""
    return jsonify({
        'total': len(REGISTERED_EMPLOYEES),
        'employees': [{'name': emp['name'], 'file': emp['file']} for emp in REGISTERED_EMPLOYEES],
    })


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

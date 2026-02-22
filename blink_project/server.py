from flask import Flask, request, jsonify, render_template
import cv2
import numpy as np
import os
import datetime
import base64
import json
from server_classification import classify_frames, detect_spectacles_in_frame
try:
    from face_comparison import compare_faces
    FACE_RECOGNITION_AVAILABLE = True
except ImportError:
    FACE_RECOGNITION_AVAILABLE = False
    print("WARNING: face_recognition library not found. /compare_face endpoint will be disabled.")

app = Flask(__name__)

MAIN_FOLDER = "captured_images"
os.makedirs(MAIN_FOLDER, exist_ok=True)

session_name = datetime.datetime.now().strftime("session_%Y-%m-%d_%H-%M-%S")
SESSION_FOLDER = os.path.join(MAIN_FOLDER, session_name)
os.makedirs(SESSION_FOLDER, exist_ok=True)

print("Saving images to:", SESSION_FOLDER)


@app.route('/')
def home():
    return render_template('index.html')


@app.route('/completed')
def completed():
    return render_template('completed.html')


@app.route('/check_spectacles', methods=['POST'])
def check_spectacles():
    """
    Check if spectacles are detected in the provided frame
    """
    try:
        data = request.get_json()
        frame_b64 = data.get("frame", "")

        if not frame_b64:
            return jsonify({"detected": False, "confidence": 0.0})

        # Decode frame
        try:
            img_bytes = base64.b64decode(frame_b64.split(",")[1])
            npimg = np.frombuffer(img_bytes, np.uint8)
            frame = cv2.imdecode(npimg, cv2.IMREAD_COLOR)
            
            if frame is None:
                return jsonify({"detected": False, "confidence": 0.0})
        except Exception as e:
            print(f"Frame decode error: {e}")
            return jsonify({"detected": False, "confidence": 0.0})

        # Perform spectacle detection
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

        print("Received frames:", len(all_frames_b64))
        print("Received detection cache entries:", len(detection_cache))

        if not all_frames_b64:
            return jsonify({"status": "failed", "error": "No frames received"})

        # Convert base64 frames to OpenCV format
        frame_list = []
        for i, frame_b64 in enumerate(all_frames_b64):
            try:
                img_bytes = base64.b64decode(frame_b64.split(",")[1])
                npimg = np.frombuffer(img_bytes, np.uint8)
                frame = cv2.imdecode(npimg, cv2.IMREAD_COLOR)
                if frame is not None:
                    frame_list.append(frame)
            except Exception as e:
                print(f"Error decoding frame {i}:", e)
                continue

        print(f"Successfully decoded {len(frame_list)} frames for classification")

        # Perform server-side classification
        print("Starting server-side frame classification...")
        classification_result = classify_frames(frame_list)

        blinked_frames = classification_result['blinked']
        unblinked_frames = classification_result['unblinked']

        print(f"Classification complete: {len(blinked_frames)} blinked, {len(unblinked_frames)} unblinked")

        # Create subdirectories
        blinked_folder = os.path.join(SESSION_FOLDER, "blinked")
        unblinked_folder = os.path.join(SESSION_FOLDER, "unblinked")
        
        os.makedirs(blinked_folder, exist_ok=True)
        os.makedirs(unblinked_folder, exist_ok=True)

        # Save blinked frames
        for i, item in enumerate(blinked_frames):
            try:
                frame = item['frame']
                filename = os.path.join(blinked_folder, f"blinked_{i+1}.jpg")
                saved = cv2.imwrite(filename, frame)
                print(f"Saved blinked frame: {filename}, Status: {saved}")
            except Exception as e:
                print(f"Error saving blinked frame {i}:", e)

        # Save unblinked frames
        for i, item in enumerate(unblinked_frames):
            try:
                frame = item['frame']
                filename = os.path.join(unblinked_folder, f"unblinked_{i+1}.jpg")
                saved = cv2.imwrite(filename, frame)
                print(f"Saved unblinked frame: {filename}, Status: {saved}")
            except Exception as e:
                print(f"Error saving unblinked frame {i}:", e)

        # Save detection cache as JSON
        if detection_cache:
            try:
                cache_file = os.path.join(SESSION_FOLDER, "detection_cache.json")
                with open(cache_file, 'w') as f:
                    json.dump(detection_cache, f, indent=2)
                print("Saved detection cache to:", cache_file)
            except Exception as e:
                print("Detection cache save error:", e)

        return jsonify({"status": "success", "blinked": len(blinked_frames), "unblinked": len(unblinked_frames)})

    except Exception as e:
        print("Upload Error:", e)
        return jsonify({"status": "failed", "error": str(e)})


@app.route('/compare_face', methods=['POST'])
def compare_face_endpoint():
    """
    Compare a captured face against a stored reference face.
    Expects JSON:
      {
        "captured_frame": "data:image/jpeg;base64,...",
        "reference_face": "<raw base64 string>"
      }
    Returns:
      { "match": true/false, "confidence": 0.92, "error": null }
    """
    try:
        if not FACE_RECOGNITION_AVAILABLE:
            return jsonify({"match": False, "confidence": 0.0, "error": "Face recognition library is not installed on the server."})
            
        data = request.get_json()
        captured_b64 = data.get("captured_frame", "")
        reference_b64 = data.get("reference_face", "")

        if not captured_b64 or not reference_b64:
            return jsonify({"match": False, "confidence": 0.0, "error": "Missing captured_frame or reference_face"})

        # Decode captured frame (data URI format: "data:image/jpeg;base64,...")
        try:
            if "," in captured_b64:
                captured_bytes = base64.b64decode(captured_b64.split(",")[1])
            else:
                captured_bytes = base64.b64decode(captured_b64)
            captured_np = np.frombuffer(captured_bytes, np.uint8)
            captured_frame = cv2.imdecode(captured_np, cv2.IMREAD_COLOR)
        except Exception as e:
            return jsonify({"match": False, "confidence": 0.0, "error": f"Failed to decode captured frame: {e}"})

        # Decode reference face (raw base64 string)
        try:
            if "," in reference_b64:
                reference_bytes = base64.b64decode(reference_b64.split(",")[1])
            else:
                reference_bytes = base64.b64decode(reference_b64)
            reference_np = np.frombuffer(reference_bytes, np.uint8)
            reference_frame = cv2.imdecode(reference_np, cv2.IMREAD_COLOR)
        except Exception as e:
            return jsonify({"match": False, "confidence": 0.0, "error": f"Failed to decode reference face: {e}"})

        if captured_frame is None:
            return jsonify({"match": False, "confidence": 0.0, "error": "Captured frame is invalid"})
        if reference_frame is None:
            return jsonify({"match": False, "confidence": 0.0, "error": "Reference face is invalid"})

        # Compare faces
        result = compare_faces(captured_frame, reference_frame)

        print(f"Face comparison result: match={result['match']}, confidence={result['confidence']}")

        return jsonify(result)

    except Exception as e:
        print(f"Compare face error: {e}")
        return jsonify({"match": False, "confidence": 0.0, "error": str(e)})


if __name__ == '__main__':
    print("Folder for this session:", SESSION_FOLDER)
    app.run(host='0.0.0.0', port=5000, debug=True)

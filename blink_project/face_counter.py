def count_faces(results):
    if not results.face_landmarks:
        return 0
    return len(results.face_landmarks)

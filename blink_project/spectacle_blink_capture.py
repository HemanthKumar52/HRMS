import cv2
import time

cap = cv2.VideoCapture(0)

if not cap.isOpened():
    print("Cannot open camera")
    exit()

# Step 1: Show "Remove Spectacles" for 5 seconds
start = time.time()

while True:
    ret, frame = cap.read()
    if not ret:
        break

    cv2.putText(frame, "Remove Spectacles",
                (50, 50),
                cv2.FONT_HERSHEY_SIMPLEX,
                1,
                (0, 0, 255), 2)

    cv2.imshow("Spectacle Removal", frame)

    if time.time() - start > 5:
        break

    if cv2.waitKey(1) & 0xFF == ord('q'):
        cap.release()
        cv2.destroyAllWindows()
        exit()

# Step 2: Wait for 10 seconds
wait_start = time.time()

while True:
    ret, frame = cap.read()
    if not ret:
        break

    cv2.putText(frame, "Get Ready for Capture",
                (50, 50),
                cv2.FONT_HERSHEY_SIMPLEX,
                1,
                (255, 0, 0), 2)

    cv2.imshow("Waiting", frame)

    if time.time() - wait_start > 10:
        break

    if cv2.waitKey(1) & 0xFF == ord('q'):
        cap.release()
        cv2.destroyAllWindows()
        exit()

# Step 3: Capture Unblinked Photo
ret, frame = cap.read()
cv2.imwrite("unblinked_photo.jpg", frame)
cv2.putText(frame, "Unblinked Photo Captured",
            (50, 50),
            cv2.FONT_HERSHEY_SIMPLEX,
            1,
            (0, 255, 0), 2)

cv2.imshow("Unblinked Capture", frame)
cv2.waitKey(2000)

# Step 4: Ask user to blink
blink_start = time.time()

while True:
    ret, frame = cap.read()
    if not ret:
        break

    cv2.putText(frame, "Please Blink Now",
                (50, 50),
                cv2.FONT_HERSHEY_SIMPLEX,
                1,
                (0, 0, 255), 2)

    cv2.imshow("Blink Now", frame)

    if time.time() - blink_start > 5:
        break

    if cv2.waitKey(1) & 0xFF == ord('q'):
        break

# Step 5: Capture Blinked Photo
ret, frame = cap.read()
cv2.imwrite("blinked_photo.jpg", frame)

cv2.putText(frame, "Blink Photo Captured",
            (50, 50),
            cv2.FONT_HERSHEY_SIMPLEX,
            1,
            (0, 255, 0), 2)

cv2.imshow("Blink Capture", frame)
cv2.waitKey(2000)

print("Photos Captured Successfully!")

cap.release()
cv2.destroyAllWindows()

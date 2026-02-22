const video = document.getElementById("video");
const canvas = document.getElementById("canvas");
const message = document.getElementById("message");
const permissionButton = document.getElementById("permissionButton");
const spectacleWarning = document.getElementById("spectacleWarning");

// FRONTEND STORAGE NODES WITH FIFO (First In First Out)
class FIFOArray {
    constructor(maxSize = 10) {
        this.maxSize = maxSize;
        this.data = [];
    }
    
    push(element) {
        this.data.push(element);
        if (this.data.length > this.maxSize) {
            this.data.shift(); // Remove first element if exceeds max size
        }
    }
    
    getAll() {
        return [...this.data];
    }
}

let blinked_nodes = new FIFOArray(10);
let unblinked_nodes = new FIFOArray(10);

// All captured frames for server-side classification
let all_frames = new FIFOArray(100);  // Capture up to 100 frames for server-side processing

// Cache queue for storing blink detection data (EAR, face position, etc.)
class CacheQueue {
    constructor(maxSize = 10) {
        this.maxSize = maxSize;
        this.data = [];
    }
    
    push(element) {
        this.data.push(element);
        if (this.data.length > this.maxSize) {
            this.data.shift(); // Remove first element if exceeds max size
        }
    }
    
    getAll() {
        return [...this.data];
    }
    
    clear() {
        this.data = [];
    }
}

let detectionCache = new CacheQueue(10);  // Cache for blink detection metadata

const LEFT_EYE = [33, 160, 158, 133, 153, 144];
const RIGHT_EYE = [362, 385, 387, 263, 373, 380];

const EAR_THRESHOLD = 0.25;           // Blink threshold
const FULLY_OPEN_THRESHOLD = 0.37;    // Eyes fully open threshold

// State variables
let blinking = false;
let blinked_saved = false;
let unblinked_saved = false;
let capture_allowed = false;
let sessionActive = false;
let start_time = null;
let spectacles_detected = false;
let spectacle_detection_interval = null;
let last_spectacle_check = 0;
const SPECTACLE_CHECK_INTERVAL = 500; // Check every 500ms to avoid overwhelming server

// Timer manager that supports pause/resume
const TimerManager = {
    spectaclesRemaining: 5.0,
    captureRemaining: 6.0,
    stage: 'idle', // idle | spectacles | capture | done
    paused: false,
    lastTick: null,
    intervalId: null,

    start() {
        this.spectaclesRemaining = 5.0;
        this.captureRemaining = 20.0;
        this.stage = 'spectacles';
        this.paused = false;
        this.lastTick = performance.now();
        sessionActive = true;
        capture_allowed = false;
        this.intervalId = setInterval(() => this.tick(), 100);
    },

    tick() {
        if (this.paused || this.stage === 'done') {
            this.lastTick = performance.now();
            return;
        }

        const now = performance.now();
        const dt = (now - this.lastTick) / 1000.0;
        this.lastTick = now;

        if (this.stage === 'spectacles') {
            this.spectaclesRemaining = Math.max(0, this.spectaclesRemaining - dt);
            if (this.spectaclesRemaining > 0) {
                message.innerText = `Welcome (${Math.ceil(this.spectaclesRemaining)}s)`;
            } else {
                this.stage = 'capture';
                capture_allowed = true;
                message.innerText = 'Capturing Images... Blink naturally';
                console.log('[BLINK] Capture started!');
            }
        } else if (this.stage === 'capture') {
            this.captureRemaining = Math.max(0, this.captureRemaining - dt);
            if (this.captureRemaining <= 0) {
                this.end();
            }
        }
    },

    pause() {
        this.paused = true;
        console.log('[BLINK] Timer paused');
    },

    resume() {
        if (!this.paused) return;
        this.paused = false;
        this.lastTick = performance.now();
        console.log('[BLINK] Timer resumed');
    },

    end() {
        this.stage = 'done';
        clearInterval(this.intervalId);
        sessionActive = false;
        capture_allowed = false;
        console.log('[BLINK] Session ended');
        console.log('[BLINK] Total frames captured:', all_frames.data.length);
        console.log('[BLINK] Detection cache entries:', detectionCache.getAll().length);
        message.innerText = 'Transferring frames to server for classification...';
        setTimeout(() => sendNodesToServer(), 1000);
    }
};

// Pause reasons tracking so we only resume when all reasons cleared
const pausedReasons = new Set();

function pauseSession(reason) {
    if (reason) pausedReasons.add(reason);
    TimerManager.pause();
    if (reason) message.innerText = reason;
}

function resumeSession(reason) {
    if (reason) pausedReasons.delete(reason);
    if (pausedReasons.size === 0) {
        // restore message based on current stage
        TimerManager.resume();
        if (TimerManager.stage === 'spectacles') {
            message.innerText = `Welcome (${Math.ceil(TimerManager.spectaclesRemaining)}s)`;
        } else if (TimerManager.stage === 'capture') {
            message.innerText = 'Capturing Images... Blink naturally';
        }
    } else {
        // still paused for other reason(s)
        message.innerText = Array.from(pausedReasons).join(' | ');
    }
}

// Start the timer via manager
function startSessionTimer() {
    TimerManager.start();
}


function storeImageLocally(type) {

    const ctx = canvas.getContext("2d");

    canvas.width = video.videoWidth;
    canvas.height = video.videoHeight;

    ctx.drawImage(video, 0, 0);

    let imageData = canvas.toDataURL("image/jpeg");

    // Store all frames for server-side classification
    all_frames.push(imageData);
    console.log("[BLINK] Captured frame. Total frames:", all_frames.data.length);
}


// ----------- SEND ALL NODES TO SERVER -----------

function sendNodesToServer() {

    let payload = {
        all_frames: all_frames.getAll(),
        detection_cache: detectionCache.getAll()
    };

    fetch("/upload_nodes", {
        method: "POST",
        headers: {
            "Content-Type": "application/json"
        },
        body: JSON.stringify(payload)
    })
    .then(res => res.json())
    .then(data => {
        window.location.href = "/completed";
    })
    .catch(err => {
        message.innerText = "Transfer failed";
    });
}


// ----------- SPECTACLE DETECTION CNN (FRONTEND) -----------

// Frontend CNN for Spectacle Detection
const SpectacleDetectorCNN = {
    
    // Extract eye region from landmarks
    extractEyeRegion(imageData, landmarks, isLeft = true) {
        const width = imageData.width;
        const height = imageData.height;
        const data = imageData.data;
        
        if (!landmarks || landmarks.length < 468) return null;
        
        // Eye indices
        const eyePoints = isLeft ? [33, 160, 158, 133, 153, 144] : [362, 385, 387, 263, 373, 380];
        
        // Get eye region bounds
        let minX = Infinity, maxX = -Infinity;
        let minY = Infinity, maxY = -Infinity;
        
        for (const idx of eyePoints) {
            const pt = landmarks[idx];
            if (pt) {
                minX = Math.min(minX, pt.x * width);
                maxX = Math.max(maxX, pt.x * width);
                minY = Math.min(minY, pt.y * height);
                maxY = Math.max(maxY, pt.y * height);
            }
        }
        
        // Add margin
        const margin = 30;
        minX = Math.max(0, minX - margin);
        maxX = Math.min(width, maxX + margin);
        minY = Math.max(0, minY - margin);
        maxY = Math.min(height, maxY + margin);
        
        // Extract region
        const regionWidth = Math.floor(maxX - minX);
        const regionHeight = Math.floor(maxY - minY);
        
        if (regionWidth < 20 || regionHeight < 20) return null;
        
        const regionData = new Uint8ClampedArray(regionWidth * regionHeight * 4);
        for (let y = 0; y < regionHeight; y++) {
            for (let x = 0; x < regionWidth; x++) {
                const srcIdx = ((Math.floor(minY) + y) * width + (Math.floor(minX) + x)) * 4;
                const dstIdx = (y * regionWidth + x) * 4;
                regionData[dstIdx] = data[srcIdx];
                regionData[dstIdx + 1] = data[srcIdx + 1];
                regionData[dstIdx + 2] = data[srcIdx + 2];
                regionData[dstIdx + 3] = data[srcIdx + 3];
            }
        }
        
        return { data: regionData, width: regionWidth, height: regionHeight };
    },
    
    // Detect frame structure (edges/contours)
    detectFrameStructure(imageData) {
        if (!imageData) return 0;
        
        const data = imageData.data;
        const width = imageData.width;
        const height = imageData.height;
        
        // Convert to grayscale
        const gray = new Uint8Array(width * height);
        for (let i = 0; i < width * height; i++) {
            gray[i] = 0.3 * data[i*4] + 0.59 * data[i*4+1] + 0.11 * data[i*4+2];
        }
        
        // Edge detection (simple Canny-like)
        let edgeCount = 0;
        for (let y = 1; y < height - 1; y++) {
            for (let x = 1; x < width - 1; x++) {
                const idx = y * width + x;
                const gx = -gray[idx-width-1] + gray[idx-width+1] - 2*gray[idx-1] + 2*gray[idx+1] - gray[idx+width-1] + gray[idx+width+1];
                const gy = gray[idx-width-1] + 2*gray[idx-width] + gray[idx-width+1] - gray[idx+width-1] - 2*gray[idx+width] - gray[idx+width+1];
                const magnitude = Math.sqrt(gx*gx + gy*gy);
                if (magnitude > 50) edgeCount++;
            }
        }
        
        // Frame structure score (0-1)
        const maxEdges = width * height * 0.3;
        return Math.min(1, edgeCount / maxEdges);
    },
    
    // Detect lens pattern (bright reflections)
    detectLensPattern(imageData) {
        if (!imageData) return 0;
        
        const data = imageData.data;
        const width = imageData.width;
        const height = imageData.height;
        
        let brightPixels = 0;
        let darkPixels = 0;
        let totalPixels = width * height;
        
        for (let i = 0; i < totalPixels; i++) {
            const r = data[i*4];
            const g = data[i*4+1];
            const b = data[i*4+2];
            const brightness = (r + g + b) / 3;
            
            if (brightness > 200) brightPixels++;
            if (brightness < 50) darkPixels++;
        }
        
        // Lens pattern score - high contrast indicates glasses
        const brightRatio = brightPixels / totalPixels;
        const darkRatio = darkPixels / totalPixels;
        
        return Math.min(1, (brightRatio + darkRatio) * 2);
    },
    
    // Detect symmetry (glasses are typically symmetric)
    detectSymmetry(imageData) {
        if (!imageData) return 0;
        
        const data = imageData.data;
        const width = imageData.width;
        const height = imageData.height;
        
        // Split left and right halves
        let correlationSum = 0;
        let leftMean = 0, rightMean = 0;
        const halfWidth = Math.floor(width / 2);
        
        for (let y = 0; y < height; y++) {
            for (let x = 0; x < halfWidth; x++) {
                const leftIdx = (y * width + x) * 4;
                const rightIdx = (y * width + (width - 1 - x)) * 4;
                
                const leftVal = (data[leftIdx] + data[leftIdx+1] + data[leftIdx+2]) / 3;
                const rightVal = (data[rightIdx] + data[rightIdx+1] + data[rightIdx+2]) / 3;
                
                leftMean += leftVal;
                rightMean += rightVal;
            }
        }
        
        leftMean /= (halfWidth * height);
        rightMean /= (halfWidth * height);
        
        // Calculate correlation
        for (let y = 0; y < height; y++) {
            for (let x = 0; x < halfWidth; x++) {
                const leftIdx = (y * width + x) * 4;
                const rightIdx = (y * width + (width - 1 - x)) * 4;
                
                const leftVal = (data[leftIdx] + data[leftIdx+1] + data[leftIdx+2]) / 3;
                const rightVal = (data[rightIdx] + data[rightIdx+1] + data[rightIdx+2]) / 3;
                
                correlationSum += (leftVal - leftMean) * (rightVal - rightMean);
            }
        }
        
        // Normalize correlation to 0-1
        const maxCorrelation = halfWidth * height * 255;
        return Math.min(1, Math.max(0, correlationSum / maxCorrelation + 0.5));
    },
    
    // Detect nose bridge (horizontal line features)
    detectBridge(imageData) {
        if (!imageData) return 0;
        
        const data = imageData.data;
        const width = imageData.width;
        const height = imageData.height;
        
        // Convert to grayscale
        const gray = new Uint8Array(width * height);
        for (let i = 0; i < width * height; i++) {
            gray[i] = 0.3 * data[i*4] + 0.59 * data[i*4+1] + 0.11 * data[i*4+2];
        }
        
        // Detect horizontal lines in center region
        let horizontalLines = 0;
        const centerY = Math.floor(height / 2);
        const searchRadius = Math.floor(height / 4);
        
        for (let y = Math.max(0, centerY - searchRadius); y < Math.min(height - 1, centerY + searchRadius); y++) {
            for (let x = 1; x < width - 1; x++) {
                const idx = y * width + x;
                const diff = Math.abs(gray[idx-1] - gray[idx+1]);
                if (diff > 30) horizontalLines++;
            }
        }
        
        const maxLines = (width - 2) * (2 * searchRadius + 1);
        return Math.min(1, horizontalLines / maxLines);
    },
    
    // Main detection function
    detect(imageData, landmarks) {
        if (!imageData || !landmarks) return { detected: false, confidence: 0 };
        
        // Extract both eye regions
        const leftEye = this.extractEyeRegion(imageData, landmarks, true);
        const rightEye = this.extractEyeRegion(imageData, landmarks, false);
        
        if (!leftEye || !rightEye) {
            return { detected: false, confidence: 0 };
        }
        
        // Detect features in both eyes
        const leftFrameScore = this.detectFrameStructure(leftEye);
        const rightFrameScore = this.detectFrameStructure(rightEye);
        const frameScore = (leftFrameScore + rightFrameScore) / 2;
        
        const leftLensScore = this.detectLensPattern(leftEye);
        const rightLensScore = this.detectLensPattern(rightEye);
        const lensScore = (leftLensScore + rightLensScore) / 2;
        
        const leftSymmetry = this.detectSymmetry(leftEye);
        const rightSymmetry = this.detectSymmetry(rightEye);
        const symmetryScore = (leftSymmetry + rightSymmetry) / 2;
        
        const bridgeScore = this.detectBridge({
            data: new Uint8ClampedArray(imageData.data),
            width: imageData.width,
            height: imageData.height
        });
        
        // Weighted fusion (35% Frame + 30% Lens + 20% Symmetry + 15% Bridge)
        const confidence = 
            frameScore * 0.35 +
            lensScore * 0.30 +
            symmetryScore * 0.20 +
            bridgeScore * 0.15;
        
        console.log("[SPECTACLES-CNN] Scores:", {
            frame: frameScore.toFixed(2),
            lens: lensScore.toFixed(2),
            symmetry: symmetryScore.toFixed(2),
            bridge: bridgeScore.toFixed(2),
            combined: confidence.toFixed(2)
        });
        
        const threshold = 0.40;
        const detected = confidence > threshold;
        
        return { detected, confidence };
    }
};

function detectSpectaclesSimple(landmarks) {
    // Frontend CNN-based spectacle detection - runs during BOTH spectacles and capture phases
    if (!landmarks || landmarks.length === 0) return false;
    
    const now = Date.now();
    if (now - last_spectacle_check < SPECTACLE_CHECK_INTERVAL) {
        return false; // Skip this frame, checked too recently
    }
    
    last_spectacle_check = now;
    
    try {
        // Run during BOTH spectacles and capture phases (not just spectacles)
        if (TimerManager.stage !== 'spectacles' && TimerManager.stage !== 'capture') return false;
        
        // Get current video frame
        const ctx = canvas.getContext("2d");
        canvas.width = video.videoWidth;
        canvas.height = video.videoHeight;
        ctx.drawImage(video, 0, 0);
        
        // Get image data
        const imageData = ctx.getImageData(0, 0, canvas.width, canvas.height);
        
        // Run CNN detection
        const result = SpectacleDetectorCNN.detect(imageData, landmarks);
        
        console.log("[SPECTACLES] Detection:", {
            detected: result.detected,
            confidence: result.confidence.toFixed(2),
            stage: TimerManager.stage
        });
        
        if (result.detected) {
            handleSpectaclesDetected();
        } else {
            handleSpectaclesNotDetected();
        }
        
        return result.detected;
    } catch (e) {
        console.log("[SPECTACLES] Detection error:", e);
        return false;
    }
}

function handleSpectaclesDetected() {
    // Handle spectacles detection - show warning and pause timer
    // Keep warning active throughout execution (spectacles and capture phases)
    if (!spectacles_detected) {
        spectacles_detected = true;
        
        // Show warning banner
        if (spectacleWarning) {
            spectacleWarning.style.display = 'block';
            console.log("[SPECTACLES] Warning banner shown at stage:", TimerManager.stage);
        }
        
        // Pause session
        pauseSession('Spectacles detected! Please remove them');
        message.innerText = '⚠️ SPECTACLES DETECTED - Please remove them';
        message.style.color = '#ff6b6b';
        console.log("[SPECTACLES] Timer paused - warning active throughout execution");
    } else {
        // Keep warning visible if already detected (even across phases)
        if (spectacleWarning && spectacleWarning.style.display !== 'block') {
            spectacleWarning.style.display = 'block';
        }
        if (message.style.color !== '#ff6b6b') {
            message.style.color = '#ff6b6b';
        }
    }
}

function handleSpectaclesNotDetected() {
    // Handle when spectacles are no longer detected
    if (spectacles_detected) {
        spectacles_detected = false;
        
        // Hide warning banner
        if (spectacleWarning) {
            spectacleWarning.style.display = 'none';
            console.log("[SPECTACLES] Warning banner hidden at stage:", TimerManager.stage);
        }
        
        // Resume session
        resumeSession('Spectacles detected! Please remove them');
        message.style.color = '#333';
        
        // Restore appropriate message based on stage
        if (TimerManager.stage === 'capture') {
            message.innerText = 'Capturing Images... Blink naturally';
        } else if (TimerManager.stage === 'spectacles') {
            message.innerText = 'Welcome';
        }
        
        console.log("[SPECTACLES] Spectacles removed - session resumed at stage:", TimerManager.stage);
    }
}


// ----------- BLINK DETECTION (Using exact logic from blink_detector.py) -----------

function onResults(results) {

    // If session not active or capture not allowed, ignore
    if (!sessionActive) return;

    // Count faces (adapted from face_counter.py)
    const faces = results.multiFaceLandmarks ? results.multiFaceLandmarks.length : 0;

        if (faces > 1) {
            pauseSession('Multiple Faces Detected');
            return;
        } else {
            // clear multiple faces pause if previously set
            resumeSession('Multiple Faces Detected');
        }

        if (faces === 0) {
            pauseSession('No face detected. Please look at the camera.');
            return;
        } else {
            resumeSession('No face detected. Please look at the camera.');
        }

        // Spectacle detection during spectacles phase
        if (TimerManager.stage === 'spectacles') {
            detectSpectaclesSimple(results.multiFaceLandmarks[0]);
        }

        // Brightness check: if too bright, pause
        try {
            const brightness = getBrightness();
            if (brightness > BRIGHTNESS_THRESHOLD) {
                pauseSession('Move to a different area, too bright');
                return;
            } else {
                resumeSession('Move to a different area, too bright');
            }
        } catch (e) {
            // ignore brightness errors
        }

    // If capture not yet allowed (spectacles timer), just show message
    if (!capture_allowed) {
        // keep existing message (spectacles countdown handled elsewhere)
        return;
    }

    const landmarks = results.multiFaceLandmarks[0];

    const leftEAR = calculateEAR(landmarks, LEFT_EYE);
    const rightEAR = calculateEAR(landmarks, RIGHT_EYE);

    const ear = (leftEAR + rightEAR) / 2.0;

    // Store detection data in cache for reference
    const cacheEntry = {
        timestamp: Date.now(),
        ear: parseFloat(ear.toFixed(3)),
        leftEAR: parseFloat(leftEAR.toFixed(3)),
        rightEAR: parseFloat(rightEAR.toFixed(3))
    };

    console.log("[BLINK] EAR:", ear.toFixed(3), "Frames captured:", all_frames.data.length);

    // Capture frame for server-side classification
    storeImageLocally("frame");

    // Add to cache queue
    detectionCache.push(cacheEntry);
}


// ----------- HELPERS -----------

function distance(p1, p2) {
    return Math.sqrt(
        Math.pow(p1.x - p2.x, 2) +
        Math.pow(p1.y - p2.y, 2)
    );
}

function calculateEAR(landmarks, indices) {
    // Get the 6 points for the eye
    const p1 = landmarks[indices[0]];
    const p2 = landmarks[indices[1]];
    const p3 = landmarks[indices[2]];
    const p4 = landmarks[indices[3]];
    const p5 = landmarks[indices[4]];
    const p6 = landmarks[indices[5]];

    // Calculate distances exactly as in Python ear_utils.py
    // A = distance between points 1 and 5 (vertical)
    // B = distance between points 2 and 4 (vertical)
    // C = distance between points 0 and 3 (horizontal)
    const A = distance(p2, p6);
    const B = distance(p3, p5);
    const C = distance(p1, p4);

    // EAR = (A + B) / (2.0 * C)
    return (A + B) / (2.0 * C);
}

// ---------- BRIGHTNESS CHECK ----------
function getBrightness() {
    const w = brightnessCanvas.width;
    const h = brightnessCanvas.height;
    if (video.readyState < 2 || video.videoWidth === 0) return 0;
    try {
        brightnessCtx.drawImage(video, 0, 0, w, h);
        const img = brightnessCtx.getImageData(0, 0, w, h).data;
        let sum = 0;
        for (let i = 0; i < img.length; i += 4) {
            const r = img[i], g = img[i+1], b = img[i+2];
            const lum = 0.299 * r + 0.587 * g + 0.114 * b;
            sum += lum;
        }
        const avg = sum / (w * h);
        return avg;
    } catch (e) {
        return 0;
    }
}

// ----------- START CAMERA -----------

async function startCamera() {

    try {
        console.log("[BLINK] Requesting camera access...");
        const stream = await navigator.mediaDevices.getUserMedia({ video: true });

        video.srcObject = stream;
        
        message.innerText = "Camera ready. Initializing...";
        
        // Hide permission button on success
        if (permissionButton) {
            permissionButton.style.display = "none";
        }

        // Start face mesh
        startFaceMesh();
        
        // Give face mesh time to initialize (1 second)
        setTimeout(() => {
            console.log("[BLINK] Starting timer...");
            startSessionTimer();
        }, 1000);

    } catch (err) {
        console.error("[BLINK] Camera error:", err);
        message.innerText = "Camera access denied. Click button to allow.";
        
        // Show permission button on denial
        if (permissionButton) {
            permissionButton.style.display = "block";
        }
    }
}

// ----------- REQUEST CAMERA PERMISSION AGAIN -----------

function requestCameraPermission() {
    console.log("[BLINK] User requesting camera permission again...");
    // Hide button and retry camera access
    if (permissionButton) {
        permissionButton.style.display = "none";
    }
    message.innerText = "Requesting camera access...";
    startCamera();
}


// ----------- INIT MEDIAPIPE -----------

function startFaceMesh() {

    const faceMesh = new FaceMesh({
        locateFile: (file) => {
            return `https://cdn.jsdelivr.net/npm/@mediapipe/face_mesh/${file}`;
        }
    });

    faceMesh.setOptions({
        maxNumFaces: 3
    });

    faceMesh.onResults(onResults);

    const camera = new Camera(video, {
        onFrame: async () => {
            await faceMesh.send({ image: video });
        }
    });

    camera.start();
}


// ----------- INIT -----------

window.onload = () => {
    startCamera();
};

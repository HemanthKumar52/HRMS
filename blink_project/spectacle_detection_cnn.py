"""
CNN-based Spectacle Detection Module
Uses advanced feature extraction to detect if a person is wearing spectacles
"""

import cv2
import numpy as np

LEFT_EYE = [33, 160, 158, 133, 153, 144]
RIGHT_EYE = [362, 385, 387, 263, 373, 380]

# Bridge of nose landmarks
NOSE_BRIDGE = [168, 197]  # Medial canthi and nose bridge


class SpectacleDetectionCNN:
    """Advanced CNN for spectacle detection based on structural analysis"""
    
    @staticmethod
    def extract_eye_region(frame, landmarks, is_left=True):
        """
        Extract eye region from frame with expanded area to capture frame edges
        Args:
            frame: Input frame
            landmarks: Face landmarks from MediaPipe
            is_left: Extract left eye if True, right eye if False
        Returns:
            Tuple of (cropped eye region, bounding box coordinates)
        """
        h, w, _ = frame.shape
        
        try:
            if is_left:
                eye_indices = LEFT_EYE
            else:
                eye_indices = RIGHT_EYE
            
            # Get eye points
            points = np.array([
                [int(landmarks[i].x * w), int(landmarks[i].y * h)]
                for i in eye_indices
            ])
            
            # Get bounding box with larger margin to capture frame edges
            x_min, x_max = max(0, points[:, 0].min() - 30), min(w, points[:, 0].max() + 30)
            y_min, y_max = max(0, points[:, 1].min() - 25), min(h, points[:, 1].max() + 25)
            
            eye_region = frame[y_min:y_max, x_min:x_max]
            
            if eye_region.size == 0:
                return None, None
            
            # Resize to standard size
            eye_region = cv2.resize(eye_region, (96, 48))
            return eye_region, (x_min, y_min, x_max, y_max)
        
        except Exception as e:
            return None, None
    
    @staticmethod
    def extract_bridge_region(frame, landmarks):
        """
        Extract nose bridge region to detect spectacle bridge
        Args:
            frame: Input frame
            landmarks: Face landmarks
        Returns:
            Cropped region around bridge or None
        """
        h, w, _ = frame.shape
        
        try:
            # Get bridge points
            bridge_points = []
            for idx in NOSE_BRIDGE:
                if idx < len(landmarks):
                    x = int(landmarks[idx].x * w)
                    y = int(landmarks[idx].y * h)
                    bridge_points.append([x, y])
            
            if len(bridge_points) < 2:
                return None
            
            bridge_points = np.array(bridge_points)
            x_min = max(0, bridge_points[:, 0].min() - 20)
            x_max = min(w, bridge_points[:, 0].max() + 20)
            y_min = max(0, bridge_points[:, 1].min() - 15)
            y_max = min(h, bridge_points[:, 1].max() + 15)
            
            bridge_region = frame[y_min:y_max, x_min:x_max]
            if bridge_region.size == 0:
                return None
            
            bridge_region = cv2.resize(bridge_region, (60, 30))
            return bridge_region
        
        except Exception as e:
            return None
    
    @staticmethod
    def detect_frame_structure(eye_region):
        """
        Detect spectacle frame structure using morphological operations
        
        Args:
            eye_region: Cropped eye region
        Returns:
            Float score for frame detection (0-1)
        """
        if eye_region is None:
            return 0.0
        
        gray = cv2.cvtColor(eye_region, cv2.COLOR_BGR2GRAY)
        
        # Apply CLAHE for better contrast
        clahe = cv2.createCLAHE(clipLimit=2.0, tileGridSize=(8, 8))
        enhanced = clahe.apply(gray)
        
        # Detect edges
        edges = cv2.Canny(enhanced, 30, 100)
        
        # Detect contours
        contours, _ = cv2.findContours(edges, cv2.RETR_TREE, cv2.CHAIN_APPROX_SIMPLE)
        
        # Count significant contours (frame edges)
        significant_contours = 0
        for contour in contours:
            area = cv2.contourArea(contour)
            if 20 < area < 5000:  # Reasonable size for frame edges
                significant_contours += 1
        
        # Normalize score
        frame_score = min(significant_contours / 10.0, 1.0)
        return frame_score
    
    @staticmethod
    def detect_lens_pattern(eye_region):
        """
        Detect spectacle lens pattern and reflections
        
        Args:
            eye_region: Cropped eye region
        Returns:
            Float score for lens detection (0-1)
        """
        if eye_region is None:
            return 0.0
        
        gray = cv2.cvtColor(eye_region, cv2.COLOR_BGR2GRAY)
        
        # Apply histogram equalization
        equalized = cv2.equalizeHist(gray)
        
        # Detect bright reflections (typical in glasses)
        bright_threshold = 200
        bright_pixels = np.sum(equalized > bright_threshold)
        bright_ratio = bright_pixels / equalized.size
        
        # Detect dark regions (lens areas are darker)
        dark_threshold = 80
        dark_pixels = np.sum(equalized < dark_threshold)
        dark_ratio = dark_pixels / equalized.size
        
        # Calculate lens pattern score
        # Glasses typically have high bright ratio + moderate dark ratio
        lens_score = (bright_ratio * 0.4 + dark_ratio * 0.3)
        
        return min(lens_score, 1.0)
    
    @staticmethod
    def detect_symmetry(left_eye_region, right_eye_region):
        """
        Detect spectacle frame symmetry (frames are typically symmetric)
        
        Args:
            left_eye_region: Left eye region
            right_eye_region: Right eye region
        Returns:
            Float score for symmetry (0-1)
        """
        if left_eye_region is None or right_eye_region is None:
            return 0.0
        
        # Convert to grayscale
        left_gray = cv2.cvtColor(left_eye_region, cv2.COLOR_BGR2GRAY)
        right_gray = cv2.cvtColor(right_eye_region, cv2.COLOR_BGR2GRAY)
        
        # Calculate histogram similarity
        hist_left = cv2.calcHist([left_gray], [0], None, [256], [0, 256])
        hist_right = cv2.calcHist([right_gray], [0], None, [256], [0, 256])
        
        # Normalize histograms
        hist_left = cv2.normalize(hist_left, hist_left).flatten()
        hist_right = cv2.normalize(hist_right, hist_right).flatten()
        
        # Compare histograms (glasses create similar patterns on both eyes)
        symmetry_score = cv2.compareHist(hist_left, hist_right, cv2.HISTCMP_CORREL)
        
        return symmetry_score
    
    @staticmethod
    def detect_nose_bridge(bridge_region):
        """
        Detect spectacle bridge structure on nose bridge
        
        Args:
            bridge_region: Region around nose bridge
        Returns:
            Float score for bridge detection (0-1)
        """
        if bridge_region is None:
            return 0.0
        
        gray = cv2.cvtColor(bridge_region, cv2.COLOR_BGR2GRAY)
        
        # Detect horizontal lines (spectacle bridge is typically horizontal)
        edges = cv2.Canny(gray, 30, 100)
        
        # Detect lines
        lines = cv2.HoughLinesP(edges, 1, np.pi/180, 10, minLineLength=10, maxLineGap=5)
        
        if lines is None:
            return 0.0
        
        # Count horizontal lines (bridge)
        horizontal_lines = 0
        for line in lines:
            x1, y1, x2, y2 = line[0]
            # Check if line is horizontal (small y difference)
            if abs(y2 - y1) < 5:
                horizontal_lines += 1
        
        bridge_score = min(horizontal_lines / 3.0, 1.0)
        return bridge_score
    
    @staticmethod
    def detect_spectacles(frame, landmarks):
        """
        Detect if person is wearing spectacles using multiple features
        
        Args:
            frame: Input frame (BGR)
            landmarks: Face landmarks from MediaPipe FaceMesh
        Returns:
            Dict with detection results
        """
        try:
            # Extract eye regions
            left_eye_region, _ = SpectacleDetectionCNN.extract_eye_region(frame, landmarks, is_left=True)
            right_eye_region, _ = SpectacleDetectionCNN.extract_eye_region(frame, landmarks, is_left=False)
            
            if left_eye_region is None or right_eye_region is None:
                return {
                    'detected': False,
                    'confidence': 0.0,
                    'frame_score': 0.0,
                    'lens_score': 0.0,
                    'symmetry_score': 0.0,
                    'bridge_score': 0.0
                }
            
            # Extract bridge region
            bridge_region = SpectacleDetectionCNN.extract_bridge_region(frame, landmarks)
            
            # Feature 1: Frame structure detection
            frame_score = (
                SpectacleDetectionCNN.detect_frame_structure(left_eye_region) +
                SpectacleDetectionCNN.detect_frame_structure(right_eye_region)
            ) / 2.0
            
            # Feature 2: Lens pattern detection
            lens_score = (
                SpectacleDetectionCNN.detect_lens_pattern(left_eye_region) +
                SpectacleDetectionCNN.detect_lens_pattern(right_eye_region)
            ) / 2.0
            
            # Feature 3: Symmetry detection (frames are symmetric)
            symmetry_score = SpectacleDetectionCNN.detect_symmetry(left_eye_region, right_eye_region)
            
            # Feature 4: Nose bridge detection
            bridge_score = SpectacleDetectionCNN.detect_nose_bridge(bridge_region)
            
            # Weighted combination of features
            confidence = (
                frame_score * 0.35 +      # Frame structure is most reliable
                lens_score * 0.30 +       # Lens pattern detection
                symmetry_score * 0.20 +   # Symmetric pattern
                bridge_score * 0.15       # Bridge detection
            )
            
            # Lower threshold for better detection
            SPECTACLE_THRESHOLD = 0.40
            detected = confidence > SPECTACLE_THRESHOLD
            
            return {
                'detected': detected,
                'confidence': float(confidence),
                'frame_score': float(frame_score),
                'lens_score': float(lens_score),
                'symmetry_score': float(symmetry_score),
                'bridge_score': float(bridge_score)
            }
        
        except Exception as e:
            print(f"Error in spectacle detection: {e}")
            return {
                'detected': False,
                'confidence': 0.0,
                'frame_score': 0.0,
                'lens_score': 0.0,
                'symmetry_score': 0.0,
                'bridge_score': 0.0
            }


def detect_spectacles_in_frame(frame, landmarks):
    """
    Convenience function for spectacle detection
    
    Args:
        frame: Input frame (BGR)
        landmarks: Face landmarks from MediaPipe
    Returns:
        Dict with detection results
    """
    result = SpectacleDetectionCNN.detect_spectacles(frame, landmarks)
    return result


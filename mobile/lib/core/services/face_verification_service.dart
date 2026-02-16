import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

/// Service for face verification using device camera
class FaceVerificationService {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;
  CameraController? get controller => _controller;

  /// Initialize the camera (prefer front camera for face verification)
  Future<bool> initialize() async {
    try {
      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) {
        return false;
      }

      // Find front camera, fallback to first camera
      final frontCamera = _cameras!.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => _cameras!.first,
      );

      _controller = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _controller!.initialize();
      _isInitialized = true;
      return true;
    } catch (e) {
      debugPrint('Failed to initialize camera: $e');
      return false;
    }
  }

  /// Take a photo and return the file path
  Future<String?> capturePhoto() async {
    if (_controller == null || !_isInitialized) {
      return null;
    }

    try {
      final XFile photo = await _controller!.takePicture();

      // Move to app's document directory with timestamp
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final newPath = '${directory.path}/face_verification_$timestamp.jpg';

      final File newFile = await File(photo.path).copy(newPath);
      return newFile.path;
    } catch (e) {
      debugPrint('Failed to capture photo: $e');
      return null;
    }
  }

  /// Dispose the camera controller
  Future<void> dispose() async {
    if (_controller != null) {
      await _controller!.dispose();
      _controller = null;
      _isInitialized = false;
    }
  }
}

final faceVerificationServiceProvider = Provider<FaceVerificationService>((ref) {
  return FaceVerificationService();
});

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../network/blink_api_client.dart';
import '../theme/app_colors.dart';
import 'glass_card.dart';

/// Face verification result returned to the caller
class FaceVerificationResult {
  final String? photoPath;
  final String? employeeName;
  final double confidence;

  FaceVerificationResult({this.photoPath, this.employeeName, this.confidence = 0.0});
}

/// Verification phases
enum _VerificationPhase { welcome, capture, processing, success, failed }

/// Dialog that shows camera preview, captures frames, and verifies liveness
/// via the blink detection Flask server before allowing attendance clock-in.
class FaceVerificationDialog extends ConsumerStatefulWidget {
  final Function(FaceVerificationResult? result) onComplete;

  const FaceVerificationDialog({
    super.key,
    required this.onComplete,
  });

  @override
  ConsumerState<FaceVerificationDialog> createState() =>
      _FaceVerificationDialogState();
}

class _FaceVerificationDialogState
    extends ConsumerState<FaceVerificationDialog> {
  CameraController? _controller;
  bool _isInitialized = false;
  String? _errorMessage;

  // Phase management
  _VerificationPhase _phase = _VerificationPhase.welcome;
  int _welcomeCountdown = 3;
  int _captureCountdown = 15;
  int _framesCaptured = 0;

  // Timers
  Timer? _welcomeTimer;
  Timer? _captureTimer;
  Timer? _countdownTimer;

  // Frame buffer for blink server
  final List<String> _frameBuffer = [];
  static const int _maxFrames = 100;

  // Last captured photo path for avatar
  String? _lastPhotoPath;

  // Prevent concurrent takePicture calls
  bool _isTakingPicture = false;

  // Failure message
  String _failureMessage = 'Liveness check failed. No blinks detected.';

  // Matched employee info from face verification
  String? _matchedEmployeeName;
  double _matchedConfidence = 0.0;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() {
          _errorMessage = 'No camera available on this device';
        });
        return;
      }

      final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _controller = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _controller!.initialize();

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
        _startWelcomePhase();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to initialize camera: $e';
        });
      }
    }
  }

  // ─── Phase 1: Welcome ─────────────────────────────────────────────

  void _startWelcomePhase() {
    setState(() {
      _phase = _VerificationPhase.welcome;
      _welcomeCountdown = 3;
    });

    _welcomeTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _welcomeCountdown--;
      });
      if (_welcomeCountdown <= 0) {
        timer.cancel();
        _startCapturePhase();
      }
    });
  }

  // ─── Phase 2: Capture ─────────────────────────────────────────────

  void _startCapturePhase() {
    setState(() {
      _phase = _VerificationPhase.capture;
      _captureCountdown = 15;
      _framesCaptured = 0;
      _frameBuffer.clear();
      _lastPhotoPath = null;
    });

    // Capture a frame every 500ms
    _captureTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      _captureFrame();
    });

    // Countdown display ticks every 1s
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _captureCountdown--;
      });
      if (_captureCountdown <= 0) {
        timer.cancel();
        _captureTimer?.cancel();
        _startProcessingPhase();
      }
    });
  }

  Future<void> _captureFrame() async {
    if (_controller == null ||
        !_isInitialized ||
        _isTakingPicture ||
        _phase != _VerificationPhase.capture) {
      return;
    }

    _isTakingPicture = true;

    try {
      final XFile photo = await _controller!.takePicture();
      final bytes = await photo.readAsBytes();
      final base64Str = base64Encode(bytes);
      final dataUri = 'data:image/jpeg;base64,$base64Str';

      // FIFO buffer
      if (_frameBuffer.length >= _maxFrames) {
        _frameBuffer.removeAt(0);
      }
      _frameBuffer.add(dataUri);
      _lastPhotoPath = photo.path;

      if (mounted) {
        setState(() {
          _framesCaptured = _frameBuffer.length;
        });
      }
    } catch (e) {
      debugPrint('Frame capture error: $e');
    } finally {
      _isTakingPicture = false;
    }
  }

  // ─── Phase 3: Processing ──────────────────────────────────────────

  Future<void> _startProcessingPhase() async {
    setState(() {
      _phase = _VerificationPhase.processing;
    });

    if (_frameBuffer.isEmpty) {
      setState(() {
        _phase = _VerificationPhase.failed;
        _failureMessage = 'No frames captured. Please try again.';
      });
      return;
    }

    try {
      final blinkDio = ref.read(blinkDioProvider);

      // ── Step 1: Liveness check (blink detection) ──
      final livenessResponse = await blinkDio.post(
        '/upload_nodes',
        data: {
          'all_frames': _frameBuffer,
          'detection_cache': <Map<String, dynamic>>[],
        },
      );

      if (!mounted) return;

      if (livenessResponse.statusCode != 200 || livenessResponse.data == null) {
        setState(() {
          _phase = _VerificationPhase.failed;
          _failureMessage = 'Server returned an unexpected response.';
        });
        return;
      }

      final livenessData = livenessResponse.data;
      final status = livenessData['status'] as String?;
      final blinked = livenessData['blinked'] as int? ?? 0;
      final liveness = livenessData['liveness'] as bool? ?? false;

      if (status != 'success' || blinked < 1 || !liveness) {
        setState(() {
          _phase = _VerificationPhase.failed;
          _failureMessage = blinked == 0
              ? 'No blinks detected. Please blink naturally and try again.'
              : 'Liveness verification failed. Please try again.';
        });
        return;
      }

      // ── Step 2: Check face verification result from blink server ──
      // The /upload_nodes endpoint already verifies the face against registered employees
      final verification = livenessData['verification'] as Map<String, dynamic>?;

      if (verification != null) {
        final isMatched = verification['matched'] as bool? ?? false;
        final employeeName = verification['employee_name'] as String?;
        final confidence = (verification['confidence'] as num?)?.toDouble() ?? 0.0;

        if (isMatched && employeeName != null) {
          debugPrint('[FaceVerification] MATCH: $employeeName (${(confidence * 100).toStringAsFixed(1)}%)');
          _matchedEmployeeName = employeeName;
          _matchedConfidence = confidence;
          _onVerificationSuccess();
        } else {
          debugPrint('[FaceVerification] NO MATCH (confidence: ${(confidence * 100).toStringAsFixed(1)}%)');
          setState(() {
            _phase = _VerificationPhase.failed;
            _failureMessage = 'Face not recognized. You are not a registered employee.';
          });
        }
      } else {
        setState(() {
          _phase = _VerificationPhase.failed;
          _failureMessage = 'Face verification unavailable. Please try again.';
        });
      }
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() {
        _phase = _VerificationPhase.failed;
        _failureMessage = e.type == DioExceptionType.connectionTimeout ||
                e.type == DioExceptionType.connectionError
            ? 'Cannot connect to verification server. Ensure it is running.'
            : 'Network error: ${e.message}';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _phase = _VerificationPhase.failed;
        _failureMessage = 'Verification error: $e';
      });
    }
  }

  // ─── Phase 4a: Success ────────────────────────────────────────────

  void _onVerificationSuccess() {
    setState(() {
      _phase = _VerificationPhase.success;
    });

    // Brief success display, then return result
    Future.delayed(const Duration(milliseconds: 2000), () {
      if (mounted) {
        widget.onComplete(FaceVerificationResult(
          photoPath: _lastPhotoPath,
          employeeName: _matchedEmployeeName,
          confidence: _matchedConfidence,
        ));
        Navigator.of(context).pop();
      }
    });
  }

  // ─── Phase 4b: Retry ─────────────────────────────────────────────

  void _retry() {
    _cancelTimers();
    _startWelcomePhase();
  }

  // ─── Cancel / Dispose ─────────────────────────────────────────────

  void _cancelTimers() {
    _welcomeTimer?.cancel();
    _captureTimer?.cancel();
    _countdownTimer?.cancel();
  }

  void _cancelDialog() {
    widget.onComplete(null);
    Navigator.of(context).pop();
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }

  @override
  void dispose() {
    _cancelTimers();
    _controller?.dispose();
    super.dispose();
  }

  // ─── Build ────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 400, maxHeight: screenHeight * 0.7),
        child: GlassCard(
          blur: 12,
          opacity: 0.15,
          borderRadius: 20,
          padding: EdgeInsets.zero,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              _buildHeader(),

              // Camera Preview
              Expanded(
                child: Container(
                  margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: Colors.black,
                  ),
                  clipBehavior: Clip.hardEdge,
                  child: _buildCameraContent(),
                ),
              ),

              // Phase-specific bottom section
              _buildBottomSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    Color headerColor;
    String headerText;
    IconData headerIcon;

    switch (_phase) {
      case _VerificationPhase.welcome:
        headerColor = AppColors.primary;
        headerText = 'Face Verification';
        headerIcon = Icons.face;
        break;
      case _VerificationPhase.capture:
        headerColor = Colors.orange.shade700;
        headerText = 'Capturing - Blink Naturally';
        headerIcon = Icons.visibility;
        break;
      case _VerificationPhase.processing:
        headerColor = Colors.blue.shade700;
        headerText = 'Verifying Liveness...';
        headerIcon = Icons.hourglass_top;
        break;
      case _VerificationPhase.success:
        headerColor = AppColors.success;
        headerText = _matchedEmployeeName != null
            ? 'Verified: ${_capitalize(_matchedEmployeeName!)}'
            : 'Verification Successful';
        headerIcon = Icons.check_circle;
        break;
      case _VerificationPhase.failed:
        headerColor = AppColors.error;
        headerText = 'Verification Failed';
        headerIcon = Icons.error;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: headerColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          Icon(headerIcon, color: Colors.white, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              headerText,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (_phase != _VerificationPhase.processing &&
              _phase != _VerificationPhase.success)
            IconButton(
              onPressed: _cancelDialog,
              icon: const Icon(Icons.close, color: Colors.white, size: 20),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }

  Widget _buildCameraContent() {
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
      );
    }

    if (!_isInitialized) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 16),
            Text(
              'Initializing camera...',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
      );
    }

    // Success/Failed overlays
    if (_phase == _VerificationPhase.success) {
      return _buildSuccessOverlay();
    }
    if (_phase == _VerificationPhase.processing) {
      return _buildProcessingOverlay();
    }
    if (_phase == _VerificationPhase.failed) {
      return _buildFailedOverlay();
    }

    // Camera preview with overlays
    return Stack(
      fit: StackFit.expand,
      children: [
        CameraPreview(_controller!),

        // Face outline overlay
        Center(
          child: Container(
            width: 220,
            height: 280,
            decoration: BoxDecoration(
              border: Border.all(
                color: _phase == _VerificationPhase.capture
                    ? Colors.orange.withValues(alpha: 0.8)
                    : AppColors.success.withValues(alpha: 0.8),
                width: 3,
              ),
              borderRadius: BorderRadius.circular(120),
            ),
          ),
        ),

        // Corner guides
        Positioned(
          top: 30,
          left: 30,
          right: 30,
          bottom: 30,
          child: CustomPaint(
            painter: _CornerGuidePainter(
              color: _phase == _VerificationPhase.capture
                  ? Colors.orange
                  : Colors.white,
            ),
          ),
        ),

        // Countdown overlay
        if (_phase == _VerificationPhase.welcome)
          Center(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha:0.5),
                shape: BoxShape.circle,
              ),
              child: Text(
                '$_welcomeCountdown',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ).animate().scale(
                  duration: 800.ms,
                  curve: Curves.easeOutBack,
                ),
          ),

        // Capture countdown
        if (_phase == _VerificationPhase.capture)
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha:0.6),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${_captureCountdown}s',
                style: const TextStyle(
                  color: Colors.orange,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

        // Frame counter during capture
        if (_phase == _VerificationPhase.capture)
          Positioned(
            bottom: 8,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha:0.6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Frames: $_framesCaptured',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSuccessOverlay() {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Show captured face photo
            if (_lastPhotoPath != null)
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.success, width: 3),
                  image: DecorationImage(
                    image: FileImage(File(_lastPhotoPath!)),
                    fit: BoxFit.cover,
                  ),
                ),
              ).animate().scale(duration: 500.ms, curve: Curves.easeOutBack)
            else
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: AppColors.success,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 48),
              ).animate().scale(duration: 500.ms, curve: Curves.easeOutBack),
            const SizedBox(height: 16),
            // Show matched employee name
            if (_matchedEmployeeName != null)
              Text(
                'Welcome, ${_capitalize(_matchedEmployeeName!)}!',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ).animate().fadeIn(delay: 300.ms)
            else
              const Text(
                'Verified!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ).animate().fadeIn(delay: 300.ms),
            const SizedBox(height: 8),
            // Confidence score
            if (_matchedConfidence > 0)
              Text(
                'Confidence: ${(_matchedConfidence * 100).toStringAsFixed(1)}%',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 14,
                ),
              ).animate().fadeIn(delay: 500.ms),
            const SizedBox(height: 4),
            const Text(
              'Attendance Marked: PRESENT',
              style: TextStyle(
                color: AppColors.success,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ).animate().fadeIn(delay: 600.ms),
          ],
        ),
      ),
    );
  }

  Widget _buildProcessingOverlay() {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 60,
              height: 60,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation(Colors.blue),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Analyzing $_framesCaptured frames...',
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 8),
            const Text(
              'Verifying liveness & identity',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFailedOverlay() {
    return Container(
      color: Colors.black,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha:0.2),
                  shape: BoxShape.circle,
                ),
                child:
                    const Icon(Icons.error_outline, color: AppColors.error, size: 48),
              ),
              const SizedBox(height: 16),
              Text(
                _failureMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomSection() {
    switch (_phase) {
      case _VerificationPhase.welcome:
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
          child: Text(
            'Position your face within the frame',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600], fontSize: 13),
          ),
        );

      case _VerificationPhase.capture:
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.visibility, color: Colors.orange.shade700, size: 18),
              const SizedBox(width: 8),
              Text(
                'Blink naturally while looking at the camera',
                style: TextStyle(
                  color: Colors.orange.shade700,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );

      case _VerificationPhase.processing:
        return const Padding(
          padding: EdgeInsets.fromLTRB(16, 4, 16, 16),
          child: Text(
            'Please wait...',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
        );

      case _VerificationPhase.success:
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
          child: Text(
            _matchedEmployeeName != null
                ? '${_capitalize(_matchedEmployeeName!)} verified successfully!'
                : 'You are verified!',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.success,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        );

      case _VerificationPhase.failed:
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _cancelDialog,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.grey,
                    side: const BorderSide(color: Colors.grey),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _retry,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Retry'),
                ),
              ),
            ],
          ),
        );
    }
  }
}

/// Custom painter for corner guides
class _CornerGuidePainter extends CustomPainter {
  final Color color;

  _CornerGuidePainter({this.color = Colors.white});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha:0.6)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    const cornerLength = 30.0;

    // Top left
    canvas.drawLine(Offset.zero, const Offset(cornerLength, 0), paint);
    canvas.drawLine(Offset.zero, const Offset(0, cornerLength), paint);

    // Top right
    canvas.drawLine(
      Offset(size.width, 0),
      Offset(size.width - cornerLength, 0),
      paint,
    );
    canvas.drawLine(
      Offset(size.width, 0),
      Offset(size.width, cornerLength),
      paint,
    );

    // Bottom left
    canvas.drawLine(
      Offset(0, size.height),
      Offset(cornerLength, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(0, size.height),
      Offset(0, size.height - cornerLength),
      paint,
    );

    // Bottom right
    canvas.drawLine(
      Offset(size.width, size.height),
      Offset(size.width - cornerLength, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(size.width, size.height),
      Offset(size.width, size.height - cornerLength),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _CornerGuidePainter oldDelegate) =>
      color != oldDelegate.color;
}

/// Show face verification dialog with liveness detection.
/// Returns FaceVerificationResult on success, null on cancel/failure.
Future<FaceVerificationResult?> showFaceVerificationDialog(BuildContext context) async {
  FaceVerificationResult? result;

  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => FaceVerificationDialog(
      onComplete: (r) {
        result = r;
      },
    ),
  );

  return result;
}

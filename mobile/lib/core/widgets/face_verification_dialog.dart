import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../network/blink_api_client.dart';
import '../services/local_face_store.dart';
import '../theme/app_colors.dart';
import 'glass_card.dart';

/// Face verification result returned to the caller
class FaceVerificationResult {
  final String? photoPath;
  final String? employeeName;
  final double confidence;

  FaceVerificationResult({this.photoPath, this.employeeName, this.confidence = 0.0});
}

/// Verification phases — simplified (no liveness)
enum _VerificationPhase { countdown, capturing, processing, success, failed }

/// Dialog that shows camera preview, captures a SINGLE face photo,
/// and verifies identity against registered employees.
/// No liveness/blink detection — just one photo and verify.
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
  _VerificationPhase _phase = _VerificationPhase.countdown;
  int _countdown = 3;

  // Timers
  Timer? _countdownTimer;

  // Captured photo
  String? _lastPhotoPath;

  // Failure message
  String _failureMessage = 'Face not recognized.';

  // Matched employee info
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
        _startCountdown();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to initialize camera: $e';
        });
      }
    }
  }

  // ─── Phase 1: Countdown ──────────────────────────────────────────

  void _startCountdown() {
    setState(() {
      _phase = _VerificationPhase.countdown;
      _countdown = 3;
    });

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _countdown--;
      });
      if (_countdown <= 0) {
        timer.cancel();
        _captureAndVerify();
      }
    });
  }

  // ─── Phase 2: Capture single photo & verify ──────────────────────

  Future<void> _captureAndVerify() async {
    if (_controller == null || !_isInitialized) return;

    setState(() {
      _phase = _VerificationPhase.capturing;
    });

    HapticFeedback.mediumImpact();

    try {
      // Capture ONE photo
      final XFile photo = await _controller!.takePicture();
      final bytes = await photo.readAsBytes();
      final base64Str = base64Encode(bytes);
      final dataUri = 'data:image/jpeg;base64,$base64Str';
      _lastPhotoPath = photo.path;

      setState(() {
        _phase = _VerificationPhase.processing;
      });

      // Send to Flask /verify_face
      final blinkDio = ref.read(blinkDioProvider);

      final response = await blinkDio.post('/verify_face', data: {
        'frame': dataUri,
      });

      if (!mounted) return;

      if (response.statusCode != 200 || response.data == null) {
        setState(() {
          _phase = _VerificationPhase.failed;
          _failureMessage = 'Server returned an unexpected response.';
        });
        return;
      }

      final data = response.data;
      final status = data['status'] as String?;
      final serverError = data['error'] as String?;

      // Check for multiple faces
      if (serverError == 'multiple_faces_detected') {
        setState(() {
          _phase = _VerificationPhase.failed;
          _failureMessage = 'Multiple faces detected. Only one person should be in the frame.';
        });
        return;
      }

      // Check for other errors
      if (status == 'failed') {
        setState(() {
          _phase = _VerificationPhase.failed;
          _failureMessage = serverError ?? 'Verification failed. Please try again.';
        });
        return;
      }

      final isMatched = data['matched'] as bool? ?? false;
      final employeeName = data['employee_name'] as String?;
      final confidence = (data['confidence'] as num?)?.toDouble() ?? 0.0;

      if (isMatched && employeeName != null) {
        debugPrint('[FaceVerification] MATCH: $employeeName (${(confidence * 100).toStringAsFixed(1)}%)');
        _matchedEmployeeName = employeeName;
        _matchedConfidence = confidence;
        _onVerificationSuccess();
        return;
      }

      // Fallback: try offline face match using cached data
      debugPrint('[FaceVerification] Server match failed — trying offline cache...');
      final offlineResult = await _tryOfflineFaceMatch(blinkDio, dataUri);

      if (!mounted) return;

      if (offlineResult != null) {
        _matchedEmployeeName = offlineResult['employee_name'] as String?;
        _matchedConfidence = (offlineResult['confidence'] as num?)?.toDouble() ?? 0.0;
        debugPrint('[FaceVerification] MATCH via cached data: $_matchedEmployeeName');
        _onVerificationSuccess();
      } else {
        setState(() {
          _phase = _VerificationPhase.failed;
          _failureMessage = 'Face not recognized. You are not a registered employee.';
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

  /// Try face matching using locally cached employee face photos.
  Future<Map<String, dynamic>?> _tryOfflineFaceMatch(Dio blinkDio, String capturedFrame) async {
    try {
      final localFaceStore = ref.read(localFaceStoreProvider);
      final cachedFaces = await localFaceStore.getAllCachedFaces();

      if (cachedFaces.isEmpty) {
        debugPrint('[FaceVerification] No cached faces available for offline match.');
        return null;
      }

      final employees = cachedFaces.map((emp) => {
            'id': emp.id,
            'name': emp.name,
            'facePhoto': emp.facePhotoBase64,
          }).toList();

      debugPrint('[FaceVerification] Trying offline match against ${employees.length} cached employees...');

      final response = await blinkDio.post('/classify_face', data: {
        'captured_frame': capturedFrame,
        'employees': employees,
      });

      if (response.statusCode == 200 && response.data != null) {
        final matched = response.data['matched'] as bool? ?? false;
        if (matched) {
          return response.data as Map<String, dynamic>;
        }
      }
    } catch (e) {
      debugPrint('[FaceVerification] Offline face match error: $e');
    }
    return null;
  }

  // ─── Success ─────────────────────────────────────────────────────

  void _onVerificationSuccess() {
    // Haptic feedback — success pattern
    HapticFeedback.heavyImpact();
    Future.delayed(const Duration(milliseconds: 150), () => HapticFeedback.mediumImpact());
    Future.delayed(const Duration(milliseconds: 300), () => HapticFeedback.lightImpact());

    setState(() {
      _phase = _VerificationPhase.success;
    });

    Future.delayed(const Duration(milliseconds: 2500), () {
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

  void _vibrateError() {
    HapticFeedback.heavyImpact();
    Future.delayed(const Duration(milliseconds: 100), () => HapticFeedback.heavyImpact());
  }

  // ─── Retry ──────────────────────────────────────────────────────

  void _retry() {
    _countdownTimer?.cancel();
    _startCountdown();
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
    _countdownTimer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  // ─── Build ──────────────────────────────────────────────────────

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
              _buildHeader(),
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
      case _VerificationPhase.countdown:
        headerColor = AppColors.primary;
        headerText = 'Face Verification';
        headerIcon = Icons.face;
        break;
      case _VerificationPhase.capturing:
        headerColor = Colors.orange.shade700;
        headerText = 'Capturing...';
        headerIcon = Icons.camera_alt;
        break;
      case _VerificationPhase.processing:
        headerColor = Colors.blue.shade700;
        headerText = 'Verifying Identity...';
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
              _phase != _VerificationPhase.success &&
              _phase != _VerificationPhase.capturing)
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

    if (_phase == _VerificationPhase.success) {
      return _buildSuccessOverlay();
    }
    if (_phase == _VerificationPhase.processing || _phase == _VerificationPhase.capturing) {
      return _buildProcessingOverlay();
    }
    if (_phase == _VerificationPhase.failed) {
      return _buildFailedOverlay();
    }

    // Camera preview with countdown
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
                color: AppColors.success.withValues(alpha: 0.8),
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
            painter: _CornerGuidePainter(color: Colors.white),
          ),
        ),

        // Countdown overlay
        Center(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
            child: Text(
              '$_countdown',
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
            // Face photo with green tick badge
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 130,
                  height: 130,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.success.withValues(alpha: 0.3),
                      width: 4,
                    ),
                  ),
                ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack),
                if (_lastPhotoPath != null)
                  Container(
                    width: 110,
                    height: 110,
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
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.success, width: 3),
                      color: AppColors.success.withValues(alpha: 0.15),
                    ),
                    child: const Icon(Icons.person, color: AppColors.success, size: 56),
                  ).animate().scale(duration: 500.ms, curve: Curves.easeOutBack),
                Positioned(
                  bottom: 4,
                  right: 4,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.black, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.success.withValues(alpha: 0.5),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.check, color: Colors.white, size: 22),
                  ).animate(delay: 400.ms).scale(
                        duration: 400.ms,
                        curve: Curves.easeOutBack,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (_matchedEmployeeName != null)
              Text(
                _capitalize(_matchedEmployeeName!),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2, end: 0)
            else
              const Text(
                'Verified!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ).animate().fadeIn(delay: 300.ms),
            const SizedBox(height: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.verified, color: AppColors.success, size: 18),
                const SizedBox(width: 6),
                Text(
                  _matchedConfidence > 0
                      ? 'Identity Verified  -  ${(_matchedConfidence * 100).toStringAsFixed(1)}%'
                      : 'Identity Verified',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 14,
                  ),
                ),
              ],
            ).animate().fadeIn(delay: 500.ms),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.success.withValues(alpha: 0.4),
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle, color: AppColors.success, size: 16),
                  SizedBox(width: 6),
                  Text(
                    'Attendance Marked: PRESENT',
                    style: TextStyle(
                      color: AppColors.success,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 650.ms).slideY(begin: 0.3, end: 0),
          ],
        ),
      ),
    );
  }

  Widget _buildProcessingOverlay() {
    return Container(
      color: Colors.black,
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 60,
              height: 60,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation(Colors.blue),
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Verifying identity...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Please wait',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFailedOverlay() {
    _vibrateError();
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
                  color: AppColors.error.withValues(alpha: 0.2),
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
      case _VerificationPhase.countdown:
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
          child: Text(
            'Position your face within the frame',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600], fontSize: 13),
          ),
        );

      case _VerificationPhase.capturing:
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
      ..color = color.withValues(alpha: 0.6)
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

/// Show face verification dialog.
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

import 'dart:convert';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme_extensions.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/dynamic_island_notification.dart';
import '../../../core/network/api_client.dart';

class AddEmployeeScreen extends ConsumerStatefulWidget {
  const AddEmployeeScreen({super.key});

  @override
  ConsumerState<AddEmployeeScreen> createState() => _AddEmployeeScreenState();
}

class _AddEmployeeScreenState extends ConsumerState<AddEmployeeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _employeeIdController = TextEditingController();

  String? _capturedPhotoPath;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _employeeIdController.dispose();
    super.dispose();
  }

  Future<void> _capturePhoto() async {
    try {
      final cameras = await availableCameras();
      final frontCamera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      final controller = CameraController(frontCamera, ResolutionPreset.medium);
      await controller.initialize();

      if (!mounted) {
        await controller.dispose();
        return;
      }

      final result = await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => _FaceCaptureDialog(controller: controller),
      );

      await controller.dispose();

      if (result != null && mounted) {
        setState(() => _capturedPhotoPath = result);
      }
    } catch (e) {
      if (mounted) {
        DynamicIslandManager().show(context, message: 'Camera error: $e');
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_capturedPhotoPath == null) {
      DynamicIslandManager().show(context, message: 'Please capture employee face photo');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final apiClient = ref.read(apiClientProvider);

      // Read captured face photo and encode as base64
      final photoBytes = await File(_capturedPhotoPath!).readAsBytes();
      final photoBase64 = base64Encode(photoBytes);

      await apiClient.post('/users', data: {
        'firstName': _firstNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'password': 'Welcome@123', // Default password for new employee
        'role': 'EMPLOYEE',
        'designation': _employeeIdController.text.trim(),
        'facePhoto': photoBase64,
      });

      if (mounted) {
        DynamicIslandManager().show(context, message: 'Employee added successfully');
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        DynamicIslandManager().show(context, message: 'Failed to add employee');
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        title: Text(
          'Add Employee',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: context.textPrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Face Photo Capture
              Center(
                child: GestureDetector(
                  onTap: _capturePhoto,
                  child: Column(
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: context.isDark
                              ? AppColors.grey800
                              : AppColors.grey100,
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.5),
                            width: 2,
                          ),
                          image: _capturedPhotoPath != null
                              ? DecorationImage(
                                  image: FileImage(File(_capturedPhotoPath!)),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: _capturedPhotoPath == null
                            ? Icon(
                                Icons.camera_alt,
                                size: 40,
                                color: context.textTertiary,
                              )
                            : null,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _capturedPhotoPath == null
                            ? 'Tap to capture face'
                            : 'Tap to retake',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // Form Fields
              _buildTextField(
                controller: _firstNameController,
                label: 'First Name',
                icon: Icons.person_outline,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _lastNameController,
                label: 'Last Name',
                icon: Icons.person_outline,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _emailController,
                label: 'Email',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Required';
                  if (!v.contains('@')) return 'Invalid email';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _phoneController,
                label: 'Mobile Number',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _employeeIdController,
                label: 'Employee ID',
                icon: Icons.badge_outlined,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 32),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    disabledBackgroundColor:
                        AppColors.primary.withValues(alpha: 0.5),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Add Employee',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return GlassCard(
      blur: 10,
      opacity: 0.1,
      borderRadius: 12,
      padding: EdgeInsets.zero,
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: validator,
        style: GoogleFonts.poppins(
          color: context.textPrimary,
          fontSize: 14,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.poppins(
            color: context.textSecondary,
            fontSize: 14,
          ),
          prefixIcon: Icon(icon, color: context.textTertiary, size: 20),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.transparent,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          errorStyle: GoogleFonts.poppins(fontSize: 11),
        ),
      ),
    );
  }
}

/// Dialog to capture employee face photo
class _FaceCaptureDialog extends StatelessWidget {
  final CameraController controller;

  const _FaceCaptureDialog({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.black,
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.6,
          child: Stack(
            children: [
              // Camera preview
              Positioned.fill(child: CameraPreview(controller)),

              // Face oval guide
              Center(
                child: Container(
                  width: 200,
                  height: 260,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white54, width: 2),
                    borderRadius: BorderRadius.circular(120),
                  ),
                ),
              ),

              // Instructions
              Positioned(
                top: 20,
                left: 0,
                right: 0,
                child: Text(
                  'Position face within the oval',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              // Capture button
              Positioned(
                bottom: 20,
                left: 0,
                right: 0,
                child: Center(
                  child: GestureDetector(
                    onTap: () async {
                      try {
                        final file = await controller.takePicture();
                        if (context.mounted) {
                          Navigator.of(context).pop(file.path);
                        }
                      } catch (e) {
                        if (context.mounted) {
                          Navigator.of(context).pop();
                        }
                      }
                    },
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                      ),
                      child: Container(
                        margin: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Close button
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 28),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

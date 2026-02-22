import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme_extensions.dart';
import '../../../core/responsive.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/dynamic_island_notification.dart';
import '../providers/claim_provider.dart';

class CreateClaimScreen extends ConsumerStatefulWidget {
  const CreateClaimScreen({super.key});

  @override
  ConsumerState<CreateClaimScreen> createState() => _CreateClaimScreenState();
}

class _CreateClaimScreenState extends ConsumerState<CreateClaimScreen> {
  final _amountController = TextEditingController();
  final _reasonController = TextEditingController();
  String _claimType = 'Travel';
  final _formKey = GlobalKey<FormState>();

  // File upload state
  File? _selectedFile;
  String? _selectedFileName;
  bool _isImage = false;

  final ImagePicker _imagePicker = ImagePicker();

  @override
  void dispose() {
    _amountController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedFile = File(image.path);
          _selectedFileName = image.name;
          _isImage = true;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _pickPDF() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.path != null) {
          setState(() {
            _selectedFile = File(file.path!);
            _selectedFileName = file.name;
            _isImage = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick PDF: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Attach Bill/Receipt',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Choose how to add your receipt',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppColors.grey600,
              ),
            ),
            const SizedBox(height: 24),
            _buildAttachmentOption(
              icon: Icons.camera_alt,
              title: 'Take Photo',
              subtitle: 'Capture receipt using camera',
              color: AppColors.primary,
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            const SizedBox(height: 12),
            _buildAttachmentOption(
              icon: Icons.photo_library,
              title: 'Choose from Gallery',
              subtitle: 'Select image from your photos',
              color: AppColors.success,
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            const SizedBox(height: 12),
            _buildAttachmentOption(
              icon: Icons.picture_as_pdf,
              title: 'Upload PDF',
              subtitle: 'Select PDF document',
              color: AppColors.error,
              onTap: () {
                Navigator.pop(context);
                _pickPDF();
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppColors.grey600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.grey400),
          ],
        ),
      ),
    );
  }

  void _removeFile() {
    setState(() {
      _selectedFile = null;
      _selectedFileName = null;
      _isImage = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    Responsive.init(context);
    ref.listen(createClaimProvider, (previous, next) {
      if (next.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${next.error}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    });

    final isLoading = ref.watch(createClaimProvider).isLoading;

    return SafeScaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AdaptiveAppBar(
        title: 'Submit Expense',
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(Responsive.horizontalPadding),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Main Form Card
                GlassCard(
                  blur: 12,
                  opacity: 0.15,
                  borderRadius: 16,
                  padding: EdgeInsets.all(Responsive.value(mobile: 16.0, tablet: 24.0)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Claim Type
                      Text(
                        'Expense Type',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: Responsive.sp(14),
                          color: AppColors.grey700,
                        ),
                      ),
                      SizedBox(height: Responsive.value(mobile: 8.0, tablet: 12.0)),
                      DropdownButtonFormField<String>(
                        value: _claimType,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: AppColors.grey50,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                        items: ['Travel', 'Medical', 'Food', 'Stationery', 'Accommodation', 'Other']
                            .map((e) => DropdownMenuItem(
                                  value: e,
                                  child: Text(e, style: GoogleFonts.poppins()),
                                ))
                            .toList(),
                        onChanged: (val) => setState(() => _claimType = val!),
                      ),
                      SizedBox(height: Responsive.value(mobile: 20.0, tablet: 28.0)),

                      // Amount
                      Text(
                        'Amount',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: Responsive.sp(14),
                          color: AppColors.grey700,
                        ),
                      ),
                      SizedBox(height: Responsive.value(mobile: 8.0, tablet: 12.0)),
                      TextFormField(
                        controller: _amountController,
                        keyboardType: TextInputType.number,
                        style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
                        decoration: InputDecoration(
                          prefixText: '\u{20B9} ',
                          prefixStyle: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.grey800,
                          ),
                          hintText: '0.00',
                          filled: true,
                          fillColor: AppColors.grey50,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                        validator: (v) => (v == null || v.isEmpty) ? 'Amount is required' : null,
                      ),
                      SizedBox(height: Responsive.value(mobile: 20.0, tablet: 28.0)),

                      // Description (Required)
                      Row(
                        children: [
                          Text(
                            'Notes / Instructions',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: Responsive.sp(14),
                              color: AppColors.grey700,
                            ),
                          ),
                          SizedBox(width: Responsive.value(mobile: 4.0, tablet: 6.0)),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: Responsive.value(mobile: 6.0, tablet: 8.0),
                              vertical: Responsive.value(mobile: 2.0, tablet: 4.0),
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.error.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Required',
                              style: GoogleFonts.poppins(
                                fontSize: Responsive.sp(10),
                                fontWeight: FontWeight.w600,
                                color: AppColors.error,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: Responsive.value(mobile: 8.0, tablet: 12.0)),
                      TextFormField(
                        controller: _reasonController,
                        maxLines: 4,
                        style: GoogleFonts.poppins(fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Enter details about this expense...',
                          hintStyle: GoogleFonts.poppins(color: AppColors.grey400),
                          filled: true,
                          fillColor: AppColors.grey50,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.all(16),
                        ),
                        validator: (v) => (v == null || v.isEmpty) ? 'Notes/Instructions are required' : null,
                      ),
                    ],
                  ),
                ),

                SizedBox(height: Responsive.horizontalPadding),

                // Attachment Section (Required)
                GlassCard(
                  blur: 12,
                  opacity: 0.15,
                  borderRadius: 16,
                  padding: EdgeInsets.all(Responsive.value(mobile: 16.0, tablet: 24.0)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Bill / Receipt',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: Responsive.sp(14),
                              color: AppColors.grey700,
                            ),
                          ),
                          SizedBox(width: Responsive.value(mobile: 4.0, tablet: 6.0)),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: Responsive.value(mobile: 6.0, tablet: 8.0),
                              vertical: Responsive.value(mobile: 2.0, tablet: 4.0),
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.error.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Required',
                              style: GoogleFonts.poppins(
                                fontSize: Responsive.sp(10),
                                fontWeight: FontWeight.w600,
                                color: AppColors.error,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: Responsive.value(mobile: 4.0, tablet: 6.0)),
                      Text(
                        'Upload a photo or PDF of your bill/receipt',
                        style: GoogleFonts.poppins(
                          fontSize: Responsive.sp(12),
                          color: AppColors.grey500,
                        ),
                      ),
                      SizedBox(height: Responsive.horizontalPadding),

                      // File Preview or Upload Button
                      if (_selectedFile != null) ...[
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.grey50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.success.withOpacity(0.3)),
                          ),
                          child: Column(
                            children: [
                              // Preview
                              if (_isImage)
                                ClipRRect(
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                                  child: Image.file(
                                    _selectedFile!,
                                    height: 200,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              else
                                Container(
                                  height: 120,
                                  decoration: BoxDecoration(
                                    color: AppColors.error.withOpacity(0.1),
                                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                                  ),
                                  child: Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          Icons.picture_as_pdf,
                                          size: 48,
                                          color: AppColors.error,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'PDF Document',
                                          style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.w500,
                                            color: AppColors.error,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                              // File Info & Actions
                              Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  children: [
                                    Icon(
                                      _isImage ? Icons.image : Icons.picture_as_pdf,
                                      color: _isImage ? AppColors.success : AppColors.error,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _selectedFileName ?? 'File',
                                        style: GoogleFonts.poppins(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: _showAttachmentOptions,
                                      icon: const Icon(Icons.edit, size: 20),
                                      color: AppColors.primary,
                                      tooltip: 'Change file',
                                    ),
                                    IconButton(
                                      onPressed: _removeFile,
                                      icon: const Icon(Icons.delete, size: 20),
                                      color: AppColors.error,
                                      tooltip: 'Remove file',
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ] else ...[
                        // Upload Area
                        InkWell(
                          onTap: _showAttachmentOptions,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 32),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.primary.withOpacity(0.3),
                                style: BorderStyle.solid,
                              ),
                            ),
                            child: Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.cloud_upload_outlined,
                                    size: 32,
                                    color: AppColors.primary,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Tap to upload',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Photo or PDF (Max 10MB)',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: AppColors.grey500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                SizedBox(height: Responsive.value(mobile: 24.0, tablet: 32.0)),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: Responsive.value(mobile: 52.0, tablet: 60.0),
                  child: FilledButton(
                    onPressed: isLoading
                        ? null
                        : () async {
                            // Validate file upload
                            if (_selectedFile == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Please upload a bill/receipt',
                                    style: GoogleFonts.poppins(),
                                  ),
                                  backgroundColor: AppColors.error,
                                ),
                              );
                              return;
                            }

                            if (_formKey.currentState?.validate() ?? false) {
                              await ref.read(createClaimProvider.notifier).createClaim({
                                'type': _claimType.toUpperCase(),
                                'amount': _amountController.text.trim(),
                                'description': _reasonController.text.trim(),
                                'attachmentPath': _selectedFile!.path,
                                'attachmentName': _selectedFileName,
                              });

                              if (context.mounted && !ref.read(createClaimProvider).hasError) {
                                DynamicIslandManager().show(context, message: 'Expense claim submitted');
                                context.pop();
                              }
                            }
                          },
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(Responsive.cardRadius),
                      ),
                    ),
                    child: isLoading
                        ? SizedBox(
                            height: Responsive.sp(24),
                            width: Responsive.sp(24),
                            child: const CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            'Submit Expense',
                            style: GoogleFonts.poppins(
                              fontSize: Responsive.sp(15),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),

                SizedBox(height: Responsive.value(mobile: 32.0, tablet: 40.0)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

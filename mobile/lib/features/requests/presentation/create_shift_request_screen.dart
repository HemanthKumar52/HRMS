import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme_extensions.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/dynamic_island_notification.dart';
import '../../../core/widgets/safe_scaffold.dart';
import '../providers/request_tracking_provider.dart';

class CreateShiftRequestScreen extends ConsumerStatefulWidget {
  const CreateShiftRequestScreen({super.key});

  @override
  ConsumerState<CreateShiftRequestScreen> createState() =>
      _CreateShiftRequestScreenState();
}

class _CreateShiftRequestScreenState
    extends ConsumerState<CreateShiftRequestScreen> {
  final _titleController = TextEditingController();
  final _reasonController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String _fromShift = 'Morning (9 AM - 6 PM)';
  String _toShift = 'Evening (2 PM - 11 PM)';
  DateTime _requestDate = DateTime.now();
  bool _isSubmitting = false;

  static const _shiftOptions = [
    'Morning (9 AM - 6 PM)',
    'Afternoon (12 PM - 9 PM)',
    'Evening (2 PM - 11 PM)',
    'Night (10 PM - 7 AM)',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _requestDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (picked != null) {
      setState(() => _requestDate = picked);
    }
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_fromShift == _toShift) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('From and To shifts must be different'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final dio = ref.read(dioProvider);
      await dio.post(ApiConstants.shiftRequests, data: {
        'title': _titleController.text.trim(),
        'fromShift': _fromShift,
        'toShift': _toShift,
        'requestDate': _requestDate.toIso8601String(),
        'reason': _reasonController.text.trim().isNotEmpty
            ? _reasonController.text.trim()
            : null,
      });

      ref.invalidate(userShiftRequestsProvider);

      if (mounted) {
        DynamicIslandManager()
            .show(context, message: 'Shift request submitted');
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeScaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AdaptiveAppBar(
        title: 'Request Shift Change',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GlassCard(
                blur: 12,
                opacity: 0.15,
                borderRadius: 12,
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Title
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Title',
                        hintText: 'e.g., Shift swap with Rahul',
                        border: OutlineInputBorder(),
                      ),
                      style: GoogleFonts.poppins(),
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Title is required' : null,
                    ),
                    const SizedBox(height: 16),

                    // Date picker
                    InkWell(
                      onTap: _pickDate,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Request Date',
                          border: OutlineInputBorder(),
                          suffixIcon: Icon(Icons.calendar_today),
                        ),
                        child: Text(
                          DateFormat('dd MMM yyyy').format(_requestDate),
                          style: GoogleFonts.poppins(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // From shift
                    DropdownButtonFormField<String>(
                      initialValue: _fromShift,
                      decoration: const InputDecoration(
                        labelText: 'Current Shift',
                        border: OutlineInputBorder(),
                      ),
                      items: _shiftOptions
                          .map((e) => DropdownMenuItem(
                                value: e,
                                child: Text(e, style: GoogleFonts.poppins(fontSize: 14)),
                              ))
                          .toList(),
                      onChanged: (val) => setState(() => _fromShift = val!),
                    ),
                    const SizedBox(height: 16),

                    // To shift
                    DropdownButtonFormField<String>(
                      initialValue: _toShift,
                      decoration: const InputDecoration(
                        labelText: 'Requested Shift',
                        border: OutlineInputBorder(),
                      ),
                      items: _shiftOptions
                          .map((e) => DropdownMenuItem(
                                value: e,
                                child: Text(e, style: GoogleFonts.poppins(fontSize: 14)),
                              ))
                          .toList(),
                      onChanged: (val) => setState(() => _toShift = val!),
                    ),
                    const SizedBox(height: 16),

                    // Reason
                    TextFormField(
                      controller: _reasonController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Reason (optional)',
                        hintText: 'Why do you need this shift change?',
                        border: OutlineInputBorder(),
                      ),
                      style: GoogleFonts.poppins(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton(
                  onPressed: _isSubmitting ? null : _submit,
                  style: FilledButton.styleFrom(backgroundColor: Colors.orange),
                  child: _isSubmitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          'Submit Request',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }
}

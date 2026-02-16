import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/responsive.dart';
import '../../../core/utils/extensions.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/leave_model.dart';
import '../providers/leave_provider.dart';

/// Duration type for leave
enum LeaveDurationType { fullDay, firstHalf, secondHalf }

extension LeaveDurationTypeExtension on LeaveDurationType {
  String get displayName {
    switch (this) {
      case LeaveDurationType.fullDay:
        return 'Full Day';
      case LeaveDurationType.firstHalf:
        return 'First Half';
      case LeaveDurationType.secondHalf:
        return 'Second Half';
    }
  }

  IconData get icon {
    switch (this) {
      case LeaveDurationType.fullDay:
        return Icons.wb_sunny;
      case LeaveDurationType.firstHalf:
        return Icons.wb_twighlight;
      case LeaveDurationType.secondHalf:
        return Icons.nights_stay;
    }
  }
}

String _getLeaveTypeDisplayName(LeaveType type) {
  switch (type) {
    case LeaveType.casual:
      return 'Casual';
    case LeaveType.sick:
      return 'Sick';
    case LeaveType.earned:
      return 'Earned';
    case LeaveType.unpaid:
      return 'Unpaid';
    case LeaveType.parental:
      return 'Parental';
    case LeaveType.od:
      return 'On Duty (OD)';
    case LeaveType.compensatory:
      return 'Compensatory';
  }
}

class ApplyLeaveScreen extends ConsumerStatefulWidget {
  const ApplyLeaveScreen({super.key});

  @override
  ConsumerState<ApplyLeaveScreen> createState() => _ApplyLeaveScreenState();
}

class _ApplyLeaveScreenState extends ConsumerState<ApplyLeaveScreen> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();

  LeaveType _selectedType = LeaveType.casual;
  DateTime _fromDate = DateTime.now();
  DateTime _toDate = DateTime.now();
  LeaveDurationType _durationType = LeaveDurationType.fullDay;
  bool _isLoading = false;
  bool _isSingleDay = true;
  bool _isSubmitted = false;
  String? _submittedLeaveId;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  bool get _isHalfDay => _durationType != LeaveDurationType.fullDay;

  HalfDayType? get _halfDayType {
    switch (_durationType) {
      case LeaveDurationType.firstHalf:
        return HalfDayType.firstHalf;
      case LeaveDurationType.secondHalf:
        return HalfDayType.secondHalf;
      case LeaveDurationType.fullDay:
        return null;
    }
  }

  bool get _showSingleDatePicker => _isHalfDay || _isSingleDay;

  Future<void> _selectDate(BuildContext context, bool isFromDate) async {
    final initialDate = isFromDate ? _fromDate : _toDate;
    final firstDate = isFromDate ? DateTime.now() : _fromDate;

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppColors.grey800,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isFromDate) {
          _fromDate = picked;
          if (_showSingleDatePicker) {
            _toDate = _fromDate;
          } else if (_toDate.isBefore(_fromDate)) {
            _toDate = _fromDate;
          }
        } else {
          _toDate = picked;
        }
      });
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final leave = await ref.read(applyLeaveProvider.notifier).applyLeave(
            type: _selectedType,
            fromDate: _fromDate,
            toDate: _showSingleDatePicker ? _fromDate : _toDate,
            isHalfDay: _isHalfDay,
            halfDayType: _halfDayType,
            reason: _reasonController.text.trim(),
          );

      if (mounted) {
        ref.invalidate(leaveHistoryProvider);
        ref.invalidate(leaveBalanceProvider);
        setState(() {
          _isSubmitted = true;
          _submittedLeaveId = leave.id;
        });
        context.showSnackBar('Leave request submitted successfully!');
      }
    } catch (e) {
      if (mounted) {
        String message = 'Failed to submit leave request';
        if (e is DioException) {
          message = e.response?.data?['message'] ?? message;
        }
        context.showSnackBar(message, isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Responsive.init(context);
    final user = ref.watch(currentUserProvider);

    return SafeScaffold(
      backgroundColor: AppColors.grey50,
      appBar: AdaptiveAppBar(
        title: 'Apply Leave',
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: IgnorePointer(
            ignoring: _isSubmitted,
            child: Opacity(
              opacity: _isSubmitted ? 0.6 : 1.0,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // User Info Card
                  Container(
                    width: double.infinity,
                    margin: EdgeInsets.all(Responsive.horizontalPadding),
                    padding: EdgeInsets.all(Responsive.horizontalPadding),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(Responsive.cardRadius),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: Responsive.value(mobile: 26.0, tablet: 32.0),
                          backgroundColor: Colors.white.withOpacity(0.2),
                          child: Text(
                            user?.initials ?? 'U',
                            style: GoogleFonts.poppins(
                              fontSize: Responsive.sp(18),
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        SizedBox(width: Responsive.horizontalPadding),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user?.fullName ?? 'Employee',
                                style: GoogleFonts.poppins(
                                  fontSize: Responsive.sp(16),
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: Responsive.value(mobile: 2.0, tablet: 4.0)),
                              Text(
                                user?.email ?? '',
                                style: GoogleFonts.poppins(
                                  fontSize: Responsive.sp(12),
                                  color: Colors.white.withOpacity(0.9),
                                ),
                              ),
                              if (user?.designation != null || user?.department != null)
                                Text(
                                  '${user?.designation ?? ''} ${user?.department != null ? '| ${user!.department}' : ''}',
                                  style: GoogleFonts.poppins(
                                    fontSize: Responsive.sp(11),
                                    color: Colors.white.withOpacity(0.8),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Leave Type Section
                  _buildSectionCard(
                    title: 'Leave Type',
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: LeaveType.values.map((type) {
                        final isSelected = type == _selectedType;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedType = type),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.primary : Colors.white,
                              borderRadius: BorderRadius.circular(25),
                              border: Border.all(
                                color: isSelected ? AppColors.primary : AppColors.grey300,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: AppColors.primary.withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      )
                                    ]
                                  : null,
                            ),
                            child: Text(
                              _getLeaveTypeDisplayName(type),
                              style: GoogleFonts.poppins(
                                color: isSelected ? Colors.white : AppColors.grey700,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  // Duration Type Section
                  _buildSectionCard(
                    title: 'Duration Type',
                    child: Row(
                      children: LeaveDurationType.values.map((type) {
                        final isSelected = type == _durationType;
                        return Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _durationType = type;
                                if (type != LeaveDurationType.fullDay) {
                                  _toDate = _fromDate;
                                  _isSingleDay = true;
                                }
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: EdgeInsets.only(
                                right: type != LeaveDurationType.secondHalf ? 8 : 0,
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.primary.withOpacity(0.1)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected ? AppColors.primary : AppColors.grey300,
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    type.icon,
                                    color: isSelected ? AppColors.primary : AppColors.grey500,
                                    size: 24,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    type.displayName,
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                      color: isSelected ? AppColors.primary : AppColors.grey700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  // Date Selection Section
                  _buildSectionCard(
                    title: 'Select Date${!_showSingleDatePicker ? 's' : ''}',
                    child: Column(
                      children: [
                        // Single Day / Multiple Days toggle (only for Full Day)
                        if (!_isHalfDay) ...[
                          Row(
                            children: [
                              _buildDayToggle('Single Day', true),
                              const SizedBox(width: 8),
                              _buildDayToggle('Multiple Days', false),
                            ],
                          ),
                          const SizedBox(height: 12),
                        ],
                        // Date picker(s)
                        if (_showSingleDatePicker)
                          _DatePickerField(
                            label: _isHalfDay ? 'Date' : 'Date',
                            date: _fromDate,
                            onTap: () => _selectDate(context, true),
                          )
                        else
                          Row(
                            children: [
                              Expanded(
                                child: _DatePickerField(
                                  label: 'From Date',
                                  date: _fromDate,
                                  onTap: () => _selectDate(context, true),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _DatePickerField(
                                  label: 'To Date',
                                  date: _toDate,
                                  onTap: () => _selectDate(context, false),
                                ),
                              ),
                            ],
                          ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.info.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.info_outline,
                                color: AppColors.info,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _isHalfDay
                                      ? 'Half day leave (${_durationType.displayName})'
                                      : 'Total: ${_toDate.difference(_fromDate).inDays + 1} day(s)',
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    color: AppColors.info,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Reason Section (Mandatory)
                  _buildSectionCard(
                    title: 'Reason',
                    child: TextFormField(
                      controller: _reasonController,
                      maxLines: 4,
                      style: GoogleFonts.poppins(fontSize: 14),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please provide a reason for your leave';
                        }
                        return null;
                      },
                      decoration: InputDecoration(
                        hintText: 'Enter reason for leave (required)...',
                        hintStyle: GoogleFonts.poppins(color: AppColors.grey400),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.grey300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.grey300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.primary, width: 2),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.error),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.error, width: 2),
                        ),
                      ),
                    ),
                  ),

                  // Approval Info
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: Responsive.horizontalPadding),
                    padding: EdgeInsets.all(Responsive.value(mobile: 12.0, tablet: 16.0)),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(Responsive.cardRadius),
                      border: Border.all(color: AppColors.warning.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.approval, color: AppColors.warning, size: Responsive.sp(20)),
                        SizedBox(width: Responsive.value(mobile: 12.0, tablet: 16.0)),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Approval Required',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                  fontSize: Responsive.sp(13),
                                  color: AppColors.warning,
                                ),
                              ),
                              Text(
                                user?.manager != null
                                    ? 'Your request will be sent to ${user!.manager!.fullName} for approval'
                                    : 'Your request will be sent to your reporting manager for approval',
                                style: GoogleFonts.poppins(
                                  fontSize: Responsive.sp(12),
                                  color: AppColors.grey600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: Responsive.value(mobile: 24.0, tablet: 32.0)),
                ],
              ),
            ),
          ),
        ),
      ),
      // Bottom buttons outside the IgnorePointer
      bottomNavigationBar: Padding(
        padding: EdgeInsets.fromLTRB(
          Responsive.horizontalPadding,
          8,
          Responsive.horizontalPadding,
          Responsive.value(mobile: 32.0, tablet: 40.0),
        ),
        child: _isSubmitted
            ? SizedBox(
                height: Responsive.value(mobile: 52.0, tablet: 60.0),
                child: ElevatedButton.icon(
                  onPressed: () {
                    if (_submittedLeaveId != null) {
                      context.pushNamed('leave-track', pathParameters: {'id': _submittedLeaveId!});
                    }
                  },
                  icon: const Icon(Icons.timeline),
                  label: Text(
                    'Track',
                    style: GoogleFonts.poppins(
                      fontSize: Responsive.sp(15),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF97316),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(Responsive.cardRadius),
                    ),
                    elevation: 4,
                  ),
                ),
              )
            : Row(
                children: [
                  // Cancel Button (Red)
                  Expanded(
                    child: SizedBox(
                      height: Responsive.value(mobile: 52.0, tablet: 60.0),
                      child: OutlinedButton(
                        onPressed: _isLoading ? null : () => context.pop(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                          side: const BorderSide(color: AppColors.error, width: 1.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(Responsive.cardRadius),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.poppins(
                            fontSize: Responsive.sp(15),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Submit Button (Blue)
                  Expanded(
                    flex: 2,
                    child: SizedBox(
                      height: Responsive.value(mobile: 52.0, tablet: 60.0),
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleSubmit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(Responsive.cardRadius),
                          ),
                          elevation: 4,
                        ),
                        child: _isLoading
                            ? SizedBox(
                                height: Responsive.sp(24),
                                width: Responsive.sp(24),
                                child: const CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                'Submit',
                                style: GoogleFonts.poppins(
                                  fontSize: Responsive.sp(15),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildDayToggle(String label, bool isSingle) {
    final isSelected = _isSingleDay == isSingle;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _isSingleDay = isSingle;
            if (isSingle) _toDate = _fromDate;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.grey300,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? AppColors.primary : AppColors.grey600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.fromLTRB(
        Responsive.horizontalPadding,
        0,
        Responsive.horizontalPadding,
        Responsive.horizontalPadding,
      ),
      padding: EdgeInsets.all(Responsive.horizontalPadding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(Responsive.cardRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: Responsive.sp(14),
              fontWeight: FontWeight.w600,
              color: AppColors.grey700,
            ),
          ),
          SizedBox(height: Responsive.value(mobile: 12.0, tablet: 16.0)),
          child,
        ],
      ),
    );
  }
}

class _DatePickerField extends StatelessWidget {
  final String label;
  final DateTime date;
  final VoidCallback onTap;

  const _DatePickerField({
    required this.label,
    required this.date,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Responsive.init(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Responsive.cardRadius),
      child: Container(
        padding: EdgeInsets.all(Responsive.horizontalPadding),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.grey300),
          borderRadius: BorderRadius.circular(Responsive.cardRadius),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: Responsive.sp(11),
                color: AppColors.grey500,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: Responsive.value(mobile: 6.0, tablet: 8.0)),
            Row(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: Responsive.sp(18),
                  color: AppColors.primary,
                ),
                SizedBox(width: Responsive.value(mobile: 8.0, tablet: 12.0)),
                Text(
                  DateFormat('dd MMM, yyyy').format(date),
                  style: GoogleFonts.poppins(
                    fontSize: Responsive.sp(14),
                    fontWeight: FontWeight.w600,
                    color: AppColors.grey800,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

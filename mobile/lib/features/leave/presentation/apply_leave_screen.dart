import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/extensions.dart';
import '../data/leave_model.dart';
import '../providers/leave_provider.dart';

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
  bool _isHalfDay = false;
  HalfDayType _halfDayType = HalfDayType.firstHalf;
  bool _isLoading = false;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isFromDate) async {
    final initialDate = isFromDate ? _fromDate : _toDate;
    final firstDate = isFromDate ? DateTime.now() : _fromDate;

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        if (isFromDate) {
          _fromDate = picked;
          if (_toDate.isBefore(_fromDate)) {
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
      await ref.read(applyLeaveProvider.notifier).applyLeave(
            type: _selectedType,
            fromDate: _fromDate,
            toDate: _isHalfDay ? _fromDate : _toDate,
            isHalfDay: _isHalfDay,
            halfDayType: _isHalfDay ? _halfDayType : null,
            reason: _reasonController.text.trim().isNotEmpty
                ? _reasonController.text.trim()
                : null,
          );

      if (mounted) {
        context.showSnackBar('Leave request submitted successfully');
        ref.invalidate(leaveHistoryProvider);
        ref.invalidate(leaveBalanceProvider);
        context.pop();
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Apply Leave'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Gender (For Leave Eligibility)',
              style: context.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildGenderRadio('Male'),
                const SizedBox(width: 16),
                _buildGenderRadio('Female'),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Leave Type',
              style: context.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: LeaveType.values.where((type) {
                // OD is available for everyone
                if (type == LeaveType.od) return true;
                if (_gender == 'Male' && type == LeaveType.maternity) return false;
                if (_gender == 'Female' && type == LeaveType.paternity) return false;
                return true;
              }).map((type) {
                final isSelected = type == _selectedType;
                return ChoiceChip(
                  label: Text(type == LeaveType.od ? 'On Duty (OD)' : type.toString().split('.').last.capitalize),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _selectedType = type);
                    }
                  },
                  selectedColor: AppColors.primary.withOpacity(0.2),
                  labelStyle: TextStyle(
                    color: isSelected ? AppColors.primary : AppColors.grey700,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            SwitchListTile(
              title: const Text('Half Day'),
              value: _isHalfDay,
              onChanged: (value) {
                setState(() {
                  _isHalfDay = value;
                  if (value) {
                    _toDate = _fromDate;
                  }
                });
              },
              contentPadding: EdgeInsets.zero,
            ),
            if (_isHalfDay) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: HalfDayType.values.map((type) {
                  final isSelected = type == _halfDayType;
                  return ChoiceChip(
                    label: Text(
                      type == HalfDayType.firstHalf
                          ? 'First Half'
                          : 'Second Half',
                    ),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _halfDayType = type);
                      }
                    },
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 24),
            Text(
              'Duration',
              style: context.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _DateField(
                    label: 'From',
                    date: _fromDate,
                    onTap: () => _selectDate(context, true),
                  ),
                ),
                if (!_isHalfDay) ...[
                  const SizedBox(width: 16),
                  Expanded(
                    child: _DateField(
                      label: 'To',
                      date: _toDate,
                      onTap: () => _selectDate(context, false),
                    ),
                  ),
                ],
              ],
            ),
            if (!_isHalfDay) ...[
              const SizedBox(height: 8),
              Text(
                'Total: ${_toDate.difference(_fromDate).inDays + 1} day(s)',
                style: context.textTheme.bodySmall?.copyWith(
                  color: AppColors.grey600,
                ),
              ),
            ],
            const SizedBox(height: 24),
            Text(
              'Reason (Optional)',
              style: context.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _reasonController,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Enter reason for leave...',
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleSubmit,
                child: _isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.white,
                        ),
                      )
                    : const Text('Submit Request'),
              ),
            ),
          ],
        ),
      ),
    );
  }
  String _gender = 'Female'; // Default mock

  Widget _buildGenderRadio(String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Radio<String>(
          value: value,
          groupValue: _gender,
          onChanged: (val) {
            setState(() {
              _gender = val!;
              // Reset type if incompatible
              if (_gender == 'Male' && _selectedType == LeaveType.maternity) _selectedType = LeaveType.casual;
              if (_gender == 'Female' && _selectedType == LeaveType.paternity) _selectedType = LeaveType.casual;
            });
          },
          activeColor: AppColors.primary,
        ),
        Text(value),
      ],
    );
  }
}

class _DateField extends StatelessWidget {
  final String label;
  final DateTime date;
  final VoidCallback onTap;

  const _DateField({
    required this.label,
    required this.date,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.grey300),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: context.textTheme.bodySmall?.copyWith(
                color: AppColors.grey500,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(
                  Icons.calendar_today_outlined,
                  size: 18,
                  color: AppColors.grey600,
                ),
                const SizedBox(width: 8),
                Text(
                  DateFormat('MMM dd, yyyy').format(date),
                  style: context.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
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

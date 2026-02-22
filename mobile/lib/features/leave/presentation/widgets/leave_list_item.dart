import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/extensions.dart';
import '../../data/leave_model.dart';

class LeaveListItem extends StatelessWidget {
  final LeaveModel leave;
  final VoidCallback? onTap;

  const LeaveListItem({super.key, required this.leave, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getTypeColor(leave.type).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          leave.type.toString().split('.').last.capitalize,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _getTypeColor(leave.type),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (leave.isHalfDay)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.grey100,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Half Day',
                            style: context.textTheme.labelSmall?.copyWith(
                              color: AppColors.grey600,
                            ),
                          ),
                        ),
                    ],
                  ),
                  _buildStatusChip(context, leave.status),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today_outlined,
                    size: 16,
                    color: AppColors.grey500,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _formatDateRange(leave.fromDate, leave.toDate),
                    style: context.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '(${leave.leaveDays} ${leave.leaveDays == 1 ? 'day' : 'days'})',
                    style: context.textTheme.bodySmall?.copyWith(
                      color: AppColors.grey500,
                    ),
                  ),
                ],
              ),
              if (leave.reason != null && leave.reason!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  leave.reason!,
                  style: context.textTheme.bodySmall?.copyWith(
                    color: AppColors.grey600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(BuildContext context, LeaveStatus status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _getStatusColor(status).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.toString().split('.').last.capitalize,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: _getStatusColor(status),
        ),
      ),
    );
  }

  String _formatDateRange(DateTime from, DateTime to) {
    if (from.year == to.year && from.month == to.month && from.day == to.day) {
      return from.formatted;
    }
    return '${from.formatted} - ${to.formatted}';
  }

  Color _getTypeColor(LeaveType type) {
    switch (type) {
      case LeaveType.casual:
        return AppColors.primary;
      case LeaveType.sick:
        return AppColors.error;
      case LeaveType.earned:
        return AppColors.success;
      case LeaveType.unpaid:
        return AppColors.warning;
      case LeaveType.parental:
        return Colors.pink;
      case LeaveType.od:
        return Colors.purpleAccent;
      case LeaveType.compensatory:
        return AppColors.secondary;
      case LeaveType.permission:
        return Colors.teal;
    }
  }

  Color _getStatusColor(LeaveStatus status) {
    switch (status) {
      case LeaveStatus.pending:
        return AppColors.pending;
      case LeaveStatus.approved:
        return AppColors.approved;
      case LeaveStatus.rejected:
        return AppColors.rejected;
      case LeaveStatus.cancelled:
        return AppColors.cancelled;
    }
  }
}

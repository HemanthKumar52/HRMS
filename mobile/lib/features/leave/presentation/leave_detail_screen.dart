import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/extensions.dart';
import '../data/leave_model.dart';
import '../providers/leave_provider.dart';

class LeaveDetailScreen extends ConsumerWidget {
  final String leaveId;

  const LeaveDetailScreen({super.key, required this.leaveId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(
      leaveHistoryProvider(const LeaveHistoryParams()),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Leave Details'),
      ),
      body: historyAsync.when(
        data: (leaves) {
          final leave = leaves.where((l) => l.id == leaveId).firstOrNull;
          if (leave == null) {
            return const Center(child: Text('Leave not found'));
          }
          return _buildContent(context, ref, leave);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, LeaveModel leave) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildDetailRow(
                    context,
                    'Status',
                    leave.status.name.capitalize,
                    valueColor: _getStatusColor(leave.status),
                  ),
                  const Divider(height: 24),
                  _buildDetailRow(
                    context,
                    'Type',
                    leave.type.name.capitalize,
                  ),
                  const Divider(height: 24),
                  _buildDetailRow(
                    context,
                    'From',
                    leave.fromDate.formatted,
                  ),
                  const Divider(height: 24),
                  _buildDetailRow(
                    context,
                    'To',
                    leave.toDate.formatted,
                  ),
                  const Divider(height: 24),
                  _buildDetailRow(
                    context,
                    'Duration',
                    '${leave.leaveDays} ${leave.leaveDays == 1 ? 'day' : 'days'}${leave.isHalfDay ? ' (Half Day)' : ''}',
                  ),
                  if (leave.reason != null && leave.reason!.isNotEmpty) ...[
                    const Divider(height: 24),
                    _buildDetailRow(
                      context,
                      'Reason',
                      leave.reason!,
                    ),
                  ],
                  if (leave.rejectReason != null &&
                      leave.rejectReason!.isNotEmpty) ...[
                    const Divider(height: 24),
                    _buildDetailRow(
                      context,
                      'Rejection Reason',
                      leave.rejectReason!,
                      valueColor: AppColors.error,
                    ),
                  ],
                  const Divider(height: 24),
                  _buildDetailRow(
                    context,
                    'Applied On',
                    leave.createdAt.formattedWithTime,
                  ),
                  if (leave.approvedAt != null) ...[
                    const Divider(height: 24),
                    _buildDetailRow(
                      context,
                      'Approved On',
                      leave.approvedAt!.formattedWithTime,
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          if (leave.status == LeaveStatus.pending)
            SizedBox(
              width: double.infinity,
              height: 56,
              child: OutlinedButton(
                onPressed: () => _showCancelDialog(context, ref, leave.id),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error),
                ),
                child: const Text('Cancel Request'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: context.textTheme.bodyMedium?.copyWith(
              color: AppColors.grey500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: context.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
              color: valueColor ?? AppColors.grey900,
            ),
          ),
        ),
      ],
    );
  }

  void _showCancelDialog(BuildContext context, WidgetRef ref, String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Leave Request'),
        content: const Text(
          'Are you sure you want to cancel this leave request?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ref.read(applyLeaveProvider.notifier).cancelLeave(id);
                if (context.mounted) {
                  context.showSnackBar('Leave request cancelled');
                  ref.invalidate(leaveHistoryProvider);
                  ref.invalidate(leaveBalanceProvider);
                  context.pop();
                }
              } catch (e) {
                if (context.mounted) {
                  context.showSnackBar('Failed to cancel leave', isError: true);
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );
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

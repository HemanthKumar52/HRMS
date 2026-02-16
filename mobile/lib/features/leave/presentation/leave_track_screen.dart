import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/responsive.dart';
import '../../../core/utils/extensions.dart';
import '../data/leave_model.dart';
import '../providers/leave_provider.dart';

class LeaveTrackScreen extends ConsumerWidget {
  final String leaveId;

  const LeaveTrackScreen({super.key, required this.leaveId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Responsive.init(context);
    final leaveAsync = ref.watch(leaveDetailProvider(leaveId));

    return SafeScaffold(
      backgroundColor: AppColors.grey50,
      appBar: AdaptiveAppBar(title: 'Track Leave'),
      body: leaveAsync.when(
        data: (leave) => _buildContent(context, leave),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text(
            'Error: $e',
            style: GoogleFonts.poppins(color: AppColors.error),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, LeaveModel leave) {
    final steps = _buildTimelineSteps(leave);

    return SingleChildScrollView(
      padding: EdgeInsets.all(Responsive.horizontalPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Leave summary card
          _buildLeaveSummaryCard(context, leave),
          SizedBox(height: Responsive.value(mobile: 24.0, tablet: 32.0)),

          Text(
            'Request Timeline',
            style: GoogleFonts.poppins(
              fontSize: Responsive.sp(16),
              fontWeight: FontWeight.w600,
              color: AppColors.grey800,
            ),
          ),
          SizedBox(height: Responsive.value(mobile: 16.0, tablet: 20.0)),

          // Timeline
          ...steps.asMap().entries.map((entry) {
            final index = entry.key;
            final step = entry.value;
            return _buildTimelineItem(
              title: step.title,
              subtitle: step.subtitle,
              date: step.date,
              color: step.color,
              isCompleted: step.isCompleted,
              isActive: step.isActive,
              isLast: index == steps.length - 1,
            );
          }),

          SizedBox(height: Responsive.value(mobile: 32.0, tablet: 40.0)),
        ],
      ),
    );
  }

  Widget _buildLeaveSummaryCard(BuildContext context, LeaveModel leave) {
    return Container(
      width: double.infinity,
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Leave type badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getTypeColor(leave.type).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _getLeaveTypeDisplayName(leave.type),
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _getTypeColor(leave.type),
                  ),
                ),
              ),
              // Status badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getStatusColor(leave.status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  leave.status.name.capitalize,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _getStatusColor(leave.status),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Dates
          Row(
            children: [
              const Icon(Icons.calendar_today_outlined, size: 16, color: AppColors.grey500),
              const SizedBox(width: 8),
              Text(
                _formatDateRange(leave.fromDate, leave.toDate),
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.grey800,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '(${leave.leaveDays} ${leave.leaveDays == 1 ? 'day' : 'days'})',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: AppColors.grey500,
                ),
              ),
            ],
          ),
          if (leave.reason != null && leave.reason!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              leave.reason!,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: AppColors.grey600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  List<_TimelineStep> _buildTimelineSteps(LeaveModel leave) {
    final steps = <_TimelineStep>[];

    // Step 1: Applied (always completed)
    steps.add(_TimelineStep(
      title: 'Applied',
      subtitle: '${_getLeaveTypeDisplayName(leave.type)} leave request submitted',
      date: DateFormat('dd MMM yyyy, hh:mm a').format(leave.createdAt),
      color: AppColors.approved,
      isCompleted: true,
      isActive: false,
    ));

    // Steps based on current status
    if (leave.status == LeaveStatus.pending) {
      steps.add(_TimelineStep(
        title: 'Pending Review',
        subtitle: 'Awaiting manager approval',
        date: null,
        color: AppColors.pending,
        isCompleted: false,
        isActive: true,
      ));
      steps.add(_TimelineStep(
        title: 'Decision',
        subtitle: 'Approval or rejection pending',
        date: null,
        color: AppColors.grey300,
        isCompleted: false,
        isActive: false,
      ));
    } else if (leave.status == LeaveStatus.approved) {
      steps.add(_TimelineStep(
        title: 'Reviewed',
        subtitle: 'Manager reviewed your request',
        date: null,
        color: AppColors.approved,
        isCompleted: true,
        isActive: false,
      ));
      steps.add(_TimelineStep(
        title: 'Approved',
        subtitle: 'Your leave has been approved',
        date: leave.approvedAt != null
            ? DateFormat('dd MMM yyyy, hh:mm a').format(leave.approvedAt!)
            : null,
        color: AppColors.approved,
        isCompleted: true,
        isActive: true,
      ));
    } else if (leave.status == LeaveStatus.rejected) {
      steps.add(_TimelineStep(
        title: 'Reviewed',
        subtitle: 'Manager reviewed your request',
        date: null,
        color: AppColors.approved,
        isCompleted: true,
        isActive: false,
      ));
      steps.add(_TimelineStep(
        title: 'Rejected',
        subtitle: leave.rejectReason ?? 'Your leave request was rejected',
        date: null,
        color: AppColors.rejected,
        isCompleted: true,
        isActive: true,
      ));
    } else if (leave.status == LeaveStatus.cancelled) {
      steps.add(_TimelineStep(
        title: 'Cancelled',
        subtitle: 'You cancelled this request',
        date: null,
        color: AppColors.cancelled,
        isCompleted: true,
        isActive: true,
      ));
    }

    return steps;
  }

  Widget _buildTimelineItem({
    required String title,
    required String subtitle,
    String? date,
    required Color color,
    required bool isCompleted,
    required bool isActive,
    required bool isLast,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Dot + Line column
          SizedBox(
            width: 24,
            child: Column(
              children: [
                Container(
                  width: isActive ? 20 : 16,
                  height: isActive ? 20 : 16,
                  decoration: BoxDecoration(
                    color: isCompleted || isActive ? color : Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(color: color, width: 2.5),
                    boxShadow: isActive
                        ? [
                            BoxShadow(
                              color: color.withOpacity(0.3),
                              blurRadius: 6,
                              spreadRadius: 1,
                            ),
                          ]
                        : null,
                  ),
                  child: isCompleted
                      ? Icon(Icons.check, size: isActive ? 12 : 10, color: Colors.white)
                      : null,
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: isCompleted ? color : AppColors.grey300,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: isActive
                          ? color
                          : (isCompleted ? AppColors.grey800 : AppColors.grey400),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: AppColors.grey500,
                    ),
                  ),
                  if (date != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      date,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: AppColors.grey400,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateRange(DateTime from, DateTime to) {
    final f = DateFormat('dd MMM, yyyy');
    if (from.year == to.year && from.month == to.month && from.day == to.day) {
      return f.format(from);
    }
    return '${f.format(from)} - ${f.format(to)}';
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

class _TimelineStep {
  final String title;
  final String subtitle;
  final String? date;
  final Color color;
  final bool isCompleted;
  final bool isActive;

  _TimelineStep({
    required this.title,
    required this.subtitle,
    this.date,
    required this.color,
    required this.isCompleted,
    required this.isActive,
  });
}

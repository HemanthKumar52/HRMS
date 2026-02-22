import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_theme_extensions.dart';
import '../../../../../core/widgets/glass_card.dart';
import '../../../../auth/providers/auth_provider.dart';
import '../../../../attendance/providers/attendance_provider.dart';
import '../../../../leave/providers/leave_provider.dart';
import '../../../../notifications/providers/notification_provider.dart';
import '../dashboard/attendance_timer_card.dart';
import '../dashboard/leave_details_card.dart';
import '../dashboard/dashboard_stats_grid.dart';
import '../dashboard/announcements_card.dart';
import '../dashboard/timesheet_card.dart';
import '../../../providers/timesheet_provider.dart';

class EmployeeDashboard extends ConsumerWidget {
  const EmployeeDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final todayStatusAsync = ref.watch(todayStatusProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(todayStatusProvider);
        ref.invalidate(leaveBalanceProvider);
        ref.invalidate(notificationsProvider);
        ref.invalidate(currentTimesheetProvider);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          16,
          MediaQuery.of(context).padding.top + kToolbarHeight + 16,
          16,
          16,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Banner
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: AppColors.primary, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Welcome Back, ${user?.firstName ?? 'Employee'}! You have pending approvals.',
                      style: GoogleFonts.poppins(
                        color: context.isDark ? AppColors.primaryLight : AppColors.primaryDark,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn().slideX(),

            // Announcements
            const AnnouncementsCard(),
            const SizedBox(height: 16),

            // Leave Details
            const LeaveDetailsCard().animate().fadeIn(delay: 100.ms).slideY(begin: 0.1),
            const SizedBox(height: 16),

            // Attendance Timer
            todayStatusAsync.when(
              data: (status) => AttendanceTimerCard(
                isClockedIn: status.isClockedIn,
                clockInTime: status.clockInTime != null
                    ? '${status.clockInTime!.hour.toString().padLeft(2, '0')}:${status.clockInTime!.minute.toString().padLeft(2, '0')}'
                    : null,
                clockOutTime: status.clockOutTime != null
                    ? '${status.clockOutTime!.hour.toString().padLeft(2, '0')}:${status.clockOutTime!.minute.toString().padLeft(2, '0')}'
                    : null,
                totalHours: status.totalHours,
                clockInDateTime: status.clockInTime,
                onPunch: () => context.go('/attendance'),
              ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),
              loading: () => const Center(child: CircularProgressIndicator()).animate().fadeIn(delay: 200.ms),
              error: (e, _) => AttendanceTimerCard(
                isClockedIn: false,
                clockInTime: null,
                clockOutTime: null,
                totalHours: '0h 0m',
                onPunch: () => context.go('/attendance'),
              ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),
            ),

            const SizedBox(height: 16),

            // Weekly Timesheet
            const TimesheetCard().animate().fadeIn(delay: 250.ms).slideY(begin: 0.1),

            const SizedBox(height: 20),

            // Statistics
            Text(
              'Statistics',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: context.textPrimary,
              ),
            ).animate().fadeIn(delay: 300.ms),
            const SizedBox(height: 12),
            const DashboardStatsGrid().animate().fadeIn(delay: 300.ms).slideY(begin: 0.1),

            const SizedBox(height: 20),

            // View Profile Button
            GlassCard(
              blur: 12,
              opacity: 0.15,
              borderRadius: 12,
              padding: const EdgeInsets.all(16),
              onTap: () => context.push('/profile'),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.person_outline, color: AppColors.primary),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('My Profile', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16, color: context.textPrimary)),
                        Text('View skills, performance & details', style: GoogleFonts.poppins(color: context.textSecondary, fontSize: 12)),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: context.textTertiary),
                ],
              ),
            ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1),

            const SizedBox(height: 20),

            // Recent Activities
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Activities',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: context.textPrimary,
                  ),
                ),
                TextButton(
                  onPressed: () => context.go('/notifications'),
                  child: const Text('View All'),
                ),
              ],
            ).animate().fadeIn(delay: 500.ms),
            const SizedBox(height: 8),
            Column(
              children: [
                _buildNotificationItem(context, 'Leave Approved', 'Your leave for 25 Oct was approved', false),
                _buildNotificationItem(context, 'New Policy Update', 'Please review the updated HR policy', true),
              ],
            ).animate().fadeIn(delay: 550.ms),

            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationItem(BuildContext context, String title, String body, bool isRead) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        blur: 10,
        opacity: 0.15,
        borderRadius: 12,
        padding: EdgeInsets.zero,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.notifications_none_rounded,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          title: Text(
            title,
            style: GoogleFonts.poppins(
              fontWeight: isRead ? FontWeight.normal : FontWeight.w600,
              fontSize: 14,
              color: context.textPrimary,
            ),
          ),
          subtitle: Text(
            body,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              color: context.textSecondary,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}

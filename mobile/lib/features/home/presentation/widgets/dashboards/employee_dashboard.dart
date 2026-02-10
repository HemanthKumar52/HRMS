import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../auth/providers/auth_provider.dart';
import '../../../../attendance/providers/attendance_provider.dart';
import '../../../../leave/providers/leave_provider.dart';
import '../../../../notifications/providers/notification_provider.dart';
import '../dashboard/attendance_timer_card.dart';
import '../dashboard/leave_details_card.dart';
import '../dashboard/dashboard_stats_grid.dart';
import '../dashboard/projects_carousel.dart';
import '../dashboard/tasks_list.dart';
import '../salary_info_card.dart';
import '../status_timeline_widget.dart';

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
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Breadcrumb / Welcome
            Container(
              margin: const EdgeInsets.only(bottom: 24),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.primary.withOpacity(0.1)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: AppColors.primary, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Welcome Back, ${user?.firstName ?? 'Employee'}! You have pending approvals.',
                      style: GoogleFonts.poppins(
                        color: AppColors.primaryDark,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn().slideX(),

            // Top Section: Leave Details & Attendance
            Column(
              children: [
                const LeaveDetailsCard().animate().fadeIn(delay: 100.ms).slideY(begin: 0.1),
                const SizedBox(height: 16),
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
              ],
            ),
            
            const SizedBox(height: 24),

            // Financials
            Text(
              'Financials',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.grey900,
              ),
            ).animate().fadeIn(delay: 300.ms),
            const SizedBox(height: 12),
            const SalaryInfoCard().animate().fadeIn(delay: 300.ms).slideY(begin: 0.1),
            
            const SizedBox(height: 24),

            // Quick Actions
            Row(
              children: [
                Expanded(child: _buildQuickAction(context, 'Raise Ticket', Icons.confirmation_number_outlined, Colors.orange)),
                const SizedBox(width: 16),
                Expanded(child: _buildQuickAction(context, 'Submit Claim', Icons.receipt_long_outlined, Colors.purple)),
              ],
            ),

            const SizedBox(height: 24),

            // Status Tracking
            Text(
              'Request Tracking',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.grey900,
              ),
            ).animate().fadeIn(delay: 300.ms),
            const SizedBox(height: 12),
            const StatusTimelineWidget().animate().fadeIn().slideY(),
            
            const SizedBox(height: 24),
            
            // Shift Details
            Container(
               padding: const EdgeInsets.all(16),
               decoration: BoxDecoration(
                 color: Colors.blue.shade50,
                 borderRadius: BorderRadius.circular(12),
                 border: Border.all(color: Colors.blue.shade200),
               ),
               child: Row(
                 children: [
                   Icon(Icons.access_time, color: Colors.blue.shade700),
                   const SizedBox(width: 12),
                   Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       Text('Current Shift: General', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.blue.shade900)),
                       Text('09:00 AM - 06:00 PM', style: GoogleFonts.poppins(fontSize: 12, color: Colors.blue.shade700)),
                     ],
                   )
                 ],
               ),
            ).animate().fadeIn(delay: 400.ms),

            const SizedBox(height: 24),

            // Statistics (General)
            Text(
              'Statistics',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.grey900,
              ),
            ).animate().fadeIn(delay: 300.ms),
            const SizedBox(height: 12),
            const DashboardStatsGrid().animate().fadeIn(delay: 300.ms).slideY(begin: 0.1),

            const SizedBox(height: 24),

            // View Profile Button (Performance & Skills moved to Profile)
            InkWell(
              onTap: () => context.push('/profile'),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.grey200),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.person_outline, color: AppColors.primary),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('My Profile', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
                          Text('View skills, performance & details', style: GoogleFonts.poppins(color: AppColors.grey500, fontSize: 12)),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: AppColors.grey400),
                  ],
                ),
              ),
            ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1),

            const SizedBox(height: 24),
            
            // Projects & Tasks
            const ProjectsList().animate().fadeIn(delay: 500.ms).slideX(begin: 0.1),
            const SizedBox(height: 24),
            const TasksList().animate().fadeIn(delay: 550.ms).slideX(begin: 0.1),

            const SizedBox(height: 24),
            
            // Recent Activities
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Activities',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.grey900,
                  ),
                ),
                TextButton(
                  onPressed: () => context.go('/notifications'),
                  child: const Text('View All'),
                ),
              ],
            ).animate().fadeIn(delay: 600.ms),
            const SizedBox(height: 8),
            Column(
              children: [
                _buildNotificationItem(context, 'Leave Approved', 'Your leave for 25 Oct was approved', false),
                _buildNotificationItem(context, 'New Policy Update', 'Please review the updated HR policy', true),
              ],
            ).animate().fadeIn(delay: 650.ms),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationItem(BuildContext context, String title, String body, bool isRead) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.grey200),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
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
          ),
        ),
        subtitle: Text(
          body,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.poppins(
            color: AppColors.grey500,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildQuickAction(BuildContext context, String label, IconData icon, Color color) {
    return InkWell(
      onTap: () {
        if (label == 'Raise Ticket') {
          context.push('/create-ticket');
        } else if (label == 'Submit Claim') {
           context.push('/create-claim');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Feature coming soon!')));
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.grey200),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(label, style: GoogleFonts.poppins(fontWeight: FontWeight.w500, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}

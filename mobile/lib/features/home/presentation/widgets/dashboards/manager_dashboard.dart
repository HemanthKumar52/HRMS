import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_theme_extensions.dart';
import '../../../../../core/widgets/glass_card.dart';
import '../../../../../shared/models/user_model.dart';
import '../../../../auth/providers/auth_provider.dart';
import '../../../../directory/providers/directory_provider.dart';
import '../../../../attendance/providers/attendance_provider.dart';
import '../dashboard/attendance_timer_card.dart';
import '../dashboard/dashboard_stats_grid.dart';

class ManagerDashboard extends ConsumerWidget {
  const ManagerDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final teamAsync = ref.watch(userTeamProvider(user?.id ?? ''));
    final todayStatusAsync = ref.watch(todayStatusProvider);

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        16,
        MediaQuery.of(context).padding.top + kToolbarHeight + 16,
        16,
        16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome
          Container(
            margin: const EdgeInsets.only(bottom: 20),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.people_alt, color: AppColors.primary, size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Manager View: ${user?.firstName ?? 'Manager'}. You have 3 pending leave requests.',
                    style: GoogleFonts.poppins(
                      color: context.isDark ? AppColors.primaryLight : AppColors.primaryDark,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn().slideX(),

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
              onPunch: () => context.go('/attendance'),
            ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => AttendanceTimerCard(
              isClockedIn: false,
              clockInTime: null,
              clockOutTime: null,
              totalHours: '0h 0m',
              onPunch: () => context.go('/attendance'),
            ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1),
          ),

          const SizedBox(height: 20),

          // Add Person Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => context.push('/add-employee'),
              icon: const Icon(Icons.person_add_alt_1, size: 20),
              label: Text(
                'Add Person',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary, width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.1),

          const SizedBox(height: 20),

          // Team Overview
          Text(
            'My Team',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: context.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          teamAsync.when(
            data: (team) => _buildTeamOverviewCard(context, team),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('Failed to load team: $e', style: const TextStyle(color: AppColors.error)),
            ),
          ),

          const SizedBox(height: 20),

          // Approvals
          Text(
            'Pending Approvals',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: context.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          _buildApprovalList(context),

          const SizedBox(height: 20),

          // Manager Stats
          const DashboardStatsGrid(),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildTeamOverviewCard(BuildContext context, List<UserModel> team) {
    return GlassCard(
      blur: 12,
      opacity: 0.15,
      borderRadius: 16,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatItem(context, 'Total Team', '${team.length}', Colors.blue),
              _buildStatItem(context, 'Active', '${team.length}', Colors.green),
              _buildStatItem(context, 'On Leave', '0', Colors.orange),
            ],
          ),
          Divider(height: 32, color: context.dividerColor),
          if (team.isEmpty)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'No team members found.',
                style: TextStyle(color: context.textSecondary),
              ),
            ),
          ...team.take(5).map((member) => ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(
              backgroundColor: Colors.purple.withValues(alpha: 0.2),
              backgroundImage: member.avatarUrl != null ? NetworkImage(member.avatarUrl!) : null,
              child: member.avatarUrl == null
                  ? Text(member.initials, style: const TextStyle(color: Colors.purple, fontWeight: FontWeight.bold))
                  : null,
            ),
            title: Text(
              member.fullName,
              style: TextStyle(fontWeight: FontWeight.bold, color: context.textPrimary),
            ),
            subtitle: Text(
              member.designation ?? 'Team Member',
              style: TextStyle(color: context.textSecondary),
            ),
            trailing: Icon(Icons.chevron_right, size: 20, color: context.textTertiary),
          )),
          if (team.length > 5)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '+${team.length - 5} more',
                style: const TextStyle(color: AppColors.primary),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: GoogleFonts.poppins(fontSize: 12, color: context.textSecondary)),
      ],
    );
  }

  Widget _buildApprovalList(BuildContext context) {
    return Column(
      children: [
        _buildApprovalItem(context, 'Leave Request', 'Alice Smith requested 2 days Sick Leave', '2m ago'),
        _buildApprovalItem(context, 'Expense Claim', 'Bob Jones claimed \$50 for Transport', '1h ago'),
        _buildApprovalItem(context, 'Shift Swap', 'Charlie wants to swap shift with Dave', '3h ago'),
      ],
    );
  }

  Widget _buildApprovalItem(BuildContext context, String type, String desc, String time) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        blur: 10,
        opacity: 0.15,
        borderRadius: 12,
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.assignment_turned_in, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    type,
                    style: TextStyle(fontWeight: FontWeight.bold, color: context.textPrimary),
                  ),
                  Text(
                    desc,
                    style: TextStyle(fontSize: 12, color: context.textSecondary),
                  ),
                ],
              ),
            ),
            Column(
              children: [
                Text(time, style: TextStyle(fontSize: 10, color: context.textTertiary)),
                const SizedBox(height: 4),
                Icon(Icons.arrow_forward_ios, size: 12, color: context.textTertiary),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

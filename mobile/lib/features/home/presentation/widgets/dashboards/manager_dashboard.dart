import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/glass_card.dart';
import '../../../../../shared/models/user_model.dart';
import '../../../../auth/providers/auth_provider.dart';
import '../../../../directory/providers/directory_provider.dart';
import '../../../../attendance/providers/attendance_provider.dart';
import '../dashboard/attendance_timer_card.dart';
import '../dashboard/dashboard_stats_grid.dart';
import '../dashboard/tasks_list.dart';

class ManagerDashboard extends ConsumerWidget {
  const ManagerDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final teamAsync = ref.watch(userTeamProvider(user?.id ?? ''));
    final todayStatusAsync = ref.watch(todayStatusProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome
          Container(
            margin: const EdgeInsets.only(bottom: 24),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.people_alt, color: Colors.blue, size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Manager View: ${user?.firstName ?? 'Manager'}. You have 3 pending leave requests.',
                    style: GoogleFonts.poppins(
                      color: Colors.blue.shade900,
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

          const SizedBox(height: 24),

          // Team Overview
          Text(
            'My Team',
            style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.grey900),
          ),
          const SizedBox(height: 12),
          teamAsync.when(
            data: (team) => _buildTeamOverviewCard(team),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1), 
                borderRadius: BorderRadius.circular(8)
              ),
              child: Text('Failed to load team: $e', style: const TextStyle(color: Colors.red)),
            ),
          ),

          const SizedBox(height: 24),

          // Approvals
          Text(
            'Pending Approvals',
            style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.grey900),
          ),
          const SizedBox(height: 12),
          _buildApprovalList(),

          const SizedBox(height: 24),
          
          // Projects (Manager oversees projects)
          const TasksList(),
          
          const SizedBox(height: 24),

          // Manager Stats
          const DashboardStatsGrid(), 
        ],
      ),
    );
  }

  Widget _buildTeamOverviewCard(List<UserModel> team) {
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
              _buildStatItem('Total Team', '${team.length}', Colors.blue),
              _buildStatItem('Active', '${team.length}', Colors.green), // Assuming all active
              _buildStatItem('On Leave', '0', Colors.orange), // TODO: Fetch leave status
            ],
          ),
          const Divider(height: 32),
          if (team.isEmpty)
             const Padding(
               padding: EdgeInsets.all(8.0),
               child: Text("No team members found."),
             ),
          ...team.take(5).map((member) => ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(
              backgroundColor: Colors.purple.withOpacity(0.2), 
              backgroundImage: member.avatarUrl != null ? NetworkImage(member.avatarUrl!) : null,
              child: member.avatarUrl == null ? Text(member.initials, style: const TextStyle(color: Colors.purple, fontWeight: FontWeight.bold)) : null,
            ),
            title: Text(member.fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(member.designation ?? 'Team Member'),
            trailing: const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
          )),
          if (team.length > 5)
             Padding(
               padding: const EdgeInsets.only(top: 8),
               child: Text("+${team.length - 5} more", style: const TextStyle(color: Colors.blue)),
             )
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: GoogleFonts.poppins(fontSize: 12, color: AppColors.grey500)),
      ],
    );
  }

  Widget _buildApprovalList() {
    // Keeping mock data for approvals for now as requested task was about Team Duplicates/View
    return Column(
      children: [
        _buildApprovalItem('Leave Request', 'Alice Smith requested 2 days Sick Leave', '2m ago'),
        _buildApprovalItem('Expense Claim', 'Bob Jones claimed \$50 for Transport', '1h ago'),
        _buildApprovalItem('Shift Swap', 'Charlie wants to swap shift with Dave', '3h ago'),
      ],
    );
  }

  Widget _buildApprovalItem(String type, String desc, String time) {
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
            decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.assignment_turned_in, color: Colors.blue),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(type, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(desc, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
          Column(
            children: [
              Text(time, style: const TextStyle(fontSize: 10, color: Colors.grey)),
              const SizedBox(height: 4),
              const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey),
            ],
          )
        ],
      ),
      ),
    );
  }
}

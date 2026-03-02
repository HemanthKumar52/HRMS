import 'package:flutter/material.dart';
import 'package:vibration/vibration.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_theme_extensions.dart';
import '../../../../../core/widgets/glass_card.dart';
import '../../../../auth/providers/auth_provider.dart';
import '../../../../attendance/providers/attendance_provider.dart';
import '../dashboard/attendance_timer_card.dart';
import '../dashboard/dashboard_stats_grid.dart';

class ManagerDashboard extends ConsumerWidget {
  const ManagerDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final todayStatusAsync = ref.watch(todayStatusProvider);
    final teamTodayAsync = ref.watch(teamTodayStatusProvider);

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
          teamTodayAsync.when(
            data: (teamData) {
              final present = teamData['present'] ?? 0;
              final total = teamData['total'] ?? 0;
              return Container(
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.people_alt, color: AppColors.primary, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Manager View: ${user?.firstName ?? 'Manager'}. $present/$total present today.',
                        style: GoogleFonts.poppins(
                          color: context.isDark ? AppColors.primaryLight : AppColors.primaryDark,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.05);
            },
            loading: () => _buildShimmerWelcome(context, user),
            error: (e, _) => Container(
              margin: const EdgeInsets.only(bottom: 20),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.people_alt, color: AppColors.primary, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Manager View: ${user?.firstName ?? 'Manager'}',
                      style: GoogleFonts.poppins(
                        color: context.isDark ? AppColors.primaryLight : AppColors.primaryDark,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn().slideX(begin: -0.05),
          ),

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
              onPressed: () {
                Vibration.vibrate(duration: 50);
                context.push('/add-employee');
              },
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

          // Team Attendance Overview
          Text(
            'Team Attendance Today',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: context.textPrimary,
            ),
          ).animate().fadeIn(delay: 200.ms),
          const SizedBox(height: 12),
          teamTodayAsync.when(
            data: (teamData) => _buildTeamAttendanceCard(context, teamData),
            loading: () => _buildShimmerTeamCard(context),
            error: (e, _) => Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('Failed to load team attendance: $e', style: const TextStyle(color: AppColors.error)),
            ),
          ),

          const SizedBox(height: 20),

          // Manager Stats
          const DashboardStatsGrid(),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  /// Shimmer placeholder for the welcome banner during loading
  Widget _buildShimmerWelcome(BuildContext context, dynamic user) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.people_alt, color: AppColors.primary, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Manager View: ${user?.firstName ?? 'Manager'}',
                  style: GoogleFonts.poppins(
                    color: context.isDark ? AppColors.primaryLight : AppColors.primaryDark,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  height: 10,
                  width: 100,
                  decoration: BoxDecoration(
                    color: AppColors.grey300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 1200.ms, color: AppColors.grey100),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Shimmer placeholder for the team attendance card during loading
  Widget _buildShimmerTeamCard(BuildContext context) {
    return GlassCard(
      blur: 12,
      opacity: 0.15,
      borderRadius: 16,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(3, (i) {
              return Column(
                children: [
                  Container(
                    width: 48,
                    height: 28,
                    decoration: BoxDecoration(
                      color: AppColors.grey200,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 1200.ms, delay: (i * 150).ms, color: AppColors.grey100),
                  const SizedBox(height: 4),
                  Container(
                    width: 60,
                    height: 12,
                    decoration: BoxDecoration(
                      color: AppColors.grey200,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              );
            }),
          ),
          const SizedBox(height: 16),
          ...List.generate(3, (i) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.grey200,
                      shape: BoxShape.circle,
                    ),
                  ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 1200.ms, delay: (i * 200).ms, color: AppColors.grey100),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(height: 12, width: 120, decoration: BoxDecoration(color: AppColors.grey200, borderRadius: BorderRadius.circular(4))),
                        const SizedBox(height: 4),
                        Container(height: 10, width: 80, decoration: BoxDecoration(color: AppColors.grey200, borderRadius: BorderRadius.circular(4))),
                      ],
                    ),
                  ),
                  Container(
                    width: 56,
                    height: 24,
                    decoration: BoxDecoration(
                      color: AppColors.grey200,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTeamAttendanceCard(BuildContext context, Map<String, dynamic> teamData) {
    final total = teamData['total'] ?? 0;
    final present = teamData['present'] ?? 0;
    final absent = teamData['absent'] ?? 0;
    final members = (teamData['members'] as List<dynamic>?) ?? [];

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
              _buildAnimatedStatItem(context, 'Total Team', total, Colors.blue, 0),
              _buildAnimatedStatItem(context, 'Present', present, Colors.green, 1),
              _buildAnimatedStatItem(context, 'Absent', absent, Colors.red, 2),
            ],
          ),
          Divider(height: 32, color: context.dividerColor),
          if (members.isEmpty)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'No team members found.',
                style: TextStyle(color: context.textSecondary),
              ),
            ),
          ...members.take(5).toList().asMap().entries.map((entry) {
            final index = entry.key;
            final member = entry.value;
            final name = member['name'] ?? 'Unknown';
            final status = member['status'] ?? 'ABSENT';
            final designation = member['designation'] ?? 'Team Member';
            final totalHours = member['totalHours'] ?? '0h 0m';
            final isPresent = status == 'PRESENT';
            final initials = name.split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(2).join().toUpperCase();

            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Stack(
                children: [
                  CircleAvatar(
                    backgroundColor: (isPresent ? Colors.green : Colors.red).withValues(alpha: 0.2),
                    backgroundImage: member['avatarUrl'] != null ? NetworkImage(member['avatarUrl']) : null,
                    child: member['avatarUrl'] == null
                        ? Text(initials, style: TextStyle(color: isPresent ? Colors.green : Colors.red, fontWeight: FontWeight.bold))
                        : null,
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: isPresent ? Colors.green : Colors.red,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
              title: Text(
                name,
                style: TextStyle(fontWeight: FontWeight.bold, color: context.textPrimary),
              ),
              subtitle: Text(
                isPresent ? '$designation - $totalHours' : designation,
                style: TextStyle(color: context.textSecondary, fontSize: 12),
              ),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: (isPresent ? Colors.green : Colors.red).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isPresent ? 'Present' : 'Absent',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isPresent ? Colors.green : Colors.red,
                  ),
                ),
              ),
            ).animate().fadeIn(delay: (300 + index * 100).ms).slideX(begin: 0.05);
          }),
          if (members.length > 5)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '+${members.length - 5} more',
                style: const TextStyle(color: AppColors.primary),
              ),
            ),
        ],
      ),
    ).animate().fadeIn(delay: 250.ms).slideY(begin: 0.08);
  }

  Widget _buildAnimatedStatItem(BuildContext context, String label, int value, Color color, int index) {
    return Column(
      children: [
        TweenAnimationBuilder<int>(
          tween: IntTween(begin: 0, end: value),
          duration: Duration(milliseconds: 800 + index * 200),
          curve: Curves.easeOutCubic,
          builder: (context, animValue, _) {
            return Text(
              '$animValue',
              style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: color),
            );
          },
        ),
        Text(label, style: GoogleFonts.poppins(fontSize: 12, color: context.textSecondary)),
      ],
    ).animate().fadeIn(delay: (200 + index * 150).ms).scale(begin: const Offset(0.8, 0.8));
  }
}

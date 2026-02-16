import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/glass_card.dart';
import '../../../../auth/providers/auth_provider.dart';
import '../../../../attendance/providers/attendance_provider.dart';
import '../dashboard/attendance_timer_card.dart';

class HRDashboard extends ConsumerWidget {
  const HRDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todayStatusAsync = ref.watch(todayStatusProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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

          // HR Overview
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFFDE6262), Color(0xFFFFB88C)]),
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('HR Overview', style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14)),
                    const SizedBox(height: 8),
                    Text('12 New Applications', style: GoogleFonts.poppins(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                     const SizedBox(height: 4),
                    Text('Requires Attention', style: GoogleFonts.poppins(color: Colors.white54, fontSize: 12)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.people_outline, color: Colors.white, size: 32),
                ),
              ],
            ),
          ).animate().fadeIn().slideY(),

          const SizedBox(height: 24),
          
          Text('Requests Management', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          
          _buildRequestCard(
            'Leave Approvals', '5 Pending', Icons.calendar_today, Colors.orange,
            onTap: () => context.push('/approvals'),
          ),
          const SizedBox(height: 12),
          _buildRequestCard(
            'Expense Claims', '2 Pending', Icons.attach_money, Colors.green,
            onTap: () => context.push('/approvals'),
          ),
          const SizedBox(height: 12),
          _buildRequestCard(
            'Onboarding Tasks', '3 Pending', Icons.person_add_alt, Colors.blue,
            onTap: () => context.push('/onboarding-tasks'),
          ),

          const SizedBox(height: 24),

          // Department Stats
          Text('Department Stats', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          SizedBox(
            height: 100,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildDeptCard('Engineering', '45', Colors.blue),
                _buildDeptCard('Sales', '20', Colors.purple),
                _buildDeptCard('Marketing', '12', Colors.pink),
                _buildDeptCard('HR', '5', Colors.orange),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestCard(String title, String status, IconData icon, Color color, {VoidCallback? onTap}) {
    return GlassCard(
      blur: 12,
      opacity: 0.15,
      borderRadius: 12,
      padding: const EdgeInsets.all(16),
      onTap: onTap,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text(status, style: TextStyle(color: color, fontWeight: FontWeight.w500, fontSize: 12)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.grey),
        ],
      ),
    );
  }

  Widget _buildDeptCard(String dept, String count, Color color) {
    return Container(
      width: 120,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(count, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
          Text(dept, style: TextStyle(fontSize: 12, color: color.withOpacity(0.8))),
        ],
      ),
    );
  }
}

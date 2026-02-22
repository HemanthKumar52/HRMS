import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../core/theme/app_theme_extensions.dart';
import '../../../../../core/widgets/glass_card.dart';

class AdminDashboard extends ConsumerWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // final user = ref.watch(currentUserProvider);

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
          // Admin Overview
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF2C3E50), Color(0xFF4CA1AF)]),
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Organization Health', style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14)),
                    const SizedBox(height: 8),
                    Text('98% Active', style: GoogleFonts.poppins(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                     const SizedBox(height: 4),
                    Text('Last updated 5m ago', style: GoogleFonts.poppins(color: Colors.white54, fontSize: 12)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.analytics, color: Colors.white, size: 32),
                ),
              ],
            ),
          ).animate().fadeIn().slideY(),

          const SizedBox(height: 24),

          // User Stats
          Row(
            children: [
              _buildMetricCard(context, 'Total Users', '150', Icons.people, Colors.blue),
              const SizedBox(width: 16),
              _buildMetricCard(context, 'Departments', '8', Icons.domain, Colors.purple),
            ],
          ).animate().fadeIn(delay: 100.ms),

          const SizedBox(height: 16),

          Row(
            children: [
              _buildMetricCard(context, 'New Hires', '5', Icons.person_add, Colors.green),
              const SizedBox(width: 16),
              _buildMetricCard(context, 'Pending', '3', Icons.pending_actions, Colors.orange),
            ],
          ).animate().fadeIn(delay: 200.ms),

          const SizedBox(height: 24),
          
          Text('System Actions', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: context.textPrimary)),
          const SizedBox(height: 16),
          
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
               _buildActionBtn(context, 'Manage Users', Icons.manage_accounts, Colors.indigo),
               _buildActionBtn(context, 'Attendance Logs', Icons.timer, Colors.teal),
               _buildActionBtn(context, 'Payroll Run', Icons.payments, Colors.green),
               _buildActionBtn(context, 'Settings', Icons.settings, Colors.grey),
            ],
          ).animate().fadeIn(delay: 300.ms),

          const SizedBox(height: 24),
          
          Text('Recent Audit Logs', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: context.textPrimary)),
          const SizedBox(height: 8),
          
          Column(
            children: [
              _buildLogItem(context, 'User Created - Sarah J.', '2 mins ago'),
              _buildLogItem(context, 'Policy Updated - Leave 2024', '1 hour ago'),
              _buildLogItem(context, 'System Backup Completed', '4 hours ago'),
            ],
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildMetricCard(BuildContext context, String label, String value, IconData icon, Color color) {
    return Expanded(
      child: GlassCard(
        blur: 10,
        opacity: 0.15,
        borderRadius: 12,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(value, style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: context.textPrimary)),
            Text(label, style: GoogleFonts.poppins(fontSize: 12, color: context.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _buildActionBtn(BuildContext context, String label, IconData icon, Color color) {
    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: (MediaQuery.of(context).size.width - 48) / 2, // 2 column grid approx
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 12),
            Text(label, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildLogItem(BuildContext context, String title, String time) {
    return ListTile(
      leading: Icon(Icons.history, color: context.textTertiary, size: 20),
      title: Text(title, style: TextStyle(fontSize: 14, color: context.textPrimary)),
      trailing: Text(time, style: TextStyle(color: context.textTertiary, fontSize: 12)),
      dense: true,
      contentPadding: EdgeInsets.zero,
    );
  }
}

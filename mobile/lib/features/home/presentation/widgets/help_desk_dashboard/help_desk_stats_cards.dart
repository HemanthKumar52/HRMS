import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/theme/app_theme_extensions.dart';
import '../../../../../core/widgets/glass_card.dart';

class HelpDeskStatsCards extends StatelessWidget {
  const HelpDeskStatsCards({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildCard(context, 'Total Tickets', '2,847', '+12.5%', Colors.deepOrange, Icons.confirmation_number_outlined),
          const SizedBox(width: 16),
          _buildCard(context, 'Open Tickets', '342', '+3.2%', const Color(0xFF264653), Icons.assignment_outlined), // Dark Teal
          const SizedBox(width: 16),
          _buildCard(context, 'Resolved Today', '128', '+13.5%', Colors.green, Icons.check_circle_outline),
          const SizedBox(width: 16),
          _buildCard(context, 'Avg Time', '2.4h', '+12.3%', Colors.blue, Icons.timer_outlined),
          const SizedBox(width: 16),
          _buildCard(context, 'Overdue', '23', '-5.2%', Colors.red, Icons.warning_amber_rounded),
          const SizedBox(width: 16),
          _buildCard(context, 'Active Agents', '42', '+8.2%', Colors.purple, Icons.people_outline),
        ],
      ),
    );
  }

  Widget _buildCard(BuildContext context, String label, String value, String trend, Color color, IconData icon) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(height: 12),
          Text(label, style: GoogleFonts.poppins(fontSize: 12, color: context.textSecondary)),
          const SizedBox(height: 4),
          Text(value, style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: context.textPrimary)),
          const SizedBox(height: 8),
           GlassCard(
             blur: 12,
             opacity: 0.15,
             borderRadius: 12,
             padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
             child: Row(
               mainAxisSize: MainAxisSize.min,
               children: [
                 Icon(trend.contains('-') ? Icons.arrow_downward : Icons.arrow_upward, size: 12, color: trend.contains('-') ? Colors.red : Colors.green),
                 const SizedBox(width: 4),
                 Text(trend, style: GoogleFonts.poppins(fontSize: 10,  color: trend.contains('-') ? Colors.red : Colors.green, fontWeight: FontWeight.bold)),
               ],
             ),
           ),
        ],
      ),
    );
  }
}

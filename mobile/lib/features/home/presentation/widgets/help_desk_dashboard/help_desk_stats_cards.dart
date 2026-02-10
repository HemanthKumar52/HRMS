import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../../core/theme/app_colors.dart';

class HelpDeskStatsCards extends StatelessWidget {
  const HelpDeskStatsCards({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildCard('Total Tickets', '2,847', '+12.5%', Colors.deepOrange, Icons.confirmation_number_outlined),
          const SizedBox(width: 16),
          _buildCard('Open Tickets', '342', '+3.2%', const Color(0xFF264653), Icons.assignment_outlined), // Dark Teal
          const SizedBox(width: 16),
          _buildCard('Resolved Today', '128', '+13.5%', Colors.green, Icons.check_circle_outline),
          const SizedBox(width: 16),
          _buildCard('Avg Time', '2.4h', '+12.3%', Colors.blue, Icons.timer_outlined),
          const SizedBox(width: 16),
          _buildCard('Overdue', '23', '-5.2%', Colors.red, Icons.warning_amber_rounded),
          const SizedBox(width: 16),
          _buildCard('Active Agents', '42', '+8.2%', Colors.purple, Icons.people_outline),
        ],
      ),
    );
  }

  Widget _buildCard(String label, String value, String trend, Color color, IconData icon) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
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
          Text(label, style: GoogleFonts.poppins(fontSize: 12, color: AppColors.grey700)),
          const SizedBox(height: 4),
          Text(value, style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.grey900)),
          const SizedBox(height: 8),
           Container(
             padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
             decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
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

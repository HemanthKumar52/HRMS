import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../../core/theme/app_colors.dart';

class SystemUptimeCard extends StatelessWidget {
  const SystemUptimeCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      // decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildUptimeItem(
                  'HRMS System Uptime',
                  '99.9%',
                  Colors.orange,
                  Icons.show_chart,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildUptimeItem(
                  'API Status',
                  'Healthy',
                  Colors.green,
                  Icons.api,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
             children: [
               Expanded(
                 child: _buildUptimeItem(
                   'Open IT Tickets',
                   '18',
                   Colors.blue,
                   Icons.confirmation_number_outlined,
                 ),
               ),
               const SizedBox(width: 16),
               Expanded(
                 child: _buildUptimeItem(
                   'Background Jobs',
                   'Running',
                   Colors.orange,
                   Icons.work_outline,
                 ),
               ),
             ],
          ),
        ],
      ),
    );
  }

  Widget _buildUptimeItem(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.grey200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
               Text(label, style: GoogleFonts.poppins(fontSize: 10, color: AppColors.grey500)),
               Icon(icon, size: 16, color: color),
            ],
          ),
          const SizedBox(height: 8),
          Text(value, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
          if (value == '99.9%')
             Text('Last 30 Days', style: GoogleFonts.poppins(fontSize: 10, color: AppColors.grey400)),
        ],
      ),
    );
  }
}

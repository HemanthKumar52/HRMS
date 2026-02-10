import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../../core/theme/app_colors.dart';

class PeakHoursCard extends StatelessWidget {
  const PeakHoursCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: AppColors.grey200)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('User Access & Role Management', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text('Peak Hours (Today)', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.grey700)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _buildPeakItem('9 AM', '85%', Colors.deepOrange),
                _buildPeakItem('10 AM', '92%', Colors.red),
                _buildPeakItem('11 AM', '78%', Colors.deepOrange),
                _buildPeakItem('12 AM', '45%', Colors.green),
                _buildPeakItem('1 AM', '38%', Colors.green),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeakItem(String time, String pct, Color color) {
    return Container(
      width: 150, // Fixed width for uniformity
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.grey200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(time, style: GoogleFonts.poppins(fontSize: 10, color: AppColors.grey500)),
              Icon(Icons.circle, size: 6, color: color),
            ],
          ),
          const SizedBox(height: 8),
          Text(pct, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          LinearProgressIndicator(value: double.parse(pct.replaceAll('%', '')) / 100, color: color, backgroundColor: AppColors.grey100, minHeight: 4),
        ],
      ),
    );
  }
}

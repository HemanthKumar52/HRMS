import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../../core/theme/app_colors.dart';

class RecruitmentOverviewCard extends StatelessWidget {
  const RecruitmentOverviewCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.grey200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Recruitment Overview', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                    Text('Offer Acceptance', style: GoogleFonts.poppins(fontSize: 10, color: AppColors.grey500)),
                    const SizedBox(height: 4),
                    Text('74.4%', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
                  ],
                ),
                 Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Monthly', style: GoogleFonts.poppins(fontSize: 10, color: AppColors.grey500)),
                    Text('Overall Hire Rate', style: GoogleFonts.poppins(fontSize: 10, color: AppColors.grey500)),
                    const SizedBox(height: 4),
                    Text('2.7%', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 150,
              child: Stack(
                children: [
                  PieChart(
                    PieChartData(
                      startDegreeOffset: 180,
                      centerSpaceRadius: 50,
                      sectionsSpace: 5,
                      sections: List.generate(12, (index) {
                         // Gauge bars
                         final isFilled = index < 8; // Approx 70%
                         return PieChartSectionData(
                           color: isFilled ? Colors.deepOrange : AppColors.grey100,
                           value: 10,
                           radius: 12,
                           showTitle: false,
                         );
                      }) + [PieChartSectionData(value: 120, color: Colors.transparent, radius: 10, showTitle: false)], // Bottom half transparency
                    ),
                  ),
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('2,384', style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold)),
                        Text('Total Applications', style: GoogleFonts.poppins(fontSize: 10, color: AppColors.grey500)),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

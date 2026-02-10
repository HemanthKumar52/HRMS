import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../../core/theme/app_colors.dart';

class SlaComplianceCard extends StatelessWidget {
  const SlaComplianceCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: AppColors.grey200)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('SLA Compliance', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                const Icon(Icons.more_horiz, color: AppColors.grey500),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 120,
              child: Stack(
                children: [
                  PieChart(
                    PieChartData(
                      startDegreeOffset: 270,
                      sectionsSpace: 0,
                      centerSpaceRadius: 40,
                      sections: [
                        PieChartSectionData(color: Colors.deepOrange, value: 80.5, showTitle: false, radius: 10),
                        PieChartSectionData(color: AppColors.grey200, value: 19.5, showTitle: false, radius: 10),
                      ],
                    ),
                  ),
                  const Center(
                    child: Text('80.5%', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _slaItem('First Response SLA', '96.2%', Colors.green),
            _slaItem('Resolution SLA', '92.6%', Colors.green),
            _slaItem('Escalation SLA', '89.5%', Colors.red),
          ],
        ),
      ),
    );
  }

  Widget _slaItem(String label, String val, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
               Container(width: 2, height: 10, color: color == Colors.red ? Colors.deepOrange : Colors.green), // Indicator
               const SizedBox(width: 8),
               Text(label, style: GoogleFonts.poppins(fontSize: 10, color: AppColors.grey600)),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
            child: Text(val, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

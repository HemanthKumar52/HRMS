import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../../core/theme/app_colors.dart';

class HrCostBreakdownChart extends StatelessWidget {
  const HrCostBreakdownChart({super.key});

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
                Text('HR Cost Breakdown', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                const Icon(Icons.more_horiz, color: AppColors.grey500),
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
                      centerSpaceRadius: 40,
                      sectionsSpace: 4,
                      sections: [
                        PieChartSectionData(color: const Color(0xFF00334E), value: 40, radius: 15, showTitle: false), // Dark Blue
                        PieChartSectionData(color: const Color(0xFF5588A3), value: 20, radius: 15, showTitle: false), // Blue Grey
                        PieChartSectionData(color: const Color(0xFF8EAFBC), value: 20, radius: 15, showTitle: false), // Light Blue
                        PieChartSectionData(color: Colors.transparent, value: 80, radius: 15, showTitle: false), // Transparent bottom
                      ],
                    ),
                    swapAnimationDuration: const Duration(milliseconds: 800),
                    swapAnimationCurve: Curves.easeInOutCubic,
                  ),
                  const Positioned(
                    top: 50,
                    left: 0,
                    right: 0,
                    child: Center(child: Text('\$2.4M', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                  ),
                ],
              ),
            ),
            // Legends
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _legendItem('Salaries', '184k', const Color(0xFF00334E)),
                _legendItem('Benefits', '89k', const Color(0xFF5588A3)),
                _legendItem('Training', '42k', const Color(0xFF8EAFBC)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _legendItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 12)),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 4),
            Text(label, style: GoogleFonts.poppins(fontSize: 10, color: AppColors.grey600)),
          ],
        ),
      ],
    );
  }
}

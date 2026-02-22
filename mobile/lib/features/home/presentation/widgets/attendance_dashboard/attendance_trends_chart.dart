import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../../core/theme/app_colors.dart';

class AttendanceTrendsChart extends StatelessWidget {
  const AttendanceTrendsChart({super.key});

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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Attendance Trends', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                // Could add dropdown here
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  barGroups: List.generate(12, (index) {
                     // Alternating logic for demo
                     final isHigh = index % 3 == 0;
                     return BarChartGroupData(
                       x: index,
                       barRods: [
                         BarChartRodData(
                            toY: isHigh ? 80 : 40 + (index * 2),
                            color: isHigh ? Colors.deepOrange : const Color(0xFFFFCCBC), // Highlight vs Normal
                            width: 12,
                            borderRadius: BorderRadius.circular(2),
                         ),
                       ],
                     );
                  }),
                  titlesData: FlTitlesData(
                     leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 30, interval: 20, getTitlesWidget: (v,m)=>Text('${v.toInt()}%', style: const TextStyle(fontSize: 10)))),
                     bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, m) {
                       const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
                       if(v.toInt() < months.length) return Text(months[v.toInt()], style: const TextStyle(fontSize: 10));
                       return const SizedBox();
                     })),
                     topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                     rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: 20, getDrawingHorizontalLine: (v) => FlLine(color: AppColors.grey200, strokeWidth: 1)),
                  borderData: FlBorderData(show: false),
                ),
                swapAnimationDuration: const Duration(milliseconds: 800),
                swapAnimationCurve: Curves.easeInOutCubic,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

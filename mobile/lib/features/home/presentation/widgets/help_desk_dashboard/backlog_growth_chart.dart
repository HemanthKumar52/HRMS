import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../../core/theme/app_colors.dart';

class BacklogGrowthChart extends StatelessWidget {
  const BacklogGrowthChart({super.key});

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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Backlog Growth', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                Container(
                   padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                   decoration: BoxDecoration(border: Border.all(color: AppColors.grey300), borderRadius: BorderRadius.circular(4)),
                   child: Row(
                     children: [
                       const Icon(Icons.calendar_today, size: 12, color: AppColors.grey600),
                       const SizedBox(width: 4),
                       Text('Monthly', style: GoogleFonts.poppins(fontSize: 10, color: AppColors.grey600)),
                     ],
                   ),
                 ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 180,
              child: BarChart(
                BarChartData(
                  titlesData: FlTitlesData(
                     bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v,m) {
                        const days = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
                        if(v.toInt() < days.length) return Text(days[v.toInt()], style: const TextStyle(fontSize: 10));
                        return const SizedBox();
                     })),
                     leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 25, getTitlesWidget: (v,m)=>Text('${v.toInt()}', style: const TextStyle(fontSize: 10)))),
                     topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                     rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  barGroups: [
                    _barGroup(0, 100),
                    _barGroup(1, 280),
                    _barGroup(2, 320),
                    _barGroup(3, 400),
                    _barGroup(4, 450),
                    _barGroup(5, 520),
                    _barGroup(6, 560),
                  ],
                ),
                swapAnimationDuration: const Duration(milliseconds: 800),
                swapAnimationCurve: Curves.easeInOutCubic,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.arrow_upward, color: Colors.green, size: 16),
                const SizedBox(width: 4),
                Text('12% Compared to Last Week', style: GoogleFonts.poppins(fontSize: 10, color: Colors.green, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  BarChartGroupData _barGroup(int x, double y) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: const Color(0xFF264653),
          width: 30,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          backDrawRodData: BackgroundBarChartRodData(show: true, toY: 600, color: AppColors.grey100),
        ),
      ],
    );
  }
}

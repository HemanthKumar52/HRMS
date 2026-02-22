import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../../core/theme/app_colors.dart';

class HeadcountVsPayrollChart extends StatelessWidget {
  const HeadcountVsPayrollChart({super.key});

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
                Text('Headcount Vs Payroll Growth', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                // Legend
                Row(
                  children: [
                    _legendItem(Colors.deepOrange, 'Payroll Growth'),
                    const SizedBox(width: 8),
                    _legendItem(AppColors.grey200, 'Head Count'),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('+14%', style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold)),
            Text('Increased From the Last Quarter', style: GoogleFonts.poppins(fontSize: 10, color: AppColors.grey500)),
            const SizedBox(height: 20),
            
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  barGroups: List.generate(12, (index) {
                     return BarChartGroupData(
                       x: index,
                       barRods: [
                         BarChartRodData(
                            toY: (index % 2 == 0 ? 10 : 15).toDouble() + (index * 0.5),
                            color: Colors.deepOrange,
                            width: 8,
                            borderRadius: BorderRadius.circular(2),
                         ),
                         BarChartRodData(
                            toY: (index % 2 == 0 ? 5 : 8).toDouble(),
                            color: AppColors.grey200,
                            width: 8,
                            borderRadius: BorderRadius.circular(2),
                         ),
                       ],
                     );
                  }),
                  titlesData: FlTitlesData(
                     bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, m) {
                       if(v == 2) return const Text('Jun', style: TextStyle(fontSize: 10));
                       if(v == 5) return const Text('Feb', style: TextStyle(fontSize: 10));
                       if(v == 8) return const Text('Mar', style: TextStyle(fontSize: 10));
                       if(v == 11) return const Text('Apr', style: TextStyle(fontSize: 10));
                       return const SizedBox();
                     })),
                     leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                     topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                     rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: FlGridData(show: false),
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

  Widget _legendItem(Color color, String label) {
    return Row(
      children: [
        Container(width: 8, height: 8, color: color),
        const SizedBox(width: 4),
        Text(label, style: GoogleFonts.poppins(fontSize: 10, color: AppColors.grey600)),
      ],
    );
  }
}

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../../core/theme/app_colors.dart';

class HrmsUsageTrendChart extends StatelessWidget {
  const HrmsUsageTrendChart({super.key});

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
                 Text('HRMS Usage Trend', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                 // Toggle buttons 1H 1D 1W 1M
               ],
             ),
             const SizedBox(height: 20),
             SizedBox(
               height: 150,
               child: LineChart(
                 LineChartData(
                    gridData: FlGridData(show: false),
                    titlesData: FlTitlesData(
                       bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v,m) {
                          const days = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
                          if(v.toInt() < days.length) return Text(days[v.toInt()], style: const TextStyle(fontSize: 10));
                          return const SizedBox();
                       })),
                       leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 25, getTitlesWidget: (v,m)=>Text('${v.toInt()}k', style: const TextStyle(fontSize: 10)))),
                       topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                       rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: const [
                          FlSpot(0, 1), FlSpot(1, 4), FlSpot(2, 4), FlSpot(3, 2),
                          FlSpot(4, 5.5), FlSpot(5, 5.5), FlSpot(6, 6.5)
                        ],
                        isCurved: true,
                        color: const Color(0xFF264653), // Dark Blue
                        barWidth: 3,
                        dotData: FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            colors: [const Color(0xFF264653).withOpacity(0.3), const Color(0xFF264653).withOpacity(0.0)],
                             begin: Alignment.topCenter,
                             end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ],
                 ),
               ),
             ),
          ],
        ),
      ),
    );
  }
}

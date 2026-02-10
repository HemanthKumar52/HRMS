import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../../core/theme/app_colors.dart';

class TicketTrendsChart extends StatelessWidget {
  const TicketTrendsChart({super.key});

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
                 Text('Ticket Trends', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
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
               child: LineChart(
                 LineChartData(
                    gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (v) => FlLine(color: AppColors.grey200, strokeWidth: 1)),
                    titlesData: FlTitlesData(
                       bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v,m) {
                          const days = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
                          if(v.toInt() < days.length) return Text(days[v.toInt()], style: const TextStyle(fontSize: 10, color: Colors.grey));
                          return const SizedBox();
                       })),
                       leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 30, getTitlesWidget: (v,m)=>Text('${v.toInt()}', style: const TextStyle(fontSize: 10, color: Colors.grey)))),
                       topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                       rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      // Created
                      LineChartBarData(
                        spots: const [FlSpot(0, 50), FlSpot(1, 60), FlSpot(2, 90), FlSpot(3, 70), FlSpot(4, 75), FlSpot(5, 60), FlSpot(6, 75)],
                        isCurved: true,
                        color: Colors.deepOrange,
                        barWidth: 2,
                        dotData: FlDotData(show: true, getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(radius: 2, color: Colors.deepOrange, strokeWidth: 0)),
                        belowBarData: BarAreaData(show: true, color: Colors.deepOrange.withOpacity(0.1)),
                      ),
                      // Resolved
                      LineChartBarData(
                        spots: const [FlSpot(0, 140), FlSpot(1, 150), FlSpot(2, 180), FlSpot(3, 140), FlSpot(4, 145), FlSpot(5, 160), FlSpot(6, 160)],
                        isCurved: true,
                        color: const Color(0xFF264653), // Dark Blue
                        barWidth: 2,
                        dotData: FlDotData(show: true, getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(radius: 2, color: const Color(0xFF264653), strokeWidth: 0)),
                      ),
                    ],
                 )
               ),
             ),
             const SizedBox(height: 16),
             Row(
               mainAxisAlignment: MainAxisAlignment.center,
               children: [
                 _legendItem('Created', Colors.deepOrange),
                 const SizedBox(width: 24),
                 _legendItem('Resolved', const Color(0xFF264653)),
               ],
             ),
          ],
        ),
      ),
    );
  }

  Widget _legendItem(String label, Color color) {
    return Row(
      children: [
        Icon(Icons.circle, size: 8, color: color),
        const SizedBox(width: 4),
        Text(label, style: GoogleFonts.poppins(fontSize: 12, color: AppColors.grey600)),
      ],
    );
  }
}

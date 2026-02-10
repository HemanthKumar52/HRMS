import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../../core/theme/app_colors.dart';

class OfficeVsRemoteChart extends StatelessWidget {
  const OfficeVsRemoteChart({super.key});

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
                Text('Office Vs Remote', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                // Legend
                Row(
                  children: [
                     _legend(Colors.deepOrange, 'Office'),
                     const SizedBox(width: 8),
                     _legend(const Color(0xFF004D40), 'Remote'),
                  ],
                ),
              ],
            ),
             const SizedBox(height: 20),
             SizedBox(
               height: 180,
               child: LineChart(
                 LineChartData(
                   gridData: FlGridData(show: true, drawVerticalLine: false),
                   titlesData: FlTitlesData(
                     bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, m) {
                       const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                       if (v.toInt() < days.length) return Text(days[v.toInt()], style: const TextStyle(fontSize: 10));
                       return const SizedBox();
                     })),
                     leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 20, interval: 100, getTitlesWidget: (v,m)=>Text('${v.toInt()}', style: const TextStyle(fontSize: 10)))),
                     rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                     topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                   ),
                   borderData: FlBorderData(show: false),
                   lineBarsData: [
                     LineChartBarData(
                       spots: const [FlSpot(0, 300), FlSpot(1, 320), FlSpot(2, 280), FlSpot(3, 350), FlSpot(4, 330), FlSpot(5, 100), FlSpot(6, 120)],
                       isCurved: true,
                       color: Colors.deepOrange,
                       dotData: FlDotData(show: false),
                     ),
                      LineChartBarData(
                       spots: const [FlSpot(0, 100), FlSpot(1, 120), FlSpot(2, 150), FlSpot(3, 110), FlSpot(4, 130), FlSpot(5, 50), FlSpot(6, 60)],
                       isCurved: true,
                       color: const Color(0xFF004D40),
                       dotData: FlDotData(show: false),
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
  
  Widget _legend(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: GoogleFonts.poppins(fontSize: 10, color: AppColors.grey600)),
      ],
    );
  }
}

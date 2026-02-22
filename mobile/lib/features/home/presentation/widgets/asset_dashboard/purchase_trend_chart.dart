import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../../core/theme/app_colors.dart';

class PurchaseTrendChart extends StatelessWidget {
  const PurchaseTrendChart({super.key});

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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Purchase Trend', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text('654', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 8),
                         Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                          child: Text('+18%', style: GoogleFonts.poppins(fontSize: 10, color: Colors.green, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 4),
                        Text('vs last year', style: GoogleFonts.poppins(fontSize: 10, color: AppColors.grey500)),
                      ],
                    )
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(border: Border.all(color: AppColors.grey300), borderRadius: BorderRadius.circular(4)),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 12, color: AppColors.grey600),
                      const SizedBox(width: 4),
                      Text('Weekly', style: GoogleFonts.poppins(fontSize: 10, color: AppColors.grey600)),
                    ],
                  ),
                ),
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
                      const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
                      if (v.toInt() < months.length) return Text(months[v.toInt()], style: const TextStyle(fontSize: 10, color: Colors.grey));
                      return const SizedBox();
                    })),
                    leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 25, getTitlesWidget: (v,m)=>Text('${v.toInt()}k', style: const TextStyle(fontSize: 10, color: Colors.grey)))),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: [
                        const FlSpot(0, 2), const FlSpot(1, 2.5), const FlSpot(2, 4), const FlSpot(3, 5),
                        const FlSpot(4, 5.2), const FlSpot(5, 5), const FlSpot(6, 6), const FlSpot(7, 6.2),
                        const FlSpot(8, 6), const FlSpot(9, 6.1), const FlSpot(10, 6.8), const FlSpot(11, 7),
                      ],
                      isCurved: false,
                      color: Colors.deepOrange, // Matches the orange fill look
                      barWidth: 2,
                      dotData: FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [Colors.deepOrange.withOpacity(0.3), Colors.deepOrange.withOpacity(0.0)],
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

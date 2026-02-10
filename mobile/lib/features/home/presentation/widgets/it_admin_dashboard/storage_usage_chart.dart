import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../../core/theme/app_colors.dart';

class StorageUsageChart extends StatelessWidget {
  const StorageUsageChart({super.key});

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
            Text('Storage Usage By Module (GB)', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
            const SizedBox(height: 20),
            SizedBox(
              height: 180,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  barGroups: [
                    _buildBarGroup(0, 280, const Color(0xFF264653)), // HR - Dark Blue
                    _buildBarGroup(1, 260, const Color(0xFF264653)), // Payroll
                    _buildBarGroup(2, 140, Colors.orange), // Attendance
                    _buildBarGroup(3, 60, const Color(0xFF2A9D8F)), // Recruitment - Teal
                    _buildBarGroup(4, 120, const Color(0xFF264653)), // Leaves
                    _buildBarGroup(5, 260, const Color(0xFF264653)), // Document
                  ],
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, m) {
                      switch (v.toInt()) {
                        case 0: return const Text('HR', style: TextStyle(fontSize: 10));
                        case 1: return const Text('Pay', style: TextStyle(fontSize: 10));
                        case 2: return const Text('Att', style: TextStyle(fontSize: 10));
                        case 3: return const Text('Rect', style: TextStyle(fontSize: 10));
                        case 4: return const Text('Lev', style: TextStyle(fontSize: 10));
                        case 5: return const Text('Doc', style: TextStyle(fontSize: 10));
                      }
                      return const SizedBox();
                    })),
                    leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 30, getTitlesWidget: (v,m)=>Text('${v.toInt()}', style: const TextStyle(fontSize: 10)))),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  BarChartGroupData _buildBarGroup(int x, double y, Color color) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: color,
          width: 24,
          borderRadius: BorderRadius.circular(4),
          backDrawRodData: BackgroundBarChartRodData(
            show: true,
            toY: 300,
            color: AppColors.grey100,
          ),
        ),
      ],
    );
  }
}

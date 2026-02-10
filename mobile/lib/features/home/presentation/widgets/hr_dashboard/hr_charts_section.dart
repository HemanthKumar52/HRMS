import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../../core/theme/app_colors.dart';

class HrChartsSection extends StatelessWidget {
  const HrChartsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _LeaveTypeDistributionCard()),
          ],
        ),
        const SizedBox(height: 16),
        const _AttendanceTrendCard(),
      ],
    );
  }
}

class _LeaveTypeDistributionCard extends StatelessWidget {
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
                Text(
                  'Leave Type Distribution',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
                const Icon(Icons.more_horiz, color: AppColors.grey500),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                SizedBox(
                  height: 100,
                  width: 100,
                  child: PieChart(
                    PieChartData(
                      startDegreeOffset: 180,
                      centerSpaceRadius: 35,
                      sectionsSpace: 4,
                      sections: [
                        PieChartSectionData(color: Colors.orange, value: 45, radius: 10, showTitle: false),
                        PieChartSectionData(color: const Color(0xFF455A64), value: 60, radius: 10, showTitle: false),
                        PieChartSectionData(color: Colors.grey, value: 12, radius: 10, showTitle: false),
                        // Transparent section to make it a semi-circle if needed, 
                        // but fl_chart draws full circle by default. 
                        // For a simple semi-circle, we usually just render full data or use specific offset.
                        // Let's stick to full circle but thin for now to look like gauge
                        PieChartSectionData(color: Colors.transparent, value: 100, radius: 10, showTitle: false), 
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    children: [
                      _buildLegendInfo('Sick Leave', '45', Colors.orange),
                      const SizedBox(height: 8),
                      _buildLegendInfo('Casual Leave', '60', const Color(0xFF455A64)),
                      const SizedBox(height: 8),
                      _buildLegendInfo('Unpaid', '12', Colors.grey),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendInfo(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 8),
            Text(label, style: GoogleFonts.poppins(fontSize: 12, color: AppColors.grey600)),
          ],
        ),
        Text(value, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 12)),
      ],
    );
  }
}

class _AttendanceTrendCard extends StatelessWidget {
  const _AttendanceTrendCard();

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
            Text('Attendance Trend', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
            const SizedBox(height: 20),
            AspectRatio(
              aspectRatio: 1.5,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  barGroups: [
                    _makeGroupData(0, 15, 5, 2),
                    _makeGroupData(1, 12, 6, 1),
                    _makeGroupData(2, 14, 4, 3),
                    _makeGroupData(3, 16, 2, 0),
                    _makeGroupData(4, 10, 8, 2),
                  ],
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          const titles = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'];
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(titles[value.toInt()], style: const TextStyle(fontSize: 10)),
                          );
                        },
                      ),
                    ),
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)), // Hide Left Titles for cleaner look
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  gridData: const FlGridData(show: false),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  BarChartGroupData _makeGroupData(int x, double y1, double y2, double y3) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(toY: y1, color: Colors.orange, width: 6),
        BarChartRodData(toY: y2, color: const Color(0xFF455A64), width: 6),
        BarChartRodData(toY: y3, color: Colors.amber, width: 6),
      ],
    );
  }
}

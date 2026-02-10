import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../core/theme/app_colors.dart';

class LeaveDetailsCard extends StatelessWidget {
  const LeaveDetailsCard({super.key});

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
                Text(
                  'Leave Details',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.grey300),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 14, color: AppColors.grey600),
                      const SizedBox(width: 4),
                      Text(
                        '2025',
                        style: GoogleFonts.poppins(fontSize: 12, color: AppColors.grey600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLegendItem(AppColors.primaryDark, '1254 On Leave'),
                      _buildLegendItem(AppColors.success, '32 Late Attendance'),
                      _buildLegendItem(Colors.orange, '658 Work From Home'),
                      _buildLegendItem(Colors.red, '14 Absent'),
                      _buildLegendItem(Colors.yellow, '60 Sick Leave'),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(Icons.check_box, size: 16, color: Colors.orange),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'Better than 85% of Employees',
                              style: GoogleFonts.poppins(fontSize: 12, color: AppColors.grey600),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                 Expanded(
                  flex: 2,
                  child: SizedBox(
                    height: 120,
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 30,
                        sections: [
                          PieChartSectionData(
                            color: AppColors.primaryDark,
                            value: 30,
                            radius: 15,
                            showTitle: false,
                          ),
                          PieChartSectionData(
                            color: AppColors.success,
                            value: 15,
                            radius: 15,
                            showTitle: false,
                          ),
                          PieChartSectionData(
                            color: Colors.orange,
                            value: 25,
                            radius: 15,
                            showTitle: false,
                          ),
                          PieChartSectionData(
                            color: Colors.red,
                            value: 10,
                            radius: 15,
                            showTitle: false,
                          ),
                           PieChartSectionData(
                            color: Colors.yellow,
                            value: 20,
                            radius: 15,
                            showTitle: false,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: GoogleFonts.poppins(fontSize: 12, color: AppColors.grey700),
          ),
        ],
      ),
    );
  }
}

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_theme_extensions.dart';
import '../../../../../core/widgets/glass_card.dart';

class LeaveDetailsCard extends StatelessWidget {
  const LeaveDetailsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      blur: 12,
      opacity: 0.15,
      borderRadius: 16,
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
                    color: context.textPrimary,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    border: Border.all(color: context.borderColor),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today, size: 14, color: context.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        '2025',
                        style: GoogleFonts.poppins(fontSize: 12, color: context.textSecondary),
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
                      _buildLegendItem(context, AppColors.primaryDark, '1254 On Leave'),
                      _buildLegendItem(context, AppColors.success, '32 Late Attendance'),
                      _buildLegendItem(context, Colors.orange, '658 Work From Home'),
                      _buildLegendItem(context, Colors.red, '14 Absent'),
                      _buildLegendItem(context, Colors.yellow, '60 Sick Leave'),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.check_box, size: 16, color: Colors.orange),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'Better than 85% of Employees',
                              style: GoogleFonts.poppins(fontSize: 12, color: context.textSecondary),
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
                      swapAnimationDuration: const Duration(milliseconds: 800),
                      swapAnimationCurve: Curves.easeInOutCubic,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
    );
  }

  Widget _buildLegendItem(BuildContext context, Color color, String text) {
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
            style: GoogleFonts.poppins(fontSize: 12, color: context.textSecondary),
          ),
        ],
      ),
    );
  }
}

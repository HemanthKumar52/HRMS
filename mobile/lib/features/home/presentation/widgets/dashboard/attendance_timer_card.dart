import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../../core/theme/app_colors.dart';

class AttendanceTimerCard extends StatelessWidget {
  final bool isClockedIn;
  final String? clockInTime;
  final String? clockOutTime;
  final String totalHours;
  final VoidCallback onPunch;

  const AttendanceTimerCard({
    super.key,
    required this.isClockedIn,
    required this.clockInTime,
    required this.clockOutTime,
    required this.totalHours,
    required this.onPunch,
  });

  @override
  Widget build(BuildContext context) {
    // Parse total hours to double for progress (assuming "HH:mm" or similar)
    double progress = 0.0;
    try {
      if (totalHours.contains('h')) {
        // Format "Xh Ym"
        final parts = totalHours.split(' ');
        final h = int.tryParse(parts[0].replaceAll('h', '')) ?? 0;
        final m = int.tryParse(parts[1].replaceAll('m', '')) ?? 0;
        progress = (h + m / 60) / 9.0; // Assuming 9 hours work day
      }
    } catch (_) {}
    
    // Cap progress at 1.0
    progress = progress > 1.0 ? 1.0 : progress;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.primary.withOpacity(0.5), width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              'Attendance',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.grey700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              DateFormat('hh:mm a, dd MMM yyyy').format(DateTime.now()),
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppColors.grey500,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 180,
              child: Stack(
                children: [
                   PieChart(
                    PieChartData(
                      sectionsSpace: 0,
                      centerSpaceRadius: 70,
                      startDegreeOffset: 270,
                      sections: [
                        PieChartSectionData(
                          color: AppColors.success,
                          value: progress * 100,
                          title: '',
                          radius: 15,
                          showTitle: false,
                        ),
                        PieChartSectionData(
                          color: AppColors.grey100,
                          value: (1 - progress) * 100,
                          title: '',
                          radius: 15,
                          showTitle: false,
                        ),
                      ],
                    ),
                  ),
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Total Hours',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: AppColors.grey400,
                          ),
                        ),
                        Text(
                          totalHours,
                          style: GoogleFonts.poppins(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.grey900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.grey900,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Production : $totalHours',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (clockInTime != null)
              Text(
                'Punch In at $clockInTime',
                style: GoogleFonts.poppins(
                  color: AppColors.grey500,
                  fontSize: 12,
                ),
              ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onPunch,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF97316), // Orange
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  isClockedIn ? 'Punch Out' : 'Punch In',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

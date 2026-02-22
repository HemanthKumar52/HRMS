import 'dart:async';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_theme_extensions.dart';
import '../../../../../core/widgets/glass_card.dart';

class AttendanceTimerCard extends StatefulWidget {
  final bool isClockedIn;
  final String? clockInTime;
  final String? clockOutTime;
  final String totalHours;
  final DateTime? clockInDateTime;
  final VoidCallback onPunch;

  const AttendanceTimerCard({
    super.key,
    required this.isClockedIn,
    required this.clockInTime,
    required this.clockOutTime,
    required this.totalHours,
    this.clockInDateTime,
    required this.onPunch,
  });

  @override
  State<AttendanceTimerCard> createState() => _AttendanceTimerCardState();
}

class _AttendanceTimerCardState extends State<AttendanceTimerCard> {
  Timer? _timer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _now = DateTime.now();
        });
      }
    });
  }

  String _computeLiveHours() {
    if (!widget.isClockedIn || widget.clockInDateTime == null) {
      return widget.totalHours;
    }
    final elapsed = _now.difference(widget.clockInDateTime!);
    final h = elapsed.inHours;
    final m = elapsed.inMinutes % 60;
    return '${h}h ${m}m';
  }

  double _computeProgress() {
    final display = _computeLiveHours();
    double progress = 0.0;
    try {
      if (display.contains('h')) {
        final parts = display.split(' ');
        final h = int.tryParse(parts[0].replaceAll('h', '')) ?? 0;
        final m = int.tryParse(parts[1].replaceAll('m', '')) ?? 0;
        progress = (h + m / 60) / 9.0;
      }
    } catch (_) {}
    return progress > 1.0 ? 1.0 : progress;
  }

  @override
  Widget build(BuildContext context) {
    final liveHours = _computeLiveHours();
    final progress = _computeProgress();

    return GlassCard(
      blur: 15,
      opacity: 0.15,
      borderRadius: 16,
      padding: const EdgeInsets.all(20),
      child: Column(
          children: [
            Text(
              'Attendance',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: context.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              DateFormat('hh:mm:ss a, dd MMM yyyy').format(_now),
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: context.textSecondary,
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
                          color: context.isDark ? AppColors.grey700 : AppColors.grey100,
                          value: (1 - progress) * 100,
                          title: '',
                          radius: 15,
                          showTitle: false,
                        ),
                      ],
                    ),
                    swapAnimationDuration: const Duration(milliseconds: 800),
                    swapAnimationCurve: Curves.easeInOutCubic,
                  ),
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Total Hours',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: context.textTertiary,
                          ),
                        ),
                        Text(
                          liveHours,
                          style: GoogleFonts.poppins(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: context.textPrimary,
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
                color: context.isDark ? AppColors.grey700 : AppColors.grey900,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Production : $liveHours',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (widget.clockInTime != null)
              Text(
                'Punch In at ${widget.clockInTime}',
                style: GoogleFonts.poppins(
                  color: context.textSecondary,
                  fontSize: 12,
                ),
              ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: widget.onPunch,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF97316),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  widget.isClockedIn ? 'Punch Out' : 'Punch In',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
    );
  }
}

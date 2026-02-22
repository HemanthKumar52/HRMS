import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../../core/constants/api_constants.dart';
import '../../../../../core/network/api_client.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_theme_extensions.dart';
import '../../../../../core/widgets/glass_card.dart';
import '../../../../home/providers/timesheet_provider.dart';

class TimesheetCard extends ConsumerStatefulWidget {
  const TimesheetCard({super.key});

  @override
  ConsumerState<TimesheetCard> createState() => _TimesheetCardState();
}

class _TimesheetCardState extends ConsumerState<TimesheetCard> {
  Timer? _countdownTimer;
  Duration _remaining = Duration.zero;
  bool _isCountingToSaturday = true;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    _updateRemaining();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateRemaining();
    });
  }

  void _updateRemaining() {
    final now = DateTime.now();
    // Find this week's Saturday 23:59:59
    final daysUntilSaturday = (6 - now.weekday) % 7;
    final saturday = DateTime(
      now.year,
      now.month,
      now.day + (daysUntilSaturday == 0 && now.weekday == 6
          ? 0
          : daysUntilSaturday == 0
              ? 7
              : daysUntilSaturday),
      23,
      59,
      59,
    );

    // If it's Saturday, count to Saturday end
    if (now.weekday == 6) {
      final saturdayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);
      if (now.isBefore(saturdayEnd)) {
        setState(() {
          _remaining = saturdayEnd.difference(now);
          _isCountingToSaturday = true;
        });
        return;
      }
    }

    // If it's Sunday, count to next Monday
    if (now.weekday == 7 || now.weekday == 0) {
      final nextMonday = DateTime(
        now.year,
        now.month,
        now.day + (DateTime.monday - now.weekday + 7) % 7,
        0,
        0,
        0,
      );
      setState(() {
        _remaining = nextMonday.difference(now);
        _isCountingToSaturday = false;
      });
      return;
    }

    // Weekday Mon-Fri: count to Saturday 23:59
    setState(() {
      _remaining = saturday.difference(now);
      _isCountingToSaturday = true;
    });
  }

  String _formatCountdown(Duration d) {
    final days = d.inDays;
    final hours = d.inHours % 24;
    final minutes = d.inMinutes % 60;
    final seconds = d.inSeconds % 60;

    if (days > 0) {
      return '${days}d ${hours}h ${minutes}m';
    }
    if (hours > 0) {
      return '${hours}h ${minutes}m ${seconds}s';
    }
    return '${minutes}m ${seconds}s';
  }

  @override
  Widget build(BuildContext context) {
    final timesheetAsync = ref.watch(currentTimesheetProvider);

    return GlassCard(
      blur: 15,
      opacity: 0.15,
      borderRadius: 16,
      padding: const EdgeInsets.all(20),
      onTap: () => context.push('/timesheet'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.access_time_filled,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Weekly Timesheet',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: context.textPrimary,
                    ),
                  ),
                ],
              ),
              timesheetAsync.when(
                data: (ts) => _buildStatusBadge(
                  ts['status'] as String? ?? 'DRAFT',
                ),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ],
          ),
          const SizedBox(height: 4),

          // Week range
          timesheetAsync.when(
            data: (ts) {
              final weekStart = ts['weekStart'] as String?;
              final weekEnd = ts['weekEnd'] as String?;
              if (weekStart != null && weekEnd != null) {
                final start = DateTime.parse(weekStart);
                final end = DateTime.parse(weekEnd);
                return Padding(
                  padding: const EdgeInsets.only(left: 40),
                  child: Text(
                    '${DateFormat('dd MMM').format(start)} - ${DateFormat('dd MMM yyyy').format(end)}',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: context.textTertiary,
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),

          const SizedBox(height: 16),

          // Daily entries
          timesheetAsync.when(
            data: (ts) => _buildEntries(context, ts),
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
            error: (e, _) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'Could not load timesheet',
                  style: GoogleFonts.poppins(
                    color: context.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Countdown timer
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: (_isCountingToSaturday
                      ? AppColors.primary
                      : AppColors.success)
                  .withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: (_isCountingToSaturday
                        ? AppColors.primary
                        : AppColors.success)
                    .withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _isCountingToSaturday
                      ? Icons.timer_outlined
                      : Icons.refresh,
                  size: 18,
                  color: _isCountingToSaturday
                      ? AppColors.primary
                      : AppColors.success,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _isCountingToSaturday
                        ? 'Timesheet closes in ${_formatCountdown(_remaining)}'
                        : 'New timesheet in ${_formatCountdown(_remaining)}',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: _isCountingToSaturday
                          ? AppColors.primary
                          : AppColors.success,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // View Full Timesheet link
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'View Full Timesheet',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_forward_ios, size: 12, color: AppColors.primary),
              ],
            ),
          ),

          // Submit button (only for DRAFT)
          timesheetAsync.when(
            data: (ts) {
              final status = ts['status'] as String? ?? 'DRAFT';
              final id = ts['id'] as String?;
              if (status == 'DRAFT' && id != null) {
                return Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _submitTimesheet(id),
                      icon: const Icon(Icons.send, size: 16),
                      label: Text(
                        'Submit Timesheet',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildEntries(BuildContext context, Map<String, dynamic> ts) {
    final entries = (ts['entries'] as List<dynamic>?) ?? [];
    final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

    return Column(
      children: [
        // Header row
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              SizedBox(
                width: 40,
                child: Text(
                  'Day',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: context.textTertiary,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  'Date',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: context.textTertiary,
                  ),
                ),
              ),
              SizedBox(
                width: 60,
                child: Text(
                  'Hours',
                  textAlign: TextAlign.right,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: context.textTertiary,
                  ),
                ),
              ),
            ],
          ),
        ),
        Divider(height: 1, color: context.dividerColor),
        const SizedBox(height: 4),

        // Entry rows
        ...List.generate(6, (i) {
          // Find entry for this day
          final weekStartStr = ts['weekStart'] as String?;
          DateTime? entryDate;
          String hoursWorked = '00:00';
          bool hasData = false;

          if (weekStartStr != null) {
            final weekStart = DateTime.parse(weekStartStr);
            entryDate = weekStart.add(Duration(days: i));

            for (final entry in entries) {
              final eDateStr = entry['date'] as String?;
              if (eDateStr != null) {
                final eDate = DateTime.parse(eDateStr);
                if (eDate.year == entryDate.year &&
                    eDate.month == entryDate.month &&
                    eDate.day == entryDate.day) {
                  hoursWorked = (entry['hoursWorked'] as String?) ?? '00:00';
                  hasData = true;
                  break;
                }
              }
            }
          }

          // Parse hours for color coding
          final parts = hoursWorked.split(':');
          final h = int.tryParse(parts[0]) ?? 0;
          final m = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
          final totalMinutes = h * 60 + m;

          Color hoursColor;
          if (!hasData || totalMinutes == 0) {
            hoursColor = context.textTertiary;
          } else if (totalMinutes >= 480) {
            // 8+ hours
            hoursColor = AppColors.success;
          } else if (totalMinutes >= 240) {
            // 4-8 hours
            hoursColor = Colors.amber.shade700;
          } else {
            hoursColor = AppColors.error;
          }

          final isToday = entryDate != null &&
              entryDate.year == DateTime.now().year &&
              entryDate.month == DateTime.now().month &&
              entryDate.day == DateTime.now().day;

          final isFuture =
              entryDate != null && entryDate.isAfter(DateTime.now());

          return Container(
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: isToday
                ? BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(6),
                  )
                : null,
            child: Row(
              children: [
                SizedBox(
                  width: 40,
                  child: Text(
                    dayNames[i],
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: isToday ? FontWeight.w600 : FontWeight.w500,
                      color: isToday
                          ? AppColors.primary
                          : isFuture
                              ? context.textTertiary
                              : context.textSecondary,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    entryDate != null
                        ? DateFormat('dd MMM').format(entryDate)
                        : '-',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: isToday
                          ? AppColors.primary
                          : isFuture
                              ? context.textTertiary
                              : context.textSecondary,
                    ),
                  ),
                ),
                SizedBox(
                  width: 60,
                  child: Text(
                    isFuture ? '-' : '${h}h ${m}m',
                    textAlign: TextAlign.right,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isFuture ? context.textTertiary : hoursColor,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),

        const SizedBox(height: 4),
        Divider(height: 1, color: context.dividerColor),
        const SizedBox(height: 8),

        // Total row
        Row(
          children: [
            const SizedBox(width: 40),
            Expanded(
              child: Text(
                'Total',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: context.textPrimary,
                ),
              ),
            ),
            SizedBox(
              width: 60,
              child: Text(
                _formatTotalHours(ts['totalHours'] as String? ?? '00:00'),
                textAlign: TextAlign.right,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _formatTotalHours(String hhMm) {
    final parts = hhMm.split(':');
    final h = int.tryParse(parts[0]) ?? 0;
    final m = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
    return '${h}h ${m}m';
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    switch (status) {
      case 'SUBMITTED':
        color = Colors.blue;
        break;
      case 'APPROVED':
        color = AppColors.success;
        break;
      case 'REJECTED':
        color = AppColors.error;
        break;
      default:
        color = Colors.amber.shade700;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status,
        style: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Future<void> _submitTimesheet(String id) async {
    try {
      final dio = ref.read(dioProvider);
      await dio.post(ApiConstants.timesheetSubmit(id));
      ref.invalidate(currentTimesheetProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Timesheet submitted successfully'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}

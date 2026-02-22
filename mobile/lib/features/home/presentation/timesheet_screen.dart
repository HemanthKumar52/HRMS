import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme_extensions.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/safe_scaffold.dart';

// Projects list
const _projects = [
  '-- Select Project --',
  '75Health',
  "Chairman's Office",
  'Kaaspro',
  'HRMS App',
  'Internal Tools',
  'Client Portal',
];

// Activities list
const _activities = [
  '-- Select Activity --',
  'HRMS Enhancement',
  'AI Projects',
  'Development',
  'Testing',
  'Project Exploring',
  'HR Tasks',
  'Microsoft Migration',
  'Meeting',
  'Bug Fixing',
  'Lead Generation Activity',
  'Calling',
  'Mailing',
  'Demo Activity',
  'Daily CRM updates',
  'Daily sales report (DSR) submission',
  'Weekly sales plan',
  'Monthly sales target review',
  'Customer follow-up calls',
  'Client exploring',
];

const _dayKeys = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];
const _dayLabels = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];

/// Provider to fetch the timesheet detail (with tasks)
final timesheetDetailProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, String>((ref, timesheetId) async {
  final dio = ref.read(dioProvider);
  final response = await dio.get(ApiConstants.timesheetDetail(timesheetId));
  return Map<String, dynamic>.from(response.data);
});

class TimesheetScreen extends ConsumerStatefulWidget {
  const TimesheetScreen({super.key});

  @override
  ConsumerState<TimesheetScreen> createState() => _TimesheetScreenState();
}

class _TimesheetScreenState extends ConsumerState<TimesheetScreen> {
  // Week navigation
  DateTime _weekStart = _getMonday(DateTime.now());
  String? _timesheetId;
  String _status = 'DRAFT';
  bool _isLoading = true;

  // Summary data
  String _totalHours = '00:00';
  String _wfoHours = '00:00';
  String _wfhHours = '00:00';

  // Task rows (local state)
  List<Map<String, dynamic>> _tasks = [];

  // Day dates for current week
  List<DateTime> _weekDates = [];

  @override
  void initState() {
    super.initState();
    _computeWeekDates();
    _loadTimesheet();
  }

  static DateTime _getMonday(DateTime d) {
    final diff = d.weekday - DateTime.monday;
    return DateTime(d.year, d.month, d.day - diff);
  }

  void _computeWeekDates() {
    _weekDates = List.generate(7, (i) => _weekStart.add(Duration(days: i)));
  }

  Future<void> _loadTimesheet() async {
    setState(() => _isLoading = true);
    try {
      final dio = ref.read(dioProvider);
      final response = await dio.get(ApiConstants.timesheetCurrent);
      final data = Map<String, dynamic>.from(response.data);

      setState(() {
        _timesheetId = data['id'] as String?;
        _status = data['status'] as String? ?? 'DRAFT';
        _totalHours = data['totalHours'] as String? ?? '00:00';

        // Parse tasks
        final tasksList = data['tasks'] as List<dynamic>? ?? [];
        _tasks = tasksList
            .map((t) => Map<String, dynamic>.from(t as Map))
            .toList();

        // Compute WFO/WFH hours
        _computeLocationHours();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _computeLocationHours() {
    int wfoMinutes = 0;
    int wfhMinutes = 0;

    for (final task in _tasks) {
      final location = task['workLocation'] as String? ?? 'WFO';
      int taskMinutes = 0;

      for (final key in ['monHours', 'tueHours', 'wedHours', 'thuHours', 'friHours', 'satHours', 'sunHours']) {
        final val = task[key] as String? ?? '00:00';
        final parts = val.split(':');
        taskMinutes += (int.tryParse(parts[0]) ?? 0) * 60 + (parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0);
      }

      if (location == 'WFH') {
        wfhMinutes += taskMinutes;
      } else {
        wfoMinutes += taskMinutes;
      }
    }

    _wfoHours = '${(wfoMinutes ~/ 60).toString().padLeft(2, '0')}:${(wfoMinutes % 60).toString().padLeft(2, '0')}';
    _wfhHours = '${(wfhMinutes ~/ 60).toString().padLeft(2, '0')}:${(wfhMinutes % 60).toString().padLeft(2, '0')}';

    // Total from tasks
    final total = wfoMinutes + wfhMinutes;
    if (_tasks.isNotEmpty) {
      _totalHours = '${(total ~/ 60).toString().padLeft(2, '0')}:${(total % 60).toString().padLeft(2, '0')}';
    }
  }

  void _navigateWeek(int direction) {
    setState(() {
      _weekStart = _weekStart.add(Duration(days: 7 * direction));
      _computeWeekDates();
    });
    _loadTimesheet();
  }

  Future<void> _addTask() async {
    if (_timesheetId == null) return;

    try {
      final dio = ref.read(dioProvider);
      await dio.post(
        ApiConstants.timesheetAddTask(_timesheetId!),
        data: {
          'project': _projects[1],
          'activity': _activities[1],
          'workLocation': 'WFO',
        },
      );
      await _loadTimesheet();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add task: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _updateTask(String taskId, Map<String, dynamic> updates) async {
    try {
      final dio = ref.read(dioProvider);
      await dio.patch(ApiConstants.timesheetUpdateTask(taskId), data: updates);
      await _loadTimesheet();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _deleteTask(String taskId) async {
    try {
      final dio = ref.read(dioProvider);
      await dio.delete(ApiConstants.timesheetDeleteTask(taskId));
      await _loadTimesheet();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _submitTimesheet() async {
    if (_timesheetId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Submit Timesheet'),
        content: const Text('Are you sure you want to submit this timesheet for approval?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Submit')),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final dio = ref.read(dioProvider);
      await dio.post(ApiConstants.timesheetSubmit(_timesheetId!));
      await _loadTimesheet();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Timesheet submitted successfully!'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Submit failed: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  void _showEntryDetailsDialog(Map<String, dynamic> task, String dayKey, int dayIndex) {
    final hoursKey = '${dayKey}Hours';
    final currentHours = task[hoursKey] as String? ?? '00:00';
    final descController = TextEditingController(text: task['description'] as String? ?? '');
    final hoursController = TextEditingController(text: currentHours);
    String workLocation = task['workLocation'] as String? ?? 'WFO';

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              backgroundColor: context.isDark ? AppColors.grey900 : Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Entry Details',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: context.textPrimary,
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close, color: context.textSecondary),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Hours input
                    Text('HOURS', style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: context.textTertiary)),
                    const SizedBox(height: 6),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: context.borderColor),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: TextField(
                        controller: hoursController,
                        style: GoogleFonts.poppins(color: context.textPrimary),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          hintText: '00:00',
                          hintStyle: GoogleFonts.poppins(color: context.textTertiary),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Task description
                    Text('TASK DESCRIPTION', style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: context.textTertiary)),
                    const SizedBox(height: 6),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: context.borderColor),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: TextField(
                        controller: descController,
                        maxLines: 3,
                        style: GoogleFonts.poppins(color: context.textPrimary, fontSize: 14),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.all(12),
                          hintText: 'Describe what you worked on...',
                          hintStyle: GoogleFonts.poppins(color: context.textTertiary, fontSize: 14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Work Location
                    Text('WORK LOCATION', style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: context.textTertiary)),
                    const SizedBox(height: 6),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: context.borderColor),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: workLocation,
                          isExpanded: true,
                          dropdownColor: context.isDark ? AppColors.grey800 : Colors.white,
                          style: GoogleFonts.poppins(color: context.textPrimary, fontSize: 14),
                          items: const [
                            DropdownMenuItem(value: 'WFO', child: Text('Work From Office (WFO)')),
                            DropdownMenuItem(value: 'WFH', child: Text('Work From Home (WFH)')),
                          ],
                          onChanged: (v) => setDialogState(() => workLocation = v!),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: context.textSecondary,
                            side: BorderSide(color: context.borderColor),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('Close'),
                        ),
                        const SizedBox(width: 12),
                        FilledButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                            _updateTask(task['id'] as String, {
                              hoursKey: hoursController.text.trim().isEmpty ? '00:00' : hoursController.text.trim(),
                              'description': descController.text.trim(),
                              'workLocation': workLocation,
                            });
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('Save'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final weekEndDate = _weekStart.add(const Duration(days: 6));
    final periodText =
        '${DateFormat('dd/MM/yyyy').format(_weekStart)} – ${DateFormat('dd/MM/yyyy').format(weekEndDate)}';

    return SafeScaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AdaptiveAppBar(
        title: 'Timesheet',
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.textPrimary),
          onPressed: () => context.pop(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadTimesheet,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // My Timesheet header with status
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.access_time_filled, color: AppColors.primary, size: 22),
                            const SizedBox(width: 8),
                            Text(
                              'My Timesheet',
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: context.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        _buildStatusBadge(_status),
                      ],
                    ).animate().fadeIn().slideX(),
                    const SizedBox(height: 16),

                    // Period selector
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: context.isDark ? AppColors.grey800 : AppColors.grey50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: context.borderColor),
                      ),
                      child: Row(
                        children: [
                          Text('Timesheet Period', style: GoogleFonts.poppins(fontSize: 12, color: context.textSecondary)),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: Icon(Icons.chevron_left, size: 20, color: context.textPrimary),
                            onPressed: () => _navigateWeek(-1),
                            constraints: const BoxConstraints(),
                            padding: EdgeInsets.zero,
                          ),
                          Expanded(
                            child: Center(
                              child: Text(
                                periodText,
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: context.textPrimary,
                                ),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.chevron_right, size: 20, color: context.textPrimary),
                            onPressed: () => _navigateWeek(1),
                            constraints: const BoxConstraints(),
                            padding: EdgeInsets.zero,
                          ),
                          Icon(Icons.calendar_today, size: 16, color: context.textSecondary),
                        ],
                      ),
                    ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1),
                    const SizedBox(height: 16),

                    // Summary cards
                    Row(
                      children: [
                        Expanded(child: _buildSummaryCard('TOTAL HOURS', _totalHours, Icons.access_time, AppColors.primary)),
                        const SizedBox(width: 10),
                        Expanded(child: _buildSummaryCard('WFO HOURS', _wfoHours, Icons.business, Colors.teal)),
                        const SizedBox(width: 10),
                        Expanded(child: _buildSummaryCard('WFH HOURS', _wfhHours, Icons.home_work, AppColors.success)),
                      ],
                    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),
                    const SizedBox(height: 20),

                    // Task rows
                    if (_tasks.isEmpty)
                      _buildEmptyState()
                    else
                      ..._tasks.asMap().entries.map((entry) => _buildTaskCard(entry.key, entry.value)),

                    const SizedBox(height: 12),

                    // Totals row
                    if (_tasks.isNotEmpty) _buildTotalsRow(),

                    const SizedBox(height: 16),

                    // Action buttons
                    if (_status == 'DRAFT') ...[
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _addTask,
                              icon: const Icon(Icons.add_circle_outline, size: 18),
                              label: Text('Add Activity/Task', style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.primary,
                                side: const BorderSide(color: AppColors.primary),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: _tasks.isEmpty ? null : _submitTimesheet,
                              icon: const Icon(Icons.check_circle_outline, size: 18),
                              label: Text('Submit for Approval', style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.success,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                disabledBackgroundColor: AppColors.success.withValues(alpha: 0.3),
                              ),
                            ),
                          ),
                        ],
                      ).animate().fadeIn(delay: 400.ms),
                    ],

                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSummaryCard(String label, String value, IconData icon, Color color) {
    return GlassCard(
      blur: 12,
      opacity: 0.12,
      borderRadius: 12,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w600, color: context.textSecondary),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: color),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: context.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Icon(Icons.assignment_outlined, size: 48, color: context.textTertiary),
          const SizedBox(height: 12),
          Text(
            'No tasks added yet',
            style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w500, color: context.textSecondary),
          ),
          const SizedBox(height: 4),
          Text(
            'Tap "Add Activity/Task" to get started',
            style: GoogleFonts.poppins(fontSize: 13, color: context.textTertiary),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms);
  }

  Widget _buildTaskCard(int index, Map<String, dynamic> task) {
    final project = task['project'] as String? ?? '';
    final activity = task['activity'] as String? ?? '';
    final taskId = task['id'] as String;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: context.isDark ? AppColors.grey800.withValues(alpha: 0.5) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Task header
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 8, 0),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${index + 1}',
                    style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Project dropdown
                      _buildInlineDropdown(
                        value: _projects.contains(project) ? project : _projects[0],
                        items: _projects,
                        onChanged: _status == 'DRAFT'
                            ? (v) {
                                if (v != null && v != _projects[0]) {
                                  _updateTask(taskId, {'project': v});
                                }
                              }
                            : null,
                        color: AppColors.primary,
                        icon: Icons.folder_outlined,
                      ),
                      // Activity dropdown
                      _buildInlineDropdown(
                        value: _activities.contains(activity) ? activity : _activities[0],
                        items: _activities,
                        onChanged: _status == 'DRAFT'
                            ? (v) {
                                if (v != null && v != _activities[0]) {
                                  _updateTask(taskId, {'activity': v});
                                }
                              }
                            : null,
                        color: Colors.teal,
                        icon: Icons.task_alt,
                      ),
                    ],
                  ),
                ),
                if (_status == 'DRAFT')
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 20),
                    onPressed: () => _deleteTask(taskId),
                  ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Daily hours grid
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                // Day headers
                Row(
                  children: List.generate(7, (i) {
                    final isToday = _weekDates[i].day == DateTime.now().day &&
                        _weekDates[i].month == DateTime.now().month &&
                        _weekDates[i].year == DateTime.now().year;
                    return Expanded(
                      child: Column(
                        children: [
                          Text(
                            _dayLabels[i],
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: isToday ? AppColors.primary : context.textTertiary,
                            ),
                          ),
                          Text(
                            '${_weekDates[i].day}',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                              color: isToday ? AppColors.primary : context.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  // Total column
                ),
                const SizedBox(height: 6),

                // Hour values
                Row(
                  children: List.generate(7, (i) {
                    final key = '${_dayKeys[i]}Hours';
                    final hours = task[key] as String? ?? '00:00';
                    final isToday = _weekDates[i].day == DateTime.now().day &&
                        _weekDates[i].month == DateTime.now().month &&
                        _weekDates[i].year == DateTime.now().year;

                    return Expanded(
                      child: GestureDetector(
                        onTap: _status == 'DRAFT' ? () => _showEntryDetailsDialog(task, _dayKeys[i], i) : null,
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: isToday
                                ? AppColors.primary.withValues(alpha: 0.08)
                                : (hours != '00:00'
                                    ? AppColors.success.withValues(alpha: 0.06)
                                    : Colors.transparent),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: isToday
                                  ? AppColors.primary.withValues(alpha: 0.3)
                                  : context.borderColor.withValues(alpha: 0.5),
                            ),
                          ),
                          child: Column(
                            children: [
                              Text(
                                hours,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: hours != '00:00'
                                      ? (isToday ? AppColors.primary : context.textPrimary)
                                      : context.textTertiary,
                                ),
                              ),
                              if (_status == 'DRAFT')
                                Icon(Icons.chat_bubble_outline, size: 10, color: context.textTertiary),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),

          // Task total
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.04),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Task Total',
                  style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: context.textSecondary),
                ),
                Text(
                  task['totalHours'] as String? ?? '00:00',
                  style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: 250 + index * 100)).slideY(begin: 0.1);
  }

  Widget _buildInlineDropdown({
    required String value,
    required List<String> items,
    required void Function(String?)? onChanged,
    required Color color,
    required IconData icon,
  }) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Expanded(
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: items.contains(value) ? value : items[0],
              isDense: true,
              isExpanded: true,
              dropdownColor: context.isDark ? AppColors.grey800 : Colors.white,
              style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500, color: context.textPrimary),
              items: items
                  .map((item) => DropdownMenuItem(
                        value: item,
                        child: Text(item, overflow: TextOverflow.ellipsis),
                      ))
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTotalsRow() {
    // Compute per-day totals across all tasks
    final dayTotals = List.filled(7, 0);
    for (final task in _tasks) {
      for (int i = 0; i < 7; i++) {
        final key = '${_dayKeys[i]}Hours';
        final val = task[key] as String? ?? '00:00';
        final parts = val.split(':');
        dayTotals[i] += (int.tryParse(parts[0]) ?? 0) * 60 + (parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0);
      }
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'WEEKLY TOTALS',
            style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary),
          ),
          const SizedBox(height: 8),
          Row(
            children: List.generate(7, (i) {
              final h = dayTotals[i] ~/ 60;
              final m = dayTotals[i] % 60;
              final formatted = '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
              return Expanded(
                child: Column(
                  children: [
                    Text(_dayLabels[i], style: GoogleFonts.poppins(fontSize: 9, fontWeight: FontWeight.w600, color: context.textTertiary)),
                    const SizedBox(height: 4),
                    Text(
                      formatted,
                      style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold, color: context.textPrimary),
                    ),
                  ],
                ),
              );
            }),
          ),
          const Divider(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Grand Total', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: context.textPrimary)),
              Text(_totalHours, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 350.ms).slideY(begin: 0.1);
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}

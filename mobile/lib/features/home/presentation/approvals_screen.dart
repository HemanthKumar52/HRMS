import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme_extensions.dart';
import '../../../core/responsive.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/dynamic_island_notification.dart';
import '../../../core/widgets/safe_scaffold.dart';
import '../../requests/data/approval_repository.dart';
import '../../requests/providers/request_tracking_provider.dart';

class ApprovalsScreen extends ConsumerStatefulWidget {
  const ApprovalsScreen({super.key});

  @override
  ConsumerState<ApprovalsScreen> createState() => _ApprovalsScreenState();
}

class _ApprovalsScreenState extends ConsumerState<ApprovalsScreen> {
  String _selectedType = 'All';
  String _selectedDate = 'All';
  final Set<String> _processingIds = {};

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.3),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
            child: StatefulBuilder(
              builder: (context, setModalState) {
                return Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        context.glassOverlayStart,
                        context.glassOverlayEnd,
                      ],
                    ),
                  ),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: AppColors.grey300,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      Text('Filter Approvals', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 20),
                      Text('Request Type', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: AppColors.grey600)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: ['All', 'Leave', 'Shift'].map((type) {
                          final isSelected = _selectedType == type;
                          return ChoiceChip(
                            label: Text(type),
                            selected: isSelected,
                            selectedColor: AppColors.primary.withOpacity(0.2),
                            labelStyle: TextStyle(
                              color: isSelected ? AppColors.primary : AppColors.grey700,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                            ),
                            side: BorderSide(
                              color: isSelected ? AppColors.primary : AppColors.grey300,
                            ),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            showCheckmark: false,
                            onSelected: (val) {
                              setModalState(() => _selectedType = type);
                              setState(() {});
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),
                      Text('Time Period', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: AppColors.grey600)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: ['All', 'Today', 'This Week'].map((date) {
                          final isSelected = _selectedDate == date;
                          return ChoiceChip(
                            label: Text(date),
                            selected: isSelected,
                            selectedColor: AppColors.primary.withOpacity(0.2),
                            labelStyle: TextStyle(
                              color: isSelected ? AppColors.primary : AppColors.grey700,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                            ),
                            side: BorderSide(
                              color: isSelected ? AppColors.primary : AppColors.grey300,
                            ),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            showCheckmark: false,
                            onSelected: (val) {
                              setModalState(() => _selectedDate = date);
                              setState(() {});
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text('Apply Filters', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  List<Map<String, dynamic>> _filterRequests(List<Map<String, dynamic>> requests) {
    return requests.where((req) {
      // Type filter
      if (_selectedType != 'All' && req['_type'] != _selectedType) return false;

      // Date filter
      if (_selectedDate != 'All') {
        final createdAt = req['_createdAt'] as DateTime?;
        if (createdAt != null) {
          final now = DateTime.now();
          if (_selectedDate == 'Today') {
            if (createdAt.day != now.day || createdAt.month != now.month || createdAt.year != now.year) {
              return false;
            }
          } else if (_selectedDate == 'This Week') {
            final weekAgo = now.subtract(const Duration(days: 7));
            if (createdAt.isBefore(weekAgo)) return false;
          }
        }
      }
      return true;
    }).toList();
  }

  Future<void> _handleApprove(Map<String, dynamic> req) async {
    final id = req['id'] as String;
    final type = req['_type'] as String;

    setState(() => _processingIds.add(id));

    try {
      final repo = ref.read(approvalRepositoryProvider);
      if (type == 'Leave') {
        await repo.approveLeave(id);
      } else {
        await repo.approveShiftRequest(id);
      }

      if (mounted) {
        DynamicIslandManager().show(context, message: '$type request approved');
        ref.invalidate(pendingLeaveApprovalsProvider);
        ref.invalidate(pendingShiftRequestsProvider);
      }
    } catch (e) {
      if (mounted) {
        DynamicIslandManager().show(context, message: 'Failed to approve: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _processingIds.remove(id));
    }
  }

  Future<void> _handleReject(Map<String, dynamic> req) async {
    final id = req['id'] as String;
    final type = req['_type'] as String;

    // Show reason dialog
    final reason = await _showRejectReasonDialog();
    if (reason == null) return;

    setState(() => _processingIds.add(id));

    try {
      final repo = ref.read(approvalRepositoryProvider);
      if (type == 'Leave') {
        await repo.rejectLeave(id, reason: reason.isNotEmpty ? reason : null);
      } else {
        await repo.rejectShiftRequest(id, reason: reason.isNotEmpty ? reason : null);
      }

      if (mounted) {
        DynamicIslandManager().show(context, message: '$type request rejected', isError: true);
        ref.invalidate(pendingLeaveApprovalsProvider);
        ref.invalidate(pendingShiftRequestsProvider);
      }
    } catch (e) {
      if (mounted) {
        DynamicIslandManager().show(context, message: 'Failed to reject: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _processingIds.remove(id));
    }
  }

  Future<String?> _showRejectReasonDialog() async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Reject Reason', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Enter reason (optional)',
            hintStyle: GoogleFonts.poppins(color: AppColors.grey400),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Responsive.init(context);

    final leaveApprovalsAsync = ref.watch(pendingLeaveApprovalsProvider);
    final shiftRequestsAsync = ref.watch(pendingShiftRequestsProvider);

    return SafeScaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AdaptiveAppBar(
        title: 'Pending Approvals',
        actions: [
          IconButton(
            icon: Icon(
              Icons.filter_alt_outlined,
              color: _selectedType != 'All' || _selectedDate != 'All'
                  ? AppColors.primary
                  : AppColors.grey500,
            ),
            onPressed: _showFilterSheet,
          ),
        ],
      ),
      body: _buildBody(leaveApprovalsAsync, shiftRequestsAsync),
    );
  }

  Widget _buildBody(
    AsyncValue<List<Map<String, dynamic>>> leaveAsync,
    AsyncValue<List<Map<String, dynamic>>> shiftAsync,
  ) {
    // If both are loading
    if (leaveAsync is AsyncLoading && shiftAsync is AsyncLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Combine results
    final List<Map<String, dynamic>> allRequests = [];

    // Add leaves
    final leaves = leaveAsync.valueOrNull ?? [];
    for (final leave in leaves) {
      allRequests.add({
        ...leave,
        '_type': 'Leave',
        '_createdAt': leave['createdAt'] != null ? DateTime.tryParse(leave['createdAt'].toString()) : null,
      });
    }

    // Add shift requests
    final shifts = shiftAsync.valueOrNull ?? [];
    for (final shift in shifts) {
      allRequests.add({
        ...shift,
        '_type': 'Shift',
        '_createdAt': shift['createdAt'] != null ? DateTime.tryParse(shift['createdAt'].toString()) : null,
      });
    }

    // Sort by date, newest first
    allRequests.sort((a, b) {
      final aDate = a['_createdAt'] as DateTime?;
      final bDate = b['_createdAt'] as DateTime?;
      if (aDate == null && bDate == null) return 0;
      if (aDate == null) return 1;
      if (bDate == null) return -1;
      return bDate.compareTo(aDate);
    });

    // Apply filters
    final filtered = _filterRequests(allRequests);

    // Show error if both failed
    if (leaveAsync is AsyncError && shiftAsync is AsyncError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: AppColors.error, size: 48),
            const SizedBox(height: 12),
            Text('Failed to load approvals', style: GoogleFonts.poppins(color: AppColors.grey600)),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                ref.invalidate(pendingLeaveApprovalsProvider);
                ref.invalidate(pendingShiftRequestsProvider);
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, color: AppColors.success, size: 48),
            const SizedBox(height: 12),
            Text('No pending approvals', style: GoogleFonts.poppins(color: AppColors.grey500)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(pendingLeaveApprovalsProvider);
        ref.invalidate(pendingShiftRequestsProvider);
      },
      child: ListView.separated(
        padding: EdgeInsets.only(
          left: Responsive.horizontalPadding,
          right: Responsive.horizontalPadding,
          top: 16,
          bottom: 100,
        ),
        itemCount: filtered.length,
        separatorBuilder: (ctx, i) => const SizedBox(height: 12),
        itemBuilder: (ctx, i) => _buildApprovalCard(filtered[i], i),
      ),
    );
  }

  Widget _buildApprovalCard(Map<String, dynamic> req, int index) {
    final type = req['_type'] as String;
    final id = req['id'] as String;
    final isProcessing = _processingIds.contains(id);

    Color typeColor;
    IconData typeIcon;
    String name;
    String details;
    String dateStr;

    if (type == 'Leave') {
      typeColor = Colors.purple;
      typeIcon = Icons.calendar_today;
      final user = req['user'] as Map<String, dynamic>?;
      name = user != null ? '${user['firstName'] ?? ''} ${user['lastName'] ?? ''}'.trim() : 'Employee';
      final leaveType = (req['type'] as String?) ?? 'Leave';
      final isHalfDay = req['isHalfDay'] == true;
      final fromDate = req['fromDate'] != null ? DateTime.tryParse(req['fromDate'].toString()) : null;
      final toDate = req['toDate'] != null ? DateTime.tryParse(req['toDate'].toString()) : null;
      final days = fromDate != null && toDate != null ? toDate.difference(fromDate).inDays + 1 : 1;
      details = '$leaveType Leave${isHalfDay ? ' (Half Day)' : ' ($days Day${days > 1 ? 's' : ''})'}';
      if (req['reason'] != null && (req['reason'] as String).isNotEmpty) {
        details += ' - ${req['reason']}';
      }
    } else {
      typeColor = Colors.teal;
      typeIcon = Icons.swap_horiz;
      final user = req['user'] as Map<String, dynamic>?;
      name = user != null ? '${user['firstName'] ?? ''} ${user['lastName'] ?? ''}'.trim() : 'Employee';
      final fromShift = req['fromShift'] ?? '';
      final toShift = req['toShift'] ?? '';
      details = 'Shift change: $fromShift → $toShift';
      if (req['reason'] != null && (req['reason'] as String).isNotEmpty) {
        details += ' - ${req['reason']}';
      }
    }

    final createdAt = req['_createdAt'] as DateTime?;
    if (createdAt != null) {
      final now = DateTime.now();
      if (createdAt.day == now.day && createdAt.month == now.month && createdAt.year == now.year) {
        dateStr = 'Today';
      } else if (createdAt.day == now.day - 1 && createdAt.month == now.month && createdAt.year == now.year) {
        dateStr = 'Yesterday';
      } else {
        dateStr = DateFormat('dd MMM').format(createdAt);
      }
    } else {
      dateStr = '';
    }

    return GlassCard(
      blur: 12,
      opacity: 0.15,
      borderRadius: Responsive.cardRadius,
      padding: EdgeInsets.all(Responsive.horizontalPadding),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: typeColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(typeIcon, color: typeColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 15)),
                    Text(type, style: GoogleFonts.poppins(fontSize: 12, color: typeColor, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              Text(dateStr, style: GoogleFonts.poppins(fontSize: 12, color: AppColors.grey500)),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50.withOpacity(0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(details, style: GoogleFonts.poppins(fontSize: 14, color: context.textPrimary)),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: OutlinedButton(
                    onPressed: isProcessing ? null : () => _handleReject(req),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: isProcessing
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : Text('Reject', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: ElevatedButton(
                    onPressed: isProcessing ? null : () => _handleApprove(req),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: isProcessing
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text('Approve', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: (index * 100).ms).slideX();
  }
}

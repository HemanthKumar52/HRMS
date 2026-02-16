import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/responsive.dart';
import '../../../core/utils/extensions.dart';
import '../data/leave_model.dart';
import '../providers/leave_provider.dart';
import 'widgets/leave_balance_card.dart';
import 'widgets/leave_list_item.dart';

class LeaveScreen extends ConsumerWidget {
  const LeaveScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Responsive.init(context);
    final balanceAsync = ref.watch(leaveBalanceProvider);
    final selectedFilter = ref.watch(selectedLeaveFilterProvider);
    final historyAsync = ref.watch(
      leaveHistoryProvider(LeaveHistoryParams(status: selectedFilter)),
    );

    return SafeScaffold(
      appBar: AdaptiveAppBar(
        title: 'Leave',
        actions: [
          IconButton(
            icon: Icon(
              Icons.filter_list,
              color: selectedFilter != null
                  ? AppColors.primary
                  : AppColors.grey500,
              size: Responsive.iconSize,
            ),
            tooltip: 'Filter',
            onPressed: () => _showFilterBottomSheet(context, ref, selectedFilter),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(leaveBalanceProvider);
          ref.invalidate(leaveHistoryProvider);
        },
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(Responsive.horizontalPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Leave Balance',
                      style: context.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: Responsive.sp(16),
                      ),
                    ),
                    SizedBox(height: Responsive.value(mobile: 12.0, tablet: 16.0)),
                    balanceAsync.when(
                      data: (balances) => _buildBalanceGrid(balances),
                      loading: () => const Center(
                        child: CircularProgressIndicator(),
                      ),
                      error: (e, _) => Center(
                        child: Text('Error loading balances: $e'),
                      ),
                    ),
                    SizedBox(height: Responsive.value(mobile: 24.0, tablet: 32.0)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Leave History',
                          style: context.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: Responsive.sp(16),
                          ),
                        ),
                        if (selectedFilter != null)
                          GestureDetector(
                            onTap: () {
                              ref.read(selectedLeaveFilterProvider.notifier).state = null;
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _getFilterLabel(selectedFilter),
                                    style: GoogleFonts.poppins(
                                      fontSize: Responsive.sp(11),
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    Icons.close,
                                    size: Responsive.sp(14),
                                    color: AppColors.primary,
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            historyAsync.when(
              data: (leaves) {
                if (leaves.isEmpty) {
                  return const SliverFillRemaining(
                    child: Center(
                      child: Text('No leave requests found'),
                    ),
                  );
                }
                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: Responsive.horizontalPadding,
                        vertical: Responsive.value(mobile: 4.0, tablet: 6.0),
                      ),
                      child: LeaveListItem(
                        leave: leaves[index],
                        onTap: () => context.pushNamed(
                          'leave-detail',
                          pathParameters: {'id': leaves[index].id},
                        ),
                      ),
                    ),
                    childCount: leaves.length,
                  ),
                );
              },
              loading: () => const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => SliverFillRemaining(
                child: Center(child: Text('Error: $e')),
              ),
            ),
            // Bottom padding for glass nav bar
            SliverToBoxAdapter(
              child: SizedBox(height: Responsive.value(mobile: 80.0, tablet: 100.0)),
            ),
          ],
        ),
      ),
      // Glass FAB - icon only, positioned above nav bar
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 72),
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.9),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.4),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
              BoxShadow(
                color: Colors.white.withOpacity(0.1),
                blurRadius: 8,
                spreadRadius: -2,
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => context.pushNamed('apply-leave'),
              borderRadius: BorderRadius.circular(16),
              child: const Icon(
                Icons.add,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBalanceGrid(List<LeaveBalance> balances) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: balances.map((b) => LeaveBalanceCard(balance: b)).toList(),
    );
  }

  String _getFilterLabel(LeaveStatus? status) {
    switch (status) {
      case LeaveStatus.pending:
        return 'Requested';
      case LeaveStatus.approved:
        return 'Approved';
      case LeaveStatus.rejected:
        return 'Rejected';
      case LeaveStatus.cancelled:
        return 'Cancelled';
      default:
        return 'All';
    }
  }

  void _showFilterBottomSheet(
    BuildContext context,
    WidgetRef ref,
    LeaveStatus? currentFilter,
  ) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(Responsive.cardRadius * 1.5),
        ),
      ),
      builder: (context) {
        LeaveStatus? tempFilter = currentFilter;
        return StatefulBuilder(
          builder: (context, setModalState) => SafeArea(
            child: Padding(
              padding: EdgeInsets.all(Responsive.horizontalPadding * 1.5),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle bar
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
                  Text(
                    'Filter Leave History',
                    style: GoogleFonts.poppins(
                      fontSize: Responsive.sp(18),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: Responsive.value(mobile: 16.0, tablet: 20.0)),
                  Text(
                    'Status',
                    style: GoogleFonts.poppins(
                      fontSize: Responsive.sp(14),
                      fontWeight: FontWeight.w500,
                      color: AppColors.grey600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildFilterOption('All', null, tempFilter, (val) {
                        setModalState(() => tempFilter = val);
                      }),
                      _buildFilterOption(
                          'Requested', LeaveStatus.pending, tempFilter, (val) {
                        setModalState(() => tempFilter = val);
                      }),
                      _buildFilterOption(
                          'Approved', LeaveStatus.approved, tempFilter, (val) {
                        setModalState(() => tempFilter = val);
                      }),
                      _buildFilterOption(
                          'Rejected', LeaveStatus.rejected, tempFilter, (val) {
                        setModalState(() => tempFilter = val);
                      }),
                      _buildFilterOption(
                          'Cancelled', LeaveStatus.cancelled, tempFilter, (val) {
                        setModalState(() => tempFilter = val);
                      }),
                    ],
                  ),
                  SizedBox(height: Responsive.value(mobile: 24.0, tablet: 32.0)),
                  SizedBox(
                    width: double.infinity,
                    height: Responsive.buttonHeight,
                    child: ElevatedButton(
                      onPressed: () {
                        ref.read(selectedLeaveFilterProvider.notifier).state =
                            tempFilter;
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(Responsive.cardRadius),
                        ),
                      ),
                      child: Text(
                        'Apply Filter',
                        style: GoogleFonts.poppins(
                          fontSize: Responsive.sp(15),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                      height: Responsive.bottomSafeArea > 0 ? 0 : 16),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFilterOption(
    String label,
    LeaveStatus? value,
    LeaveStatus? groupValue,
    ValueChanged<LeaveStatus?> onSelected,
  ) {
    final isSelected = value == groupValue;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) onSelected(value);
      },
      selectedColor: AppColors.primary.withOpacity(0.2),
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primary : AppColors.grey700,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        fontSize: Responsive.sp(13),
      ),
      side: BorderSide(
        color: isSelected ? AppColors.primary : AppColors.grey300,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      showCheckmark: false,
    );
  }
}

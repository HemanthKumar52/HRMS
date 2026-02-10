import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/extensions.dart';
import '../data/leave_model.dart';
import '../providers/leave_provider.dart';
import 'widgets/leave_balance_card.dart';
import 'widgets/leave_list_item.dart';

class LeaveScreen extends ConsumerWidget {
  const LeaveScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balanceAsync = ref.watch(leaveBalanceProvider);
    final selectedFilter = ref.watch(selectedLeaveFilterProvider);
    final historyAsync = ref.watch(
      leaveHistoryProvider(LeaveHistoryParams(status: selectedFilter)),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Leave'),
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
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Leave Balance',
                      style: context.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    balanceAsync.when(
                      data: (balances) => _buildBalanceGrid(balances),
                      loading: () => const Center(
                        child: CircularProgressIndicator(),
                      ),
                      error: (e, _) => Center(
                        child: Text('Error loading balances: $e'),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Leave History',
                          style: context.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _buildFilterChip(context, ref, 'All', null, selectedFilter),
                              const SizedBox(width: 8),
                              _buildFilterChip(context, ref, 'Requested', LeaveStatus.pending, selectedFilter),
                              const SizedBox(width: 8),
                              _buildFilterChip(context, ref, 'Approved', LeaveStatus.approved, selectedFilter),
                              const SizedBox(width: 8),
                              _buildFilterChip(context, ref, 'Expired', LeaveStatus.rejected, selectedFilter),
                              const SizedBox(width: 8),
                              _buildFilterChip(context, ref, 'History', LeaveStatus.cancelled, selectedFilter),
                            ],
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
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
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.pushNamed('apply-leave'),
        icon: const Icon(CupertinoIcons.add),
        label: const Text('Apply Leave'),
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

  Widget _buildFilterChip(
    BuildContext context,
    WidgetRef ref,
    String label,
    LeaveStatus? value,
    LeaveStatus? groupValue,
  ) {
    final isSelected = value == groupValue;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (bool selected) {
        if (selected) {
          ref.read(selectedLeaveFilterProvider.notifier).state = value;
        }
      },
      selectedColor: AppColors.primary.withOpacity(0.2),
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primary : AppColors.grey700,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        fontSize: 12,
      ),
      side: BorderSide(
        color: isSelected ? AppColors.primary : AppColors.grey300,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      showCheckmark: false,
    );
  }
}

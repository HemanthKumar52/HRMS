import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme_extensions.dart';
import '../../../core/responsive.dart';
import '../../../core/widgets/glass_card.dart';
import '../../leave/providers/leave_provider.dart';
import '../../leave/presentation/widgets/leave_list_item.dart';
import '../providers/request_tracking_provider.dart';

class RequestTrackingScreen extends ConsumerStatefulWidget {
  const RequestTrackingScreen({super.key});

  @override
  ConsumerState<RequestTrackingScreen> createState() => _RequestTrackingScreenState();
}

class _RequestTrackingScreenState extends ConsumerState<RequestTrackingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        ref.read(selectedRequestTabProvider.notifier).state = _tabController.index;
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Responsive.init(context);
    final currentTab = ref.watch(selectedRequestTabProvider);

    return SafeScaffold(
      appBar: AdaptiveAppBar(
        title: 'Request Tracking',
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.grey500,
          indicatorColor: AppColors.primary,
          indicatorSize: TabBarIndicatorSize.label,
          labelStyle: GoogleFonts.poppins(
            fontSize: Responsive.sp(13),
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: GoogleFonts.poppins(
            fontSize: Responsive.sp(13),
          ),
          tabs: const [
            Tab(text: 'Tickets'),
            Tab(text: 'Leaves'),
            Tab(text: 'Claims'),
            Tab(text: 'Shifts'),
          ],
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 100),
        child: FloatingActionButton(
          onPressed: () => _onFabPressed(currentTab),
          backgroundColor: AppColors.primary,
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.add, color: Colors.white, size: 28),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _TicketsTab(),
          _LeavesTab(),
          _ClaimsTab(),
          _ShiftsTab(),
        ],
      ),
    );
  }

  void _onFabPressed(int tab) {
    switch (tab) {
      case 0:
        context.push('/create-ticket');
        break;
      case 1:
        context.pushNamed('apply-leave');
        break;
      case 2:
        context.push('/create-claim');
        break;
      case 3:
        context.push('/create-shift-request');
        break;
    }
  }
}

// ─── Tickets Tab ─────────────────────────────────────────────────
class _TicketsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ticketsAsync = ref.watch(userTicketsProvider);

    return ticketsAsync.when(
      data: (tickets) {
        if (tickets.isEmpty) {
          return const Center(child: Text('No tickets raised'));
        }
        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(userTicketsProvider),
          child: ListView.builder(
            padding: EdgeInsets.all(Responsive.horizontalPadding),
            itemCount: tickets.length + 1,
            itemBuilder: (context, index) {
              if (index == tickets.length) {
                return const SizedBox(height: 100);
              }
              final ticket = tickets[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _RequestCard(
                  id: ticket['id'] as String,
                  title: ticket['title'] as String,
                  subtitle: '${ticket['department']} • ${ticket['priority']} Priority',
                  status: ticket['status'] as String,
                  date: ticket['date'] as DateTime,
                  statusColor: _ticketStatusColor(ticket['status'] as String),
                  icon: Icons.confirmation_number_outlined,
                  iconColor: Colors.orange,
                ).animate().fadeIn(delay: (index * 80).ms).slideX(begin: 0.05),
              );
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }

  Color _ticketStatusColor(String status) {
    switch (status) {
      case 'In Progress':
        return Colors.blue;
      case 'Resolved':
        return AppColors.success;
      case 'Closed':
        return AppColors.grey500;
      default:
        return AppColors.pending;
    }
  }
}

// ─── Leaves Tab ──────────────────────────────────────────────────
class _LeavesTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(
      leaveHistoryProvider(const LeaveHistoryParams()),
    );

    return historyAsync.when(
      data: (leaves) {
        if (leaves.isEmpty) {
          return const Center(child: Text('No leave requests'));
        }
        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(leaveHistoryProvider),
          child: ListView.builder(
            padding: EdgeInsets.all(Responsive.horizontalPadding),
            itemCount: leaves.length + 1,
            itemBuilder: (context, index) {
              if (index == leaves.length) {
                return const SizedBox(height: 100);
              }
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: LeaveListItem(
                  leave: leaves[index],
                  onTap: () => context.pushNamed(
                    'leave-detail',
                    pathParameters: {'id': leaves[index].id},
                  ),
                ).animate().fadeIn(delay: (index * 80).ms).slideX(begin: 0.05),
              );
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}

// ─── Claims Tab ──────────────────────────────────────────────────
class _ClaimsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final claimsAsync = ref.watch(userClaimsProvider);

    return claimsAsync.when(
      data: (claims) {
        if (claims.isEmpty) {
          return const Center(child: Text('No expense claims'));
        }
        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(userClaimsProvider),
          child: ListView.builder(
            padding: EdgeInsets.all(Responsive.horizontalPadding),
            itemCount: claims.length + 1,
            itemBuilder: (context, index) {
              if (index == claims.length) {
                return const SizedBox(height: 100);
              }
              final claim = claims[index];
              final amount = (claim['amount'] as double).toStringAsFixed(0);
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _RequestCard(
                  id: claim['id'] as String,
                  title: claim['title'] as String,
                  subtitle: '${claim['type']} • \u20B9$amount',
                  status: claim['status'] as String,
                  date: claim['date'] as DateTime,
                  statusColor: _claimStatusColor(claim['status'] as String),
                  icon: Icons.receipt_long_outlined,
                  iconColor: Colors.purple,
                ).animate().fadeIn(delay: (index * 80).ms).slideX(begin: 0.05),
              );
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }

  Color _claimStatusColor(String status) {
    switch (status) {
      case 'Approved':
        return AppColors.success;
      case 'Rejected':
        return AppColors.error;
      default:
        return AppColors.pending;
    }
  }
}

// ─── Shifts Tab ──────────────────────────────────────────────────
class _ShiftsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shiftsAsync = ref.watch(userShiftRequestsProvider);

    return shiftsAsync.when(
      data: (shifts) {
        if (shifts.isEmpty) {
          return const Center(child: Text('No shift requests'));
        }
        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(userShiftRequestsProvider),
          child: ListView.builder(
            padding: EdgeInsets.all(Responsive.horizontalPadding),
            itemCount: shifts.length + 1,
            itemBuilder: (context, index) {
              if (index == shifts.length) {
                return const SizedBox(height: 100);
              }
              final shift = shifts[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _RequestCard(
                  id: shift['id'] as String,
                  title: shift['title'] as String,
                  subtitle: '${shift['fromShift']} \u2192 ${shift['toShift']}',
                  status: shift['status'] as String,
                  date: shift['date'] as DateTime,
                  statusColor: shift['status'] == 'Approved'
                      ? AppColors.success
                      : AppColors.pending,
                  icon: Icons.swap_horiz,
                  iconColor: Colors.teal,
                ).animate().fadeIn(delay: (index * 80).ms).slideX(begin: 0.05),
              );
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}

// ─── Shared Request Card ─────────────────────────────────────────
class _RequestCard extends StatelessWidget {
  final String id;
  final String title;
  final String subtitle;
  final String status;
  final DateTime date;
  final Color statusColor;
  final IconData icon;
  final Color iconColor;

  const _RequestCard({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.status,
    required this.date,
    required this.statusColor,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      blur: 12,
      opacity: 0.15,
      borderRadius: 16,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        status,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: context.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      id,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: context.textTertiary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      DateFormat('dd MMM yyyy').format(date),
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: context.textTertiary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

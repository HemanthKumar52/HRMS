import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/leave_model.dart';
import '../data/leave_repository.dart';

final leaveBalanceProvider =
    FutureProvider.autoDispose<List<LeaveBalance>>((ref) async {
  // Mock Data
  await Future.delayed(const Duration(milliseconds: 500));
  return [
    const LeaveBalance(type: LeaveType.casual, used: 5, total: 12, available: 7), // Changed 'annual' to 'casual' as it seems 'annual' is not in enum or imported wrong
    const LeaveBalance(type: LeaveType.sick, used: 2, total: 10, available: 8),
    const LeaveBalance(type: LeaveType.casual, used: 3, total: 8, available: 5),
  ];
});

final leaveHistoryProvider = FutureProvider.autoDispose
    .family<List<LeaveModel>, LeaveHistoryParams>((ref, params) async {
  // Mock Data
  await Future.delayed(const Duration(milliseconds: 800));
  return [
    LeaveModel(
      id: '1',
      userId: 'mock-user',
      type: LeaveType.casual, // Changed annual to casual
      fromDate: DateTime.now().subtract(const Duration(days: 5)),
      toDate: DateTime.now().subtract(const Duration(days: 4)),
      status: LeaveStatus.approved,
      reason: 'Vacation',
      createdAt: DateTime.now().subtract(const Duration(days: 10)),
    ),
    LeaveModel(
      id: '2',
      userId: 'mock-user',
      type: LeaveType.sick,
      fromDate: DateTime.now().subtract(const Duration(days: 20)),
      toDate: DateTime.now().subtract(const Duration(days: 19)),
      status: LeaveStatus.rejected,
      reason: 'Fever',
      rejectReason: 'Urgent meeting',
      createdAt: DateTime.now().subtract(const Duration(days: 22)),
    ),
  ];
});

class LeaveHistoryParams {
  final LeaveStatus? status;
  final LeaveType? type;
  final int page;
  final int limit;

  const LeaveHistoryParams({
    this.status,
    this.type,
    this.page = 1,
    this.limit = 20,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LeaveHistoryParams &&
          status == other.status &&
          type == other.type &&
          page == other.page &&
          limit == other.limit;

  @override
  int get hashCode => Object.hash(status, type, page, limit);
}

class ApplyLeaveNotifier extends StateNotifier<AsyncValue<void>> {
  final LeaveRepository _repository;

  ApplyLeaveNotifier(this._repository) : super(const AsyncValue.data(null));

  Future<void> applyLeave({
    required LeaveType type,
    required DateTime fromDate,
    required DateTime toDate,
    bool isHalfDay = false,
    HalfDayType? halfDayType,
    String? reason,
  }) async {
    state = const AsyncValue.loading();
    await Future.delayed(const Duration(seconds: 1)); // Mock Network Delay
    state = const AsyncValue.data(null);
  }

  Future<void> cancelLeave(String id) async {
    state = const AsyncValue.loading();
    await Future.delayed(const Duration(seconds: 1));
    state = const AsyncValue.data(null);
  }
}

final applyLeaveProvider =
    StateNotifierProvider<ApplyLeaveNotifier, AsyncValue<void>>((ref) {
  final repository = ref.watch(leaveRepositoryProvider);
  return ApplyLeaveNotifier(repository);
});

final selectedLeaveFilterProvider = StateProvider<LeaveStatus?>((ref) => null);

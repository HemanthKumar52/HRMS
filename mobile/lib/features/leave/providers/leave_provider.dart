import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/leave_model.dart';
import '../data/leave_repository.dart';

final leaveBalanceProvider =
    FutureProvider.autoDispose<List<LeaveBalance>>((ref) async {
  // Mock Data
  await Future.delayed(const Duration(milliseconds: 500));
  return [
    const LeaveBalance(type: LeaveType.casual, used: 5, total: 12, available: 7),
    const LeaveBalance(type: LeaveType.sick, used: 2, total: 10, available: 8),
    const LeaveBalance(type: LeaveType.earned, used: 3, total: 8, available: 5),
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
      type: LeaveType.casual,
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

final leaveDetailProvider = FutureProvider.autoDispose
    .family<LeaveModel, String>((ref, leaveId) async {
  // Mock Data - find from history or return a mock pending leave
  await Future.delayed(const Duration(milliseconds: 500));
  final history = await ref.watch(leaveHistoryProvider(const LeaveHistoryParams()).future);
  final match = history.where((l) => l.id == leaveId).firstOrNull;
  if (match != null) return match;

  return LeaveModel(
    id: leaveId,
    userId: 'mock-user',
    type: LeaveType.casual,
    fromDate: DateTime.now(),
    toDate: DateTime.now(),
    status: LeaveStatus.pending,
    reason: 'Leave request',
    createdAt: DateTime.now(),
  );
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

  Future<LeaveModel> applyLeave({
    required LeaveType type,
    required DateTime fromDate,
    required DateTime toDate,
    bool isHalfDay = false,
    HalfDayType? halfDayType,
    required String reason,
  }) async {
    state = const AsyncValue.loading();
    await Future.delayed(const Duration(seconds: 1)); // Mock Network Delay

    // Return a mock LeaveModel for tracking
    final mockLeave = LeaveModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: 'mock-user',
      type: type,
      status: LeaveStatus.pending,
      fromDate: fromDate,
      toDate: toDate,
      isHalfDay: isHalfDay,
      halfDayType: halfDayType,
      reason: reason,
      createdAt: DateTime.now(),
    );

    state = const AsyncValue.data(null);
    return mockLeave;
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

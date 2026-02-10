import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/services/connectivity_service.dart';
import '../../../core/services/offline_queue_service.dart';
import '../../../core/services/sync_service.dart';
import '../data/attendance_model.dart';
import '../data/attendance_repository.dart';

final todayStatusProvider =
    FutureProvider.autoDispose<TodayStatusModel>((ref) async {
  final repository = ref.watch(attendanceRepositoryProvider);
  return repository.getTodayStatus();
});

final attendanceSummaryProvider = FutureProvider.autoDispose
    .family<AttendanceSummaryModel, String>((ref, period) async {
  final repository = ref.watch(attendanceRepositoryProvider);
  return repository.getSummary(period: period);
});

final selectedPeriodProvider = StateProvider<String>((ref) => 'week');

class PunchNotifier extends StateNotifier<AsyncValue<PunchResult>> {
  final AttendanceRepository _repository;
  final OfflineQueueService _queueService;
  final ConnectivityService _connectivityService;
  final SyncService _syncService;

  PunchNotifier(
    this._repository,
    this._queueService,
    this._connectivityService,
    this._syncService,
  ) : super(const AsyncValue.data(PunchResult(success: true, isOffline: false)));

  Future<void> punch({
    PunchType? punchType,
    double? latitude,
    double? longitude,
    String? address,
    String? workMode,
  }) async {
    state = const AsyncValue.loading();

    try {
      // 1. Check Offline Mode (optional) or just Try API
      // For "dynamic" real-time, we try API first.
      
      await _repository.punch(
        punchType: punchType,
        latitude: latitude,
        longitude: longitude,
        address: address,
        isOffline: false,
        timestamp: DateTime.now(),
      );

      state = const AsyncValue.data(
        PunchResult(
          success: true,
          isOffline: false,
          message: 'Punch recorded successfully',
        ),
      );
    } catch (e, st) {
      // If error is network related, maybe save offline?
      // For now, reporting error to UI so user sees "dynamic" failure if backend is down.
      state = AsyncValue.error(e, st);
      
      // If you want offline fallback:
      // _savePunchOffline(...)
    }
  }

  Future<void> _savePunchOffline({
    PunchType? punchType,
    double? latitude,
    double? longitude,
    String? address,
  }) async {
    final punch = OfflinePunch(
      id: const Uuid().v4(),
      punchType: punchType == PunchType.clockIn ? 'CLOCK_IN' : 'CLOCK_OUT',
      timestamp: DateTime.now(),
      latitude: latitude,
      longitude: longitude,
      address: address,
    );

    await _queueService.addPunch(punch);
  }

  Future<void> syncOfflinePunches() async {
    await _syncService.syncOfflinePunches();
  }
}

class PunchResult {
  final bool success;
  final bool isOffline;
  final String? message;

  const PunchResult({
    required this.success,
    required this.isOffline,
    this.message,
  });
}

final punchProvider =
    StateNotifierProvider<PunchNotifier, AsyncValue<PunchResult>>((ref) {
  final repository = ref.watch(attendanceRepositoryProvider);
  final queueService = ref.watch(offlineQueueServiceProvider);
  final connectivityService = ref.watch(connectivityServiceProvider);
  final syncService = ref.watch(syncServiceProvider);
  return PunchNotifier(repository, queueService, connectivityService, syncService);
});

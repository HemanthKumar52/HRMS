import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/api_constants.dart';
import 'connectivity_service.dart';
import 'offline_queue_service.dart';

class SyncService {
  final OfflineQueueService _queueService = OfflineQueueService();
  final ConnectivityService _connectivityService = ConnectivityService();

  static const int maxRetries = 3;
  bool _isSyncing = false;
  Timer? _periodicTimer;
  StreamSubscription? _connectivitySubscription;

  Future<void> init() async {
    await _queueService.init();

    // Listen for connectivity changes and sync when online
    _connectivitySubscription = _connectivityService.statusStream.listen((status) {
      if (status == NetworkStatus.online) {
        syncOfflinePunches();
      }
    });
  }

  Future<void> schedulePeriodicSync() async {
    // Simple periodic sync every 15 minutes while app is running
    _periodicTimer?.cancel();
    _periodicTimer = Timer.periodic(const Duration(minutes: 15), (_) {
      syncOfflinePunches();
    });
  }

  Future<SyncResult> syncOfflinePunches() async {
    if (_isSyncing) {
      return SyncResult(synced: 0, failed: 0, message: 'Sync already in progress');
    }

    final isOnline = await _connectivityService.isOnline();
    if (!isOnline) {
      return SyncResult(synced: 0, failed: 0, message: 'No internet connection');
    }

    _isSyncing = true;
    int syncedCount = 0;
    int failedCount = 0;

    try {
      final pendingPunches = await _queueService.getPendingPunches();

      if (pendingPunches.isEmpty) {
        return SyncResult(synced: 0, failed: 0, message: 'No pending punches');
      }

      final dio = Dio(BaseOptions(baseUrl: ApiConstants.baseUrl));

      for (final punch in pendingPunches) {
        if (punch.retryCount >= maxRetries) {
          await _queueService.removePunch(punch.id);
          failedCount++;
          continue;
        }

        try {
          await dio.post(
            ApiConstants.attendancePunch,
            data: punch.toApiJson(),
          );

          await _queueService.removePunch(punch.id);
          syncedCount++;
        } catch (e) {
          await _queueService.updateRetryCount(punch.id);
          failedCount++;
          debugPrint('Failed to sync punch ${punch.id}: $e');
        }
      }

      return SyncResult(
        synced: syncedCount,
        failed: failedCount,
        message: 'Synced $syncedCount punches, $failedCount failed',
      );
    } finally {
      _isSyncing = false;
    }
  }

  void dispose() {
    _periodicTimer?.cancel();
    _connectivitySubscription?.cancel();
  }
}

class SyncResult {
  final int synced;
  final int failed;
  final String message;

  SyncResult({
    required this.synced,
    required this.failed,
    required this.message,
  });
}

final syncServiceProvider = Provider<SyncService>((ref) {
  final service = SyncService();
  ref.onDispose(() => service.dispose());
  return service;
});

class SyncNotifier extends StateNotifier<AsyncValue<SyncResult?>> {
  final SyncService _syncService;

  SyncNotifier(this._syncService) : super(const AsyncValue.data(null));

  Future<void> syncNow() async {
    state = const AsyncValue.loading();
    try {
      final result = await _syncService.syncOfflinePunches();
      state = AsyncValue.data(result);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final syncNotifierProvider =
    StateNotifierProvider<SyncNotifier, AsyncValue<SyncResult?>>((ref) {
  final syncService = ref.watch(syncServiceProvider);
  return SyncNotifier(syncService);
});

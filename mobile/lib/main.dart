import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:permission_handler/permission_handler.dart';

import 'app.dart';
import 'core/services/offline_queue_service.dart';
import 'core/services/push_notification_service.dart';
import 'core/services/sync_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Request camera permission for face verification
  await Permission.camera.request();

  // Initialize Hive for offline storage
  await Hive.initFlutter();

  // Initialize offline queue service
  final offlineQueueService = OfflineQueueService();
  await offlineQueueService.init();

  // Initialize push notification service
  final pushNotificationService = PushNotificationService();
  try {
    await pushNotificationService.init();
  } catch (e) {
    debugPrint('Push notification initialization failed: $e');
    debugPrint('App will continue without push notifications');
  }

  // Initialize sync service and schedule background sync
  final syncService = SyncService();
  try {
    await syncService.init();
    await syncService.schedulePeriodicSync();
  } catch (e) {
    debugPrint('Sync service initialization failed: $e');
  }

  runApp(
    ProviderScope(
      overrides: [
        offlineQueueServiceProvider.overrideWithValue(offlineQueueService),
        pushNotificationServiceProvider.overrideWithValue(pushNotificationService),
        syncServiceProvider.overrideWithValue(syncService),
      ],
      child: const HRMSApp(),
    ),
  );
}

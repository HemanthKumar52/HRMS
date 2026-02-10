import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Push notification service stub.
///
/// This is a simplified implementation that works without Firebase configuration.
/// For production use with real push notifications:
/// 1. Add firebase_core and firebase_messaging to pubspec.yaml
/// 2. Configure Firebase in your project (google-services.json / GoogleService-Info.plist)
/// 3. Replace this stub with the full Firebase implementation
class PushNotificationService {
  final StreamController<NotificationPayload> _notificationController =
      StreamController<NotificationPayload>.broadcast();

  Stream<NotificationPayload> get notificationStream =>
      _notificationController.stream;

  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  Future<void> init() async {
    // Stub implementation - no actual push notification setup
    debugPrint('Push notification service initialized (stub mode)');
    debugPrint('For production push notifications, configure Firebase');
  }

  /// Simulate receiving a notification (useful for testing)
  void simulateNotification(NotificationPayload payload) {
    _notificationController.add(payload);
  }

  Future<void> subscribeToTopic(String topic) async {
    debugPrint('Would subscribe to topic: $topic');
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    debugPrint('Would unsubscribe from topic: $topic');
  }

  void dispose() {
    _notificationController.close();
  }
}

class NotificationPayload {
  final String type;
  final String? entityId;
  final Map<String, dynamic> data;

  NotificationPayload({
    required this.type,
    this.entityId,
    this.data = const {},
  });

  String? get deepLink {
    switch (type.toUpperCase()) {
      case 'LEAVE_REQUEST':
      case 'LEAVE_APPROVED':
      case 'LEAVE_REJECTED':
        return entityId != null ? '/leave/$entityId' : '/leave';
      case 'ATTENDANCE':
        return '/attendance';
      default:
        return '/notifications';
    }
  }
}

final pushNotificationServiceProvider = Provider<PushNotificationService>((ref) {
  final service = PushNotificationService();
  ref.onDispose(() => service.dispose());
  return service;
});

final notificationPayloadProvider = StreamProvider<NotificationPayload>((ref) {
  final service = ref.watch(pushNotificationServiceProvider);
  return service.notificationStream;
});

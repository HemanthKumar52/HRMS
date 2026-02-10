import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/notification_model.dart';
import '../data/notification_repository.dart';

final notificationsProvider =
    FutureProvider.autoDispose<List<NotificationModel>>((ref) async {
  // Temporary: Disable backend call until auth is fixed to prevent 401 error
  return []; 
  
  /* 
  // Restore this code when backend auth is verified
  final repository = ref.watch(notificationRepositoryProvider);
  final result = await repository.getNotifications();
  return result['notifications'] as List<NotificationModel>;
  */
});

final unreadCountProvider = FutureProvider.autoDispose<int>((ref) async {
  // Mock Data
  await Future.delayed(const Duration(milliseconds: 300));
  return 2; // Simulating 2 unread notifications
});

class NotificationNotifier extends StateNotifier<AsyncValue<void>> {
  final NotificationRepository _repository;

  NotificationNotifier(this._repository) : super(const AsyncValue.data(null));

  Future<void> markAsRead(String id) async {
    try {
      await _repository.markAsRead(id);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> markAllAsRead() async {
    state = const AsyncValue.loading();
    try {
      await _repository.markAllAsRead();
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final notificationActionsProvider =
    StateNotifierProvider<NotificationNotifier, AsyncValue<void>>((ref) {
  final repository = ref.watch(notificationRepositoryProvider);
  return NotificationNotifier(repository);
});

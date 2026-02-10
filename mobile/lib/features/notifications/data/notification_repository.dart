import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import 'notification_model.dart';

class NotificationRepository {
  final Dio _dio;

  NotificationRepository(this._dio);

  Future<Map<String, dynamic>> getNotifications({
    bool? isRead,
    int page = 1,
    int limit = 20,
  }) async {
    final response = await _dio.get(
      ApiConstants.notifications,
      queryParameters: {
        if (isRead != null) 'isRead': isRead,
        'page': page,
        'limit': limit,
      },
    );

    final data = response.data['data'];
    final notifications = (data['notifications'] as List)
        .map((n) => NotificationModel.fromJson(n))
        .toList();

    return {
      'notifications': notifications,
      'unreadCount': data['unreadCount'] ?? 0,
    };
  }

  Future<int> getUnreadCount() async {
    final response = await _dio.get(ApiConstants.notificationsUnreadCount);
    return response.data['data']['unreadCount'] ?? 0;
  }

  Future<NotificationModel> markAsRead(String id) async {
    final response = await _dio.patch(ApiConstants.notificationRead(id));
    return NotificationModel.fromJson(response.data['data']);
  }

  Future<void> markAllAsRead() async {
    await _dio.patch(ApiConstants.notificationsReadAll);
  }
}

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return NotificationRepository(dio);
});

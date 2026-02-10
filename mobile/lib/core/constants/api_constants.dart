import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConstants {
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:3000/api/v1';
    }

    if (Platform.isAndroid) {
      // Android emulator uses 10.0.2.2 to access host machine's localhost
      return 'http://10.0.2.2:3000/api/v1';
    }

    // iOS simulator, Windows, macOS, Linux can use localhost
    return 'http://localhost:3000/api/v1';
  }

  // Auth
  static const String login = '/auth/login';
  static const String refresh = '/auth/refresh';
  static const String logout = '/auth/logout';
  static const String me = '/auth/me';

  // Leave
  static const String leaveApply = '/leave/apply';
  static const String leaveBalance = '/leave/balance';
  static const String leaveHistory = '/leave/history';
  static String leaveCancel(String id) => '/leave/$id/cancel';
  static String leaveApprove(String id) => '/leave/$id/approve';
  static String leaveReject(String id) => '/leave/$id/reject';
  static const String leavePendingApprovals = '/leave/pending-approvals';

  // Attendance
  static const String attendancePunch = '/attendance/punch';
  static const String attendanceToday = '/attendance/today';
  static const String attendanceSummary = '/attendance/summary';
  static const String attendanceHistory = '/attendance/history';
  static const String attendanceSync = '/attendance/sync';

  // Users
  static const String users = '/users';
  static String userProfile(String id) => '/users/$id';
  static String userTeam(String id) => '/users/$id/team';

  // Notifications
  static const String notifications = '/notifications';
  static const String notificationsUnreadCount = '/notifications/unread-count';
  static String notificationRead(String id) => '/notifications/$id/read';
  static const String notificationsReadAll = '/notifications/read-all';

  // Tickets
  static const String tickets = '/tickets';

  // Claims
  static const String claims = '/claims';
}

import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConstants {
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:3000/api/v1';
    }

    if (Platform.isAndroid) {
      // Use local IP for physical device testing
      return 'http://192.168.1.4:3000/api/v1';
    }

    // iOS simulator, Windows, macOS, Linux can use localhost
    return 'http://localhost:3000/api/v1';
  }

  /// Blink detection Flask server (liveness verification)
  static String get blinkServerUrl {
    if (kIsWeb) {
      return 'http://localhost:5000';
    }

    if (Platform.isAndroid) {
      return 'http://192.168.1.4:5000';
    }

    return 'http://localhost:5000';
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
  static String leaveDetail(String id) => '/leave/$id';
  static const String leavePendingApprovals = '/leave/pending-approvals';

  // Attendance
  static const String attendancePunch = '/attendance/punch';
  static const String attendanceToday = '/attendance/today';
  static const String attendanceSummary = '/attendance/summary';
  static const String attendanceHistory = '/attendance/history';
  static const String attendanceSync = '/attendance/sync';

  // Users
  static const String users = '/users';
  static const String userFacePhoto = '/users/me/face-photo';
  static const String userFacePhotos = '/users/face-photos';
  static String userProfile(String id) => '/users/$id';
  static String userTeam(String id) => '/users/$id/team';

  // Timesheet
  static const String timesheetCurrent = '/timesheet/current';
  static const String timesheetHistory = '/timesheet/history';
  static String timesheetSubmit(String id) => '/timesheet/$id/submit';
  static String timesheetDetail(String id) => '/timesheet/$id/detail';
  static String timesheetAddTask(String id) => '/timesheet/$id/tasks';
  static String timesheetUpdateTask(String taskId) => '/timesheet/tasks/$taskId';
  static String timesheetDeleteTask(String taskId) => '/timesheet/tasks/$taskId';

  // Shift Requests
  static const String shiftRequests = '/shift-requests';
  static String shiftRequestApprove(String id) => '/shift-requests/$id/approve';
  static String shiftRequestReject(String id) => '/shift-requests/$id/reject';
  static String shiftRequestCancel(String id) => '/shift-requests/$id/cancel';

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

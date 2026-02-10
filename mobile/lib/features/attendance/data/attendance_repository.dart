import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import 'attendance_model.dart';

class AttendanceRepository {
  final Dio _dio;

  AttendanceRepository(this._dio);

  Future<Map<String, dynamic>> punch({
    PunchType? punchType,
    double? latitude,
    double? longitude,
    String? address,
    String? deviceId,
    bool isOffline = false,
    DateTime? timestamp,
  }) async {
    final response = await _dio.post(
      ApiConstants.attendancePunch,
      data: {
        if (punchType != null)
          'punchType':
              punchType == PunchType.clockIn ? 'CLOCK_IN' : 'CLOCK_OUT',
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        if (address != null) 'address': address,
        if (deviceId != null) 'deviceId': deviceId,
        'isOffline': isOffline,
        if (timestamp != null) 'timestamp': timestamp.toIso8601String(),
      },
    );

    return response.data['data'];
  }

  Future<TodayStatusModel> getTodayStatus() async {
    final response = await _dio.get(ApiConstants.attendanceToday);
    return TodayStatusModel.fromJson(response.data['data']);
  }

  Future<AttendanceSummaryModel> getSummary({String period = 'week'}) async {
    final response = await _dio.get(
      ApiConstants.attendanceSummary,
      queryParameters: {'period': period},
    );
    return AttendanceSummaryModel.fromJson(response.data['data']);
  }

  Future<List<AttendanceModel>> getHistory({
    String? startDate,
    String? endDate,
    int page = 1,
    int limit = 20,
  }) async {
    final response = await _dio.get(
      ApiConstants.attendanceHistory,
      queryParameters: {
        if (startDate != null) 'startDate': startDate,
        if (endDate != null) 'endDate': endDate,
        'page': page,
        'limit': limit,
      },
    );

    final punches = response.data['data']['punches'] as List;
    return punches.map((p) => AttendanceModel.fromJson(p)).toList();
  }
}

final attendanceRepositoryProvider = Provider<AttendanceRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return AttendanceRepository(dio);
});

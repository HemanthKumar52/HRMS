import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import 'leave_model.dart';

class LeaveRepository {
  final Dio _dio;

  LeaveRepository(this._dio);

  Future<LeaveModel> applyLeave({
    required LeaveType type,
    required DateTime fromDate,
    required DateTime toDate,
    bool isHalfDay = false,
    HalfDayType? halfDayType,
    required String reason,
  }) async {
    final response = await _dio.post(
      ApiConstants.leaveApply,
      data: {
        'type': type.name.toUpperCase(),
        'fromDate': fromDate.toIso8601String(),
        'toDate': toDate.toIso8601String(),
        'isHalfDay': isHalfDay,
        if (halfDayType != null)
          'halfDayType':
              halfDayType == HalfDayType.firstHalf ? 'FIRST_HALF' : 'SECOND_HALF',
        'reason': reason,
      },
    );

    return LeaveModel.fromJson(response.data['data']);
  }

  Future<LeaveModel> getLeaveById(String id) async {
    final response = await _dio.get(ApiConstants.leaveDetail(id));
    return LeaveModel.fromJson(response.data);
  }

  Future<List<LeaveBalance>> getBalance() async {
    final response = await _dio.get(ApiConstants.leaveBalance);
    final balances = response.data['data']['balances'] as List;
    return balances.map((b) => LeaveBalance.fromJson(b)).toList();
  }

  Future<List<LeaveModel>> getHistory({
    LeaveStatus? status,
    LeaveType? type,
    int page = 1,
    int limit = 20,
  }) async {
    final response = await _dio.get(
      ApiConstants.leaveHistory,
      queryParameters: {
        if (status != null) 'status': status.name.toUpperCase(),
        if (type != null) 'type': type.name.toUpperCase(),
        'page': page,
        'limit': limit,
      },
    );

    final leaves = response.data['data']['leaves'] as List;
    return leaves.map((l) => LeaveModel.fromJson(l)).toList();
  }

  Future<LeaveModel> cancelLeave(String id) async {
    final response = await _dio.patch(ApiConstants.leaveCancel(id));
    return LeaveModel.fromJson(response.data['data']);
  }

  Future<LeaveModel> approveLeave(String id) async {
    final response = await _dio.post(ApiConstants.leaveApprove(id));
    return LeaveModel.fromJson(response.data['data']);
  }

  Future<LeaveModel> rejectLeave(String id, {String? reason}) async {
    final response = await _dio.post(
      ApiConstants.leaveReject(id),
      data: {if (reason != null) 'reason': reason},
    );
    return LeaveModel.fromJson(response.data['data']);
  }
}

final leaveRepositoryProvider = Provider<LeaveRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return LeaveRepository(dio);
});

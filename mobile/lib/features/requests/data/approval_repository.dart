import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';

class ApprovalRepository {
  final Dio _dio;

  ApprovalRepository(this._dio);

  Future<List<Map<String, dynamic>>> getPendingShiftRequests() async {
    final response = await _dio.get('${ApiConstants.shiftRequests}/pending');
    final list = response.data is List ? response.data as List : (response.data['data'] as List?) ?? [];
    return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<void> approveShiftRequest(String id) async {
    await _dio.patch(ApiConstants.shiftRequestApprove(id));
  }

  Future<void> rejectShiftRequest(String id, {String? reason}) async {
    await _dio.patch(
      ApiConstants.shiftRequestReject(id),
      data: {if (reason != null) 'reason': reason},
    );
  }

  Future<List<Map<String, dynamic>>> getPendingLeaveApprovals() async {
    final response = await _dio.get(ApiConstants.leavePendingApprovals);
    final list = response.data is List ? response.data as List : (response.data['data'] as List?) ?? [];
    return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<void> approveLeave(String id) async {
    await _dio.post(ApiConstants.leaveApprove(id));
  }

  Future<void> rejectLeave(String id, {String? reason}) async {
    await _dio.post(
      ApiConstants.leaveReject(id),
      data: {if (reason != null) 'reason': reason},
    );
  }
}

final approvalRepositoryProvider = Provider<ApprovalRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return ApprovalRepository(dio);
});

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';

class ClaimRepository {
  final Dio _dio;

  ClaimRepository(this._dio);

  Future<void> createClaim(Map<String, dynamic> data) async {
    await _dio.post(ApiConstants.claims, data: data);
  }
}

final claimRepositoryProvider = Provider<ClaimRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return ClaimRepository(dio);
});

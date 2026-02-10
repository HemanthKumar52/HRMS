import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../shared/models/user_model.dart';

class DirectoryRepository {
  final Dio _dio;

  DirectoryRepository(this._dio);

  Future<List<UserModel>> getUsers({
    String? search,
    String? department,
    int page = 1,
    int limit = 20,
  }) async {
    final response = await _dio.get(
      ApiConstants.users,
      queryParameters: {
        if (search != null && search.isNotEmpty) 'search': search,
        if (department != null) 'department': department,
        'page': page,
        'limit': limit,
      },
    );

    final users = response.data['data']['users'] as List;
    return users.map((u) => UserModel.fromJson(u)).toList();
  }

  Future<UserModel> getUserProfile(String id) async {
    final response = await _dio.get(ApiConstants.userProfile(id));
    return UserModel.fromJson(response.data['data']);
  }

  Future<List<UserModel>> getUserTeam(String id) async {
    final response = await _dio.get(ApiConstants.userTeam(id));
    final reports = response.data['data']['reports'] as List;
    return reports.map((u) => UserModel.fromJson(u)).toList();
  }
}

final directoryRepositoryProvider = Provider<DirectoryRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return DirectoryRepository(dio);
});

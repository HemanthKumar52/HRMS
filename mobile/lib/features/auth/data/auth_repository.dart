import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../shared/models/user_model.dart';

class AuthRepository {
  final Dio _dio;
  final FlutterSecureStorage _storage;

  AuthRepository(this._dio, this._storage);

  Future<UserModel> login(String email, String password) async {
    final response = await _dio.post(
      ApiConstants.login,
      data: {
        'email': email,
        'password': password,
      },
    );

    final data = response.data['data'];

    await _storage.write(
      key: AppConstants.accessTokenKey,
      value: data['accessToken'],
    );
    await _storage.write(
      key: AppConstants.refreshTokenKey,
      value: data['refreshToken'],
    );
    await _storage.write(
      key: AppConstants.userKey,
      value: jsonEncode(data['user']),
    );

    return UserModel.fromJson(data['user']);
  }

  Future<UserModel?> getCurrentUser() async {
    final userJson = await _storage.read(key: AppConstants.userKey);
    if (userJson != null) {
      return UserModel.fromJson(jsonDecode(userJson));
    }

    final accessToken = await _storage.read(key: AppConstants.accessTokenKey);
    if (accessToken == null) {
      return null;
    }

    try {
      final response = await _dio.get(
        ApiConstants.me,
        options: Options(
          headers: {'Authorization': 'Bearer $accessToken'},
        ),
      );

      final user = UserModel.fromJson(response.data['data']);
      await _storage.write(
        key: AppConstants.userKey,
        value: jsonEncode(response.data['data']),
      );

      return user;
    } catch (e) {
      return null;
    }
  }

  Future<void> logout() async {
    try {
      final refreshToken = await _storage.read(key: AppConstants.refreshTokenKey);
      if (refreshToken != null) {
        await _dio.post(
          ApiConstants.logout,
          data: {'refreshToken': refreshToken},
        );
      }
    } catch (_) {}

    await _storage.deleteAll();
  }

  Future<bool> isLoggedIn() async {
    final accessToken = await _storage.read(key: AppConstants.accessTokenKey);
    return accessToken != null;
  }

  Future<UserModel> getProfile() async {
    final response = await _dio.get(ApiConstants.me);
    final user = UserModel.fromJson(response.data['data']);

    await _storage.write(
      key: AppConstants.userKey,
      value: jsonEncode(response.data['data']),
    );

    return user;
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final dio = ref.watch(dioProvider);
  final storage = ref.watch(secureStorageProvider);
  return AuthRepository(dio, storage);
});

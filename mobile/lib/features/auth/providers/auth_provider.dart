import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../shared/models/user_model.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/api_constants.dart';
import 'package:dio/dio.dart';

class AuthNotifier extends StateNotifier<AsyncValue<UserModel?>> {
  final FlutterSecureStorage _storage;
  final Dio _dio;

  AuthNotifier(this._storage)
      : _dio = Dio(BaseOptions(
          baseUrl: ApiConstants.baseUrl,
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        )),
        super(const AsyncValue.data(null)) {
    debugPrint('[Auth] Base URL: ${ApiConstants.baseUrl}');
    _loadUser();
  }

  Future<void> _loadUser() async {
    try {
      final token = await _storage.read(key: AppConstants.accessTokenKey);
      if (token != null) {
        _dio.options.headers['Authorization'] = 'Bearer $token';
        final response = await _dio.get('/auth/me');

        if (response.statusCode == 200) {
          final userData = response.data['data'];
          final user = UserModel.fromJson(userData);
          state = AsyncValue.data(user);
          debugPrint('[Auth] Restored session for ${user.email}');
        }
      }
    } catch (e) {
      debugPrint('[Auth] _loadUser failed: $e');
      state = const AsyncValue.data(null);
    }
  }

  Future<void> login(String email, {String password = 'password123', String? name, String? mockRole}) async {
    state = const AsyncValue.loading();
    debugPrint('[Auth] Logging in $email to ${_dio.options.baseUrl}');

    if (mockRole != null) {
      _dio.options.headers['x-mock-role'] = mockRole;
    }

    try {
      final response = await _dio.post('/auth/login', data: {
        'email': email,
        'password': password,
      });

      debugPrint('[Auth] Response status: ${response.statusCode}');
      debugPrint('[Auth] Response data type: ${response.data.runtimeType}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = response.data['data'];
        final userData = responseData['user'];
        final accessToken = responseData['accessToken'];
        final refreshToken = responseData['refreshToken'];

        await _storage.write(key: AppConstants.accessTokenKey, value: accessToken);
        if (refreshToken != null) {
          await _storage.write(key: AppConstants.refreshTokenKey, value: refreshToken);
        }

        final user = UserModel(
          id: userData['id'],
          email: userData['email'],
          firstName: userData['firstName'],
          lastName: userData['lastName'],
          role: mockRole ?? userData['role'],
        );

        state = AsyncValue.data(user);
        debugPrint('[Auth] Login success: ${user.email} (${user.role})');
      } else {
        debugPrint('[Auth] Unexpected status: ${response.statusCode}');
        state = AsyncValue.error('Login failed: ${response.statusMessage}', StackTrace.current);
      }
    } on DioException catch (e, st) {
      final errorMessage = e.response?.data is Map
          ? (e.response!.data['message'] ?? 'Login failed').toString()
          : 'Login failed: ${e.type.name} - ${e.message ?? "connection error"}';
      debugPrint('[Auth] DioException: ${e.type} | ${e.message} | URL: ${e.requestOptions.uri}');
      state = AsyncValue.error(errorMessage, st);
    } catch (e, st) {
      debugPrint('[Auth] Unexpected error: $e');
      state = AsyncValue.error('Login failed: $e', st);
    }
  }

  Future<void> logout() async {
    await _storage.deleteAll();
    state = const AsyncValue.data(null);
  }
}

final authStateProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<UserModel?>>((ref) {
  final storage = ref.watch(secureStorageProvider);
  return AuthNotifier(storage);
});

final currentUserProvider = Provider<UserModel?>((ref) {
  return ref.watch(authStateProvider).value;
});

final isLoggedInProvider = Provider<bool>((ref) {
  return ref.watch(currentUserProvider) != null;
});


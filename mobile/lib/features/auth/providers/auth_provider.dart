import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../shared/models/user_model.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/network/api_client.dart'; // Import secureStorageProvider

import 'package:dio/dio.dart';
import 'dart:io';

class AuthNotifier extends StateNotifier<AsyncValue<UserModel?>> {
  final FlutterSecureStorage _storage;
  
  static final String _baseUrl = Platform.isAndroid 
      ? 'http://10.0.2.2:3000/api/v1' 
      : 'http://localhost:3000/api/v1';

  final Dio _dio = Dio(BaseOptions(
    baseUrl: _baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));
  
  AuthNotifier(this._storage) : super(const AsyncValue.data(null)) {
    _loadUser();
  }

  Future<void> _loadUser() async {
    try {
      final token = await _storage.read(key: AppConstants.accessTokenKey);
      if (token != null) {
        // Token exists, try to get user profile
        _dio.options.headers['Authorization'] = 'Bearer $token';
        final response = await _dio.get('/auth/profile');
        
        if (response.statusCode == 200) {
          final userData = response.data['data'];
          final user = UserModel.fromJson(userData);
          state = AsyncValue.data(user);
        }
      }
    } catch (e) {
      // Token invalid or expired, stay logged out
      state = const AsyncValue.data(null);
    }
  }

  Future<void> login(String email, {String password = 'password123', String? name, String? mockRole}) async {
    state = const AsyncValue.loading();
    
    // DEV: Set header for backend role switching
    if (mockRole != null) {
      _dio.options.headers['x-mock-role'] = mockRole;
    }

    try {
      // 1. Perform Real API Call
      final response = await _dio.post('/auth/login', data: {
        'email': email,
        'password': password,
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = response.data['data'];
        final userData = responseData['user'];
        final accessToken = responseData['accessToken'];
        final refreshToken = responseData['refreshToken'];

        // 2. Save tokens to secure storage
        await _storage.write(key: AppConstants.accessTokenKey, value: accessToken);
        if (refreshToken != null) {
          await _storage.write(key: AppConstants.refreshTokenKey, value: refreshToken);
        }

        // 3. Parse User Data from Backend
        final user = UserModel(
          id: userData['id'],
          email: userData['email'],
          firstName: userData['firstName'],
          lastName: userData['lastName'],
          role: mockRole ?? userData['role'], // Override role locally
        );

        state = AsyncValue.data(user);
      } else {
        state = AsyncValue.error('Login failed: ${response.statusMessage}', StackTrace.current);
      }
    } on DioException catch (e) {
      String errorMessage = 'Login failed';
      if (e.response != null) {
        errorMessage = e.response?.data['message'] ?? e.message;
      }
      state = AsyncValue.error(errorMessage, e.stackTrace);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
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


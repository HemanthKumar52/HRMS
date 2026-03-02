import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';
import '../../../shared/models/user_model.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/services/local_face_store.dart';
import '../../../shared/providers/face_photo_provider.dart';
import 'package:dio/dio.dart';

class AuthNotifier extends StateNotifier<AsyncValue<UserModel?>> {
  final FlutterSecureStorage _storage;
  final LocalFaceStore _localFaceStore;
  final Ref _ref;
  final Dio _dio;

  AuthNotifier(this._storage, this._localFaceStore, this._ref)
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

        try {
          final response = await _dio.get('/auth/me');

          if (response.statusCode == 200) {
            final userData = response.data['data'];
            final user = UserModel.fromJson(userData);
            state = AsyncValue.data(user);
            debugPrint('[Auth] Restored session for ${user.email}');

            // Cache user data locally for offline access
            await _localFaceStore.cacheUserData(userData);

            // Sync face photos in background
            _syncFacePhotos();
            _loadProfilePhoto();
            return;
          }
        } catch (e) {
          debugPrint('[Auth] Online restore failed: $e — trying offline cache');
        }

        // Fallback: restore from local cache if network is unavailable
        final cachedUser = await _localFaceStore.getCachedUserData();
        if (cachedUser != null) {
          final user = UserModel.fromJson(cachedUser);
          state = AsyncValue.data(user);
          debugPrint('[Auth] Restored session from local cache for ${user.email}');
          return;
        }
      }
    } catch (e) {
      debugPrint('[Auth] _loadUser failed: $e');
    }

    state = const AsyncValue.data(null);
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

        // Cache user data locally for offline access
        await _localFaceStore.cacheUserData(user.toJson());

        // Fetch and cache all face photos for offline face recognition
        _syncFacePhotos();

        // Load the current user's DB face photo as profile picture
        _loadProfilePhoto();
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

  Future<void> loginWithSSO(String microsoftToken) async {
    state = const AsyncValue.loading();
    debugPrint('[Auth] SSO login with Microsoft token');

    try {
      final response = await _dio.post('/auth/sso/token', data: {
        'accessToken': microsoftToken,
      });

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
          role: userData['role'],
        );

        state = AsyncValue.data(user);
        debugPrint('[Auth] SSO login success: ${user.email} (${user.role})');

        // Cache user data locally for offline access
        await _localFaceStore.cacheUserData(user.toJson());

        // Fetch and cache face photos
        _syncFacePhotos();
      } else {
        state = AsyncValue.error('SSO login failed: ${response.statusMessage}', StackTrace.current);
      }
    } on DioException catch (e, st) {
      final errorMessage = e.response?.data is Map
          ? (e.response!.data['message'] ?? 'SSO login failed').toString()
          : 'SSO login failed: ${e.type.name}';
      debugPrint('[Auth] SSO DioException: ${e.type} | ${e.message}');
      state = AsyncValue.error(errorMessage, st);
    } catch (e, st) {
      debugPrint('[Auth] SSO unexpected error: $e');
      state = AsyncValue.error('SSO login failed: $e', st);
    }
  }

  /// Fetch all employee face photos from the backend and cache locally.
  /// Runs in background — does not block login/startup.
  Future<void> _syncFacePhotos() async {
    try {
      debugPrint('[Auth] Syncing face photos for offline recognition...');
      final response = await _dio.get('/users/face-photos');

      if (response.statusCode == 200) {
        final employees = response.data['employees'] as List<dynamic>? ?? [];
        final cachedFaces = <CachedEmployee>[];

        for (final emp in employees) {
          final id = emp['id'] as String?;
          final name = emp['name'] as String?;
          final facePhoto = emp['facePhoto'] as String?;

          if (id != null && name != null && facePhoto != null && facePhoto.isNotEmpty) {
            // Strip data:image prefix if present
            String base64Data = facePhoto;
            if (base64Data.contains(',')) {
              base64Data = base64Data.split(',').last;
            }

            cachedFaces.add(CachedEmployee(
              id: id,
              name: name,
              facePhotoBase64: base64Data,
            ));
          }
        }

        await _localFaceStore.cacheAllFaces(cachedFaces);
        debugPrint('[Auth] Face photo sync complete: ${cachedFaces.length} employees cached.');
      }
    } catch (e) {
      debugPrint('[Auth] Face photo sync failed (will use existing cache): $e');
      // Non-fatal — existing local cache (if any) will be used for offline verification
    }
  }

  /// Fetch the current user's face photo from DB and save as profile picture.
  Future<void> _loadProfilePhoto() async {
    try {
      final response = await _dio.get('/users/me/face-photo');
      if (response.statusCode == 200) {
        final data = response.data['data'] ?? response.data;
        final facePhotoB64 = data['facePhoto'] as String?;

        if (facePhotoB64 != null && facePhotoB64.isNotEmpty) {
          // Strip data URI prefix if present
          String base64Data = facePhotoB64;
          if (base64Data.contains(',')) {
            base64Data = base64Data.split(',').last;
          }

          // Decode and save to temp file
          final bytes = base64Decode(base64Data);
          final dir = await getApplicationDocumentsDirectory();
          final file = File('${dir.path}/profile_photo.jpg');
          await file.writeAsBytes(bytes);

          _ref.read(profilePhotoProvider.notifier).state = file.path;
          debugPrint('[Auth] Profile photo loaded from DB');
        }
      }
    } catch (e) {
      debugPrint('[Auth] Profile photo load failed: $e');
    }
  }

  Future<void> logout() async {
    await _storage.deleteAll();
    await _localFaceStore.clearAll();
    _ref.read(profilePhotoProvider.notifier).state = null;
    _ref.read(facePhotoProvider.notifier).state = null;
    state = const AsyncValue.data(null);
  }
}

final authStateProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<UserModel?>>((ref) {
  final storage = ref.watch(secureStorageProvider);
  final localFaceStore = ref.watch(localFaceStoreProvider);
  return AuthNotifier(storage, localFaceStore, ref);
});

final currentUserProvider = Provider<UserModel?>((ref) {
  return ref.watch(authStateProvider).value;
});

final isLoggedInProvider = Provider<bool>((ref) {
  return ref.watch(currentUserProvider) != null;
});

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../constants/api_constants.dart';
import '../constants/app_constants.dart';

class AuthInterceptor extends Interceptor {
  final Ref _ref;
  final FlutterSecureStorage _storage;

  AuthInterceptor(this._ref, this._storage);

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final accessToken = await _storage.read(key: AppConstants.accessTokenKey);

    if (accessToken != null) {
      options.headers['Authorization'] = 'Bearer $accessToken';
    }

    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      final refreshToken = await _storage.read(key: AppConstants.refreshTokenKey);

      if (refreshToken != null) {
        try {
          final dio = Dio(BaseOptions(baseUrl: ApiConstants.baseUrl));
          final response = await dio.post(
             ApiConstants.refresh,
             data: {'refreshToken': refreshToken},
          );

          if (response.statusCode == 200) {
            final data = response.data['data'];
            await _storage.write(
              key: AppConstants.accessTokenKey,
              value: data['accessToken'],
            );
            await _storage.write(
              key: AppConstants.refreshTokenKey,
              value: data['refreshToken'],
            );

            // Update header with new token
            err.requestOptions.headers['Authorization'] =
                'Bearer ${data['accessToken']}';

            // Retry the original request
            final retryResponse = await dio.fetch(err.requestOptions);
            return handler.resolve(retryResponse);
          }
        } catch (e) {
          // Refresh failed, clear storage
          await _storage.deleteAll();
        }
      }
    }
    
    // Propagate the error if it wasn't resolved by refresh
    handler.next(err);
  }
}

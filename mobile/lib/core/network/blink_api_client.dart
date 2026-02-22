import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/api_constants.dart';

/// Separate Dio instance for the Flask blink detection server.
/// No JWT auth — Flask server has no authentication.
/// Longer timeout since frame payloads can be large.
final blinkDioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: ApiConstants.blinkServerUrl,
      connectTimeout: const Duration(seconds: 60),
      receiveTimeout: const Duration(seconds: 60),
      sendTimeout: const Duration(seconds: 60),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  dio.interceptors.add(LogInterceptor(
    requestBody: false, // Frame data is huge, don't log it
    responseBody: true,
    error: true,
  ));

  return dio;
});

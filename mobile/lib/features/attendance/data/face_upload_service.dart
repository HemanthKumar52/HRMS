import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';

class FaceUploadService {
  final Dio _dio;

  FaceUploadService(this._dio);

  /// Upload face photo as user avatar (non-blocking)
  Future<void> uploadFacePhoto(String photoPath) async {
    try {
      final formData = FormData.fromMap({
        'avatar': await MultipartFile.fromFile(
          photoPath,
          filename: 'face_${DateTime.now().millisecondsSinceEpoch}.jpg',
        ),
      });

      await _dio.patch(
        '/users/me/avatar',
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
        ),
      );
    } catch (e) {
      debugPrint('Face photo upload failed: $e');
    }
  }
}

final faceUploadServiceProvider = Provider<FaceUploadService>((ref) {
  final dio = ref.watch(dioProvider);
  return FaceUploadService(dio);
});

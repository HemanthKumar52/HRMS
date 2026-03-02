import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Represents a locally cached employee face record.
class CachedEmployee {
  final String id;
  final String name;
  final String facePhotoBase64; // raw base64 (no data:image prefix)

  CachedEmployee({
    required this.id,
    required this.name,
    required this.facePhotoBase64,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'facePhotoBase64': facePhotoBase64,
      };

  factory CachedEmployee.fromJson(Map<String, dynamic> json) => CachedEmployee(
        id: json['id'] as String,
        name: json['name'] as String,
        facePhotoBase64: json['facePhotoBase64'] as String,
      );
}

/// Hive-backed local store for employee face photos and user data.
/// Used for offline face recognition and session restore.
class LocalFaceStore {
  static const String _faceBoxName = 'face_store';
  static const String _userBoxName = 'user_cache';
  late Box<String> _faceBox;
  late Box<String> _userBox;
  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;
    _faceBox = await Hive.openBox<String>(_faceBoxName);
    _userBox = await Hive.openBox<String>(_userBoxName);
    _isInitialized = true;
    debugPrint('[LocalFaceStore] Initialized. ${_faceBox.length} cached faces.');
  }

  // ─── Face Photo Storage ──────────────────────────────────────────

  /// Store a single employee's face data locally.
  Future<void> cacheEmployeeFace(CachedEmployee employee) async {
    await init();
    await _faceBox.put(employee.id, jsonEncode(employee.toJson()));
  }

  /// Bulk-save all employee faces (replaces existing cache).
  Future<void> cacheAllFaces(List<CachedEmployee> employees) async {
    await init();
    await _faceBox.clear();
    for (final emp in employees) {
      await _faceBox.put(emp.id, jsonEncode(emp.toJson()));
    }
    debugPrint('[LocalFaceStore] Cached ${employees.length} employee faces.');
  }

  /// Get all cached employee face records.
  Future<List<CachedEmployee>> getAllCachedFaces() async {
    await init();
    final results = <CachedEmployee>[];
    for (final json in _faceBox.values) {
      try {
        results.add(CachedEmployee.fromJson(jsonDecode(json)));
      } catch (e) {
        debugPrint('[LocalFaceStore] Parse error: $e');
      }
    }
    return results;
  }

  /// Get a single cached face by employee ID.
  Future<CachedEmployee?> getCachedFace(String employeeId) async {
    await init();
    final json = _faceBox.get(employeeId);
    if (json == null) return null;
    try {
      return CachedEmployee.fromJson(jsonDecode(json));
    } catch (_) {
      return null;
    }
  }

  /// Number of cached faces.
  Future<int> get cachedFaceCount async {
    await init();
    return _faceBox.length;
  }

  /// Clear all cached faces.
  Future<void> clearFaces() async {
    await init();
    await _faceBox.clear();
  }

  // ─── User Data Cache ─────────────────────────────────────────────

  /// Cache the logged-in user's JSON for offline session restore.
  Future<void> cacheUserData(Map<String, dynamic> userJson) async {
    await init();
    await _userBox.put('current_user', jsonEncode(userJson));
    debugPrint('[LocalFaceStore] Cached user data locally.');
  }

  /// Retrieve cached user data (for offline session restore).
  Future<Map<String, dynamic>?> getCachedUserData() async {
    await init();
    final json = _userBox.get('current_user');
    if (json == null) return null;
    try {
      return jsonDecode(json) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  /// Clear user cache on logout.
  Future<void> clearUserData() async {
    await init();
    await _userBox.clear();
  }

  /// Clear everything (logout).
  Future<void> clearAll() async {
    await init();
    await _faceBox.clear();
    await _userBox.clear();
    debugPrint('[LocalFaceStore] All local data cleared.');
  }
}

final localFaceStoreProvider = Provider<LocalFaceStore>((ref) {
  return LocalFaceStore();
});

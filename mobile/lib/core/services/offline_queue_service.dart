import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class OfflinePunch {
  final String id;
  final String punchType;
  final DateTime timestamp;
  final double? latitude;
  final double? longitude;
  final String? address;
  final String? deviceId;
  final int retryCount;
  final DateTime createdAt;

  OfflinePunch({
    required this.id,
    required this.punchType,
    required this.timestamp,
    this.latitude,
    this.longitude,
    this.address,
    this.deviceId,
    this.retryCount = 0,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  OfflinePunch copyWith({int? retryCount}) {
    return OfflinePunch(
      id: id,
      punchType: punchType,
      timestamp: timestamp,
      latitude: latitude,
      longitude: longitude,
      address: address,
      deviceId: deviceId,
      retryCount: retryCount ?? this.retryCount,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'punchType': punchType,
      'timestamp': timestamp.toIso8601String(),
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'deviceId': deviceId,
      'retryCount': retryCount,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory OfflinePunch.fromJson(Map<String, dynamic> json) {
    return OfflinePunch(
      id: json['id'] as String,
      punchType: json['punchType'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      latitude: json['latitude'] as double?,
      longitude: json['longitude'] as double?,
      address: json['address'] as String?,
      deviceId: json['deviceId'] as String?,
      retryCount: json['retryCount'] as int? ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toApiJson() {
    return {
      'punchType': punchType,
      'timestamp': timestamp.toIso8601String(),
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (address != null) 'address': address,
      if (deviceId != null) 'deviceId': deviceId,
      'isOffline': true,
    };
  }
}

class OfflineQueueService {
  static const String _boxName = 'offline_punches';
  late Box<String> _box;
  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;
    _box = await Hive.openBox<String>(_boxName);
    _isInitialized = true;
  }

  Future<void> addPunch(OfflinePunch punch) async {
    await init();
    await _box.put(punch.id, jsonEncode(punch.toJson()));
  }

  Future<List<OfflinePunch>> getPendingPunches() async {
    await init();
    final punches = <OfflinePunch>[];
    for (final json in _box.values) {
      try {
        punches.add(OfflinePunch.fromJson(jsonDecode(json)));
      } catch (_) {}
    }
    punches.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return punches;
  }

  Future<void> removePunch(String id) async {
    await init();
    await _box.delete(id);
  }

  Future<void> updateRetryCount(String id) async {
    await init();
    final json = _box.get(id);
    if (json != null) {
      final punch = OfflinePunch.fromJson(jsonDecode(json));
      final updated = punch.copyWith(retryCount: punch.retryCount + 1);
      await _box.put(id, jsonEncode(updated.toJson()));
    }
  }

  Future<int> getPendingCount() async {
    await init();
    return _box.length;
  }

  Future<void> clearAll() async {
    await init();
    await _box.clear();
  }

  Stream<BoxEvent> watchQueue() {
    return _box.watch();
  }
}

final offlineQueueServiceProvider = Provider<OfflineQueueService>((ref) {
  return OfflineQueueService();
});

final pendingPunchCountProvider = StreamProvider<int>((ref) async* {
  final service = ref.watch(offlineQueueServiceProvider);
  await service.init();

  yield await service.getPendingCount();

  await for (final _ in service.watchQueue()) {
    yield await service.getPendingCount();
  }
});

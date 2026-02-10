import 'package:equatable/equatable.dart';

enum PunchType { clockIn, clockOut }

// Maps to specific `AttendanceActivity` from Backend
class AttendanceModel extends Equatable {
  final String id;
  final String userId;
  final String? dailyAttendanceId; // New field to link to DailyAttendance
  final PunchType punchType;
  final DateTime timestamp;
  final double? latitude;
  final double? longitude;
  final String? address;
  final String? deviceId;
  final bool isOffline;
  final DateTime? syncedAt; // New field for sync status

  const AttendanceModel({
    required this.id,
    required this.userId,
    this.dailyAttendanceId,
    required this.punchType,
    required this.timestamp,
    this.latitude,
    this.longitude,
    this.address,
    this.deviceId,
    this.isOffline = false,
    this.syncedAt,
  });

  factory AttendanceModel.fromJson(Map<String, dynamic> json) {
    return AttendanceModel(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      dailyAttendanceId: json['dailyAttendanceId'],
      punchType: _parsePunchType(json['punchType']),
      timestamp: DateTime.parse(json['timestamp']),
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      address: json['address'],
      deviceId: json['deviceId'],
      isOffline: json['isOffline'] ?? false,
      syncedAt: json['syncedAt'] != null ? DateTime.parse(json['syncedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'dailyAttendanceId': dailyAttendanceId,
      'punchType': punchType.name.toUpperCase(), // Assuming backend expects UPPERCASE
      'timestamp': timestamp.toIso8601String(),
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'deviceId': deviceId,
      'isOffline': isOffline,
      'syncedAt': syncedAt?.toIso8601String(),
    };
  }

  static PunchType _parsePunchType(String? type) {
    switch (type?.toUpperCase()) {
      case 'CLOCK_IN':
        return PunchType.clockIn;
      case 'CLOCK_OUT':
        return PunchType.clockOut;
      default:
        return PunchType.clockIn;
    }
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        punchType,
        timestamp,
        isOffline,
        syncedAt,
      ];
}

// Maps to `DailyAttendance` from Backend
class TodayStatusModel extends Equatable {
  final String date; // YYYY-MM-DD
  final DateTime? clockInTime;
  final DateTime? clockOutTime;
  final String totalHours;
  final String overtimeHours; // New field
  final int totalMinutes;
  final List<AttendanceModel> punches; // Activities
  final bool isClockedIn;
  final PunchType nextExpectedPunchType;
  final bool isValidated; // New field
  final bool isHoliday;   // New field

  const TodayStatusModel({
    required this.date,
    this.clockInTime,
    this.clockOutTime,
    required this.totalHours,
    this.overtimeHours = '00:00',
    required this.totalMinutes,
    required this.punches,
    required this.isClockedIn,
    required this.nextExpectedPunchType,
    this.isValidated = false,
    this.isHoliday = false,
  });

  factory TodayStatusModel.fromJson(Map<String, dynamic> json) {
    return TodayStatusModel(
      date: json['date'] ?? '',
      clockInTime: json['clockInTime'] != null
          ? DateTime.parse(json['clockInTime'])
          : null,
      clockOutTime: json['clockOutTime'] != null
          ? DateTime.parse(json['clockOutTime'])
          : null,
      totalHours: json['totalHours'] ?? '0h 0m',
      overtimeHours: json['overtimeHours'] ?? '00:00',
      totalMinutes: json['totalMinutes'] ?? 0,
      punches: (json['punches'] as List?)
              ?.map((p) => AttendanceModel.fromJson(p))
              .toList() ??
          [],
      isClockedIn: json['isClockedIn'] ?? false,
      nextExpectedPunchType:
          AttendanceModel._parsePunchType(json['nextExpectedPunchType']),
      isValidated: json['isValidated'] ?? false,
      isHoliday: json['isHoliday'] ?? false,
    );
  }

  @override
  List<Object?> get props => [
        date,
        clockInTime,
        clockOutTime,
        totalHours,
        isClockedIn,
        isValidated,
      ];
}

class AttendanceSummaryModel extends Equatable {
  final String period;
  final String startDate;
  final String endDate;
  final String totalHours;
  final int totalMinutes;
  final String averageHoursPerDay;
  final int workingDays;
  final List<DailySummary> dailySummary;

  const AttendanceSummaryModel({
    required this.period,
    required this.startDate,
    required this.endDate,
    required this.totalHours,
    required this.totalMinutes,
    required this.averageHoursPerDay,
    required this.workingDays,
    required this.dailySummary,
  });

  factory AttendanceSummaryModel.fromJson(Map<String, dynamic> json) {
    return AttendanceSummaryModel(
      period: json['period'] ?? 'week',
      startDate: json['startDate'] ?? '',
      endDate: json['endDate'] ?? '',
      totalHours: json['totalHours'] ?? '0h 0m',
      totalMinutes: json['totalMinutes'] ?? 0,
      averageHoursPerDay: json['averageHoursPerDay'] ?? '0h 0m',
      workingDays: json['workingDays'] ?? 0,
      dailySummary: (json['dailySummary'] as List?)
              ?.map((d) => DailySummary.fromJson(d))
              .toList() ??
          [],
    );
  }

  @override
  List<Object?> get props => [period, totalHours, workingDays];
}

class DailySummary extends Equatable {
  final String date;
  final DateTime? clockIn;
  final DateTime? clockOut;
  final String totalHours;
  final int totalMinutes;

  const DailySummary({
    required this.date,
    this.clockIn,
    this.clockOut,
    required this.totalHours,
    required this.totalMinutes,
  });

  factory DailySummary.fromJson(Map<String, dynamic> json) {
    return DailySummary(
      date: json['date'] ?? '',
      clockIn:
          json['clockIn'] != null ? DateTime.parse(json['clockIn']) : null,
      clockOut:
          json['clockOut'] != null ? DateTime.parse(json['clockOut']) : null,
      totalHours: json['totalHours'] ?? '0h 0m',
      totalMinutes: json['totalMinutes'] ?? 0,
    );
  }

  @override
  List<Object?> get props => [date, clockIn, clockOut, totalHours];
}

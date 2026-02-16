import 'package:equatable/equatable.dart';

enum LeaveType { casual, sick, earned, unpaid, parental, od, compensatory }

enum LeaveStatus { pending, approved, rejected, cancelled }

enum HalfDayType { firstHalf, secondHalf }

class LeaveModel extends Equatable {
  final String id;
  final String userId;
  final LeaveType type;
  final LeaveStatus status;
  final DateTime fromDate;
  final DateTime toDate;
  final bool isHalfDay;
  final HalfDayType? halfDayType;
  final String? reason;
  final String? rejectReason;
  final String? approvedBy;
  final DateTime? approvedAt;
  final DateTime createdAt;

  const LeaveModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.status,
    required this.fromDate,
    required this.toDate,
    this.isHalfDay = false,
    this.halfDayType,
    this.reason,
    this.rejectReason,
    this.approvedBy,
    this.approvedAt,
    required this.createdAt,
  });

  int get totalDays {
    if (isHalfDay) return 0;
    return toDate.difference(fromDate).inDays + 1;
  }

  double get leaveDays {
    if (isHalfDay) return 0.5;
    return totalDays.toDouble();
  }

  factory LeaveModel.fromJson(Map<String, dynamic> json) {
    return LeaveModel(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      type: _parseLeaveType(json['type']),
      status: _parseLeaveStatus(json['status']),
      fromDate: DateTime.parse(json['fromDate']),
      toDate: DateTime.parse(json['toDate']),
      isHalfDay: json['isHalfDay'] ?? false,
      halfDayType: json['halfDayType'] != null
          ? _parseHalfDayType(json['halfDayType'])
          : null,
      reason: json['reason'],
      rejectReason: json['rejectReason'],
      approvedBy: json['approvedBy'],
      approvedAt:
          json['approvedAt'] != null ? DateTime.parse(json['approvedAt']) : null,
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  static LeaveType _parseLeaveType(String? type) {
    switch (type?.toUpperCase()) {
      case 'CASUAL':
        return LeaveType.casual;
      case 'SICK':
        return LeaveType.sick;
      case 'EARNED':
        return LeaveType.earned;
      case 'UNPAID':
        return LeaveType.unpaid;
      case 'PARENTAL':
      case 'MATERNITY':
      case 'PATERNITY':
        return LeaveType.parental;
      case 'OD':
        return LeaveType.od;
      case 'COMPENSATORY':
        return LeaveType.compensatory;
      default:
        return LeaveType.casual;
    }
  }

  static LeaveStatus _parseLeaveStatus(String? status) {
    switch (status?.toUpperCase()) {
      case 'PENDING':
        return LeaveStatus.pending;
      case 'APPROVED':
        return LeaveStatus.approved;
      case 'REJECTED':
        return LeaveStatus.rejected;
      case 'CANCELLED':
        return LeaveStatus.cancelled;
      default:
        return LeaveStatus.pending;
    }
  }

  static HalfDayType _parseHalfDayType(String? type) {
    switch (type?.toUpperCase()) {
      case 'FIRST_HALF':
        return HalfDayType.firstHalf;
      case 'SECOND_HALF':
        return HalfDayType.secondHalf;
      default:
        return HalfDayType.firstHalf;
    }
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        type,
        status,
        fromDate,
        toDate,
        isHalfDay,
        halfDayType,
        reason,
      ];
}

class LeaveBalance extends Equatable {
  final LeaveType type;
  final double total;
  final double used;
  final double available;

  const LeaveBalance({
    required this.type,
    required this.total,
    required this.used,
    required this.available,
  });

  factory LeaveBalance.fromJson(Map<String, dynamic> json) {
    return LeaveBalance(
      type: LeaveModel._parseLeaveType(json['type']),
      total: (json['total'] ?? 0).toDouble(),
      used: (json['used'] ?? 0).toDouble(),
      available: (json['available'] ?? 0).toDouble(),
    );
  }

  @override
  List<Object?> get props => [type, total, used, available];
}

import 'package:equatable/equatable.dart';

class UserModel extends Equatable {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String? phone;
  final String? avatarUrl;
  final String role;
  final String? workMode;
  final String? department;
  final String? designation;
  final OrganizationModel? organization;
  final ManagerModel? manager;

  const UserModel({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.phone,
    this.avatarUrl,
    required this.role,
    this.workMode,
    this.department,
    this.designation,
    this.organization,
    this.manager,
  });

  String get fullName => '$firstName $lastName';

  String get initials =>
      '${firstName.isNotEmpty ? firstName[0] : ''}${lastName.isNotEmpty ? lastName[0] : ''}'
          .toUpperCase();

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      phone: json['phone'],
      avatarUrl: json['avatarUrl'],
      role: json['role'] ?? 'EMPLOYEE',
      workMode: json['workMode'],
      department: json['department'],
      designation: json['designation'],
      organization: json['organization'] is Map<String, dynamic>
          ? OrganizationModel.fromJson(json['organization'])
          : json['organization'] is String
              ? OrganizationModel(id: '', name: json['organization'])
              : null,
      manager: json['manager'] != null
          ? ManagerModel.fromJson(json['manager'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'phone': phone,
      'avatarUrl': avatarUrl,
      'role': role,
      'workMode': workMode,
      'department': department,
      'designation': designation,
      'organization': organization?.toJson(),
      'manager': manager?.toJson(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        email,
        firstName,
        lastName,
        phone,
        avatarUrl,
        role,
        workMode,
        department,
        designation,
      ];
}

class OrganizationModel extends Equatable {
  final String id;
  final String name;

  const OrganizationModel({
    required this.id,
    required this.name,
  });

  factory OrganizationModel.fromJson(Map<String, dynamic> json) {
    return OrganizationModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }

  @override
  List<Object?> get props => [id, name];
}

class ManagerModel extends Equatable {
  final String id;
  final String firstName;
  final String lastName;
  final String email;

  const ManagerModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
  });

  String get fullName => '$firstName $lastName';

  factory ManagerModel.fromJson(Map<String, dynamic> json) {
    return ManagerModel(
      id: json['id'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      email: json['email'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
    };
  }

  @override
  List<Object?> get props => [id, firstName, lastName, email];
}

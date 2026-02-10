import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/rbac_config.dart';
import '../../features/auth/providers/auth_provider.dart';

// Permission Check Provider
final permissionProvider = Provider.family<bool, Permission>((ref, permission) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return false;
  
  return RBACConfig.hasPermission(user.role, permission);
});

// Multiple Permissions Check (ANY)
final hasAnyPermissionProvider = Provider.family<bool, List<Permission>>((ref, permissions) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return false;
  
  return RBACConfig.hasAnyPermission(user.role, permissions);
});

// Multiple Permissions Check (ALL)
final hasAllPermissionsProvider = Provider.family<bool, List<Permission>>((ref, permissions) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return false;
  
  return RBACConfig.hasAllPermissions(user.role, permissions);
});

// Get all permissions for current user
final userPermissionsProvider = Provider<List<Permission>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  
  return RBACConfig.getPermissions(user.role);
});

// Helper extension for easy permission checks in widgets
extension PermissionCheckExtension on WidgetRef {
  bool can(Permission permission) {
    return read(permissionProvider(permission));
  }
  
  bool canAny(List<Permission> permissions) {
    return read(hasAnyPermissionProvider(permissions));
  }
  
  bool canAll(List<Permission> permissions) {
    return read(hasAllPermissionsProvider(permissions));
  }
}

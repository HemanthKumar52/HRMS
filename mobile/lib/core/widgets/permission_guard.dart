import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/rbac_config.dart';
import '../providers/permission_provider.dart';

/// Widget that conditionally renders its child based on user permissions
/// 
/// Usage:
/// ```dart
/// PermissionGuard(
///   permission: Permission.USER_CREATE,
///   child: ElevatedButton(
///     onPressed: () => createUser(),
///     child: Text('Create User'),
///   ),
///   fallback: Text('You don\'t have permission'),
/// )
/// ```
class PermissionGuard extends ConsumerWidget {
  final Permission? permission;
  final List<Permission>? anyPermissions;
  final List<Permission>? allPermissions;
  final Widget child;
  final Widget? fallback;
  final bool hideIfNoPermission;

  const PermissionGuard({
    super.key,
    this.permission,
    this.anyPermissions,
    this.allPermissions,
    required this.child,
    this.fallback,
    this.hideIfNoPermission = true,
  }) : assert(
          permission != null || anyPermissions != null || allPermissions != null,
          'At least one permission check must be provided',
        );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    bool hasPermission = false;

    if (permission != null) {
      hasPermission = ref.watch(permissionProvider(permission!));
    } else if (anyPermissions != null) {
      hasPermission = ref.watch(hasAnyPermissionProvider(anyPermissions!));
    } else if (allPermissions != null) {
      hasPermission = ref.watch(hasAllPermissionsProvider(allPermissions!));
    }

    if (hasPermission) {
      return child;
    }

    if (hideIfNoPermission) {
      return const SizedBox.shrink();
    }

    return fallback ?? const SizedBox.shrink();
  }
}

/// Button that is automatically disabled if user doesn't have permission
class PermissionButton extends ConsumerWidget {
  final Permission permission;
  final VoidCallback? onPressed;
  final Widget child;
  final ButtonStyle? style;

  const PermissionButton({
    super.key,
    required this.permission,
    required this.onPressed,
    required this.child,
    this.style,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasPermission = ref.watch(permissionProvider(permission));

    return ElevatedButton(
      onPressed: hasPermission ? onPressed : null,
      style: style,
      child: child,
    );
  }
}

/// IconButton that is automatically disabled if user doesn't have permission
class PermissionIconButton extends ConsumerWidget {
  final Permission permission;
  final VoidCallback? onPressed;
  final Icon icon;
  final String? tooltip;

  const PermissionIconButton({
    super.key,
    required this.permission,
    required this.onPressed,
    required this.icon,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasPermission = ref.watch(permissionProvider(permission));

    return IconButton(
      onPressed: hasPermission ? onPressed : null,
      icon: icon,
      tooltip: tooltip,
    );
  }
}

/// FloatingActionButton that is hidden if user doesn't have permission
class PermissionFAB extends ConsumerWidget {
  final Permission permission;
  final VoidCallback? onPressed;
  final Widget child;
  final String? tooltip;

  const PermissionFAB({
    super.key,
    required this.permission,
    required this.onPressed,
    required this.child,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasPermission = ref.watch(permissionProvider(permission));

    if (!hasPermission) {
      return const SizedBox.shrink();
    }

    return FloatingActionButton(
      onPressed: onPressed,
      tooltip: tooltip,
      child: child,
    );
  }
}

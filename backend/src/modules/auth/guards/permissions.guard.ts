import { Injectable, CanActivate, ExecutionContext } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { PERMISSIONS_KEY } from '../decorators/permissions.decorator';
import { Permission, PermissionService } from '../permissions/permissions.service';

@Injectable()
export class PermissionsGuard implements CanActivate {
    constructor(private reflector: Reflector) { }

    canActivate(context: ExecutionContext): boolean {
        const requiredPermissions = this.reflector.getAllAndOverride<Permission[]>(
            PERMISSIONS_KEY,
            [context.getHandler(), context.getClass()],
        );

        if (!requiredPermissions) {
            return true; // No permissions required, allow access
        }

        const request = context.switchToHttp().getRequest();
        const user = request.user;

        if (!user) {
            return false; // No user, deny access
        }

        // Check if user has ANY of the required permissions
        return PermissionService.hasAnyPermission(user.role, requiredPermissions);
    }
}

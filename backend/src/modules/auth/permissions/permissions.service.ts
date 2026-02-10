import { Role } from '@prisma/client';

export enum Permission {
    // Attendance Permissions
    ATTENDANCE_VIEW_OWN = 'attendance:view:own',
    ATTENDANCE_MARK_OWN = 'attendance:mark:own',
    ATTENDANCE_VIEW_TEAM = 'attendance:view:team',
    ATTENDANCE_APPROVE_TEAM = 'attendance:approve:team',
    ATTENDANCE_VIEW_ALL = 'attendance:view:all',
    ATTENDANCE_EDIT_ALL = 'attendance:edit:all',

    // Leave Permissions
    LEAVE_VIEW_OWN = 'leave:view:own',
    LEAVE_APPLY = 'leave:apply',
    LEAVE_CANCEL_OWN = 'leave:cancel:own',
    LEAVE_VIEW_TEAM = 'leave:view:team',
    LEAVE_APPROVE_TEAM = 'leave:approve:team',
    LEAVE_REJECT_TEAM = 'leave:reject:team',
    LEAVE_VIEW_ALL = 'leave:view:all',
    LEAVE_APPROVE_ALL = 'leave:approve:all',
    LEAVE_EDIT_ALL = 'leave:edit:all',

    // User Permissions
    USER_VIEW_DIRECTORY = 'user:view:directory',
    USER_VIEW_PROFILE = 'user:view:profile',
    USER_EDIT_OWN_PROFILE = 'user:edit:own:profile',
    USER_VIEW_TEAM = 'user:view:team',
    USER_CREATE = 'user:create',
    USER_EDIT_ALL = 'user:edit:all',
    USER_DELETE = 'user:delete',
    USER_ASSIGN_ROLES = 'user:assign:roles',

    // Asset Permissions
    ASSET_VIEW_OWN = 'asset:view:own',
    ASSET_REQUEST = 'asset:request',
    ASSET_VIEW_ALL = 'asset:view:all',
    ASSET_CREATE = 'asset:create',
    ASSET_ASSIGN = 'asset:assign',
    ASSET_EDIT = 'asset:edit',
    ASSET_DELETE = 'asset:delete',
    ASSET_APPROVE_REQUESTS = 'asset:approve:requests',

    // Notification Permissions
    NOTIFICATION_VIEW_OWN = 'notification:view:own',
    NOTIFICATION_SEND_TEAM = 'notification:send:team',
    NOTIFICATION_SEND_ALL = 'notification:send:all',
}

export const ROLE_PERMISSIONS: Record<Role, Permission[]> = {
    [Role.EMPLOYEE]: [
        Permission.ATTENDANCE_VIEW_OWN,
        Permission.ATTENDANCE_MARK_OWN,
        Permission.LEAVE_VIEW_OWN,
        Permission.LEAVE_APPLY,
        Permission.LEAVE_CANCEL_OWN,
        Permission.USER_VIEW_DIRECTORY,
        Permission.USER_VIEW_PROFILE,
        Permission.USER_EDIT_OWN_PROFILE,
        Permission.ASSET_VIEW_OWN,
        Permission.ASSET_REQUEST,
        Permission.NOTIFICATION_VIEW_OWN,
    ],

    [Role.MANAGER]: [
        // All EMPLOYEE permissions
        Permission.ATTENDANCE_VIEW_OWN,
        Permission.ATTENDANCE_MARK_OWN,
        Permission.LEAVE_VIEW_OWN,
        Permission.LEAVE_APPLY,
        Permission.LEAVE_CANCEL_OWN,
        Permission.USER_VIEW_DIRECTORY,
        Permission.USER_VIEW_PROFILE,
        Permission.USER_EDIT_OWN_PROFILE,
        Permission.ASSET_VIEW_OWN,
        Permission.ASSET_REQUEST,
        Permission.NOTIFICATION_VIEW_OWN,

        // Additional MANAGER permissions
        Permission.ATTENDANCE_VIEW_TEAM,
        Permission.ATTENDANCE_APPROVE_TEAM,
        Permission.LEAVE_VIEW_TEAM,
        Permission.LEAVE_APPROVE_TEAM,
        Permission.LEAVE_REJECT_TEAM,
        Permission.USER_VIEW_TEAM,
        Permission.NOTIFICATION_SEND_TEAM,
    ],

    [Role.HR_ADMIN]: [
        // All MANAGER permissions
        Permission.ATTENDANCE_VIEW_OWN,
        Permission.ATTENDANCE_MARK_OWN,
        Permission.LEAVE_VIEW_OWN,
        Permission.LEAVE_APPLY,
        Permission.LEAVE_CANCEL_OWN,
        Permission.USER_VIEW_DIRECTORY,
        Permission.USER_VIEW_PROFILE,
        Permission.USER_EDIT_OWN_PROFILE,
        Permission.ASSET_VIEW_OWN,
        Permission.ASSET_REQUEST,
        Permission.NOTIFICATION_VIEW_OWN,
        Permission.ATTENDANCE_VIEW_TEAM,
        Permission.ATTENDANCE_APPROVE_TEAM,
        Permission.LEAVE_VIEW_TEAM,
        Permission.LEAVE_APPROVE_TEAM,
        Permission.LEAVE_REJECT_TEAM,
        Permission.USER_VIEW_TEAM,
        Permission.NOTIFICATION_SEND_TEAM,

        // Additional HR_ADMIN permissions
        Permission.ATTENDANCE_VIEW_ALL,
        Permission.ATTENDANCE_EDIT_ALL,
        Permission.LEAVE_VIEW_ALL,
        Permission.LEAVE_APPROVE_ALL,
        Permission.LEAVE_EDIT_ALL,
        Permission.USER_CREATE,
        Permission.USER_EDIT_ALL,
        Permission.USER_DELETE,
        Permission.USER_ASSIGN_ROLES,
        Permission.ASSET_VIEW_ALL,
        Permission.ASSET_CREATE,
        Permission.ASSET_ASSIGN,
        Permission.ASSET_EDIT,
        Permission.ASSET_DELETE,
        Permission.ASSET_APPROVE_REQUESTS,
        Permission.NOTIFICATION_SEND_ALL,
    ],
};

export class PermissionService {
    static hasPermission(role: Role, permission: Permission): boolean {
        const permissions = ROLE_PERMISSIONS[role];
        return permissions.includes(permission);
    }

    static hasAnyPermission(role: Role, permissions: Permission[]): boolean {
        return permissions.some((p) => this.hasPermission(role, p));
    }

    static hasAllPermissions(role: Role, permissions: Permission[]): boolean {
        return permissions.every((p) => this.hasPermission(role, p));
    }

    static getPermissions(role: Role): Permission[] {
        return ROLE_PERMISSIONS[role] || [];
    }
}

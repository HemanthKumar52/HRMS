// Role-Based Access Control (RBAC) Configuration
// Defines what each role can do in the system

enum Permission {
  // Attendance Permissions
  ATTENDANCE_VIEW_OWN,
  ATTENDANCE_MARK_OWN,
  ATTENDANCE_VIEW_TEAM,
  ATTENDANCE_APPROVE_TEAM,
  ATTENDANCE_VIEW_ALL,
  ATTENDANCE_EDIT_ALL,
  
  // Leave Permissions
  LEAVE_VIEW_OWN,
  LEAVE_APPLY,
  LEAVE_CANCEL_OWN,
  LEAVE_VIEW_TEAM,
  LEAVE_APPROVE_TEAM,
  LEAVE_REJECT_TEAM,
  LEAVE_VIEW_ALL,
  LEAVE_APPROVE_ALL,
  LEAVE_EDIT_ALL,
  
  // User/Directory Permissions
  USER_VIEW_DIRECTORY,
  USER_VIEW_PROFILE,
  USER_EDIT_OWN_PROFILE,
  USER_VIEW_TEAM,
  USER_CREATE,
  USER_EDIT_ALL,
  USER_DELETE,
  USER_ASSIGN_ROLES,
  
  // Asset Permissions
  ASSET_VIEW_OWN,
  ASSET_REQUEST,
  ASSET_VIEW_ALL,
  ASSET_CREATE,
  ASSET_ASSIGN,
  ASSET_EDIT,
  ASSET_DELETE,
  ASSET_APPROVE_REQUESTS,
  
  // Notification Permissions
  NOTIFICATION_VIEW_OWN,
  NOTIFICATION_SEND_TEAM,
  NOTIFICATION_SEND_ALL,
  
  // Dashboard Permissions
  DASHBOARD_VIEW_EMPLOYEE,
  DASHBOARD_VIEW_MANAGER,
  DASHBOARD_VIEW_HR,
  DASHBOARD_VIEW_PAYROLL,
  DASHBOARD_VIEW_ATTENDANCE,
  DASHBOARD_VIEW_IT_ADMIN,
  
  // Ticket/Support Permissions
  TICKET_CREATE,
  TICKET_VIEW_OWN,
  TICKET_VIEW_ALL,
  TICKET_ASSIGN,
  TICKET_RESOLVE,
  
  // Claim/Expense Permissions
  CLAIM_CREATE,
  CLAIM_VIEW_OWN,
  CLAIM_VIEW_TEAM,
  CLAIM_APPROVE_TEAM,
  CLAIM_VIEW_ALL,
  CLAIM_APPROVE_ALL,
  
  // Payroll Permissions
  PAYROLL_VIEW_OWN,
  PAYROLL_VIEW_ALL,
  PAYROLL_PROCESS,
  PAYROLL_EDIT,
  
  // Settings Permissions
  SETTINGS_VIEW,
  SETTINGS_EDIT_OWN,
  SETTINGS_EDIT_ORGANIZATION,
  SETTINGS_MANAGE_ROLES,
}

class RBACConfig {
  static const Map<String, List<Permission>> rolePermissions = {
    'EMPLOYEE': [
      // Attendance
      Permission.ATTENDANCE_VIEW_OWN,
      Permission.ATTENDANCE_MARK_OWN,
      
      // Leave
      Permission.LEAVE_VIEW_OWN,
      Permission.LEAVE_APPLY,
      Permission.LEAVE_CANCEL_OWN,
      
      // User
      Permission.USER_VIEW_DIRECTORY,
      Permission.USER_VIEW_PROFILE,
      Permission.USER_EDIT_OWN_PROFILE,
      
      // Asset
      Permission.ASSET_VIEW_OWN,
      Permission.ASSET_REQUEST,
      
      // Notification
      Permission.NOTIFICATION_VIEW_OWN,
      
      // Dashboard
      Permission.DASHBOARD_VIEW_EMPLOYEE,
      
      // Ticket
      Permission.TICKET_CREATE,
      Permission.TICKET_VIEW_OWN,
      
      // Claim
      Permission.CLAIM_CREATE,
      Permission.CLAIM_VIEW_OWN,
      
      // Payroll
      Permission.PAYROLL_VIEW_OWN,
      
      // Settings
      Permission.SETTINGS_VIEW,
      Permission.SETTINGS_EDIT_OWN,
    ],
    
    'MANAGER': [
      // All EMPLOYEE permissions
      ...rolePermissions['EMPLOYEE']!,
      
      // Additional Attendance
      Permission.ATTENDANCE_VIEW_TEAM,
      Permission.ATTENDANCE_APPROVE_TEAM,
      
      // Additional Leave
      Permission.LEAVE_VIEW_TEAM,
      Permission.LEAVE_APPROVE_TEAM,
      Permission.LEAVE_REJECT_TEAM,
      
      // Additional User
      Permission.USER_VIEW_TEAM,
      
      // Additional Notification
      Permission.NOTIFICATION_SEND_TEAM,
      
      // Additional Dashboard
      Permission.DASHBOARD_VIEW_MANAGER,
      
      // Additional Claim
      Permission.CLAIM_VIEW_TEAM,
      Permission.CLAIM_APPROVE_TEAM,
      
      // Additional Ticket
      Permission.TICKET_ASSIGN,
    ],
    
    'HR_ADMIN': [
      // All MANAGER permissions
      ...rolePermissions['MANAGER']!,
      
      // Full Attendance Access
      Permission.ATTENDANCE_VIEW_ALL,
      Permission.ATTENDANCE_EDIT_ALL,
      
      // Full Leave Access
      Permission.LEAVE_VIEW_ALL,
      Permission.LEAVE_APPROVE_ALL,
      Permission.LEAVE_EDIT_ALL,
      
      // Full User Access
      Permission.USER_CREATE,
      Permission.USER_EDIT_ALL,
      Permission.USER_DELETE,
      Permission.USER_ASSIGN_ROLES,
      
      // Full Asset Access
      Permission.ASSET_VIEW_ALL,
      Permission.ASSET_CREATE,
      Permission.ASSET_ASSIGN,
      Permission.ASSET_EDIT,
      Permission.ASSET_DELETE,
      Permission.ASSET_APPROVE_REQUESTS,
      
      // Full Notification Access
      Permission.NOTIFICATION_SEND_ALL,
      
      // Full Dashboard Access
      Permission.DASHBOARD_VIEW_HR,
      Permission.DASHBOARD_VIEW_PAYROLL,
      Permission.DASHBOARD_VIEW_ATTENDANCE,
      Permission.DASHBOARD_VIEW_IT_ADMIN,
      
      // Full Ticket Access
      Permission.TICKET_VIEW_ALL,
      Permission.TICKET_RESOLVE,
      
      // Full Claim Access
      Permission.CLAIM_VIEW_ALL,
      Permission.CLAIM_APPROVE_ALL,
      
      // Full Payroll Access
      Permission.PAYROLL_VIEW_ALL,
      Permission.PAYROLL_PROCESS,
      Permission.PAYROLL_EDIT,
      
      // Full Settings Access
      Permission.SETTINGS_EDIT_ORGANIZATION,
      Permission.SETTINGS_MANAGE_ROLES,
    ],
  };
  
  static bool hasPermission(String role, Permission permission) {
    final permissions = rolePermissions[role];
    if (permissions == null) return false;
    return permissions.contains(permission);
  }
  
  static bool hasAnyPermission(String role, List<Permission> permissions) {
    return permissions.any((p) => hasPermission(role, p));
  }
  
  static bool hasAllPermissions(String role, List<Permission> permissions) {
    return permissions.every((p) => hasPermission(role, p));
  }
  
  static List<Permission> getPermissions(String role) {
    return rolePermissions[role] ?? [];
  }
}

# Role-Based Access Control (RBAC) System

## Overview
The HRMS application implements a comprehensive Role-Based Access Control (RBAC) system that controls what users can see and do based on their assigned role.

## Roles

### 1. EMPLOYEE (Base Role)
**Can:**
- ✅ View and mark their own attendance
- ✅ Apply for and cancel their own leave
- ✅ View company directory and employee profiles
- ✅ Edit their own profile
- ✅ View their assigned assets and request new ones
- ✅ View their own notifications
- ✅ Create support tickets
- ✅ Submit expense claims
- ✅ View their own payroll information
- ✅ Access employee dashboard

**Cannot:**
- ❌ View or manage team data
- ❌ Approve requests
- ❌ Create or edit other users
- ❌ Access admin dashboards

### 2. MANAGER (Team Lead Role)
**Inherits all EMPLOYEE permissions, plus:**
- ✅ View team attendance and approve/reject
- ✅ View team leave requests and approve/reject
- ✅ View team member profiles
- ✅ Send notifications to team members
- ✅ View and approve team expense claims
- ✅ Assign support tickets
- ✅ Access manager dashboard

**Cannot:**
- ❌ View organization-wide data
- ❌ Create or delete users
- ❌ Manage assets
- ❌ Process payroll

### 3. HR_ADMIN (Full Access Role)
**Inherits all MANAGER permissions, plus:**
- ✅ View and edit all attendance records
- ✅ View and approve all leave requests
- ✅ Create, edit, and delete users
- ✅ Assign roles to users
- ✅ Manage all assets (create, assign, edit, delete)
- ✅ Send notifications to all employees
- ✅ View and resolve all support tickets
- ✅ View and approve all expense claims
- ✅ Process and edit payroll
- ✅ Access all dashboards (HR, Payroll, Attendance, IT Admin)
- ✅ Edit organization settings

## Frontend Implementation

### Permission Checks in Widgets

#### Using PermissionGuard
```dart
PermissionGuard(
  permission: Permission.USER_CREATE,
  child: ElevatedButton(
    onPressed: () => createUser(),
    child: Text('Create User'),
  ),
  fallback: Text('You don\'t have permission'), // Optional
  hideIfNoPermission: true, // Default: true
)
```

#### Using PermissionButton
```dart
PermissionButton(
  permission: Permission.LEAVE_APPROVE_TEAM,
  onPressed: () => approveLeave(),
  child: Text('Approve Leave'),
)
```

#### Using PermissionFAB
```dart
PermissionFAB(
  permission: Permission.ASSET_CREATE,
  onPressed: () => createAsset(),
  child: Icon(Icons.add),
  tooltip: 'Create Asset',
)
```

#### Using Permission Provider
```dart
Consumer(
  builder: (context, ref, child) {
    final canEdit = ref.watch(permissionProvider(Permission.USER_EDIT_ALL));
    
    return IconButton(
      icon: Icon(Icons.edit),
      onPressed: canEdit ? () => editUser() : null,
    );
  },
)
```

#### Using Extension Method
```dart
class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.can(Permission.ATTENDANCE_VIEW_ALL)) {
      return AllAttendanceView();
    }
    return OwnAttendanceView();
  }
}
```

### Checking Multiple Permissions

```dart
// Check if user has ANY of these permissions
if (ref.canAny([
  Permission.LEAVE_APPROVE_TEAM,
  Permission.LEAVE_APPROVE_ALL,
])) {
  // Show approval UI
}

// Check if user has ALL of these permissions
if (ref.canAll([
  Permission.USER_CREATE,
  Permission.USER_ASSIGN_ROLES,
])) {
  // Show admin user creation UI
}
```

## Backend Implementation

### Using Role-Based Guards

#### Protect entire controller
```typescript
@Controller('users')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles(Role.HR_ADMIN)
export class UsersController {
  // All routes require HR_ADMIN role
}
```

#### Protect specific routes
```typescript
@Controller('attendance')
@UseGuards(JwtAuthGuard)
export class AttendanceController {
  @Get('my-attendance')
  getMyAttendance(@Request() req) {
    // Any authenticated user can access
  }

  @Get('team-attendance')
  @UseGuards(RolesGuard)
  @Roles(Role.MANAGER, Role.HR_ADMIN)
  getTeamAttendance(@Request() req) {
    // Only MANAGER and HR_ADMIN can access
  }
}
```

### Using Permission-Based Guards

```typescript
@Controller('leave')
@UseGuards(JwtAuthGuard, PermissionsGuard)
export class LeaveController {
  @Post('approve/:id')
  @RequirePermissions(
    Permission.LEAVE_APPROVE_TEAM,
    Permission.LEAVE_APPROVE_ALL,
  )
  approveLeave(@Param('id') id: string, @Request() req) {
    // User needs EITHER permission to access
  }
}
```

### Checking Permissions in Service Logic

```typescript
import { PermissionService, Permission } from './auth/permissions/permissions.service';

export class LeaveService {
  async getLeaves(userId: string, userRole: Role) {
    if (PermissionService.hasPermission(userRole, Permission.LEAVE_VIEW_ALL)) {
      // Return all leaves
      return this.prisma.leave.findMany();
    } else if (PermissionService.hasPermission(userRole, Permission.LEAVE_VIEW_TEAM)) {
      // Return team leaves
      return this.getTeamLeaves(userId);
    } else {
      // Return only user's leaves
      return this.getUserLeaves(userId);
    }
  }
}
```

## Dynamic Island Notifications

All notifications and popups in the app use the Dynamic Island component with proper theming:

### Light Mode
- Background: **Dark Grey** (#2C2C2E - iOS system grey)
- Text: **White**
- Shadow: **Black with 30% opacity**

### Dark Mode
- Background: **White**
- Text: **Black**
- Shadow: **Black with 20% opacity**

### Usage

```dart
// Success notification
DynamicIslandManager().show(
  context,
  message: 'Leave approved successfully',
  isError: false,
);

// Error notification
DynamicIslandManager().show(
  context,
  message: 'Failed to submit claim',
  isError: true,
);
```

### Features
- ✅ Auto-dismisses after 4 seconds
- ✅ Can be dismissed by tapping or swiping
- ✅ Queues multiple notifications
- ✅ Smooth animations
- ✅ Adapts to light/dark theme
- ✅ Success/Error indicators

## Permission Matrix

| Feature | Employee | Manager | HR Admin |
|---------|----------|---------|----------|
| **Attendance** |
| View own | ✅ | ✅ | ✅ |
| Mark own | ✅ | ✅ | ✅ |
| View team | ❌ | ✅ | ✅ |
| Approve team | ❌ | ✅ | ✅ |
| View all | ❌ | ❌ | ✅ |
| Edit all | ❌ | ❌ | ✅ |
| **Leave** |
| View own | ✅ | ✅ | ✅ |
| Apply | ✅ | ✅ | ✅ |
| Cancel own | ✅ | ✅ | ✅ |
| View team | ❌ | ✅ | ✅ |
| Approve team | ❌ | ✅ | ✅ |
| View all | ❌ | ❌ | ✅ |
| Approve all | ❌ | ❌ | ✅ |
| **Users** |
| View directory | ✅ | ✅ | ✅ |
| View profiles | ✅ | ✅ | ✅ |
| Edit own profile | ✅ | ✅ | ✅ |
| View team | ❌ | ✅ | ✅ |
| Create users | ❌ | ❌ | ✅ |
| Edit all users | ❌ | ❌ | ✅ |
| Delete users | ❌ | ❌ | ✅ |
| Assign roles | ❌ | ❌ | ✅ |
| **Assets** |
| View own | ✅ | ✅ | ✅ |
| Request | ✅ | ✅ | ✅ |
| View all | ❌ | ❌ | ✅ |
| Create | ❌ | ❌ | ✅ |
| Assign | ❌ | ❌ | ✅ |
| Edit | ❌ | ❌ | ✅ |
| Delete | ❌ | ❌ | ✅ |
| **Notifications** |
| View own | ✅ | ✅ | ✅ |
| Send to team | ❌ | ✅ | ✅ |
| Send to all | ❌ | ❌ | ✅ |

## Best Practices

### Frontend
1. **Always use permission checks** for sensitive UI elements
2. **Hide rather than disable** when possible (better UX)
3. **Show appropriate fallback** messages when permission is denied
4. **Check permissions early** in the widget tree to avoid unnecessary rendering

### Backend
1. **Always protect routes** with guards
2. **Use both role and permission checks** for defense in depth
3. **Validate permissions in service layer** as well as controller
4. **Return appropriate HTTP status codes** (403 Forbidden for permission denied)
5. **Log permission violations** for security auditing

## Testing Permissions

### Frontend Testing
```dart
testWidgets('Only HR Admin can see create user button', (tester) async {
  // Test with EMPLOYEE role
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        currentUserProvider.overrideWithValue(employeeUser),
      ],
      child: MyApp(),
    ),
  );
  expect(find.text('Create User'), findsNothing);

  // Test with HR_ADMIN role
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        currentUserProvider.overrideWithValue(hrAdminUser),
      ],
      child: MyApp(),
    ),
  );
  expect(find.text('Create User'), findsOneWidget);
});
```

### Backend Testing
```typescript
describe('LeaveController', () => {
  it('should deny access to team leaves for EMPLOYEE', async () => {
    const response = await request(app.getHttpServer())
      .get('/leave/team')
      .set('Authorization', `Bearer ${employeeToken}`)
      .expect(403);
  });

  it('should allow access to team leaves for MANAGER', async () => {
    const response = await request(app.getHttpServer())
      .get('/leave/team')
      .set('Authorization', `Bearer ${managerToken}`)
      .expect(200);
  });
});
```

## Future Enhancements

1. **Custom Permissions**: Allow creating custom permissions per organization
2. **Permission Groups**: Group permissions for easier management
3. **Temporary Permissions**: Grant time-limited permissions
4. **Permission Audit Log**: Track who granted/revoked permissions
5. **UI Permission Builder**: Visual tool for managing role permissions

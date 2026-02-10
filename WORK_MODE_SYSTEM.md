# Work Mode-Based Attendance System

## Overview
The HRMS app now supports **4 different work modes**, each with specific attendance verification requirements:

### Work Modes

1. **OFFICE** - Working from office location
   - ✅ Geofence verification (200m radius around Olympia Pinnacle)
   - ✅ Biometric authentication (Fingerprint/Face ID)
   - ✅ Clock In/Out tracking
   - ✅ Map display with office marker and geofence circle

2. **REMOTE** - Working from home
   - ❌ No geofence verification
   - ❌ No biometric authentication
   - ✅ Simple Clock In/Out
   - ❌ No map display (not needed)

3. **FIELD_WORK** - Visiting client locations
   - ❌ No geofence restriction
   - ✅ Biometric authentication (optional, can be configured)
   - ✅ Location tracked when clocking in at client site
   - ✅ Map display showing current location
   - ✅ GPS coordinates recorded in database

4. **ON_DUTY (OD)** - Field visits and tasks
   - ❌ No geofence restriction
   - ✅ Biometric authentication (optional, can be configured)
   - ✅ Location tracking for all visits
   - ✅ Map display
   - ✅ Manager approval workflow

## User Flow

### 1. Login
- User logs in with credentials
- Authentication is verified

### 2. Work Mode Selection
- After successful login, user is presented with work mode selection screen
- User chooses their work mode for the day:
  - Office (if working from office)
  - Remote (if working from home)
  - Field Work (if visiting client sites)
  - On Duty (if doing field visits)

### 3. Attendance Marking
Based on selected work mode:

#### Office Mode:
1. User must be within 200m of office (Olympia Pinnacle)
2. Biometric prompt appears
3. After successful authentication, Clock In/Out is recorded
4. Location is stored in database

#### Remote Mode:
1. Simple Clock In/Out buttons
2. No location or biometric verification
3. Attendance is recorded with timestamp only

#### Field Work Mode:
1. User clocks in when reaching client location
2. GPS coordinates are captured and stored
3. Map shows current location
4. Biometric verification (if enabled)

#### On Duty Mode:
1. Similar to Field Work
2. Additional "Start Visit" / "End Visit" buttons
3. Each visit location is tracked
4. Requires manager approval

## Database Schema Changes

### User Model
```prisma
model User {
  workMode WorkMode @default(OFFICE) @map("work_mode")
  // ... other fields
}

enum WorkMode {
  OFFICE       // Geofence + Biometric + Clock In/Out
  REMOTE       // Clock In/Out only
  FIELD_WORK   // Location tracking when reaching client site
  ON_DUTY      // Location tracking for field visits
}
```

### AttendanceActivity Model
```prisma
model AttendanceActivity {
  workMode WorkMode? @map("work_mode") // Track which mode was active during punch
  latitude Float?
  longitude Float?
  address String?
  // ... other fields
}
```

## Frontend Implementation

### Key Files Created/Modified:

1. **work_mode_selection_screen.dart**
   - Beautiful UI with 4 work mode cards
   - Each card shows features and requirements
   - Saves selection to SharedPreferences

2. **work_mode_provider.dart**
   - Manages work mode state
   - Persists selection across app restarts
   - Helper methods: `requiresGeofence`, `requiresBiometric`, `requiresLocationTracking`

3. **attendance_screen.dart**
   - Conditionally shows/hides map based on work mode
   - Adapts button enable logic
   - Shows appropriate messages

4. **app_router.dart**
   - Redirects to work mode selection after login
   - Ensures work mode is set before accessing app

5. **user_model.dart**
   - Added `workMode` field

## Manager Approval Workflow

For Field Work and OD modes:
1. Employee marks attendance with location
2. Attendance record includes:
   - Timestamp
   - GPS coordinates
   - Address (reverse geocoded)
   - Work mode used
3. Manager can view team attendance in Manager Dashboard
4. Manager sees location data for field workers
5. Manager approves/rejects attendance

## Attendance Calculation Logic

**"First In, Last Out" Rule:**
- Only the first Clock In and last Clock Out of the day count
- Intermediate breaks (lunch, tea) are ignored
- Total hours = Last Clock Out - First Clock In
- This applies to ALL work modes

## Security Features

### Office Mode:
- **Geofencing**: Prevents clocking in from outside office
- **Biometric**: Ensures the right person is marking attendance
- **Location Verification**: GPS coordinates must match office location

### Field Work/OD Modes:
- **Location Tracking**: Every punch records GPS coordinates
- **Audit Trail**: Manager can verify employee was at claimed location
- **Biometric**: Optional, can be enabled for extra security

### Remote Mode:
- **Trust-Based**: No location verification
- **Time-Based**: Only timestamps are recorded
- **Suitable for**: Work-from-home employees

## Configuration

### Enabling/Disabling Biometric for Non-Office Modes:
In `attendance_screen.dart`, line 85-98:
```dart
if (workModeNotifier.requiresBiometric) {
  // Biometric check
}
```

To enable biometric for Field Work/OD, update `work_mode_provider.dart`:
```dart
bool get requiresBiometric => isOfficeMode || isFieldWorkMode || isOnDutyMode;
```

### Changing Geofence Radius:
In `attendance_screen.dart`, line 27:
```dart
final LatLng _officeLocation = const LatLng(13.010236, 80.220626);
```

And line 168:
```dart
radius: 200, // Change this value (in meters)
```

## Testing

### Test Scenarios:

1. **Office Mode**:
   - Try clocking in from home (should fail)
   - Go to office location (should succeed)
   - Test biometric authentication

2. **Remote Mode**:
   - Clock in from anywhere (should work)
   - Verify no map is shown
   - Check no location is stored

3. **Field Work Mode**:
   - Clock in from different locations
   - Verify GPS coordinates are captured
   - Check map shows current location

4. **On Duty Mode**:
   - Test Start/End Visit buttons
   - Verify each visit location is tracked
   - Check manager can see visit history

## Next Steps

1. **Backend Integration**:
   - Update attendance API to accept `workMode` parameter
   - Store work mode with each attendance record
   - Implement manager approval endpoints

2. **Manager Dashboard**:
   - Show team attendance with work modes
   - Display location data for field workers
   - Add approval/rejection buttons

3. **Reporting**:
   - Generate reports by work mode
   - Show location history for field workers
   - Track work mode usage patterns

4. **Notifications**:
   - Remind users to select work mode
   - Alert managers of pending approvals
   - Notify field workers of geofence entry/exit

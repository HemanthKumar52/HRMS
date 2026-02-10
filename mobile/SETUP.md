# HRMS Mobile App - Setup Guide

Complete setup instructions for the Flutter mobile application.

## Prerequisites

- Flutter SDK 3.16+
- Dart SDK 3.2+
- Android Studio (for Android development)
- Xcode (for iOS development, macOS only)
- Backend API running (see backend setup)

## Quick Start

```bash
cd mobile

# Get dependencies
flutter pub get

# Run the app (ensure backend is running first)
flutter run
```

## Backend Connection

The mobile app requires the backend API. Start it first:

```bash
cd backend
npm install
cp .env.example .env  # Configure your database
npx prisma generate
npx prisma db push
npx prisma db seed
npm run start:dev
```

The API runs at `http://localhost:3000`

## Test Credentials

| Role | Email | Password |
|------|-------|----------|
| HR Admin | hr@acme.com | password123 |
| Manager | manager@acme.com | password123 |
| Employee | employee@acme.com | password123 |

## API Configuration

Update the API URL in `lib/core/constants/api_constants.dart`:

```dart
static String get baseUrl {
  if (kIsWeb) return 'http://localhost:3000/api/v1';
  if (Platform.isAndroid) return 'http://10.0.2.2:3000/api/v1';
  return 'http://localhost:3000/api/v1';
}
```

**Note**: Android emulator uses `10.0.2.2` to access localhost.

## Platform Setup

### Android

Permissions are already configured in `android/app/src/main/AndroidManifest.xml`:
- Internet access
- Fine and coarse location (for attendance)

Min SDK: 21 (Android 5.0+)

### iOS

Add location permissions to `ios/Runner/Info.plist`:
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>HRMS needs location access to record attendance.</string>
```

Update `ios/Podfile`:
```ruby
platform :ios, '12.0'
```

## Project Structure

```
lib/
├── main.dart              # Entry point
├── app.dart               # App configuration
├── core/
│   ├── constants/         # API endpoints, app constants
│   ├── theme/             # Colors, gradients, theme
│   ├── network/           # Dio client, interceptors
│   └── services/          # Offline sync, biometrics
├── features/
│   ├── auth/              # Login, work mode selection
│   ├── home/              # Role-based dashboards
│   ├── attendance/        # Clock in/out
│   ├── leave/             # Leave management
│   ├── directory/         # Employee directory
│   ├── profile/           # User profile
│   └── notifications/     # Notifications
├── routes/                # GoRouter navigation
└── shared/                # Models, providers, widgets
```

## Key Features

### Work Mode Selection
After login, users select their work mode:
- **Office**: Biometric + geofence verification
- **Remote**: Simple clock in/out
- **On-Duty**: GPS location captured

### Role-Based Dashboards
- **Employee**: Personal attendance, leave balance, quick actions
- **Manager**: Team overview, pending approvals
- **HR Admin**: Organization stats, employee management

### Attendance Tracking
- Real-time timer display
- GPS location capture (On-Duty mode)
- Clock in/out with verification

## State Management

Using Riverpod:
- `StateNotifierProvider` for auth state
- `FutureProvider` for async data
- `StreamProvider` for real-time updates

## Running on Devices

```bash
# List available devices
flutter devices

# Run on specific device
flutter run -d <device_id>

# Run on Android emulator
flutter run -d android

# Run on iOS simulator (macOS only)
flutter run -d ios

# Run on Chrome
flutter run -d chrome
```

## Building for Release

### Android
```bash
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

### iOS
```bash
flutter build ios --release
# Open ios/Runner.xcworkspace in Xcode to archive
```

## Troubleshooting

### Connection Refused
Ensure backend is running:
```bash
cd backend && npm run start:dev
```

### Build Errors
```bash
flutter clean
flutter pub get
flutter run
```

### Android Emulator Network Issues
Use `10.0.2.2` instead of `localhost` in API URL.

### CocoaPods Issues (iOS)
```bash
cd ios && pod install --repo-update
```

## Dependencies

Key packages used:
- `flutter_riverpod` - State management
- `go_router` - Navigation
- `dio` - HTTP client
- `flutter_secure_storage` - Token storage
- `flutter_map` - Maps for location
- `local_auth` - Biometric authentication
- `geolocator` - GPS location

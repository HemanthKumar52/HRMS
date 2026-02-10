# HRMS Mobile App - Setup Guide

## Quick Start

### Prerequisites
- Flutter SDK 3.2.0 or higher
- Dart SDK 3.2.0 or higher
- Android Studio (for Android) or Xcode (for iOS/macOS)
- Visual Studio with "Desktop development with C++" workload (for Windows)

### 1. Initialize Flutter Platform Files
```bash
cd mobile
flutter create . --org com.hrms --project-name hrms_mobile
```

### 2. Install Dependencies
```bash
flutter pub get
```

### 3. Run the App
```bash
# Android
flutter run -d android

# iOS (macOS only)
flutter run -d ios

# Windows
flutter run -d windows

# macOS
flutter run -d macos

# Linux
flutter run -d linux

# Web
flutter run -d chrome
```

## Backend Setup

The mobile app requires the backend API to be running. Start the backend first:

```bash
# From the root hrms-app directory
docker-compose up -d postgres redis
cd backend
npm install
npm run prisma:generate
npm run prisma:migrate:dev
npm run seed
npm run start:dev
```

The API will be available at `http://localhost:3000`.

## Demo Credentials

After running the seed command, use these credentials to log in:

| Email | Password | Role |
|-------|----------|------|
| employee@acme.com | password123 | Employee |
| manager@acme.com | password123 | Manager |
| hr@acme.com | password123 | HR Admin |

## Platform-Specific Configuration

### Android

Add permissions to `android/app/src/main/AndroidManifest.xml`:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">

    <!-- Internet -->
    <uses-permission android:name="android.permission.INTERNET"/>

    <!-- Location for Attendance -->
    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>

    <!-- For url_launcher -->
    <queries>
        <intent>
            <action android:name="android.intent.action.VIEW" />
            <data android:scheme="tel" />
        </intent>
        <intent>
            <action android:name="android.intent.action.SENDTO" />
            <data android:scheme="mailto" />
        </intent>
    </queries>

    <application
        android:label="HRMS"
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher">
        <!-- ... -->
    </application>
</manifest>
```

Update `android/app/build.gradle`:
```gradle
android {
    defaultConfig {
        minSdkVersion 21
    }
}
```

### iOS

Add permissions to `ios/Runner/Info.plist`:

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>HRMS needs location access to record attendance.</string>
<key>NSLocationAlwaysUsageDescription</key>
<string>HRMS needs location access to record attendance.</string>
```

Update `ios/Podfile`:
```ruby
platform :ios, '12.0'
```

### macOS

Add to `macos/Runner/DebugProfile.entitlements` and `Release.entitlements`:

```xml
<key>com.apple.security.network.client</key>
<true/>
```

### Windows

Ensure you have Visual Studio 2019+ with C++ desktop development workload.

### Linux

Install required packages:
```bash
sudo apt install clang cmake ninja-build pkg-config libgtk-3-dev libglib2.0-dev
```

## Features

- **Authentication**: Login/logout with JWT tokens
- **Leave Management**: View balance, apply for leave, view history
- **Attendance**: Clock in/out with GPS tracking, offline support
- **Employee Directory**: Search and view employee profiles
- **Notifications**: View and manage notifications

## Offline Support

The app supports offline attendance punching:
- Punches are stored locally when offline using Hive
- Automatic sync when connectivity is restored
- Manual sync available via "Sync Now" button
- Pending punches shown in a banner

### How It Works

1. **Offline Detection**: Uses `connectivity_plus` to detect network status
2. **Local Storage**: Stores punches in Hive database (no code generation needed)
3. **Auto Sync**: Automatically syncs when coming back online
4. **Periodic Sync**: Syncs every 15 minutes while app is running
5. **Retry Logic**: Failed syncs are retried up to 3 times

## Architecture

```
lib/
├── main.dart           # App entry point
├── app.dart            # MaterialApp configuration
├── core/
│   ├── constants/      # API endpoints, app constants
│   ├── theme/          # App theme, colors
│   ├── network/        # Dio client, interceptors
│   ├── services/       # Offline queue, sync, connectivity
│   └── utils/          # Extensions, helpers
├── features/
│   ├── auth/           # Authentication
│   ├── leave/          # Leave management
│   ├── attendance/     # Attendance tracking
│   ├── directory/      # Employee directory
│   ├── notifications/  # Notifications
│   └── home/           # Dashboard
├── routes/             # GoRouter configuration
└── shared/             # Shared models, widgets
```

## State Management

Using Riverpod for state management:
- `StateNotifierProvider` for mutable state (auth, punch)
- `FutureProvider` for async data fetching
- `StreamProvider` for reactive data (connectivity, sync queue)
- `Provider` for dependency injection

## API Configuration

The API URL is configured in `lib/core/constants/api_constants.dart`:

```dart
static String get baseUrl {
  if (kIsWeb) return 'http://localhost:3000/api/v1';
  if (Platform.isAndroid) return 'http://10.0.2.2:3000/api/v1';
  return 'http://localhost:3000/api/v1';
}
```

For production, update with your actual API URL.

## Testing Offline Functionality

1. Start the app and log in
2. Turn on airplane mode
3. Try to clock in/out - should show "Punch saved offline"
4. Check pending sync banner appears
5. Turn off airplane mode
6. Punches should sync automatically (or tap "Sync Now")

## Troubleshooting

### Connection Refused
Make sure the backend is running on port 3000:
```bash
cd backend && npm run start:dev
```

### Location Permission Denied
The app will still work without location - GPS coordinates will be null.

### Offline Sync Not Working
Check the connectivity banner on the attendance screen. Use "Sync Now" to manually trigger sync.

### Build Errors
```bash
flutter clean
flutter pub get
flutter run
```

### CocoaPods Issues (iOS/macOS)
```bash
sudo gem install cocoapods
cd ios && pod install
```

## Adding Push Notifications (Optional)

The current build uses a stub for push notifications. To enable real push notifications:

1. Create a Firebase project at https://console.firebase.google.com
2. Add your Android/iOS apps to Firebase
3. Download configuration files:
   - Android: `google-services.json` → `android/app/`
   - iOS: `GoogleService-Info.plist` → `ios/Runner/`
4. Add Firebase dependencies to `pubspec.yaml`:
   ```yaml
   firebase_core: ^2.24.0
   firebase_messaging: ^14.7.0
   ```
5. Replace `push_notification_service.dart` with Firebase implementation

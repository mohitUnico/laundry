# Laundry App - Delivery Partner Mobile App

Flutter mobile application for delivery partners to manage pickup and delivery tasks.

## Features

- 🔐 **Authentication**: Login and profile verification
- 📦 **Task Management**: View and accept delivery tasks
- 📍 **GPS Tracking**: Real-time location tracking during deliveries
- 🗺️ **Navigation**: Integrated maps for route guidance
- 📸 **Proof of Service**: Mandatory photo capture for pickup and delivery
- 💰 **Earnings Tracking**: Real-time earnings and payment history
- 📊 **Performance Stats**: Delivery completion rate and ratings
- 🔔 **Push Notifications**: Instant task assignments
- ⏱️ **Time Tracking**: Duration tracking for deliveries
- ⭐ **Ratings**: Customer ratings and feedback

## Tech Stack

- **Framework**: Flutter 3.x
- **Language**: Dart
- **State Management**: Provider
- **Navigation**: GoRouter
- **HTTP Client**: Dio
- **Maps**: Google Maps Flutter
- **Location**: Geolocator & Location packages
- **Push Notifications**: Firebase Cloud Messaging
- **Local Storage**: SharedPreferences & Secure Storage

## Getting Started

### Prerequisites

- Flutter SDK 3.0 or higher
- Dart SDK 3.0 or higher
- Android Studio / Xcode for platform-specific development
- Backend API running
- Location permissions enabled

### Installation

```bash
# Get dependencies
flutter pub get

# Run the app
flutter run
```

### Configuration

1. Update API base URL in `lib/services/api_service.dart`
2. Configure Google Maps API key in platform-specific files:
   - Android: `android/app/src/main/AndroidManifest.xml`
   - iOS: `ios/Runner/AppDelegate.swift`
3. Set up Firebase for push notifications
4. Configure location permissions in manifest files

## Project Structure

```
delivery-app/
├── lib/
│   ├── main.dart                # App entry point
│   ├── app.dart                 # Root widget
│   ├── screens/                 # Full-screen pages
│   │   ├── auth/               # Authentication screens
│   │   ├── home/               # Dashboard & task list
│   │   ├── delivery/           # Active delivery tracking
│   │   ├── earnings/           # Earnings and payments
│   │   └── profile/            # Partner profile
│   ├── widgets/                # Reusable widgets
│   │   ├── common/            # Generic widgets
│   │   └── features/          # Feature-specific widgets
│   ├── providers/             # State management
│   ├── models/                # Data models
│   ├── services/              # API and services
│   ├── utils/                 # Utilities
│   ├── routes/                # Navigation
│   └── theme/                 # App theme
├── assets/                    # Images, fonts, icons
├── test/                      # Tests
└── pubspec.yaml
```

## Development

### Run on Specific Platform

```bash
# Android
flutter run -d android

# iOS
flutter run -d ios
```

### Build

```bash
# Android APK
flutter build apk --release

# Android App Bundle
flutter build appbundle --release

# iOS
flutter build ios --release
```

### Testing

```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage
```

## Screens Overview

### Authentication Flow
1. **Login Screen**: Phone number or email login
2. **Verification Screen**: Document verification status
3. **Profile Setup**: Complete profile with vehicle details

### Main Flow
1. **Home Screen**: Available delivery tasks
2. **Task Details**: View task information and accept/decline
3. **Active Delivery**: Navigation and tracking
4. **Photo Proof**: Capture pickup and delivery photos
5. **Earnings**: Daily/weekly earnings breakdown
6. **Profile**: Partner details and performance stats

## State Management

Using Provider pattern for state management:

```dart
// Example Provider
class DeliveryProvider with ChangeNotifier {
  List<Delivery> _tasks = [];
  Delivery? _activeDelivery;
  
  Future<void> fetchTasks() async {
    _tasks = await deliveryService.getAvailableTasks();
    notifyListeners();
  }
  
  Future<void> acceptTask(String taskId) async {
    _activeDelivery = await deliveryService.acceptTask(taskId);
    notifyListeners();
  }
}
```

## Location Services

The app requires location permissions to:
- Track delivery partner location in real-time
- Provide navigation to pickup and delivery addresses
- Calculate distance and estimated arrival times
- Log delivery routes for verification

### Android Permissions
```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
```

### iOS Permissions
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>We need your location to track deliveries</string>
<key>NSLocationAlwaysUsageDescription</key>
<string>We need your location in the background for active deliveries</string>
```

## Contributing

Follow the coding standards defined in `.cursor/rules/frontend/flutter-coding-standards.mdc`.

## License

Proprietary - Laundry App


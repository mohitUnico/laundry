# Laundry App - Customer Mobile App

Flutter mobile application for customers to place and track laundry orders.

## Features

- 🔐 **Authentication**: OTP-based login and registration
- 🏠 **Mart Discovery**: Find nearby laundry marts
- 🧺 **Service Catalog**: Browse services and pricing
- 📦 **Order Creation**: Place orders with pickup and delivery scheduling
- 📍 **Address Management**: Save multiple addresses with geolocation
- 🚚 **Order Tracking**: Real-time order status tracking
- 💳 **Multiple Payment Options**: Card, COD, UPI, Wallet
- ⭐ **Ratings & Reviews**: Rate services and delivery
- 📜 **Order History**: View past orders and reorder

## Tech Stack

- **Framework**: Flutter 3.x
- **Language**: Dart
- **State Management**: Provider
- **Navigation**: GoRouter
- **HTTP Client**: Dio
- **Maps**: Google Maps Flutter
- **Push Notifications**: Firebase Cloud Messaging
- **Local Storage**: SharedPreferences & Secure Storage

## Getting Started

### Prerequisites

- Flutter SDK 3.0 or higher
- Dart SDK 3.0 or higher
- Android Studio / Xcode for platform-specific development
- Backend API running

### Installation

```bash
# Get dependencies
flutter pub get

# Run code generation (if needed)
# flutter pub run build_runner build

# Run the app
flutter run
```

### Configuration

1. Update API base URL in `lib/services/api_service.dart`
2. Configure Google Maps API key in platform-specific files:
   - Android: `android/app/src/main/AndroidManifest.xml`
   - iOS: `ios/Runner/AppDelegate.swift`
3. Set up Firebase for push notifications

## Project Structure

```
customer-app/
├── lib/
│   ├── main.dart                # App entry point
│   ├── app.dart                 # Root widget
│   ├── screens/                 # Full-screen pages
│   │   ├── auth/               # Authentication screens
│   │   ├── home/               # Home screen
│   │   ├── orders/             # Order management
│   │   ├── services/           # Service catalog
│   │   ├── addresses/          # Address management
│   │   └── profile/            # User profile
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

# Chrome (for web testing)
flutter run -d chrome
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
1. **Login Screen**: Phone number entry
2. **OTP Screen**: Verification code input
3. **Registration**: First-time user details

### Main Flow
1. **Home Screen**: Mart discovery and featured services
2. **Service Catalog**: Browse available services
3. **Create Order**: Select items and schedule pickup/delivery
4. **Order Tracking**: Real-time status updates
5. **Order History**: Past orders and reorder functionality
6. **Profile**: User details and settings

## State Management

Using Provider pattern for state management:

```dart
// Example Provider
class OrderProvider with ChangeNotifier {
  List<Order> _orders = [];
  
  Future<void> fetchOrders() async {
    _orders = await orderService.getOrders();
    notifyListeners();
  }
}

// Usage in Widget
Consumer<OrderProvider>(
  builder: (context, provider, child) {
    return ListView.builder(
      itemCount: provider.orders.length,
      itemBuilder: (context, index) {
        return OrderCard(order: provider.orders[index]);
      },
    );
  },
)
```

## Contributing

Follow the coding standards defined in `.cursor/rules/frontend/flutter-coding-standards.mdc`.

## License

Proprietary - Laundry App


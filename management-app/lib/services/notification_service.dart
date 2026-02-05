import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'api_service.dart';

/// Top-level handler for FCM when app is in background or terminated.
/// Must be top-level (not a class method) for Firebase.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Delivery staff: background FCM messageId=${message.messageId}');
  debugPrint('Delivery staff: data=${message.data}');
  // Notification is shown by the system when app is backgrounded/terminated.
  // No need to show locally; user can tap to open app.
}

/// FCM notification service for delivery staff (assignment requests when app is closed).
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  FirebaseMessaging? _firebaseMessaging;
  final ApiService _apiService = ApiService();
  bool _isInitialized = false;

  /// Initialize Firebase Messaging and handlers. Call from main() before runApp.
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _firebaseMessaging = FirebaseMessaging.instance;

      final settings = await _firebaseMessaging!.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        debugPrint('Delivery staff: notification permission granted');
      } else {
        debugPrint('Delivery staff: notification permission denied');
        _isInitialized = true;
        return;
      }

      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      FirebaseMessaging.onMessage.listen(_onForegroundMessage);
      FirebaseMessaging.onMessageOpenedApp.listen(_onNotificationTap);

      final initialMessage = await _firebaseMessaging!.getInitialMessage();
      if (initialMessage != null) {
        _onNotificationTap(initialMessage);
      }

      _firebaseMessaging!.onTokenRefresh.listen((String newToken) {
        debugPrint('Delivery staff: FCM token refreshed');
        saveTokenToBackend(newToken);
      });

      final token = await _firebaseMessaging!.getToken();
      if (token != null) {
        debugPrint('Delivery staff: FCM token obtained');
        // Save will be called from delivery home screen when user is logged in
      }

      _isInitialized = true;
      debugPrint('Delivery staff: NotificationService initialized');
    } catch (e) {
      debugPrint('Delivery staff: NotificationService init error: $e');
    }
  }

  void _onForegroundMessage(RemoteMessage message) {
    debugPrint('Delivery staff: foreground message ${message.messageId}');
    // When app is open we rely on SSE for assignment request popup; FCM in foreground can be ignored or shown as in-app banner
  }

  void _onNotificationTap(RemoteMessage message) {
    debugPrint('Delivery staff: notification tapped, data=${message.data}');
    // App opens; delivery home will load and show assignments. No deep link needed for now.
  }

  /// Save current FCM token to backend. Call when delivery staff is logged in (e.g. from delivery home screen).
  Future<void> saveTokenToBackend(String? token) async {
    if (token == null || token.isEmpty) return;
    try {
      await _apiService.post(
        '/delivery-staff/fcm-token',
        data: {'fcmToken': token},
      );
      debugPrint('Delivery staff: FCM token saved to backend');
    } catch (e) {
      debugPrint('Delivery staff: failed to save FCM token: $e');
    }
  }

  /// Get current FCM token and save to backend. Call from delivery partner home when user is logged in.
  Future<void> refreshAndSaveToken() async {
    if (!_isInitialized || _firebaseMessaging == null) return;
    try {
      final token = await _firebaseMessaging!.getToken();
      await saveTokenToBackend(token);
    } catch (e) {
      debugPrint('Delivery staff: refreshAndSaveToken error: $e');
    }
  }

  bool get isInitialized => _isInitialized;
}

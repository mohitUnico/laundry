import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';

import 'api_service.dart';

/// Top-level function for handling background messages
/// Must be a top-level function (not a class method) for Firebase
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Firebase is already initialized when this handler is called
  debugPrint('Handling a background message: ${message.messageId}');
  debugPrint('Message data: ${message.data}');
  debugPrint('Message notification: ${message.notification?.title}');
  
  // Process order status change if present
  final orderId = message.data['order_id'] as String?;
  final status = message.data['status'] as String?;
  if (orderId != null && status != null) {
    debugPrint('Order status changed in background: Order $orderId -> $status');
  }
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  FirebaseMessaging? _firebaseMessaging;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final ApiService _apiService = ApiService();

  bool _isInitialized = false;
  String? _currentToken;
  Function(String orderId)? onOrderStatusChanged;

  /// Initialize notification service
  Future<void> initialize() async {
    if (_isInitialized) {
      debugPrint('NotificationService already initialized');
      return;
    }

    try {
      // Check if Firebase is initialized and get messaging instance
      try {
        _firebaseMessaging = FirebaseMessaging.instance;
      } catch (e) {
        debugPrint('Firebase not initialized, skipping notification service setup: $e');
        return;
      }

      if (_firebaseMessaging == null) {
        debugPrint('Firebase Messaging not available');
        return;
      }

      // Request notification permissions
      final NotificationSettings settings =
          await _firebaseMessaging!.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('User granted notification permission');
      } else if (settings.authorizationStatus ==
          AuthorizationStatus.provisional) {
        debugPrint('User granted provisional notification permission');
      } else {
        debugPrint('User declined or has not accepted notification permission');
        _isInitialized = true;
        return;
      }

      // Initialize local notifications for foreground messages
      await _initializeLocalNotifications();

      // Set up background message handler
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle notification taps when app is in background
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

      // Check if app was opened from a notification
      final RemoteMessage? initialMessage =
          await _firebaseMessaging!.getInitialMessage();
      if (initialMessage != null) {
        _handleNotificationTap(initialMessage);
      }

      // Get and save FCM token
      await _getAndSaveToken();

      // Listen for token refresh
      _firebaseMessaging!.onTokenRefresh.listen(_handleTokenRefresh);

      _isInitialized = true;
      debugPrint('NotificationService initialized successfully');
    } catch (e) {
      debugPrint('Error initializing NotificationService: $e');
    }
  }

  /// Initialize local notifications plugin
  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        debugPrint('Notification tapped: ${response.payload}');
        if (response.payload != null) {
          _handleNotificationPayload(response.payload!);
        }
      },
    );

    // Create notification channel for Android
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'order_status_channel',
      'Order Status Updates',
      description: 'Notifications for order status changes',
      importance: Importance.high,
      playSound: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  /// Handle foreground messages (when app is open)
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('Got a message whilst in the foreground!');
    debugPrint('Message data: ${message.data}');

    if (message.notification != null) {
      _showLocalNotification(
        message.notification!.title ?? 'Order Update',
        message.notification!.body ?? '',
        message.data,
      );
    }

    // Process order status change
    _processOrderStatusChange(message.data);
  }

  /// Handle notification tap
  void _handleNotificationTap(RemoteMessage message) {
    debugPrint('Notification tapped: ${message.messageId}');
    debugPrint('Message data: ${message.data}');

    // Extract order ID from notification data
    final orderId = message.data['order_id'] as String?;
    if (orderId != null) {
      onOrderStatusChanged?.call(orderId);
    }
  }

  /// Handle notification payload from local notification tap
  void _handleNotificationPayload(String payload) {
    try {
      // Parse payload if it's JSON, otherwise treat as order ID
      if (payload.startsWith('{')) {
        // JSON payload
        // For now, we'll handle simple string payloads
        // You can extend this to parse JSON if needed
      } else {
        // Simple string payload (order ID)
        onOrderStatusChanged?.call(payload);
      }
    } catch (e) {
      debugPrint('Error handling notification payload: $e');
    }
  }

  /// Show local notification for foreground messages
  Future<void> _showLocalNotification(
    String title,
    String body,
    Map<String, dynamic> data,
  ) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'order_status_channel',
      'Order Status Updates',
      channelDescription: 'Notifications for order status changes',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      playSound: true,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Use order_id as payload, or generate a unique ID
    final payload = data['order_id'] as String? ?? 
        DateTime.now().millisecondsSinceEpoch.toString();

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      details,
      payload: payload,
    );
  }

  /// Process order status change from notification data
  void _processOrderStatusChange(Map<String, dynamic> data) {
    final orderId = data['order_id'] as String?;
    final status = data['status'] as String?;

    if (orderId != null && status != null) {
      debugPrint('Order status changed: Order $orderId -> $status');
      // Notify listeners about order status change
      onOrderStatusChanged?.call(orderId);
    }
  }

  /// Get FCM token and save to backend
  Future<void> _getAndSaveToken() async {
    if (_firebaseMessaging == null) return;
    try {
      final token = await _firebaseMessaging!.getToken();
      if (token != null) {
        _currentToken = token;
        debugPrint('FCM Token: ${token.substring(0, 20)}...');
        await _saveTokenToBackend(token);
      }
    } catch (e) {
      debugPrint('Error getting FCM token: $e');
    }
  }

  /// Handle token refresh
  Future<void> _handleTokenRefresh(String newToken) async {
    debugPrint('FCM Token refreshed: ${newToken.substring(0, 20)}...');
    _currentToken = newToken;
    await _saveTokenToBackend(newToken);
  }

  /// Save FCM token to backend
  Future<void> _saveTokenToBackend(String token) async {
    try {
      await _apiService.post(
        '/notifications/fcm-token',
        data: {'fcmToken': token},
      );
      debugPrint('FCM token saved to backend successfully');
    } catch (e) {
      debugPrint('Error saving FCM token to backend: $e');
      // Don't throw - token saving failure shouldn't break the app
    }
  }

  /// Clear FCM token on backend on logout. Call before clearing auth session.
  /// Only clears if the stored token matches (safe for multi-device).
  Future<void> clearFcmTokenOnLogout() async {
    final token = _currentToken;
    if (token == null || token.isEmpty) return;
    try {
      await _apiService.delete(
        '/notifications/fcm-token',
        data: {'fcmToken': token},
      );
      debugPrint('FCM token cleared on backend');
    } catch (e) {
      debugPrint('Error clearing FCM token on logout: $e');
      // Don't throw - don't block logout on API failure
    }
  }

  /// Get current FCM token
  String? get currentToken => _currentToken;

  /// Check if service is initialized
  bool get isInitialized => _isInitialized;
}


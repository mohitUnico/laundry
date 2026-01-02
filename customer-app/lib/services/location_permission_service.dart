import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class LocationPermissionService {
  static final LocationPermissionService _instance = LocationPermissionService._internal();
  factory LocationPermissionService() => _instance;
  LocationPermissionService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;
  DateTime? _lastNotificationTime;
  static const Duration _notificationCooldown = Duration(hours: 1);

  /// Initialize the notification service
  Future<void> initialize() async {
    if (_isInitialized) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    _isInitialized = true;
  }

  /// Handle notification tap - opens app settings
  void _onNotificationTapped(NotificationResponse response) {
    // Open app settings when notification is tapped
    openAppSettings();
  }

  /// Check location permission and show notification if needed
  Future<void> checkAndNotifyLocationPermission() async {
    if (!_isInitialized) {
      await initialize();
    }

    // Check if we should show notification (cooldown period)
    if (_lastNotificationTime != null) {
      final timeSinceLastNotification = DateTime.now().difference(_lastNotificationTime!);
      if (timeSinceLastNotification < _notificationCooldown) {
        return; // Don't spam notifications
      }
    }

    try {
      // Check location permission status
      final permission = await Geolocator.checkPermission();
      
      // Check if location services are enabled
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();

      // Only show notification if permission is denied and services are enabled
      if (!serviceEnabled) {
        return; // Don't show notification if location services are disabled
      }

      if (permission == LocationPermission.denied || 
          permission == LocationPermission.deniedForever) {
        await _showLocationPermissionNotification();
        _lastNotificationTime = DateTime.now();
      }
    } catch (e) {
      debugPrint('Error checking location permission: $e');
    }
  }

  /// Show system notification asking for location permission
  Future<void> _showLocationPermissionNotification() async {
    const androidDetails = AndroidNotificationDetails(
      'location_permission_channel',
      'Location Permission',
      channelDescription: 'Notifications for location permission requests',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      1001, // Unique notification ID
      'Location Permission Required',
      'Please allow location access to help our delivery partners find you easily. Tap to open settings.',
      notificationDetails,
      payload: 'location_permission',
    );
  }

  /// Request location permission directly (can be called from notification tap)
  Future<bool> requestLocationPermission() async {
    try {
      final permission = await Geolocator.checkPermission();
      
      if (permission == LocationPermission.denied) {
        final newPermission = await Geolocator.requestPermission();
        return newPermission == LocationPermission.whileInUse || 
               newPermission == LocationPermission.always;
      }
      
      return permission == LocationPermission.whileInUse || 
             permission == LocationPermission.always;
    } catch (e) {
      debugPrint('Error requesting location permission: $e');
      return false;
    }
  }
}


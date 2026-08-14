import 'package:flutter/material.dart';

enum NotificationType {
  orderUpdate,
  deliveryUpdate,
  promotion,
  reminder,
  achievement,
}

enum NotificationFilter {
  all,
  mentions,
  unread,
}

class NotificationModel {
  final String id;
  final NotificationType type;
  final String title;
  final String description;
  final DateTime timestamp;
  final bool isRead;
  final String? iconAsset;
  final IconData? iconData;
  final List<String> actions; // e.g., ["Mark as read", "Delete", "Reply", "Accept"]

  NotificationModel({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.timestamp,
    this.isRead = false,
    this.iconAsset,
    this.iconData,
    this.actions = const [],
  });

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    // If same day, show time (e.g., "11:04 AM", "10 AM")
    if (difference.inDays == 0) {
      final hour = timestamp.hour;
      final minute = timestamp.minute;
      final period = hour >= 12 ? 'PM' : 'AM';
      final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
      
      // If less than 1 hour, show "X min ago"
      if (difference.inMinutes < 60) {
        return '${difference.inMinutes} min ago';
      }
      
      // Otherwise show time
      if (minute == 0) {
        return '$displayHour $period';
      }
      return '$displayHour:${minute.toString().padLeft(2, '0')} $period';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else {
      return '${difference.inDays} days ago';
    }
  }

  String get formattedTime {
    final hour = timestamp.hour;
    final minute = timestamp.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
  }
}


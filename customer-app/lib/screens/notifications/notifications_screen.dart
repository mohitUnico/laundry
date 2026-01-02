import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/notification_model.dart';
import '../home/widgets/home_colors.dart';
import '../../theme/app_text_styles.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  NotificationFilter _selectedFilter = NotificationFilter.all;
  
  List<NotificationModel> _notifications = [
    NotificationModel(
      id: '1',
      type: NotificationType.reminder,
      title: 'Pickup reminder:',
      description: 'Don\'t forget your scheduled pickup at 4 PM today!',
      timestamp: DateTime.now().subtract(const Duration(minutes: 10)),
      isRead: false,
      iconData: Icons.notifications_outlined,
      actions: ['Mark as read', 'Delete'],
    ),
    NotificationModel(
      id: '2',
      type: NotificationType.deliveryUpdate,
      title: 'Delivery Partner',
      description: 'Your order is out for delivery! 🚚',
      timestamp: DateTime.now().subtract(const Duration(minutes: 20)),
      isRead: false,
      iconData: Icons.person_outline,
      actions: ['Reply', 'Mark as read', 'Delete'],
    ),
    NotificationModel(
      id: '3',
      type: NotificationType.achievement,
      title: 'Congratulations:',
      description: 'You\'ve completed 10 orders with us!',
      timestamp: DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day, 11, 4),
      isRead: true,
      iconData: Icons.celebration_outlined,
      actions: ['Mark as read', 'Delete'],
    ),
    NotificationModel(
      id: '4',
      type: NotificationType.promotion,
      title: 'New Service Available:',
      description: 'Try our Premium Dry Cleaning service!',
      timestamp: DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day, 10, 0),
      isRead: true,
      iconData: Icons.check_circle_outline,
      actions: ['Mark as read', 'Delete'],
    ),
    NotificationModel(
      id: '5',
      type: NotificationType.orderUpdate,
      title: 'Order Status Update:',
      description: 'Your order #12345 is ready for pickup',
      timestamp: DateTime.now().subtract(const Duration(days: 1)),
      isRead: true,
      iconData: Icons.check_circle_outline,
      actions: ['Accept', 'Mark as read', 'Delete'],
    ),
  ];

  List<NotificationModel> get _filteredNotifications {
    switch (_selectedFilter) {
      case NotificationFilter.all:
        return _notifications;
      case NotificationFilter.mentions:
        return _notifications.where((n) => n.type == NotificationType.deliveryUpdate).toList();
      case NotificationFilter.unread:
        return _notifications.where((n) => !n.isRead).toList();
    }
  }

  int get _unreadCount => _notifications.where((n) => !n.isRead).length;

  void _markAllAsRead() {
    setState(() {
      for (int i = 0; i < _notifications.length; i++) {
        _notifications[i] = NotificationModel(
          id: _notifications[i].id,
          type: _notifications[i].type,
          title: _notifications[i].title,
          description: _notifications[i].description,
          timestamp: _notifications[i].timestamp,
          isRead: true,
          iconData: _notifications[i].iconData,
          actions: _notifications[i].actions,
        );
      }
    });
  }

  void _markAsRead(String id) {
    setState(() {
      final index = _notifications.indexWhere((n) => n.id == id);
      if (index != -1) {
        _notifications[index] = NotificationModel(
          id: _notifications[index].id,
          type: _notifications[index].type,
          title: _notifications[index].title,
          description: _notifications[index].description,
          timestamp: _notifications[index].timestamp,
          isRead: true,
          iconData: _notifications[index].iconData,
          actions: _notifications[index].actions,
        );
      }
    });
  }

  void _deleteNotification(String id) {
    setState(() {
      _notifications.removeWhere((n) => n.id == id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredNotifications;
    
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5), // Light gray background
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Notifications',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: _markAllAsRead,
            icon: const Icon(Icons.check_circle, color: Color(0xFF2C3CA5), size: 18),
            label: Text(
              'Make all as read',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF2C3CA5),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter tabs
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            child: Row(
              children: [
                _FilterTab(
                  label: 'All Notifications ${_notifications.length}',
                  isSelected: _selectedFilter == NotificationFilter.all,
                  onTap: () => setState(() => _selectedFilter = NotificationFilter.all),
                ),
                const SizedBox(width: 8),
                _FilterTab(
                  label: 'Mentions',
                  isSelected: _selectedFilter == NotificationFilter.mentions,
                  onTap: () => setState(() => _selectedFilter = NotificationFilter.mentions),
                ),
                const SizedBox(width: 8),
                _FilterTab(
                  label: 'Unread',
                  isSelected: _selectedFilter == NotificationFilter.unread,
                  onTap: () => setState(() => _selectedFilter = NotificationFilter.unread),
                ),
              ],
            ),
          ),
          // Notifications list
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Text(
                      'No notifications',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: HomeColors.muted,
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    itemCount: filtered.length,
                    separatorBuilder: (context, index) => const Divider(height: 1, thickness: 1, color: Color(0xFFE0E0E0)),
                    itemBuilder: (context, index) {
                      final notification = filtered[index];
                      return _NotificationItem(
                        notification: notification,
                        onMarkAsRead: () => _markAsRead(notification.id),
                        onDelete: () => _deleteNotification(notification.id),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _FilterTab extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterTab({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE8E8E8) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.black,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
      ),
    );
  }
}

class _NotificationItem extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onMarkAsRead;
  final VoidCallback onDelete;

  const _NotificationItem({
    required this.notification,
    required this.onMarkAsRead,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            child: notification.iconData != null
                ? Icon(
                    notification.iconData,
                    size: 24,
                    color: Colors.black87,
                  )
                : notification.iconAsset != null
                    ? Image.asset(notification.iconAsset!)
                    : const Icon(Icons.notifications_outlined),
          ),
          const SizedBox(width: 12),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  notification.title,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                // Description
                Text(
                  notification.description,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF666666),
                  ),
                ),
                const SizedBox(height: 8),
                // Actions
                Wrap(
                  spacing: 12,
                  children: notification.actions.map((action) {
                    return InkWell(
                      onTap: () {
                        if (action == 'Mark as read') {
                          onMarkAsRead();
                        } else if (action == 'Delete') {
                          onDelete();
                        }
                      },
                      child: Text(
                        action,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF2C3CA5),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          // Timestamp
          Text(
            notification.timeAgo,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF666666),
            ),
          ),
        ],
      ),
    );
  }
}


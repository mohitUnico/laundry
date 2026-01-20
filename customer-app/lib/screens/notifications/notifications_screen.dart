import 'package:flutter/material.dart';

import '../home/widgets/home_colors.dart';
import '../../theme/app_text_styles.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  // App Notifications
  bool _pushOrderUpdates = true;
  bool _pushDeliveryUpdates = true;
  bool _pushPromotions = true;
  bool _pushReminders = true;
  bool _pushAchievements = false;

  // Email Notifications
  bool _emailOrderUpdates = true;
  bool _emailDeliveryUpdates = false;
  bool _emailPromotions = true;
  bool _emailReminders = false;
  bool _emailAchievements = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HomeColors.background,
      appBar: AppBar(
        backgroundColor: HomeColors.background,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: InkWell(
            onTap: () => Navigator.of(context).maybePop(),
            borderRadius: BorderRadius.circular(18),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: HomeColors.borderSoft),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 18,
                color: HomeColors.text,
              ),
            ),
          ),
        ),
        title: Text(
          'Notifications',
          style: AppTextStyles.header(color: HomeColors.text),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              const _SectionTitle('App Notifications'),
              const SizedBox(height: 10),
              _NotificationSettingsCard(
                items: [
                  _NotificationToggleItem(
                    icon: Icons.shopping_bag_rounded,
                    iconColor: HomeColors.primary,
                    title: 'Order Updates',
                    subtitle: 'Order status changes and updates',
                    value: _pushOrderUpdates,
                    onChanged: (value) => setState(() => _pushOrderUpdates = value),
                  ),
                  _NotificationToggleItem(
                    icon: Icons.local_shipping_rounded,
                    iconColor: const Color(0xFF10B981),
                    title: 'Delivery Updates',
                    subtitle: 'Pickup and delivery notifications',
                    value: _pushDeliveryUpdates,
                    onChanged: (value) => setState(() => _pushDeliveryUpdates = value),
                  ),
                  _NotificationToggleItem(
                    icon: Icons.tag_rounded,
                    iconColor: const Color(0xFFFF9800),
                    title: 'Promotions & Offers',
                    subtitle: 'Special deals and discounts',
                    value: _pushPromotions,
                    onChanged: (value) => setState(() => _pushPromotions = value),
                  ),
                  _NotificationToggleItem(
                    icon: Icons.access_time_rounded,
                    iconColor: const Color(0xFFFF6B35),
                    title: 'Reminders',
                    subtitle: 'Pickup and delivery reminders',
                    value: _pushReminders,
                    onChanged: (value) => setState(() => _pushReminders = value),
                  ),
                  _NotificationToggleItem(
                    icon: Icons.celebration_rounded,
                    iconColor: const Color(0xFFFFD700),
                    title: 'Achievements',
                    subtitle: 'Milestones and rewards',
                    value: _pushAchievements,
                    onChanged: (value) => setState(() => _pushAchievements = value),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const _SectionTitle('Email Notifications'),
              const SizedBox(height: 10),
              _NotificationSettingsCard(
                items: [
                  _NotificationToggleItem(
                    icon: Icons.shopping_bag_rounded,
                    iconColor: HomeColors.primary,
                    title: 'Order Updates',
                    subtitle: 'Order status changes and updates',
                    value: _emailOrderUpdates,
                    onChanged: (value) => setState(() => _emailOrderUpdates = value),
                  ),
                  _NotificationToggleItem(
                    icon: Icons.local_shipping_rounded,
                    iconColor: const Color(0xFF10B981),
                    title: 'Delivery Updates',
                    subtitle: 'Pickup and delivery notifications',
                    value: _emailDeliveryUpdates,
                    onChanged: (value) => setState(() => _emailDeliveryUpdates = value),
                  ),
                  _NotificationToggleItem(
                    icon: Icons.tag_rounded,
                    iconColor: const Color(0xFFFF9800),
                    title: 'Promotions & Offers',
                    subtitle: 'Special deals and discounts',
                    value: _emailPromotions,
                    onChanged: (value) => setState(() => _emailPromotions = value),
                  ),
                  _NotificationToggleItem(
                    icon: Icons.access_time_rounded,
                    iconColor: const Color(0xFFFF6B35),
                    title: 'Reminders',
                    subtitle: 'Pickup and delivery reminders',
                    value: _emailReminders,
                    onChanged: (value) => setState(() => _emailReminders = value),
                  ),
                  _NotificationToggleItem(
                    icon: Icons.celebration_rounded,
                    iconColor: const Color(0xFFFFD700),
                    title: 'Achievements',
                    subtitle: 'Milestones and rewards',
                    value: _emailAchievements,
                    onChanged: (value) => setState(() => _emailAchievements = value),
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Text(
        title,
        style: AppTextStyles.header(color: HomeColors.text),
      ),
    );
  }
}

class _NotificationSettingsCard extends StatelessWidget {
  final List<_NotificationToggleItem> items;

  const _NotificationSettingsCard({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: HomeColors.borderSoft),
      ),
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            items[i],
            if (i != items.length - 1)
              const Padding(
                padding: EdgeInsets.only(left: 52),
                child: Divider(height: 1, thickness: 1, color: HomeColors.borderSoft),
              ),
          ],
        ],
      ),
    );
  }
}

class _NotificationToggleItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _NotificationToggleItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: iconColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.listItemTitle(color: HomeColors.text),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTextStyles.body(color: HomeColors.muted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: HomeColors.primary,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

import 'home_colors.dart';
import '../../../routes/app_routes.dart';
import '../../../theme/app_text_styles.dart';

class HomeHeader extends StatelessWidget {
  final String userName;
  final String location;
  final int notificationCount;
  final String? profileImageUrl;

  const HomeHeader({
    super.key,
    required this.userName,
    required this.location,
    required this.notificationCount,
    this.profileImageUrl,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl = profileImageUrl;
    return Row(
      children: [
        ClipOval(
          child: (imageUrl != null && imageUrl.isNotEmpty)
              ? Image.network(
                  imageUrl,
                  width: 44,
                  height: 44,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Image.asset(
                      'assets/icons/profile_pic_demo.png',
                      width: 44,
                      height: 44,
                      fit: BoxFit.cover,
                    );
                  },
                )
              : Image.asset(
                  'assets/icons/profile_pic_demo.png',
                  width: 44,
                  height: 44,
                  fit: BoxFit.cover,
                ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hi, $userName',
                style: AppTextStyles.header(color: HomeColors.text),
              ),
              const SizedBox(height: 3),
              InkWell(
                onTap: () =>
                    Navigator.of(context).pushNamed(AppRoutes.selectLocation),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.body(color: HomeColors.muted),
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                        child: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 18,
                          color: HomeColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        _NotificationButton(count: notificationCount),
      ],
    );
  }
}

class _NotificationButton extends StatelessWidget {
  final int count;

  const _NotificationButton({required this.count});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.of(context).pushNamed(AppRoutes.notifications),
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        width: 44,
        height: 44,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: HomeColors.borderSoft),
              ),
              child: Center(
                child: Image.asset(
                  'assets/icons/notifications.png',
                  width: 18,
                  height: 18,
                ),
              ),
            ),
            if (count > 0)
              Positioned(
                right: -4,
                top: -6,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE11D48),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Text(
                    '$count',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}



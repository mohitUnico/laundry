import 'package:flutter/material.dart';

import '../../../../theme/app_colors.dart';
import '../../../../theme/app_text_styles.dart';

class DeliveryPartnersScreen extends StatelessWidget {
  const DeliveryPartnersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              color: const Color(0xFFF5F5F5),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: AppColors.textPrimary,
                        size: 18,
                      ),
                    ),
                    splashRadius: 20,
                  ),
                  Expanded(
                    child: Text(
                      'Delivery Partners',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.header(
                        color: AppColors.textPrimary,
                      ).copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 40), // Balance the back button
                ],
              ),
            ),
            // Delivery Partners List
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _DeliveryPartnerCard(
                    name: 'Murray Bauman',
                    rating: 4.9,
                    totalDeliveries: 342,
                    completedToday: 2,
                    profileImagePath: 'assets/icons/profile_pic_demo.png',
                    onAssign: () {
                      // Handle assign action
                      Navigator.pop(context);
                    },
                  ),
                  const SizedBox(height: 12),
                  _DeliveryPartnerCard(
                    name: 'Max Mayfield',
                    rating: 4.8,
                    totalDeliveries: 303,
                    completedToday: 3,
                    profileImagePath: 'assets/icons/profile_pic_demo.png',
                    onAssign: () {
                      // Handle assign action
                      Navigator.pop(context);
                    },
                  ),
                  const SizedBox(height: 12),
                  _DeliveryPartnerCard(
                    name: 'Nancy Wheeler',
                    rating: 4.5,
                    totalDeliveries: 295,
                    completedToday: 1,
                    profileImagePath: 'assets/icons/profile_pic_demo.png',
                    onAssign: () {
                      // Handle assign action
                      Navigator.pop(context);
                    },
                  ),
                  const SizedBox(height: 12),
                  _DeliveryPartnerCard(
                    name: 'Steve Harrington',
                    rating: 4.8,
                    totalDeliveries: 308,
                    completedToday: 2,
                    profileImagePath: 'assets/icons/profile_pic_demo.png',
                    onAssign: () {
                      // Handle assign action
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DeliveryPartnerCard extends StatelessWidget {
  final String name;
  final double rating;
  final int totalDeliveries;
  final int completedToday;
  final String profileImagePath;
  final VoidCallback onAssign;

  const _DeliveryPartnerCard({
    required this.name,
    required this.rating,
    required this.totalDeliveries,
    required this.completedToday,
    required this.profileImagePath,
    required this.onAssign,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Profile Picture Section
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: 2,
                  ),
                ),
                child: ClipOval(
                  child: Image.asset(
                    profileImagePath,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: AppColors.primary.withOpacity(0.1),
                        child: Icon(
                          Icons.person,
                          size: 30,
                          color: AppColors.primary,
                        ),
                      );
                    },
                  ),
                ),
              ),
              // Green online status dot
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white,
                      width: 2,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          // Details Section
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: AppTextStyles.title(
                    color: AppColors.textPrimary,
                  ).copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.star,
                      size: 14,
                      color: Colors.amber,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$rating ($totalDeliveries deliveries)',
                      style: AppTextStyles.subtitle(
                        color: AppColors.textSecondary,
                      ).copyWith(
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Completed Today & Assign Button Section
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                completedToday.toString().padLeft(2, '0'),
                style: AppTextStyles.largeNumber(
                  color: AppColors.primary,
                ).copyWith(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Completed Today',
                style: AppTextStyles.subtitle(
                  color: AppColors.textSecondary,
                ).copyWith(
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: 100,
                height: 36,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Color(0xFF283897),
                        Color(0xFF0F73F7),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextButton(
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: onAssign,
                    child: Text(
                      'Assign',
                      style: AppTextStyles.button(
                        color: Colors.white,
                      ).copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}


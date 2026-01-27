import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';

class TaskCard extends StatelessWidget {
  final String taskType; // 'Pickup' or 'Delivery'
  final String scheduledTime;
  final String customerName;
  final String address;
  final String phoneNumber;
  final int itemCount;
  final String amount;
  final String buttonText;
  final VoidCallback onButtonPressed;
  final VoidCallback onMapPressed;
  final String iconPath;

  const TaskCard({
    super.key,
    required this.taskType,
    required this.scheduledTime,
    required this.customerName,
    required this.address,
    required this.phoneNumber,
    required this.itemCount,
    required this.amount,
    required this.buttonText,
    required this.onButtonPressed,
    required this.onMapPressed,
    required this.iconPath,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.divider.withOpacity(0.4),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with task type and time
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Image.asset(
                      iconPath,
                      width: 22,
                      height: 22,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      taskType,
                      style: AppTextStyles.stepTitle(
                        color: const Color(0xFF2553C8),
                      ),
                    ),
                  ],
                ),
                Text(
                  scheduledTime,
                  style: AppTextStyles.stepTitle(
                    color: const Color(0xFF2553C8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              height: 1,
              color: const Color(0xFFE1E6F5),
            ),
            const SizedBox(height: 16),
            // Customer details row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile picture placeholder
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primaryLight.withOpacity(0.2),
                  ),
                  child: Icon(
                    Icons.person,
                    size: 26,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              customerName,
                              style: AppTextStyles.title(
                                color: AppColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          // Amount intentionally hidden for delivery staff UI (salary-based; no per-order amount shown)
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Image.asset(
                            'assets/icons/home_screen/location.png',
                            width: 12,
                            height: 12,
                            fit: BoxFit.contain,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              address,
                              style: AppTextStyles.subtitle(
                                color: AppColors.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            // Contact and items row
            Row(
              children: [
                Icon(
                  Icons.phone,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 6),
                Text(
                  phoneNumber,
                  style: AppTextStyles.smallText(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(width: 16),
                Image.asset(
                  'assets/icons/home_screen/items.png',
                  width: 16,
                  height: 16,
                  fit: BoxFit.contain,
                ),
                const SizedBox(width: 6),
                Text(
                  'Qty: $itemCount',
                  style: AppTextStyles.smallText(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          Color(0xFF283897),
                          Color(0xFF0F73F7),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: onButtonPressed,
                        borderRadius: BorderRadius.circular(30),
                        child: Center(
                          child: Text(
                            buttonText,
                            style: AppTextStyles.button(
                              color: Colors.white,
                            ).copyWith(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: const Color(0xFF2B59FF),
                      width: 1.4,
                    ),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: onMapPressed,
                      borderRadius: BorderRadius.circular(18),
                      child: Center(
                        child: Image.asset(
                          'assets/icons/home_screen/location.png',
                          width: 22,
                          height: 22,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}


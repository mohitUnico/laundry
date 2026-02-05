import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';

class AssignmentRequestPopup extends StatelessWidget {
  final String taskType; // 'Pickup' or 'Delivery'
  final String customerName;
  final String address;
  final int itemCount;
  final VoidCallback onAccept;
  final VoidCallback onReject;
  final bool isProcessing;
  /// Optional title shown above the card (e.g. "Notification for delivery boy, to Accept or Reject order").
  final String? title;
  /// Optional time shown top-right (e.g. "10:00 AM").
  final String? scheduledTime;
  /// Optional amount/earning (e.g. "\$12.00" or "₹120").
  final String? amount;
  /// Optional note shown in the card (e.g. "Need to carry weight machine" for pickup + per_kg).
  final String? extraNote;
  /// When true, show item count (per_unit/per_piece orders). When false (per_kg), hide item count.
  final bool showItemCount;

  const AssignmentRequestPopup({
    super.key,
    required this.taskType,
    required this.customerName,
    required this.address,
    required this.itemCount,
    required this.onAccept,
    required this.onReject,
    this.isProcessing = false,
    this.title,
    this.scheduledTime,
    this.amount,
    this.extraNote,
    this.showItemCount = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null && title!.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              title!,
              style: AppTextStyles.body(color: AppColors.textSecondary).copyWith(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.divider.withOpacity(0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: Pickup/Delivery (left), Time (right)
                Row(
                  children: [
                    Text(
                      taskType,
                      style: AppTextStyles.stepTitle(
                        color: AppColors.primary,
                      ).copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      scheduledTime ?? '—',
                      style: AppTextStyles.body(
                        color: AppColors.primaryLight,
                      ).copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  height: 1,
                  color: AppColors.divider.withOpacity(0.3),
                ),
                const SizedBox(height: 14),
                // Customer row: avatar, name + address + items, amount
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primary.withOpacity(0.12),
                      ),
                      child: Icon(
                        Icons.person,
                        color: AppColors.primary,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            customerName,
                            style: AppTextStyles.listItemTitle(
                              color: AppColors.textPrimary,
                            ).copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.location_on_outlined,
                                size: 16,
                                color: AppColors.textSecondary,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  address.isNotEmpty ? address : 'Address not available',
                                  style: AppTextStyles.subtitle(
                                    color: AppColors.textSecondary,
                                  ).copyWith(fontSize: 13),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Icon(
                                Icons.keyboard_arrow_down,
                                size: 18,
                                color: AppColors.textSecondary,
                              ),
                            ],
                          ),
                          if (showItemCount) ...[
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Icon(
                                  Icons.inventory_2_outlined,
                                  size: 16,
                                  color: AppColors.textSecondary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '$itemCount ${itemCount == 1 ? 'item' : 'items'}',
                                  style: AppTextStyles.subtitle(
                                    color: AppColors.textSecondary,
                                  ).copyWith(fontSize: 13),
                                ),
                              ],
                            ),
                          ],
                          if (extraNote != null && extraNote!.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Icon(
                                  Icons.scale_outlined,
                                  size: 16,
                                  color: AppColors.warning,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    extraNote!,
                                    style: AppTextStyles.subtitle(
                                      color: AppColors.warning,
                                    ).copyWith(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (amount != null && amount!.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Text(
                        amount!,
                        style: AppTextStyles.listItemTitle(
                          color: AppColors.textPrimary,
                        ).copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 18),
                // Accept & Reject buttons
                Row(
                  children: [
                    Expanded(
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: isProcessing ? null : onAccept,
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            height: 48,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.primaryDark,
                                  AppColors.primary,
                                  AppColors.primaryLight,
                                ],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            alignment: Alignment.center,
                            child: isProcessing
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : Text(
                                    'Accept',
                                    style: AppTextStyles.button(
                                      color: Colors.white,
                                    ).copyWith(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: isProcessing ? null : onReject,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          side: const BorderSide(color: AppColors.primary, width: 1.5),
                          backgroundColor: Colors.white,
                        ),
                        child: Text(
                          'Reject',
                          style: AppTextStyles.button(
                            color: AppColors.primary,
                          ).copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

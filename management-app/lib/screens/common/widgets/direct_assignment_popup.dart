import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';

/// Popup for direct assignment (manager assigned pickup/delivery to staff).
/// Same card style as assignment request but no Accept/Reject — single OK to dismiss.
class DirectAssignmentPopup extends StatelessWidget {
  final String taskType; // 'Pickup' or 'Delivery'
  final String assignedAtFormatted; // e.g. "10:43 AM"
  final int itemCount;
  final VoidCallback onDismiss;
  /// Optional note (e.g. "Need to carry weight machine" for pickup + per_kg).
  final String? extraNote;

  const DirectAssignmentPopup({
    super.key,
    required this.taskType,
    required this.assignedAtFormatted,
    required this.itemCount,
    required this.onDismiss,
    this.extraNote,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'Assigned by manager',
            style: AppTextStyles.body(color: AppColors.textSecondary).copyWith(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ),
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
                // Top row: Pickup/Delivery (left), Assigned time (right)
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
                      assignedAtFormatted,
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
                // Content: item count and optional note
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
                        Icons.assignment_outlined,
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
                            'Assigned to you',
                            style: AppTextStyles.listItemTitle(
                              color: AppColors.textPrimary,
                            ).copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
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
                  ],
                ),
                const SizedBox(height: 18),
                // Single OK button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onDismiss,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'OK',
                      style: AppTextStyles.button(
                        color: Colors.white,
                      ).copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

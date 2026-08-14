import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';

/// Shows a themed success popup dialog with auto-dismiss after 2 seconds
/// 
/// Usage:
/// ```dart
/// showSuccessPopup(
///   context,
///   message: 'Order marked as picked up ✓',
/// );
/// ```
void showSuccessPopup(
  BuildContext context, {
  required String message,
  IconData icon = Icons.check_circle_outline,
  Duration autoCloseDuration = const Duration(seconds: 2),
}) {
  showDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black.withOpacity(0.3),
    builder: (dialogContext) {
      return Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: AppColors.success,
                  size: 30,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                message,
                style: AppTextStyles.subtitle(
                  color: AppColors.textPrimary,
                ).copyWith(fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    },
  );
  
  // Auto-close after specified duration
  Future.delayed(autoCloseDuration, () {
    if (context.mounted) {
      final navigator = Navigator.of(context, rootNavigator: true);
      if (navigator.canPop()) {
        navigator.pop();
      }
    }
  });
}


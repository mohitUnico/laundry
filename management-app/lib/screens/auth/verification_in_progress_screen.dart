import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

/// Small dialog-style widget for 'Verification in Progress'.
class VerificationInProgressDialog extends StatelessWidget {
  const VerificationInProgressDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 32),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 280,
              child: Image.asset(
                'assets/images/auth/veririfcation_in_progress.png',
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Verification in Progress',
              textAlign: TextAlign.center,
              style: AppTextStyles.header(color: AppColors.textPrimary)
                  .copyWith(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            Text(
              'Your details have been submitted\nsuccessfully. Our team will review and\nverify your account shortly.',
              textAlign: TextAlign.center,
              style: AppTextStyles.body(color: AppColors.textSecondary)
                  .copyWith(fontSize: 12, height: 1.4),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: 120,
              height: 44,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  backgroundColor: AppColors.primary,
                ),
                child: Text(
                  'OK',
                  style: AppTextStyles.button(color: Colors.white).copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
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


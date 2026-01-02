import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../routes/app_routes.dart';
import '../../utils/role_manager.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        height: 320,
                        child: Image.asset(
                          'assets/images/auth/registration.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(height: 40),
                      Text(
                        'Welcome!',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.header(
                                color: AppColors.textPrimary)
                            .copyWith(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Choose your role',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.header(color: AppColors.primary)
                            .copyWith(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          height: 1.31,
                        ),
                      ),
                      const SizedBox(height: 36),
                      _RoleButton(label: 'Delivery Partner'),
                      const SizedBox(height: 16),
                      _RoleButton(label: 'Collection Manager'),
                      const SizedBox(height: 16),
                      _RoleButton(label: 'Distribution Manager'),
                      const SizedBox(height: 16),
                      _RoleButton(label: 'Service Man'),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _RoleButton extends StatelessWidget {
  final String label;

  const _RoleButton({required this.label});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: () async {
          // Save role before navigating
          await RoleManager.saveRole(label);
          Navigator.of(context).pushNamed(
            AppRoutes.login,
            arguments: {'role': label},
          );
        },
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary, width: 1.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        child: Text(
          label,
          style: AppTextStyles.button(color: AppColors.primary)
              .copyWith(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}



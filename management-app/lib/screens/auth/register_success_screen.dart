import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../routes/app_routes.dart';
import '../../utils/role_manager.dart';
import '../../utils/role_constants.dart';

class RegisterSuccessScreen extends StatelessWidget {
  const RegisterSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF2437B6), Color(0xFF2C3CA5)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints:
                      BoxConstraints(minHeight: constraints.maxHeight),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 18),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(
                          height: 280,
                          child: Image.asset(
                            'assets/images/auth/register_success.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                        const SizedBox(height: 32),
                        Text(
                          'Register Success',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.header(color: Colors.white)
                              .copyWith(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Congratulations! your account is\nverified.',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.body(color: Colors.white70)
                              .copyWith(fontSize: 13, height: 1.4),
                        ),
                        const SizedBox(height: 36),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: () async {
                              // Navigate to role-specific home screen
                              final role = await RoleManager.getRole();
                              String homeRoute = AppRoutes.home;
                              
                              // Route to role-specific home screens
                              if (role == RoleConstants.deliveryPartner) {
                                homeRoute = AppRoutes.home; // Delivery home
                              } else if (role == RoleConstants.collectionManager) {
                                homeRoute = AppRoutes.home; // Will be updated to collection home
                              } else if (role == RoleConstants.distributionManager) {
                                homeRoute = AppRoutes.home; // Will be updated to distribution home
                              } else if (role == RoleConstants.serviceMan) {
                                homeRoute = AppRoutes.home; // Service Man uses pending orders as home
                              }
                              
                              Navigator.of(context).pushNamedAndRemoveUntil(
                                homeRoute,
                                (route) => false,
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              backgroundColor: Colors.white,
                              foregroundColor: AppColors.primary,
                              elevation: 0,
                            ),
                            child: Text(
                              'Go to Homepage',
                              style: AppTextStyles.button(
                                      color: AppColors.primary)
                                  .copyWith(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}



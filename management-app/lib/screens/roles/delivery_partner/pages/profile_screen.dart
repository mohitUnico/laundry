import 'package:flutter/material.dart';

import '../../../../routes/app_routes.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_text_styles.dart';
import '../../../../utils/auth_storage.dart';
import '../../../../utils/role_manager.dart';
import '../../../../utils/role_constants.dart';
import '../../../common/widgets/bottom_nav_bar.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    final role = await RoleManager.getRole();
    await Future.wait([
      RoleManager.clearRole(),
      AuthStorage.clearAll(),
    ]);

    if (!context.mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRoutes.login,
      (route) => false,
      arguments: {'role': role ?? RoleConstants.deliveryPartner},
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const _AccountHeader(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  const SizedBox(height: 16),
                  const _AccountSummaryCard(),
                  const SizedBox(height: 16),
                  // Logout button (moved here; Home screen End Shift no longer logs out)
                  SizedBox(
                    height: 52,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(26),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: TextButton(
                        style: TextButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(26),
                          ),
                        ),
                        onPressed: () => _logout(context),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.logout, color: AppColors.error, size: 18),
                            const SizedBox(width: 10),
                            Text(
                              'Log Out',
                              style: AppTextStyles.button(color: AppColors.error).copyWith(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const _SectionTitle('Account Details'),
                  const SizedBox(height: 16),
                  const _AccountDetailItem(
                    icon: Icons.phone_outlined,
                    label: 'Phone Number',
                    value: '+91 78569 45865',
                  ),
                  const SizedBox(height: 16),
                  const _AccountDetailItem(
                    icon: Icons.email_outlined,
                    label: 'Email',
                    value: 'nadaansharma@gmail.com',
                  ),
                  const SizedBox(height: 16),
                  const _AccountDetailItem(
                    icon: Icons.location_on_outlined,
                    label: 'Address',
                    value: 'No. 42, 3rd Cross, Indiranagar, Bengaluru, Karnataka 560038',
                  ),
                  const SizedBox(height: 24),
                  const _SectionTitle('Uploaded Documents'),
                  const SizedBox(height: 16),
                  const _DocumentCard(
                    imagePath: 'assets/images/documents/aadhaar.png',
                    title: 'Id Proof',
                    subtitle: 'Adhaar',
                  ),
                  const SizedBox(height: 12),
                  const _DocumentCard(
                    imagePath: 'assets/images/documents/driving_license.png',
                    title: 'Driving License',
                    subtitle: '',
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: 3,
        onTap: (index) {
          switch (index) {
            case 0:
              Navigator.pushReplacementNamed(context, AppRoutes.home);
              break;
            case 1:
              Navigator.pushReplacementNamed(context, AppRoutes.orders);
              break;
            case 2:
              Navigator.pushReplacementNamed(context, AppRoutes.help);
              break;
            case 3:
              break;
          }
        },
      ),
    );
  }
}

class _AccountHeader extends StatelessWidget {
  const _AccountHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            splashRadius: 20,
          ),
          Text(
            'Account',
            style: AppTextStyles.title(
              color: AppColors.textPrimary,
            ).copyWith(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          IconButton(
            onPressed: () {
              // TODO: Show options menu
            },
            icon: const Icon(Icons.more_vert, size: 20),
            splashRadius: 20,
          ),
        ],
      ),
    );
  }
}

class _AccountSummaryCard extends StatelessWidget {
  const _AccountSummaryCard();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: AuthStorage.getCurrentUser(),
      builder: (context, snapshot) {
        final user = snapshot.data;
        final fullName = (user?['fullName'] ?? '').toString().trim();
        final userId = (user?['userId'] ?? '').toString().trim();
        final phone = (user?['phone'] ?? '').toString().trim();
        final email = (user?['email'] ?? '').toString().trim();

        return Container(
          padding: const EdgeInsets.all(20),
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
          child: Column(
            children: [
              // Profile Picture
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/images/profile_placeholder.png',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: AppColors.primary.withOpacity(0.1),
                        child: const Icon(
                          Icons.person,
                          size: 40,
                          color: AppColors.primary,
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Name
              Text(
                fullName.isNotEmpty ? fullName : '—',
                style: AppTextStyles.title(
                  color: AppColors.textPrimary,
                ).copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              // ID (scrollable)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'ID: ',
                    style: AppTextStyles.subtitle(
                      color: AppColors.textSecondary,
                    ).copyWith(fontSize: 13),
                  ),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 180),
                    child: userId.isNotEmpty
                        ? SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Text(
                              userId,
                              maxLines: 1,
                              softWrap: false,
                              style: AppTextStyles.subtitle(
                                color: AppColors.textSecondary,
                              ).copyWith(fontSize: 13),
                            ),
                          )
                        : Text(
                            '—',
                            style: AppTextStyles.subtitle(
                              color: AppColors.textSecondary,
                            ).copyWith(fontSize: 13),
                          ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (phone.isNotEmpty || email.isNotEmpty) ...[
                Text(
                  [if (phone.isNotEmpty) phone, if (email.isNotEmpty) email].join(' • '),
                  textAlign: TextAlign.center,
                  style: AppTextStyles.subtitle(color: AppColors.textSecondary).copyWith(fontSize: 12),
                ),
                const SizedBox(height: 12),
              ] else ...[
                const SizedBox(height: 12),
              ],
              // Statistics
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  const _StatItem(
                    value: '156',
                    label: 'Total Deliveries',
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: AppColors.divider.withOpacity(0.3),
                  ),
                  const _StatItem(
                    value: '98%',
                    label: 'On-Time Rate',
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;

  const _StatItem({
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: AppTextStyles.title(
            color: AppColors.textPrimary,
          ).copyWith(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTextStyles.subtitle(
            color: AppColors.textSecondary,
          ).copyWith(fontSize: 12),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: AppTextStyles.title(
        color: AppColors.textPrimary,
      ).copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _AccountDetailItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _AccountDetailItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            size: 20,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTextStyles.subtitle(
                  color: AppColors.textSecondary,
                ).copyWith(fontSize: 12),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: AppTextStyles.title(
                  color: AppColors.textPrimary,
                ).copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DocumentCard extends StatelessWidget {
  final String imagePath;
  final String title;
  final String subtitle;

  const _DocumentCard({
    required this.imagePath,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.divider.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          // Document thumbnail
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.divider.withOpacity(0.3),
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                imagePath,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: AppColors.background,
                    child: const Icon(
                      Icons.description,
                      size: 30,
                      color: AppColors.textSecondary,
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Document info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.title(
                    color: AppColors.textPrimary,
                  ).copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTextStyles.subtitle(
                      color: AppColors.textSecondary,
                    ).copyWith(fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}


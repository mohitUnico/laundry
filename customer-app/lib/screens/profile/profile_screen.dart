import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../routes/app_routes.dart';
import '../../providers/auth_provider.dart';
import '../home/widgets/home_colors.dart';
import '../../theme/app_text_styles.dart';

class ProfileScreen extends StatelessWidget {
  final bool showBack;

  const ProfileScreen({
    super.key,
    this.showBack = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HomeColors.background,
      appBar: AppBar(
        backgroundColor: HomeColors.background,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        leading: showBack
            ? Padding(
                padding: const EdgeInsets.only(left: 12),
                child: InkWell(
                  onTap: () => Navigator.of(context).maybePop(),
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: HomeColors.borderSoft),
                    ),
                    child: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 18,
                      color: HomeColors.text,
                    ),
                  ),
                ),
              )
            : null,
        title: Text(
          'Account',
          style: AppTextStyles.header(color: HomeColors.text),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
          children: [
            _ProfileCard(
              name: 'Zendaya Adams',
              email: 'zendaya@gmail.com',
              phone: '+91 88654 56884',
              onEdit: () {},
            ),
            const SizedBox(height: 16),
            const _SectionTitle('Account Settings'),
            const SizedBox(height: 10),
            _SettingsCard(
              items: [
                _SettingsItem(
                  icon: Icons.location_on_outlined,
                  iconColor: HomeColors.primary,
                  title: 'Saved Addresses',
                  subtitle: 'Manage delivery locations',
                  onTap: () =>
                      Navigator.of(context).pushNamed(AppRoutes.selectLocation),
                ),
                _SettingsItem(
                  icon: Icons.credit_card_outlined,
                  iconColor: HomeColors.primary,
                  title: 'Payment Methods',
                  subtitle: 'Cards and wallets',
                  onTap: () {},
                ),
                _SettingsItem(
                  icon: Icons.notifications_none_rounded,
                  iconColor: HomeColors.primary,
                  title: 'Notifications',
                  subtitle: 'Push, email, SMS preferences',
                  onTap: () {},
                ),
                _SettingsItem(
                  icon: Icons.favorite_border_rounded,
                  iconColor: HomeColors.primary,
                  title: 'Favorites',
                  subtitle: 'Your preferred services',
                  onTap: () {},
                ),
              ],
            ),
            const SizedBox(height: 16),
            const _SectionTitle('Account Settings'),
            const SizedBox(height: 10),
            _SettingsCard(
              items: [
                _SettingsItem(
                  icon: Icons.help_outline_rounded,
                  iconColor: const Color(0xFFFF9C6A),
                  title: 'Help Center',
                  subtitle: 'FAQs and support',
                  onTap: () {},
                ),
                _SettingsItem(
                  icon: Icons.description_outlined,
                  iconColor: const Color(0xFFFF9C6A),
                  title: 'Terms & Conditions',
                  subtitle: 'Legal information',
                  onTap: () {},
                ),
                _SettingsItem(
                  icon: Icons.privacy_tip_outlined,
                  iconColor: const Color(0xFFFF9C6A),
                  title: 'Privacy Policy',
                  subtitle: 'How we protect your data',
                  onTap: () {},
                ),
                _SettingsItem(
                  icon: Icons.settings_outlined,
                  iconColor: HomeColors.text,
                  title: 'App Settings',
                  subtitle: 'Language, theme, data',
                  onTap: () {},
                ),
              ],
            ),
            const SizedBox(height: 16),
            _LogoutButton(
              onTap: () {
                context.read<AuthProvider>().logout();
                Navigator.of(context).pushNamedAndRemoveUntil(
                  AppRoutes.login,
                  (route) => false,
                );
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final String name;
  final String email;
  final String phone;
  final VoidCallback onEdit;

  const _ProfileCard({
    required this.name,
    required this.email,
    required this.phone,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: HomeColors.borderSoft),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF1FF),
              borderRadius: BorderRadius.circular(14),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.asset(
                'assets/icons/profile_pic_demo.png',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(
                    Icons.person_rounded,
                    color: HomeColors.muted,
                    size: 26,
                  );
                },
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.header(color: HomeColors.text),
                ),
                const SizedBox(height: 3),
                Text(
                  email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.body(color: HomeColors.muted),
                ),
                const SizedBox(height: 3),
                Text(
                  phone,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.body(color: HomeColors.muted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          InkWell(
            onTap: onEdit,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFEFF1FF),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.edit_outlined,
                size: 18,
                color: HomeColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Text(
        title,
        style: AppTextStyles.header(color: HomeColors.text),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final List<_SettingsItem> items;

  const _SettingsCard({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: HomeColors.borderSoft),
      ),
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            items[i],
            if (i != items.length - 1)
              const Padding(
                padding: EdgeInsets.only(left: 52),
                child: Divider(height: 1, thickness: 1, color: HomeColors.borderSoft),
              ),
          ],
        ],
      ),
    );
  }
}

class _SettingsItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SettingsItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 20, color: iconColor),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.listItemTitle(color: HomeColors.text),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTextStyles.body(color: HomeColors.muted),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            const Icon(
              Icons.chevron_right_rounded,
              color: HomeColors.muted,
            ),
          ],
        ),
      ),
    );
  }
}

class _LogoutButton extends StatelessWidget {
  final VoidCallback onTap;

  const _LogoutButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(26),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: HomeColors.borderSoft),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.logout_rounded, color: Color(0xFFF04438), size: 18),
            const SizedBox(width: 8),
            Text(
              'Log Out',
              style: AppTextStyles.header(color: const Color(0xFFF04438)),
            ),
          ],
        ),
      ),
    );
  }
}

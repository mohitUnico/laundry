import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../routes/app_routes.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_text_styles.dart';
import '../../../common/widgets/bottom_nav_bar.dart';

class HelpScreen extends StatelessWidget {
  final bool showBottomNav;

  const HelpScreen({
    super.key,
    this.showBottomNav = true,
  });

  static const String _supportPhoneDisplay = '+91 87965 45689';
  static const String _supportPhoneDial = '+918796545689';
  static const String _supportEmail = 'laundryexample@gmail.com';

  // TODO: Replace these with real links when available
  static const String _termsUrl = 'https://example.com/terms';
  static const String _privacyUrl = 'https://example.com/privacy';

  static Future<void> _launchExternal(Uri uri) async {
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok) throw Exception('Unable to open');
  }

  static void _toast(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _HelpHeader(),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  // Help content is static; pull-to-refresh for consistency.
                },
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  children: [
                  const _SectionTitle('Contact Support'),
                  const SizedBox(height: 18),
                  _ContactCard(
                    iconAsset: 'assets/icons/help_support/contact_support.png',
                    title: 'Call Support',
                    subtitle: _supportPhoneDisplay,
                    onTap: () async {
                      try {
                        await _launchExternal(Uri(scheme: 'tel', path: _supportPhoneDial));
                      } catch (_) {
                        _toast(context, 'Could not open phone dialer');
                      }
                    },
                  ),
                  const SizedBox(height: 14),
                  _ContactCard(
                    iconAsset: 'assets/icons/help_support/email_support.png',
                    title: 'Email Support',
                    subtitle: _supportEmail,
                    onTap: () async {
                      try {
                        await _launchExternal(Uri(
                          scheme: 'mailto',
                          path: _supportEmail,
                          queryParameters: {
                            'subject': 'WashBee Support',
                          },
                        ));
                      } catch (_) {
                        _toast(context, 'Could not open email app');
                      }
                    },
                  ),
                  const SizedBox(height: 14),
                  _ContactCard(
                    iconAsset: 'assets/icons/help_support/live_chat.png',
                    title: 'Live chat',
                    subtitle: 'Chat with our team',
                    onTap: () async {
                      final wa = Uri.parse('https://wa.me/918796545689?text=Hi%20WashBee%20Support');
                      try {
                        await _launchExternal(wa);
                      } catch (_) {
                        _toast(context, 'Live chat is not available right now');
                      }
                    },
                  ),
                  const SizedBox(height: 24),
                  const _SectionTitle("FAQ's"),
                  const SizedBox(height: 18),
                  const _FaqItem(
                    question: 'What if the customer not answering the calls?',
                  ),
                  const SizedBox(height: 10),
                  const _FaqItem(
                    question: 'What if I face issues during delivery?',
                  ),
                  const SizedBox(height: 10),
                  const _FaqItem(
                    question: 'How do I update my profile?',
                  ),
                  const SizedBox(height: 24),
                  const _SectionTitle('Quick Links'),
                  const SizedBox(height: 18),
                  _QuickLink(
                    icon: Icons.description_outlined,
                    label: 'Terms and Conditions',
                    onTap: () async {
                      try {
                        await _launchExternal(Uri.parse(_termsUrl));
                      } catch (_) {
                        _toast(context, 'Could not open Terms and Conditions');
                      }
                    },
                  ),
                  const SizedBox(height: 10),
                  _QuickLink(
                    icon: Icons.privacy_tip_outlined,
                    label: 'Privacy Policy',
                    onTap: () async {
                      try {
                        await _launchExternal(Uri.parse(_privacyUrl));
                      } catch (_) {
                        _toast(context, 'Could not open Privacy Policy');
                      }
                    },
                  ),
                  const SizedBox(height: 24),
                ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: showBottomNav
          ? BottomNavBar(
              currentIndex: 2,
              onTap: (index) {
                switch (index) {
                  case 0:
                    Navigator.pushReplacementNamed(context, AppRoutes.home);
                    break;
                  case 1:
                    Navigator.pushReplacementNamed(context, AppRoutes.orders);
                    break;
                  case 2:
                    break;
                  case 3:
                    Navigator.pushReplacementNamed(context, AppRoutes.profile);
                    break;
                }
              },
            )
          : null,
    );
  }
}

class _HelpHeader extends StatelessWidget {
  const _HelpHeader();

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
            'Help & Support',
            style: AppTextStyles.title(
              color: AppColors.textPrimary,
            ).copyWith(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 40),
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
    return Text(
      title,
      style: AppTextStyles.title(
        color: AppColors.textPrimary,
      ).copyWith(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        fontFamily: 'Poppins',
        height: 1.0,
        letterSpacing: 0.0,
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  final String iconAsset;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _ContactCard({
    required this.iconAsset,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.divider.withOpacity(0.4)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x7317253F),
                blurRadius: 5.5,
                offset: Offset(0, 0),
              ),
            ],
          ),
          constraints: const BoxConstraints(minHeight: 86),
          child: Row(
            children: [
              Image.asset(
                iconAsset,
                width: 24,
                height: 24,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.title(
                        color: AppColors.textPrimary,
                      ).copyWith(fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: AppTextStyles.subtitle(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (onTap != null) ...[
                const SizedBox(width: 10),
                const Icon(Icons.open_in_new, size: 18, color: AppColors.textSecondary),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _FaqItem extends StatelessWidget {
  final String question;

  const _FaqItem({required this.question});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider.withOpacity(0.4)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
        ),
        child: ExpansionTile(
          tilePadding: EdgeInsets.zero,
          childrenPadding: const EdgeInsets.only(top: 8),
          iconColor: AppColors.textSecondary,
          collapsedIconColor: AppColors.textSecondary,
          title: Text(
            question,
            style: AppTextStyles.subtitle(
              color: AppColors.textPrimary,
            ).copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              fontFamily: 'Poppins',
              height: 1.0,
              letterSpacing: 0.0,
            ),
          ),
          children: [
            Text(
              'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Vivamus quis.',
              style: AppTextStyles.smallText(
                color: AppColors.textSecondary,
              ).copyWith(fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickLink extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _QuickLink({
    required this.icon,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  shape: BoxShape.circle,
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x7317253F),
                      blurRadius: 5.5,
                      offset: Offset(0, 0),
                    ),
                  ],
                  border: Border.all(
                    color: AppColors.divider.withOpacity(0.8),
                  ),
                ),
                child: Icon(
                  icon,
                  size: 18,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: AppTextStyles.title(
                    color: AppColors.textPrimary,
                  ).copyWith(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
              if (onTap != null) const Icon(Icons.chevron_right, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}


import 'package:flutter/material.dart';

import '../home/widgets/home_colors.dart';
import '../../theme/app_text_styles.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HomeColors.background,
      appBar: AppBar(
        backgroundColor: HomeColors.background,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        leading: Padding(
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
        ),
        title: Text(
          'Privacy Policy',
          style: AppTextStyles.header(color: HomeColors.text),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF10B981),
                      const Color(0xFF10B981).withValues(alpha: 0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF10B981).withValues(alpha: 0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.privacy_tip_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Privacy Policy',
                                style: AppTextStyles.header(color: Colors.white).copyWith(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Your data protection matters',
                                style: AppTextStyles.body(color: Colors.white.withValues(alpha: 0.9)).copyWith(
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_today_rounded,
                            size: 14,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Last Updated: January 2025',
                            style: AppTextStyles.body(color: Colors.white.withValues(alpha: 0.9)).copyWith(
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _PrivacySection(
                number: 1,
                icon: Icons.info_outline_rounded,
                title: 'Introduction',
                content:
                    'We are committed to protecting your privacy and personal information. This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use our laundry service application. By using our service, you consent to the data practices described in this policy.',
              ),
              const SizedBox(height: 16),
              _PrivacySection(
                number: 2,
                icon: Icons.inventory_2_outlined,
                title: 'Information We Collect',
                content:
                    'We collect information that you provide directly to us, including: name, email address, phone number, delivery addresses, payment information, order history, and preferences. We also automatically collect device information, location data (with your permission), usage patterns, and app interaction data to improve our services.',
              ),
              const SizedBox(height: 16),
              _PrivacySection(
                number: 3,
                icon: Icons.settings_applications_rounded,
                title: 'How We Use Your Information',
                content:
                    'We use your information to: process and fulfill your orders, communicate about your orders and account, send service updates and notifications, process payments, provide customer support, improve our services, send promotional offers (with your consent), ensure security and prevent fraud, and comply with legal obligations.',
              ),
              const SizedBox(height: 16),
              _PrivacySection(
                number: 4,
                icon: Icons.share_outlined,
                title: 'Information Sharing and Disclosure',
                content:
                    'We do not sell your personal information. We may share your information with: service providers (payment processors, delivery partners, laundry service providers) who assist in operations, business partners for joint services (with your consent), legal authorities when required by law, and in case of business transfers. We ensure all third parties maintain appropriate security measures.',
              ),
              const SizedBox(height: 16),
              _PrivacySection(
                number: 5,
                icon: Icons.security_rounded,
                title: 'Data Security',
                content:
                    'We implement industry-standard security measures to protect your personal information, including encryption, secure servers, access controls, and regular security audits. However, no method of transmission over the internet is 100% secure. While we strive to protect your data, we cannot guarantee absolute security.',
              ),
              const SizedBox(height: 16),
              _PrivacySection(
                number: 6,
                icon: Icons.location_on_outlined,
                title: 'Location Information',
                content:
                    'We collect location data to provide accurate delivery services, calculate delivery fees, and optimize routes. Location data is collected only when you grant permission and is used solely for service delivery purposes. You can disable location services in your device settings, though this may limit certain features.',
              ),
              const SizedBox(height: 16),
              _PrivacySection(
                number: 7,
                icon: Icons.credit_card_outlined,
                title: 'Payment Information',
                content:
                    'Payment information is processed securely through our trusted payment partners. We do not store your full credit card details on our servers. Payment data is encrypted and handled in compliance with PCI DSS standards. For cash on delivery orders, no payment information is collected.',
              ),
              const SizedBox(height: 16),
              _PrivacySection(
                number: 8,
                icon: Icons.account_circle_outlined,
                title: 'Your Rights and Choices',
                content:
                    'You have the right to: access your personal information, correct inaccurate data, request deletion of your account and data, opt-out of marketing communications, withdraw consent for data processing, and request data portability. You can exercise these rights through the app settings or by contacting us.',
              ),
              const SizedBox(height: 16),
              _PrivacySection(
                number: 9,
                icon: Icons.archive_outlined,
                title: 'Data Retention',
                content:
                    'We retain your personal information for as long as necessary to provide services, comply with legal obligations, resolve disputes, and enforce agreements. Order history and transaction data are retained for accounting and legal purposes. You can request deletion of your account and associated data at any time.',
              ),
              const SizedBox(height: 16),
              _PrivacySection(
                number: 10,
                icon: Icons.cookie_outlined,
                title: 'Cookies and Tracking Technologies',
                content:
                    'We use cookies and similar tracking technologies to enhance your experience, analyze app usage, and improve our services. These technologies help us remember your preferences, authenticate your sessions, and provide personalized content. You can manage cookie preferences through your device settings.',
              ),
              const SizedBox(height: 16),
              _PrivacySection(
                number: 11,
                icon: Icons.child_care_outlined,
                title: 'Children\'s Privacy',
                content:
                    'Our service is not intended for users under the age of 18. We do not knowingly collect personal information from children. If we become aware that we have collected information from a child, we will take steps to delete such information promptly. Parents or guardians should contact us if they believe we have collected information from a child.',
              ),
              const SizedBox(height: 16),
              _PrivacySection(
                number: 12,
                icon: Icons.link_outlined,
                title: 'Third-Party Services',
                content:
                    'Our app may contain links to third-party websites or services. We are not responsible for the privacy practices of these third parties. We encourage you to review their privacy policies. Third-party services we use include payment processors, analytics providers, and cloud storage services, all of which maintain their own privacy policies.',
              ),
              const SizedBox(height: 16),
              _PrivacySection(
                number: 13,
                icon: Icons.update_rounded,
                title: 'Changes to This Policy',
                content:
                    'We may update this Privacy Policy from time to time to reflect changes in our practices or legal requirements. We will notify you of significant changes through the app or via email. The "Last Updated" date at the top indicates when the policy was last revised. Your continued use of the service after changes constitutes acceptance of the updated policy.',
              ),
              const SizedBox(height: 16),
              _PrivacySection(
                number: 14,
                icon: Icons.contact_support_outlined,
                title: 'Contact Us',
                content:
                    'If you have questions, concerns, or requests regarding this Privacy Policy or your personal information, please contact us at privacy@laundryapp.com or through our Help Center in the app. We will respond to your inquiries within a reasonable timeframe.',
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}

class _PrivacySection extends StatelessWidget {
  final int number;
  final IconData icon;
  final String title;
  final String content;

  const _PrivacySection({
    required this.number,
    required this.icon,
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor = const Color(0xFF10B981);
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: HomeColors.borderSoft, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: iconColor.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with number, icon, and title
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.05),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                // Number badge
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: iconColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      '$number',
                      style: AppTextStyles.header(color: Colors.white).copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Icon
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    size: 20,
                    color: iconColor,
                  ),
                ),
                const SizedBox(width: 12),
                // Title
                Expanded(
                  child: Text(
                    title,
                    style: AppTextStyles.listItemTitle(color: HomeColors.text).copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(18),
            child: Text(
              content,
              style: AppTextStyles.body(color: HomeColors.text).copyWith(
                fontSize: 14,
                height: 1.7,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

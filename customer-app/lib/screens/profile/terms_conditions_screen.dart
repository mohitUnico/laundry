import 'package:flutter/material.dart';

import '../home/widgets/home_colors.dart';
import '../../theme/app_text_styles.dart';

class TermsConditionsScreen extends StatelessWidget {
  const TermsConditionsScreen({super.key});

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
          'Terms & Conditions',
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
                      HomeColors.primary,
                      HomeColors.primary.withValues(alpha: 0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: HomeColors.primary.withValues(alpha: 0.2),
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
                            Icons.description_rounded,
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
                                'Terms & Conditions',
                                style: AppTextStyles.header(color: Colors.white).copyWith(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Please read carefully',
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
              _TermsSection(
                number: 1,
                icon: Icons.check_circle_outline_rounded,
                title: 'Acceptance of Terms',
                content:
                    'By accessing and using this laundry service application, you accept and agree to be bound by the terms and provision of this agreement. If you do not agree to abide by the above, please do not use this service.',
              ),
              const SizedBox(height: 16),
              _TermsSection(
                number: 2,
                icon: Icons.local_laundry_service_rounded,
                title: 'Service Description',
                content:
                    'Our platform provides on-demand laundry services connecting customers with service providers. Services include regular wash, dry cleaning, ironing, and specialized garment care. Service availability, pricing, and delivery times may vary based on location and service type.',
              ),
              const SizedBox(height: 16),
              _TermsSection(
                number: 3,
                icon: Icons.person_outline_rounded,
                title: 'User Account',
                content:
                    'You are responsible for maintaining the confidentiality of your account credentials. You agree to provide accurate, current, and complete information during registration. You are responsible for all activities that occur under your account.',
              ),
              const SizedBox(height: 16),
              _TermsSection(
                number: 4,
                icon: Icons.payment_rounded,
                title: 'Order Placement and Payment',
                content:
                    'Orders are confirmed upon successful payment. We accept multiple payment methods including credit/debit cards, UPI, digital wallets, and cash on delivery. Prices displayed are final unless otherwise stated. All payments are processed securely through our payment partners.',
              ),
              const SizedBox(height: 16),
              _TermsSection(
                number: 5,
                icon: Icons.local_shipping_rounded,
                title: 'Service Delivery',
                content:
                    'We strive to deliver services within the estimated timeframes. Delivery times are approximate and may vary due to factors beyond our control. You must provide accurate pickup and delivery addresses. Our delivery partners will attempt delivery during scheduled times.',
              ),
              const SizedBox(height: 16),
              _TermsSection(
                number: 6,
                icon: Icons.cancel_outlined,
                title: 'Cancellation and Refunds',
                content:
                    'Orders can be cancelled before pickup. Cancellation after pickup may incur charges. Refunds for cancelled orders will be processed within 5-7 business days to the original payment method. Service quality issues will be addressed on a case-by-case basis.',
              ),
              const SizedBox(height: 16),
              _TermsSection(
                number: 7,
                icon: Icons.shield_outlined,
                title: 'Limitation of Liability',
                content:
                    'While we take utmost care in handling your garments, we are not liable for damage to items that are not suitable for standard laundry processes, items with existing damage, or items left in pockets. Our liability is limited to the service charge paid for the affected items.',
              ),
              const SizedBox(height: 16),
              _TermsSection(
                number: 8,
                icon: Icons.gavel_rounded,
                title: 'User Conduct',
                content:
                    'You agree not to use the service for any unlawful purpose or in any way that could damage, disable, or impair the service. You must not attempt to gain unauthorized access to any part of the service or interfere with its operation.',
              ),
              const SizedBox(height: 16),
              _TermsSection(
                number: 9,
                icon: Icons.lock_outline_rounded,
                title: 'Privacy and Data Protection',
                content:
                    'Your privacy is important to us. We collect and use your personal information in accordance with our Privacy Policy. By using our service, you consent to the collection and use of information as described in our Privacy Policy.',
              ),
              const SizedBox(height: 16),
              _TermsSection(
                number: 10,
                icon: Icons.edit_note_rounded,
                title: 'Modifications to Terms',
                content:
                    'We reserve the right to modify these terms at any time. Changes will be effective immediately upon posting. Your continued use of the service after changes constitutes acceptance of the modified terms. We recommend reviewing these terms periodically.',
              ),
              const SizedBox(height: 16),
              _TermsSection(
                number: 11,
                icon: Icons.contact_support_outlined,
                title: 'Contact Information',
                content:
                    'For questions about these Terms & Conditions, please contact us at support@laundryapp.com or through our Help Center in the app.',
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}

class _TermsSection extends StatelessWidget {
  final int number;
  final IconData icon;
  final String title;
  final String content;

  const _TermsSection({
    required this.number,
    required this.icon,
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: HomeColors.borderSoft, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: HomeColors.primary.withValues(alpha: 0.04),
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
              color: HomeColors.primary.withValues(alpha: 0.05),
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
                    color: HomeColors.primary,
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
                    color: HomeColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    size: 20,
                    color: HomeColors.primary,
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

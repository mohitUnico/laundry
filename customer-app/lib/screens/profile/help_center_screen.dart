import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../home/widgets/home_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/profile_service_error_messages.dart';

class FAQItem {
  final String question;
  final String answer;

  const FAQItem({
    required this.question,
    required this.answer,
  });
}

class HelpCenterScreen extends StatefulWidget {
  const HelpCenterScreen({super.key});

  @override
  State<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends State<HelpCenterScreen> {
  final List<FAQItem> _faqs = const [
    FAQItem(
      question: 'How do I place an order?',
      answer: 'Select your preferred services from the home screen, add items to your cart, choose delivery options, schedule pickup/delivery, and complete payment to place your order.',
    ),
    FAQItem(
      question: 'What payment methods are accepted?',
      answer: 'We accept multiple payment methods including Credit/Debit Cards, UPI, Wallet, and Cash on Delivery (COD).',
    ),
    FAQItem(
      question: 'How long does it take to complete an order?',
      answer: 'Order completion time varies by service type. Regular wash services typically take 24-48 hours, while Pro Clean services may take 2-3 days. You can check estimated time for each service before placing an order.',
    ),
    FAQItem(
      question: 'Can I track my order?',
      answer: 'Yes! You can track your order in real-time from the Orders screen. You\'ll see updates at each stage: pickup, processing, and delivery.',
    ),
    FAQItem(
      question: 'What if I need to cancel my order?',
      answer: 'You can cancel your order before it\'s picked up. Go to your Orders screen, select the order, and tap Cancel. Refunds will be processed within 5-7 business days.',
    ),
    FAQItem(
      question: 'How are delivery charges calculated?',
      answer: 'Delivery charges are calculated based on the distance from your location to our service center. Charges are displayed before you confirm your order.',
    ),
    FAQItem(
      question: 'What is the difference between per-piece and per-kg pricing?',
      answer: 'Per-piece pricing charges for individual items (e.g., ₹40 per shirt). Per-kg pricing charges based on total weight (e.g., ₹100 per kg). You can choose the pricing type that suits your needs.',
    ),
    FAQItem(
      question: 'Do you offer express delivery?',
      answer: 'Yes, we offer express delivery for urgent orders. Express service is available for select services and may have additional charges. Check service details for availability.',
    ),
  ];

  final Set<int> _expandedItems = {};

  void _toggleExpanded(int index) {
    setState(() {
      if (_expandedItems.contains(index)) {
        _expandedItems.remove(index);
      } else {
        _expandedItems.add(index);
      }
    });
  }

  Future<void> _openWhatsApp() async {
    const phoneNumber = '917219424556'; // WhatsApp format: country code + number (no + or spaces)
    final url = Uri.parse('https://wa.me/$phoneNumber');
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(
          url,
          mode: LaunchMode.externalApplication,
        );
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not open WhatsApp'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        final message = ProfileServiceErrorMessages.getExternalAppErrorMessage(
          e,
          appName: 'WhatsApp',
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _openEmail() async {
    const email = 'support@laundryapp.com';
    final url = Uri.parse('mailto:$email?subject=Support Request');
    try {
      if (await canLaunchUrl(url)) {
        // Use externalApplication mode to show app chooser
        await launchUrl(
          url,
          mode: LaunchMode.externalApplication,
        );
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not open email client'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        final message = ProfileServiceErrorMessages.getExternalAppErrorMessage(
          e,
          appName: 'Email',
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

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
          'Help Center',
          style: AppTextStyles.header(color: HomeColors.text),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              // Support Options Section
              const _SectionTitle('Get Support'),
              const SizedBox(height: 12),
              _SupportCard(
                icon: Icons.chat_bubble_outline_rounded,
                iconColor: const Color(0xFF25D366),
                title: 'WhatsApp Support',
                subtitle: 'Chat with us on WhatsApp',
                phoneNumber: '+91 72194 24556',
                onTap: _openWhatsApp,
              ),
              const SizedBox(height: 12),
              _SupportCard(
                icon: Icons.email_outlined,
                iconColor: HomeColors.primary,
                title: 'Email Support',
                subtitle: 'Send us an email',
                email: 'support@laundryapp.com',
                onTap: _openEmail,
              ),
              const SizedBox(height: 24),
              // FAQs Section
              const _SectionTitle('Frequently Asked Questions'),
              const SizedBox(height: 12),
              _FAQsCard(
                faqs: _faqs,
                expandedItems: _expandedItems,
                onToggle: _toggleExpanded,
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
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

class _SupportCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String? phoneNumber;
  final String? email;
  final VoidCallback onTap;

  const _SupportCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.phoneNumber,
    this.email,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: HomeColors.borderSoft),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icon,
                size: 24,
                color: iconColor,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.listItemTitle(color: HomeColors.text),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    phoneNumber ?? email ?? subtitle,
                    style: AppTextStyles.body(color: HomeColors.muted).copyWith(fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Icon(
              Icons.chevron_right_rounded,
              color: HomeColors.muted,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}

class _FAQsCard extends StatelessWidget {
  final List<FAQItem> faqs;
  final Set<int> expandedItems;
  final ValueChanged<int> onToggle;

  const _FAQsCard({
    required this.faqs,
    required this.expandedItems,
    required this.onToggle,
  });

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
          for (var i = 0; i < faqs.length; i++) ...[
            _FAQItem(
              faq: faqs[i],
              isExpanded: expandedItems.contains(i),
              onTap: () => onToggle(i),
            ),
            if (i != faqs.length - 1)
              const Padding(
                padding: EdgeInsets.only(left: 18, right: 18),
                child: Divider(height: 1, thickness: 1, color: HomeColors.borderSoft),
              ),
          ],
        ],
      ),
    );
  }
}

class _FAQItem extends StatelessWidget {
  final FAQItem faq;
  final bool isExpanded;
  final VoidCallback onTap;

  const _FAQItem({
    required this.faq,
    required this.isExpanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    faq.question,
                    style: AppTextStyles.listItemTitle(color: HomeColors.text).copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                AnimatedRotation(
                  turns: isExpanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: HomeColors.muted,
                    size: 24,
                  ),
                ),
              ],
            ),
            if (isExpanded) ...[
              const SizedBox(height: 12),
              Text(
                faq.answer,
                style: AppTextStyles.body(color: HomeColors.text).copyWith(
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}


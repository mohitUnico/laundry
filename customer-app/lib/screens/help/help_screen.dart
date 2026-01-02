import 'package:flutter/material.dart';

import '../../screens/home/widgets/home_colors.dart';
import '../../theme/app_text_styles.dart';
import '../home/widgets/home_bottom_nav.dart';
import '../shell/main_shell_screen.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

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
          'Help & Support',
          style: AppTextStyles.header(color: HomeColors.text),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          children: [
            const _SectionTitle('Contact Support'),
            const SizedBox(height: 14),
            _ContactCard(
              icon: Icons.phone_outlined,
              title: 'Contact Support',
              subtitle: '+91 87965 45689',
            ),
            const SizedBox(height: 14),
            _ContactCard(
              icon: Icons.email_outlined,
              title: 'Email Support',
              subtitle: 'laundryexample@gmail.com',
            ),
            const SizedBox(height: 14),
            _ContactCard(
              icon: Icons.chat_bubble_outline_rounded,
              title: 'Live chat',
              subtitle: 'Chat with our team',
            ),
            const SizedBox(height: 24),
            const _SectionTitle("FAQ's"),
            const SizedBox(height: 10),
            _FaqItem(
              question: 'what if the customer not answering the calls?',
            ),
            const SizedBox(height: 10),
            _FaqItem(
              question: 'What if i face issues during delivery?',
            ),
            const SizedBox(height: 10),
            _FaqItem(
              question: 'How do i update my profile?',
            ),
            const SizedBox(height: 24),
            const _SectionTitle('Quick Links'),
            const SizedBox(height: 12),
            _QuickLink(
              icon: Icons.description_outlined,
              label: 'Terms and Conditions',
            ),
            const SizedBox(height: 10),
            _QuickLink(
              icon: Icons.privacy_tip_outlined,
              label: 'Privacy Policy',
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
      bottomNavigationBar: HomeBottomNav(
        currentIndex: 2,
        onTap: (index) {
          if (index == 2) return; // Stay on help screen
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => MainShellScreen(initialIndex: index),
            ),
          );
        },
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

class _ContactCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _ContactCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: const Border(
          bottom: BorderSide(
            color: Color(0xFF283897),
            width: 2,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFE6F0FF),
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFF283897),
                width: 2,
              ),
            ),
            child: Icon(
              icon,
              size: 20,
              color: HomeColors.primary,
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
                  subtitle,
                  style: AppTextStyles.body(color: HomeColors.muted),
                ),
              ],
            ),
          ),
        ],
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
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: HomeColors.borderSoft),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
        ),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          childrenPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
          iconColor: HomeColors.muted,
          collapsedIconColor: HomeColors.muted,
          title: Text(
            question,
            style: AppTextStyles.body(color: HomeColors.text).copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          children: [
            Text(
              'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Vivamus quis.',
              style: AppTextStyles.body(color: HomeColors.muted),
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

  const _QuickLink({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: HomeColors.borderSoft),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFE6F0FF),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 20,
              color: HomeColors.primary,
            ),
          ),
          const SizedBox(width: 14),
          Text(
            label,
            style: AppTextStyles.listItemTitle(color: HomeColors.text),
          ),
        ],
      ),
    );
  }
}


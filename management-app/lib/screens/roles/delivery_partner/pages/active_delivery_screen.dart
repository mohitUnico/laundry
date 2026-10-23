import 'package:flutter/material.dart';

import '../../../../theme/app_colors.dart';
import '../../../../theme/app_text_styles.dart';
import '../../../../utils/mock_config.dart';

class ActiveDeliveryScreen extends StatelessWidget {
  const ActiveDeliveryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Active Delivery')),
      body: MockConfig.bypassBackend
          ? const _MockActiveDelivery()
          : const Center(
              child: Text('Active Delivery with Map and Navigation - To be implemented'),
            ),
    );
  }
}

class _MockActiveDelivery extends StatelessWidget {
  const _MockActiveDelivery();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        _StopCard(
          title: 'Pickup',
          name: 'Meera Iyer',
          detail: '18 Ballygunge Place, Kolkata · 6 items',
          status: 'On the way',
        ),
        SizedBox(height: 12),
        _StopCard(
          title: 'Drop',
          name: 'Arjun Mehta',
          detail: '9 Camac Street, Kolkata · 3 items',
          status: 'Out for delivery',
        ),
      ],
    );
  }
}

class _StopCard extends StatelessWidget {
  final String title;
  final String name;
  final String detail;
  final String status;

  const _StopCard({
    required this.title,
    required this.name,
    required this.detail,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.body(color: AppColors.primary)),
          const SizedBox(height: 6),
          Text(name, style: AppTextStyles.header(color: AppColors.textPrimary).copyWith(fontSize: 18)),
          const SizedBox(height: 4),
          Text(detail, style: AppTextStyles.body(color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          Text(status, style: AppTextStyles.button(color: AppColors.success)),
        ],
      ),
    );
  }
}

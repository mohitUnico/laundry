import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/mock_config.dart';

class EarningsScreen extends StatelessWidget {
  const EarningsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Earnings')),
      body: MockConfig.bypassBackend
          ? const _MockEarnings()
          : const Center(
              child: Text('Earnings and Payment History - To be implemented'),
            ),
    );
  }
}

class _MockEarnings extends StatelessWidget {
  const _MockEarnings();

  @override
  Widget build(BuildContext context) {
    const rows = [
      ('22 Oct', 'Drop · Arjun Mehta', '₹180'),
      ('21 Oct', 'Pickup · Sana Qureshi', '₹90'),
      ('20 Oct', 'Weekly incentive', '₹500'),
    ];
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('This week', style: AppTextStyles.body(color: Colors.white70)),
              const SizedBox(height: 6),
              Text(
                '₹770',
                style: AppTextStyles.header(color: Colors.white).copyWith(fontSize: 28),
              ),
              const SizedBox(height: 4),
              Text('12 completed tasks', style: AppTextStyles.body(color: Colors.white70)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ...rows.map(
          (row) => Card(
            child: ListTile(
              title: Text(row.$2),
              subtitle: Text(row.$1),
              trailing: Text(
                row.$3,
                style: AppTextStyles.button(color: AppColors.primary),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';

import '../screens/home/widgets/home_colors.dart';
import '../theme/app_text_styles.dart';

class PerKgPriceBanner extends StatelessWidget {
  final double? perKgPrice;
  final String? label;

  const PerKgPriceBanner({
    super.key,
    required this.perKgPrice,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    final price = perKgPrice;
    if (price == null || price <= 0) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Color(0xFF283897),
            Color(0xFF0F73F7),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.scale_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label ?? 'Kg-wise pricing',
                  style: AppTextStyles.body(color: Colors.white).copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Final amount is calculated after weighing.',
                  style: AppTextStyles.body(color: Colors.white.withOpacity(0.92))
                      .copyWith(fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '₹${price.toStringAsFixed(price % 1 == 0 ? 0 : 2)}/kg',
              style: AppTextStyles.button(color: HomeColors.primary).copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}



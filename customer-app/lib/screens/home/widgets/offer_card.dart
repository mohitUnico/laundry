import 'package:flutter/material.dart';

import 'home_colors.dart';
import '../../../theme/app_text_styles.dart';

class OfferCard extends StatelessWidget {
  final String headline;
  final String subhead;
  final String code;

  const OfferCard({
    super.key,
    required this.headline,
    required this.subhead,
    required this.code,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: Colors.white,
        border: Border.all(color: HomeColors.borderSoft),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            headline,
            style: AppTextStyles.offerHeadline(color: HomeColors.text),
          ),
          const SizedBox(height: 6),
          Text(
            subhead,
            style: AppTextStyles.offerSubhead(color: HomeColors.muted),
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            height: 40,
            decoration: BoxDecoration(
              color: HomeColors.primary,
              borderRadius: BorderRadius.circular(999),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                Text(
                  'Code: $code',
                  style: AppTextStyles.couponCode(color: Colors.white),
                ),
                const Spacer(),
                Container(
                  width: 28,
                  height: 28,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: HomeColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}



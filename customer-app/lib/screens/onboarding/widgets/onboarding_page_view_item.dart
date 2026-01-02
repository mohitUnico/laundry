import 'package:flutter/material.dart';

import '../onboarding_page_data.dart';

class OnboardingPageViewItem extends StatelessWidget {
  final OnboardingPageData data;
  final double size;

  const OnboardingPageViewItem({
    super.key,
    required this.data,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: Image.asset(
        data.imageAsset,
        width: size,
        height: size,
        fit: BoxFit.contain,
      ),
    );
  }
}



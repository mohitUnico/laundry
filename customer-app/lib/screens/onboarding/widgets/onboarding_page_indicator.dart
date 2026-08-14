import 'package:flutter/material.dart';

class OnboardingPageIndicator extends StatelessWidget {
  final int currentIndex;
  final int itemCount;

  const OnboardingPageIndicator({
    super.key,
    required this.currentIndex,
    required this.itemCount,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(itemCount, (index) {
        final isActive = index == currentIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          width: 8,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: isActive
                ? const Color(0xFF2C3CA5)
                : const Color(0xFFD6D9E7),
            shape: BoxShape.circle,
          ),
        );
      }),
    );
  }
}



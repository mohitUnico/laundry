import 'package:flutter/material.dart';

import '../onboarding_page_data.dart';

class OnboardingTitle extends StatelessWidget {
  final List<OnboardingTextSegment> line1;
  final List<OnboardingTextSegment> line2;

  const OnboardingTitle({
    super.key,
    required this.line1,
    required this.line2,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _Line(segments: line1, fontSize: 28),
        const SizedBox(height: 6),
        _Line(segments: line2, fontSize: 30),
      ],
    );
  }
}

class _Line extends StatelessWidget {
  final List<OnboardingTextSegment> segments;
  final double fontSize;

  const _Line({
    required this.segments,
    required this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    const base = TextStyle(
      fontWeight: FontWeight.w600,
      color: Color(0xFFB0B3C3),
      height: 1.1,
    );

    const emphasis = TextStyle(
      fontWeight: FontWeight.w800,
      color: Color(0xFF101828),
      height: 1.1,
    );

    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        children: segments
            .map(
              (s) => TextSpan(
                text: s.text,
                style: (s.isEmphasis ? emphasis : base).copyWith(
                  fontSize: fontSize,
                ),
              ),
            )
            .toList(growable: false),
      ),
    );
  }
}



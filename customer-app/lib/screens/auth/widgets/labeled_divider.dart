import 'package:flutter/material.dart';

import 'auth_colors.dart';

class LabeledDivider extends StatelessWidget {
  final String label;

  const LabeledDivider({
    super.key,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AuthColors.primary,
          ),
        ),
        const SizedBox(width: 10),
        const Expanded(
          child: Divider(
            thickness: 1.2,
            height: 1.2,
            color: Color(0xFFD9DCF0),
          ),
        ),
      ],
    );
  }
}



import 'package:flutter/material.dart';

import '../../../home/widgets/home_colors.dart';
import '../../../../theme/app_text_styles.dart';

class OthersField extends StatelessWidget {
  final TextEditingController controller;

  const OthersField({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final inputStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: HomeColors.text,
        ) ??
        const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: HomeColors.text,
        );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: HomeColors.borderSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Others',
            style:
                AppTextStyles.header(color: HomeColors.text).copyWith(fontSize: 12),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 34,
            child: TextField(
              controller: controller,
              textAlignVertical: TextAlignVertical.center,
              decoration: const InputDecoration(
                contentPadding: EdgeInsets.symmetric(vertical: 8),
                border: UnderlineInputBorder(
                  borderSide: BorderSide(color: HomeColors.borderSoft),
                ),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: HomeColors.borderSoft),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: HomeColors.primary, width: 1.6),
                ),
              ),
              style: inputStyle,
            ),
          ),
        ],
      ),
    );
  }
}



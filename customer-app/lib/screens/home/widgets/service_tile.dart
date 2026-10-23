import 'package:flutter/material.dart';

import 'home_colors.dart';
import '../../../theme/app_text_styles.dart';

class ServiceTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final String imageAsset;
  final bool isPrimary;
  final bool fullWidthImage;
  final double? imageSize;
  final VoidCallback? onTap;

  const ServiceTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.imageAsset,
    this.isPrimary = false,
    this.fullWidthImage = false,
    this.imageSize,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isPrimary ? HomeColors.primary : HomeColors.card;
    final titleColor = isPrimary ? Colors.white : HomeColors.text;
    final subtitleColor =
        isPrimary ? const Color(0xFFD7DAEA) : HomeColors.muted;
    final nonPrimaryImageSize = imageSize ?? 110;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(18),
            border: isPrimary ? null : Border.all(color: HomeColors.borderSoft),
            boxShadow: [
              if (!isPrimary)
                const BoxShadow(
                  color: Color(0x14000000),
                  blurRadius: 18,
                  offset: Offset(0, 10),
                ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Stack(
              children: [
            if (fullWidthImage)
              Positioned(
                left: 0,
                right: 0,
                bottom: -8,
                child: Image.asset(
                  imageAsset,
                  fit: BoxFit.fitWidth,
                  alignment: Alignment.bottomCenter,
                ),
              )
            else if (isPrimary)
              Positioned(
                right: -10,
                bottom: -6,
                child: Image.asset(
                  imageAsset,
                  width: 162,
                  height: 162,
                  fit: BoxFit.contain,
                ),
              )
            else
              Positioned(
                right: -14,
                bottom: -10,
                child: Image.asset(
                  imageAsset,
                  width: nonPrimaryImageSize,
                  height: nonPrimaryImageSize,
                  fit: BoxFit.contain,
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.header(color: titleColor),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.body(color: subtitleColor),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.topLeft,
                    child: _ArrowChip(isPrimary: isPrimary),
                  ),
                  const Spacer(),
                ],
              ),
            ),
          ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ArrowChip extends StatelessWidget {
  final bool isPrimary;

  const _ArrowChip({required this.isPrimary});

  @override
  Widget build(BuildContext context) {
    final fill = isPrimary ? Colors.white : const Color(0xFFF0F2FF);
    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        color: fill,
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.chevron_right_rounded,
        size: 18,
        color: HomeColors.primary,
      ),
    );
  }
}



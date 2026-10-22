import 'package:flutter/material.dart';

import '../../../theme/app_text_styles.dart';
import 'home_colors.dart';
import 'how_laundry_sheet.dart';

class HowLaundryCard extends StatelessWidget {
  const HowLaundryCard({super.key});

  static const _avatar = 'assets/images/home/how_we_do_laundry_avatar.png';

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: () => HowLaundrySheet.show(context),
        borderRadius: BorderRadius.circular(18),
        child: Ink(
        decoration: BoxDecoration(
          color: HomeColors.card,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 18,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final avatarHeight = constraints.maxHeight;
              return Stack(
                fit: StackFit.expand,
                children: [
                  Positioned(
                    right: 6,
                    bottom: 0,
                    child: Image.asset(
                      _avatar,
                      height: avatarHeight,
                      fit: BoxFit.contain,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 16, 120, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'How your laundry gets done',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.header(color: HomeColors.text),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'See the full process',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.body(color: HomeColors.muted),
                        ),
                        const Spacer(),
                        Container(
                          width: 26,
                          height: 26,
                          decoration: const BoxDecoration(
                            color: Color(0xFFF0F2FF),
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
              );
            },
          ),
        ),
        ),
      ),
    );
  }
}

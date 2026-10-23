import 'package:flutter/material.dart';

import '../../../routes/app_routes.dart';
import '../../../theme/app_text_styles.dart';
import '../../cart/schedule_bottom_sheet.dart';
import 'home_colors.dart';

class PickupCards extends StatelessWidget {
  const PickupCards({super.key});

  @override
  Widget build(BuildContext context) {
    final next = _nextPickup();
    // Figma: schedule 135×131, instant 200×131, 16px gap.
    final width = MediaQuery.sizeOf(context).width - 36;
    const designWidth = 135 + 16 + 200;
    final scale = (width / designWidth).clamp(0.82, 1.2);
    final height = 131 * scale;
    final gap = 16 * scale;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 135,
          child: _SchedulePickupCard(
            height: height,
            dayLabel: 'Next - ${next.day}',
            timeLabel: next.time,
            onTap: () async {
              final picked = await showScheduleBottomSheet(context);
              if (picked == null || !context.mounted) return;
              Navigator.of(context).pushNamed(
                AppRoutes.deliveryOptions,
                arguments: picked,
              );
            },
          ),
        ),
        SizedBox(width: gap),
        Expanded(
          flex: 200,
          child: _InstantPickupCard(
            height: height,
            onTap: () => Navigator.of(context).pushNamed(
              AppRoutes.deliveryOptions,
              arguments: 'instant',
            ),
          ),
        ),
      ],
    );
  }
}

({String day, String time}) _nextPickup() {
  final now = DateTime.now();
  var slot = DateTime(now.year, now.month, now.day, now.hour);
  if (now.minute > 0 || now.second > 0) {
    slot = slot.add(const Duration(hours: 1));
  }
  var day = 'Today';
  if (slot.hour >= 21) {
    slot = DateTime(now.year, now.month, now.day + 1, 9);
    day = 'Tomorrow';
  } else if (slot.hour < 9) {
    slot = DateTime(now.year, now.month, now.day, 9);
  }
  final hour12 = slot.hour % 12 == 0 ? 12 : slot.hour % 12;
  final period = slot.hour >= 12 ? 'PM' : 'AM';
  return (day: day, time: '$hour12:00$period');
}

class _SchedulePickupCard extends StatelessWidget {
  final double height;
  final String dayLabel;
  final String timeLabel;
  final VoidCallback onTap;

  const _SchedulePickupCard({
    required this.height,
    required this.dayLabel,
    required this.timeLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(26),
        child: Ink(
          height: height,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(26),
            boxShadow: const [
              BoxShadow(
                color: Color(0x14000000),
                blurRadius: 18,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 12, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Schedule\npick up',
                  style: AppTextStyles.header(color: const Color(0xFF1B2440)).copyWith(
                    fontSize: 16,
                    height: 1.15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            dayLabel,
                            style: AppTextStyles.body(color: const Color(0xFF8B93A7)).copyWith(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            timeLabel,
                            style: AppTextStyles.header(color: const Color(0xFF1B2440)).copyWith(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const _ArrowButton(
                      background: HomeColors.primary,
                      iconColor: Colors.white,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InstantPickupCard extends StatelessWidget {
  final double height;
  final VoidCallback onTap;

  const _InstantPickupCard({required this.height, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(26),
        child: Ink(
          height: height,
          decoration: BoxDecoration(
            color: HomeColors.primary,
            borderRadius: BorderRadius.circular(26),
            boxShadow: const [
              BoxShadow(
                color: Color(0x332C3CA5),
                blurRadius: 18,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(26),
            child: Stack(
              children: [
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Image.asset(
                    'assets/images/home/instant_pickup_cart.png',
                    height: height * 0.78,
                    fit: BoxFit.contain,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 40),
                        child: Text(
                          'Book Instant\npick up',
                          style: AppTextStyles.header(color: Colors.white).copyWith(
                            fontSize: 16,
                            height: 1.15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Icon(Icons.bolt_rounded, color: Colors.white, size: 16),
                          const SizedBox(width: 2),
                          Text(
                            '20 mins',
                            style: AppTextStyles.body(color: Colors.white).copyWith(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Positioned(
                  top: 10,
                  right: 10,
                  child: _ArrowButton(
                    background: Colors.white,
                    iconColor: Color(0xFF1B2440),
                    size: 28,
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

class _ArrowButton extends StatelessWidget {
  final Color background;
  final Color iconColor;
  final double size;

  const _ArrowButton({
    required this.background,
    required this.iconColor,
    this.size = 32,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: background, shape: BoxShape.circle),
      child: Icon(Icons.arrow_forward_rounded, color: iconColor, size: size * 0.5),
    );
  }
}

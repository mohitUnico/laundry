import 'package:flutter/material.dart';

import '../../../theme/app_text_styles.dart';
import 'home_colors.dart';

class ActiveOrderCard extends StatelessWidget {
  final String orderId;
  final int activeStepIndex; // 0..3
  final String etaText;
  final VoidCallback? onTrackNow;
  final VoidCallback? onViewDetails;

  const ActiveOrderCard({
    super.key,
    required this.orderId,
    required this.activeStepIndex,
    required this.etaText,
    this.onTrackNow,
    this.onViewDetails,
  });

  static const _steps = ['Placed', 'Pickup', 'In Progress', 'Delivered'];

  @override
  Widget build(BuildContext context) {
    final clampedStep = activeStepIndex.clamp(0, _steps.length - 1);

    return Container(
      width: double.infinity,
      // Minimal bottom padding to avoid excess white space below Track Now
      padding: const EdgeInsets.fromLTRB(18, 16, 16, 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center, // Center content vertically
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Active Order',
                  style: AppTextStyles.header(color: HomeColors.text)
                      .copyWith(fontSize: 18),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  orderId,
                  style: AppTextStyles.body(color: HomeColors.muted)
                      .copyWith(fontSize: 12),
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          // Space below the header row (Active Order + ID)
          const SizedBox(height: 14),
          _OrderStepper(
            activeIndex: clampedStep,
            labels: _steps,
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextButton(
                  onPressed: onViewDetails,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    foregroundColor: HomeColors.primary,
                    textStyle: AppTextStyles
                        .button(color: HomeColors.primary)
                        .copyWith(fontSize: 12),
                  ),
                  child: const Text('View Details'),
                ),
                const SizedBox(width: 6),
                TextButton(
                  onPressed: onTrackNow,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    foregroundColor: HomeColors.primary,
                    textStyle: AppTextStyles
                        .button(color: HomeColors.primary)
                        .copyWith(fontSize: 12),
                  ),
                  child: const Text('Track Laundry'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderStepper extends StatelessWidget {
  final int activeIndex;
  final List<String> labels;

  const _OrderStepper({
    required this.activeIndex,
    required this.labels,
  });

  @override
  Widget build(BuildContext context) {
    // Constrain width so the segments look like the design on wide screens.
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 340),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Dots row with connecting lines
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < labels.length; i++) ...[
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _Dot(isActive: i <= activeIndex),
                      const SizedBox(height: 6),
                      Text(
                        labels[i],
                        textAlign: TextAlign.center,
                        style: AppTextStyles.body(
                          color: i <= activeIndex
                              ? HomeColors.primary
                              : const Color(0xFF9AA3B2),
                        ).copyWith(fontSize: 12),
                      ),
                    ],
                  ),
                  if (i != labels.length - 1)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 9), // Align line with dot center
                        child: Container(
                          height: 4,
                          decoration: BoxDecoration(
                            color: i < activeIndex
                                ? HomeColors.primary
                                : const Color(0xFF9AA3B2),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                    ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  final bool isActive;

  const _Dot({required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        color: isActive ? HomeColors.primary : const Color(0xFF9AA3B2),
        shape: BoxShape.circle,
      ),
    );
  }
}



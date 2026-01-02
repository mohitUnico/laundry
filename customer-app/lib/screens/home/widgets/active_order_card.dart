import 'package:flutter/material.dart';

import '../../../theme/app_text_styles.dart';
import 'home_colors.dart';

class ActiveOrderCard extends StatelessWidget {
  final String orderId;
  final int activeStepIndex; // 0..3
  final String etaText;
  final VoidCallback? onTrackNow;

  const ActiveOrderCard({
    super.key,
    required this.orderId,
    required this.activeStepIndex,
    required this.etaText,
    this.onTrackNow,
  });

  static const _steps = ['Picked Up', 'Cleaning', 'Ready', 'Delivered'];

  @override
  Widget build(BuildContext context) {
    final clampedStep = activeStepIndex.clamp(0, _steps.length - 1);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
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
        children: [
          Row(
            children: [
              Text(
                'Active Order',
                style: AppTextStyles.header(color: HomeColors.text)
                    .copyWith(fontSize: 18),
              ),
              const Spacer(),
              Text(
                orderId,
                style: AppTextStyles.body(color: HomeColors.muted)
                    .copyWith(fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _OrderStepper(
            activeIndex: clampedStep,
            labels: _steps,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  etaText,
                  style: AppTextStyles.body(color: HomeColors.muted)
                      .copyWith(fontSize: 12),
                ),
              ),
              InkWell(
                onTap: onTrackNow,
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Track Now',
                        style: AppTextStyles.button(color: HomeColors.primary)
                            .copyWith(fontSize: 12),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.chevron_right_rounded,
                        size: 20,
                        color: HomeColors.primary,
                      ),
                    ],
                  ),
                ),
              ),
            ],
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
          children: [
            Row(
              children: [
                for (var i = 0; i < labels.length; i++) ...[
                  _Dot(isActive: i <= activeIndex),
                  if (i != labels.length - 1)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
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
            const SizedBox(height: 10),
            Row(
              children: [
                for (var i = 0; i < labels.length; i++)
                  Expanded(
                    child: Text(
                      labels[i],
                      textAlign: TextAlign.center,
                      style: AppTextStyles.body(
                        color: i <= activeIndex
                            ? HomeColors.primary
                            : const Color(0xFF9AA3B2),
                      ).copyWith(fontSize: 12),
                    ),
                  ),
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



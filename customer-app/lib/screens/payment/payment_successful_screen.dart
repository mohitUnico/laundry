import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:provider/provider.dart';

import '../home/widgets/home_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../providers/cart_provider.dart';
import '../../utils/pricing.dart';
import '../../routes/app_routes.dart';
import '../cart/delivery_options_screen.dart';

class PaymentSuccessfulScreen extends StatefulWidget {
  const PaymentSuccessfulScreen({super.key});

  @override
  State<PaymentSuccessfulScreen> createState() => _PaymentSuccessfulScreenState();
}

class _PaymentSuccessfulScreenState extends State<PaymentSuccessfulScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _checkAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.elasticOut),
      ),
    );

    _checkAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final transactionId = args?['transactionId'] as String? ?? 'QUCVG6516516';
    final itemTotal = args?['itemTotal'] as int? ?? 0;
    final handlingFee = args?['handlingFee'] as int? ?? 0;
    final pickupFeeOriginal = args?['pickupFeeOriginal'] as int? ?? 0;
    final pickupFee = args?['pickupFee'] as int? ?? 0;
    final deliveryFee = args?['deliveryFee'] as int? ?? 0;
    final originalTotal = args?['originalTotal'] as int? ?? 0;
    final finalTotal = args?['finalTotal'] as int? ?? 0;
    final savings = originalTotal - finalTotal;
    final deliveryOptionStr = args?['deliveryOption'] as String? ?? 'pickupOnly';
    final deliveryOption = DeliveryOptionType.values.firstWhere(
      (e) => e.name == deliveryOptionStr,
      orElse: () => DeliveryOptionType.pickupOnly,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F7),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 10),
            _TopBar(
              onBack: () => Navigator.of(context).maybePop(),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Column(
                  children: [
                    const SizedBox(height: 40),
                    _AnimatedCheckmark(
                      scaleAnimation: _scaleAnimation,
                      checkAnimation: _checkAnimation,
                    ),
                    const SizedBox(height: 30),
                    Text(
                      'Payment Successful!',
                      style: AppTextStyles.header(color: HomeColors.text)
                          .copyWith(fontSize: 24, fontWeight: FontWeight.w700),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Your order has been placed successfully',
                      style: AppTextStyles.body(color: HomeColors.muted)
                          .copyWith(fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 30),
                    _TransactionDetailsCard(
                      transactionId: transactionId,
                      itemTotal: itemTotal,
                      handlingFee: handlingFee,
                      pickupFeeOriginal: pickupFeeOriginal,
                      pickupFee: pickupFee,
                      deliveryFee: deliveryFee,
                      originalTotal: originalTotal,
                      finalTotal: finalTotal,
                      savings: savings,
                      deliveryOption: deliveryOption,
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 20),
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Color(0x0A000000),
                    blurRadius: 10,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: _TrackButton(
                  onTap: () {
                    Navigator.of(context).pushNamedAndRemoveUntil(
                      AppRoutes.orders,
                      (r) => false,
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnimatedCheckmark extends StatelessWidget {
  final Animation<double> scaleAnimation;
  final Animation<double> checkAnimation;

  const _AnimatedCheckmark({
    required this.scaleAnimation,
    required this.checkAnimation,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([scaleAnimation, checkAnimation]),
      builder: (context, child) {
        return Transform.scale(
          scale: scaleAnimation.value,
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF16A34A),
                  const Color(0xFF16A34A).withOpacity(0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF16A34A).withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: CustomPaint(
              painter: _CheckmarkPainter(checkAnimation.value),
            ),
          ),
        );
      },
    );
  }
}

class _CheckmarkPainter extends CustomPainter {
  final double progress;

  _CheckmarkPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final centerX = size.width / 2;
    final centerY = size.height / 2;

    // Draw checkmark path
    final path = Path();
    final startX = centerX - 30;
    final startY = centerY;
    final midX = centerX - 8;
    final midY = centerY + 20;
    final endX = centerX + 28;
    final endY = centerY - 18;

    if (progress < 0.5) {
      // Draw first part of checkmark
      final t = progress * 2;
      final currentX = startX + (midX - startX) * t;
      final currentY = startY + (midY - startY) * t;
      path.moveTo(startX, startY);
      path.lineTo(currentX, currentY);
    } else {
      // Draw complete first part and second part
      path.moveTo(startX, startY);
      path.lineTo(midX, midY);
      
      final t = (progress - 0.5) * 2;
      final currentX = midX + (endX - midX) * t;
      final currentY = midY + (endY - midY) * t;
      path.lineTo(currentX, currentY);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_CheckmarkPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _TopBar extends StatelessWidget {
  final VoidCallback onBack;

  const _TopBar({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      child: Row(
        children: [
          InkWell(
            onTap: onBack,
            borderRadius: BorderRadius.circular(999),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 16,
                color: Color(0xFF1B1F2A),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Text(
            'Payment Successful',
            style: AppTextStyles.header(color: const Color(0xFF1B1F2A))
                .copyWith(fontSize: 20),
          ),
        ],
      ),
    );
  }
}

class _TransactionDetailsCard extends StatelessWidget {
  final String transactionId;
  final int itemTotal;
  final int handlingFee;
  final int pickupFeeOriginal;
  final int pickupFee;
  final int deliveryFee;
  final int originalTotal;
  final int finalTotal;
  final int savings;
  final DeliveryOptionType deliveryOption;

  const _TransactionDetailsCard({
    required this.transactionId,
    required this.itemTotal,
    required this.handlingFee,
    required this.pickupFeeOriginal,
    required this.pickupFee,
    required this.deliveryFee,
    required this.originalTotal,
    required this.finalTotal,
    required this.savings,
    required this.deliveryOption,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Transaction ID: $transactionId',
            style: AppTextStyles.header(color: const Color(0xFF1B1F2A))
                .copyWith(fontSize: 16),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, thickness: 1, color: Color(0xFFE5E7EB)),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: HomeColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.receipt_long_rounded,
                  color: HomeColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bill Summary',
                      style: AppTextStyles.header(color: const Color(0xFF1B1F2A))
                          .copyWith(fontSize: 16),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Incl. all taxes & charges',
                      style: AppTextStyles.body(color: const Color(0xFF98A0B5))
                          .copyWith(fontSize: 12),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    Pricing.inr(finalTotal),
                    style: AppTextStyles.header(color: HomeColors.primary)
                        .copyWith(fontSize: 18),
                  ),
                  if (originalTotal > finalTotal) ...[
                    const SizedBox(height: 2),
                    Text(
                      Pricing.inr(originalTotal),
                      style: AppTextStyles.body(color: const Color(0xFF98A0B5))
                          .copyWith(
                        fontSize: 12,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, thickness: 1, color: Color(0xFFE5E7EB)),
          const SizedBox(height: 16),
          _FeeRow(
            label: 'Item Total',
            amount: itemTotal,
          ),
          const SizedBox(height: 8),
          _FeeRow(
            label: 'Handling Fee',
            amount: handlingFee,
          ),
          if (deliveryOption == DeliveryOptionType.pickupOnly ||
              deliveryOption == DeliveryOptionType.pickupAndDelivery) ...[
            const SizedBox(height: 8),
            _FeeRow(
              label: 'Pickup Fee',
              amount: pickupFee,
            ),
          ],
          if (deliveryOption == DeliveryOptionType.deliveryOnly ||
              deliveryOption == DeliveryOptionType.pickupAndDelivery) ...[
            const SizedBox(height: 8),
            _FeeRow(
              label: 'Delivery Fee',
              amount: deliveryFee,
            ),
          ],
          const SizedBox(height: 16),
          const Divider(height: 1, thickness: 1, color: Color(0xFFE5E7EB)),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                'To Pay',
                style: AppTextStyles.header(color: const Color(0xFF1B1F2A))
                    .copyWith(fontSize: 18),
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (originalTotal > finalTotal) ...[
                    Text(
                      Pricing.inr(originalTotal),
                      style: AppTextStyles.body(color: const Color(0xFF98A0B5))
                          .copyWith(
                        fontSize: 14,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                  Text(
                    Pricing.inr(finalTotal),
                    style: AppTextStyles.header(color: HomeColors.primary)
                        .copyWith(fontSize: 20),
                  ),
                  if (savings > 0) ...[
                    const SizedBox(height: 4),
                    Text(
                      'You saved ${Pricing.inr(savings)}',
                      style: AppTextStyles.body(color: const Color(0xFF16A34A))
                          .copyWith(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FeeRow extends StatelessWidget {
  final String label;
  final int amount;
  final int? originalAmount;

  const _FeeRow({
    required this.label,
    required this.amount,
    this.originalAmount,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: AppTextStyles.body(color: const Color(0xFF1B1F2A))
                .copyWith(fontSize: 14),
          ),
        ),
        if (originalAmount != null && originalAmount! > amount) ...[
          Text(
            Pricing.inr(originalAmount!),
            style: AppTextStyles.body(color: const Color(0xFF98A0B5))
                .copyWith(
              fontSize: 12,
              decoration: TextDecoration.lineThrough,
            ),
          ),
          const SizedBox(width: 8),
        ],
        Text(
          Pricing.inr(amount),
          style: AppTextStyles.body(color: const Color(0xFF1B1F2A))
              .copyWith(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _TrackButton extends StatelessWidget {
  final VoidCallback onTap;

  const _TrackButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: const LinearGradient(
                colors: [Color(0xFF2437B6), Color(0xFF2C3CA5)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            ),
            child: Center(
              child: Text(
                'Track your Laundry',
                style: AppTextStyles.header(color: Colors.white)
                    .copyWith(fontSize: 16),
              ),
            ),
          ),
        ),
      ),
    );
  }
}


import 'dart:async';
import 'package:flutter/material.dart';
import '../routes/app_routes.dart';
import '../theme/app_text_styles.dart';
import '../screens/home/widgets/home_colors.dart';

/// Shows an animated success dialog when items are added to cart.
/// Auto-dismisses after 2 seconds or on tap, then navigates to homepage.
class CartSuccessDialog extends StatefulWidget {
  const CartSuccessDialog({super.key});

  @override
  State<CartSuccessDialog> createState() => _CartSuccessDialogState();
}

class _CartSuccessDialogState extends State<CartSuccessDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _tickAnimation;
  Timer? _dismissTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.elasticOut,
      ),
    );

    _tickAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
      ),
    );

    _controller.forward();

    // Auto-dismiss after 2 seconds
    _dismissTimer = Timer(const Duration(seconds: 2), () {
      _dismissAndNavigate();
    });
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _dismissAndNavigate() {
    if (!mounted) return;
    Navigator.of(context).pop();
    // Navigate to homepage
    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRoutes.home,
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _dismissAndNavigate,
      child: Material(
        color: Colors.black.withOpacity(0.5),
        child: Center(
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 40),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Animated tick mark
                  AnimatedBuilder(
                    animation: _tickAnimation,
                    builder: (context, child) {
                      return CustomPaint(
                        size: const Size(60, 60),
                        painter: _TickPainter(
                          progress: _tickAnimation.value,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Items added to cart',
                    style: AppTextStyles.header(color: HomeColors.text)
                        .copyWith(fontSize: 18, fontWeight: FontWeight.w600),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap anywhere or wait 2 seconds',
                    style: AppTextStyles.body(color: HomeColors.muted)
                        .copyWith(fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Custom painter for animated tick mark
class _TickPainter extends CustomPainter {
  final double progress;

  _TickPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = HomeColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;

    // Draw circle background
    final circlePaint = Paint()
      ..color = HomeColors.primary.withOpacity(0.1)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, circlePaint);

    // Draw circle border
    canvas.drawCircle(center, radius, paint);

    if (progress > 0) {
      // Draw tick mark - simplified path
      final tickStart = Offset(center.dx - radius * 0.25, center.dy);
      final tickMid = Offset(center.dx, center.dy + radius * 0.25);
      final tickEnd = Offset(center.dx + radius * 0.4, center.dy - radius * 0.2);

      // Animate the tick drawing
      if (progress < 0.5) {
        // Draw first part of tick (from start to mid)
        final firstPartProgress = progress * 2;
        final firstPartEnd = Offset.lerp(tickStart, tickMid, firstPartProgress)!;
        canvas.drawLine(tickStart, firstPartEnd, paint);
      } else {
        // Draw complete first part
        canvas.drawLine(tickStart, tickMid, paint);
        // Draw second part of tick (from mid to end)
        final secondPartProgress = (progress - 0.5) * 2;
        final secondPartEnd = Offset.lerp(tickMid, tickEnd, secondPartProgress)!;
        canvas.drawLine(tickMid, secondPartEnd, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_TickPainter oldDelegate) => oldDelegate.progress != progress;
}

/// Helper function to show the cart success dialog
void showCartSuccessDialog(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.transparent,
    builder: (context) => const CartSuccessDialog(),
  );
}


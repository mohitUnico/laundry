import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../routes/app_routes.dart';
import '../../routes/route_args.dart';
import '../home/widgets/home_colors.dart';

class OrderPlacedScreen extends StatefulWidget {
  final String? slotText;
  final String? orderId;
  final bool scheduleOnly;

  const OrderPlacedScreen({
    super.key,
    this.slotText,
    this.orderId,
    this.scheduleOnly = false,
  });

  @override
  State<OrderPlacedScreen> createState() => _OrderPlacedScreenState();
}

class _OrderPlacedScreenState extends State<OrderPlacedScreen> {
  Timer? _timer;

  bool get _schedule => widget.scheduleOnly && (widget.orderId ?? '').isNotEmpty;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(seconds: 3), _openNext);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _openNext() {
    if (!mounted) return;
    if (_schedule) {
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.orderTracking,
        (route) => false,
        arguments: OrderTrackingArgs(
          orderId: widget.orderId!,
          backendStatus: 'placed',
          orderType: 'schedule_pickup',
          scheduleOnly: true,
          slotLabel: widget.slotText,
        ),
      );
      return;
    }
    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRoutes.orders,
      (route) => false,
    );
  }

  void _goHome(BuildContext context) {
    _timer?.cancel();
    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRoutes.home,
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_schedule) return _scheduleBody(context);
    return _catalogBody(context);
  }

  Widget _scheduleBody(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _goHome(context);
      },
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                HomeColors.background,
                Color(0xFFF9FAFF),
                Colors.white,
              ],
            ),
          ),
          child: SafeArea(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const _CelebrationArt(),
                  const SizedBox(height: 28),
                  Text(
                    'Your order\nis confirmed!',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                      color: HomeColors.text,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _catalogBody(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _goHome(context);
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/images/order_successfull.png',
                  width: width * 0.62,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 28),
                Text(
                  'Order Successful',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF101828),
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

class _CelebrationArt extends StatelessWidget {
  const _CelebrationArt();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 240,
      height: 180,
      child: CustomPaint(painter: _CelebrationPainter()),
    );
  }
}

class _CelebrationPainter extends CustomPainter {
  const _CelebrationPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final blob = Paint()..color = HomeColors.primary.withValues(alpha: 0.12);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width / 2, size.height * 0.58),
        width: size.width * 0.86,
        height: size.height * 0.62,
      ),
      blob,
    );

    final check = Paint()
      ..color = HomeColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final checkPath = Path()
      ..moveTo(size.width * 0.40, size.height * 0.22)
      ..lineTo(size.width * 0.48, size.height * 0.34)
      ..lineTo(size.width * 0.64, size.height * 0.12);
    canvas.drawPath(checkPath, check);

    _person(
      canvas,
      origin: Offset(size.width * 0.32, size.height * 0.78),
      scale: 0.86,
      bothArms: false,
    );
    _person(
      canvas,
      origin: Offset(size.width * 0.64, size.height * 0.74),
      scale: 1,
      bothArms: true,
    );

    final ground = Paint()
      ..color = HomeColors.muted.withValues(alpha: 0.45)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(size.width * 0.22, size.height * 0.9),
      Offset(size.width * 0.78, size.height * 0.9),
      ground,
    );
  }

  void _person(
    Canvas canvas, {
    required Offset origin,
    required double scale,
    required bool bothArms,
  }) {
    final shirt = Paint()..color = HomeColors.primary;
    final pants = Paint()..color = const Color(0xFFC5CAE0);
    final skin = Paint()..color = const Color(0xFFF3C7A5);
    final hair = Paint()..color = const Color(0xFF2A3148);

    canvas.drawCircle(origin.translate(0, -58 * scale), 11 * scale, skin);
    canvas.drawArc(
      Rect.fromCircle(center: origin.translate(0, -62 * scale), radius: 11 * scale),
      3.4,
      2.6,
      false,
      hair..style = PaintingStyle.stroke..strokeWidth = 3 * scale,
    );
    hair.style = PaintingStyle.fill;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: origin.translate(0, -34 * scale), width: 22 * scale, height: 26 * scale),
        Radius.circular(6 * scale),
      ),
      shirt,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: origin.translate(-6 * scale, -8 * scale), width: 7 * scale, height: 22 * scale),
        const Radius.circular(4),
      ),
      pants,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: origin.translate(bothArms ? 8 * scale : 6 * scale, -6 * scale),
          width: 7 * scale,
          height: 20 * scale,
        ),
        const Radius.circular(4),
      ),
      pants,
    );

    final arm = Paint()
      ..color = HomeColors.primary
      ..strokeWidth = 5 * scale
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(origin.translate(-8 * scale, -42 * scale), origin.translate(-18 * scale, -62 * scale), arm);
    if (bothArms) {
      canvas.drawLine(origin.translate(8 * scale, -42 * scale), origin.translate(20 * scale, -64 * scale), arm);
    } else {
      canvas.drawLine(origin.translate(8 * scale, -40 * scale), origin.translate(16 * scale, -28 * scale), arm);
    }

    final tick = Paint()
      ..color = HomeColors.primary
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(origin.translate(-28 * scale, -48 * scale), origin.translate(-34 * scale, -56 * scale), tick);
    canvas.drawLine(origin.translate(24 * scale, -46 * scale), origin.translate(32 * scale, -54 * scale), tick);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../providers/order_provider.dart';
import '../../routes/app_routes.dart';
import '../../routes/route_args.dart';
import '../home/widgets/home_colors.dart';

class OrderPlacedScreen extends StatefulWidget {
  final String? slotText;
  final String? orderId;
  final bool scheduleOnly;
  final bool instant;

  const OrderPlacedScreen({
    super.key,
    this.slotText,
    this.orderId,
    this.scheduleOnly = false,
    this.instant = false,
  });

  @override
  State<OrderPlacedScreen> createState() => _OrderPlacedScreenState();
}

class _OrderPlacedScreenState extends State<OrderPlacedScreen> {
  Timer? _timer;

  bool get _timelineOrder =>
      (widget.scheduleOnly || widget.instant) && (widget.orderId ?? '').isNotEmpty;

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
    if (_timelineOrder) {
      final match = context.read<OrderProvider>().orders.where((order) => order.id == widget.orderId);
      final order = match.isEmpty ? null : match.first;
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.orderTracking,
        (route) => false,
        arguments: OrderTrackingArgs(
          orderId: widget.orderId!,
          pickupAddress: order?.pickupAddress,
          pickupLat: order?.pickupLat,
          pickupLng: order?.pickupLng,
          backendStatus: 'placed',
          orderType: 'both',
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
    if (_timelineOrder) return _scheduleBody(context);
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
                  Image.asset(
                    'assets/images/order_confirmed.png',
                    width: 269,
                    height: 202,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 8),
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


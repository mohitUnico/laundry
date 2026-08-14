import 'package:flutter/material.dart';

import '../../../models/order_record.dart';
import '../../../routes/app_routes.dart';
import '../../../routes/route_args.dart';
import '../../../theme/app_text_styles.dart';
import 'active_order_card.dart';
import 'home_colors.dart';

class ActiveOrdersCarousel extends StatefulWidget {
  final List<OrderRecord> orders;

  const ActiveOrdersCarousel({
    super.key,
    required this.orders,
  });

  @override
  State<ActiveOrdersCarousel> createState() => _ActiveOrdersCarouselState();
}

class _ActiveOrdersCarouselState extends State<ActiveOrdersCarousel> {
  late final PageController _controller;
  bool _controllerInitialized = false;
  int _index = 0;

  static const int _loopMultiplier = 1000;

  @override
  void initState() {
    super.initState();
    if (widget.orders.isEmpty) return;
    // Show one full card at a time (no peek)
    final initial = (widget.orders.length * _loopMultiplier) ~/ 2;
    final alignedInitial = initial - (initial % widget.orders.length);
    _controller = PageController(
      viewportFraction: 1.0, // Full width - one card at a time
      initialPage: alignedInitial,
    );
    _controllerInitialized = true;
    _index = 0;
  }

  @override
  void didUpdateWidget(ActiveOrdersCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reset controller if orders list changes
    if (oldWidget.orders.length != widget.orders.length && widget.orders.isNotEmpty) {
      final initial = (widget.orders.length * _loopMultiplier) ~/ 2;
      final alignedInitial = initial - (initial % widget.orders.length);
      // If controller was never initialized (widget became non-empty later), create it once
      if (!_controllerInitialized) {
        _controller = PageController(
          viewportFraction: 1.0,
          initialPage: alignedInitial,
        );
        _controllerInitialized = true;
      } else if (_controller.hasClients) {
        // For already initialized controller, just jump to the new aligned page
        _controller.jumpToPage(alignedInitial);
      }
      _index = 0;
    }
  }

  @override
  void dispose() {
    if (_controllerInitialized) {
      _controller.dispose();
    }
    super.dispose();
  }

  int _mapOrderStatusToStepIndex(String backendStatus) {
    // Map backend order status to the 4-step Active Order card index:
    // 0: Placed, 1: Pickup, 2: In Progress, 3: Delivered
    final status = backendStatus.toLowerCase().trim();

    // Placed group
    if (status == 'placed' || status == 'pickup_assigned') return 0;

    // Pickup group
    if (status == 'picked_up') return 1;

    // In progress group (processing + dispatch + out-for-delivery + payment pending)
    if (status == 'received_by_collection' ||
        status == 'submitted_to_cm' ||
        status == 'submitted_to_services' ||
        status == 'services_in_progress' ||
        status == 'services_completed' ||
        status == 'dispatch_assigned' ||
        status == 'out_for_delivery' ||
        status == 'payment_pending' ||
        status == 'payment_completed') {
      return 2;
    }

    // Delivered group
    if (status == 'delivered') return 3;

    // For closed/cancelled we still show as delivered (these should typically not be in active orders).
    if (status == 'closed' || status == 'cancelled') return 3;

    // Default to "Placed" so the UI doesn't jump forward for unknown/empty statuses.
    return 0;
  }

  String _formatEtaText(OrderRecord order) {
    if (order.dateLabel == 'TBD' || order.timeLabel == 'TBD') {
      return 'Estimated Delivery: To be determined';
    }
    
    // Calculate if delivery is today, tomorrow, or later
    final now = DateTime.now();
    final deliveryDate = DateTime(
      now.year,
      now.month,
      now.day,
    );
    
    // Try to parse the date label (e.g., "Dec 20")
    final dateParts = order.dateLabel.split(' ');
    if (dateParts.length == 2) {
      final monthStr = dateParts[0];
      final dayStr = dateParts[1];
      
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      final monthIndex = months.indexOf(monthStr);
      final day = int.tryParse(dayStr);
      
      if (monthIndex >= 0 && day != null) {
        final deliveryDateTime = DateTime(now.year, monthIndex + 1, day);
        final diff = deliveryDateTime.difference(deliveryDate).inDays;
        
        if (diff == 0) {
          return 'Estimated Delivery: Today, ${order.timeLabel}';
        } else if (diff == 1) {
          return 'Estimated Delivery: Tomorrow, ${order.timeLabel}';
        } else if (diff > 1) {
          return 'Estimated Delivery: ${order.dateLabel}, ${order.timeLabel}';
        }
      }
    }
    
    return 'Estimated Delivery: ${order.dateLabel}, ${order.timeLabel}';
  }

  @override
  Widget build(BuildContext context) {
    if (widget.orders.isEmpty) {
      return const SizedBox.shrink();
    }

    // If there's only one active order, show a single card without carousel behavior
    if (widget.orders.length == 1) {
      final order = widget.orders.first;
      final stepIndex = _mapOrderStatusToStepIndex(order.backendStatus);
      final etaText = _formatEtaText(order);

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
          child: ActiveOrderCard(
            orderId: order.shortId,
            activeStepIndex: stepIndex,
            etaText: etaText,
            onViewDetails: () => Navigator.of(context).pushNamed(AppRoutes.orders),
            onTrackNow: () => Navigator.of(context).pushNamed(
              AppRoutes.orderTracking,
              arguments: OrderTrackingArgs(
                orderId: order.id,
                pickupAddress: order.pickupAddress,
                pickupLat: order.pickupLat,
                pickupLng: order.pickupLng,
                backendStatus: order.backendStatus,
                orderType: order.orderTypeOrBoth,
              ),
            ),
          ),
      );
    }

    final totalPages = widget.orders.length * _loopMultiplier;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final screenWidth = constraints.maxWidth;
            return SizedBox(
              height: 150, // Reduced height to make the active order card shorter
              width: screenWidth, // Use exact width from constraints
              child: ClipRect(
                clipBehavior: Clip.hardEdge, // Hard clip to prevent any overflow
                child: PageView.builder(
                  controller: _controller,
                  itemCount: totalPages,
                  padEnds: false, // No padding at ends - one full card at a time
                  physics: const PageScrollPhysics(), // Snap to pages
                  clipBehavior: Clip.hardEdge, // Hard clip for PageView
                  onPageChanged: (v) =>
                      setState(() => _index = v % widget.orders.length),
                  itemBuilder: (context, i) {
                    final order = widget.orders[i % widget.orders.length];
                    final stepIndex = _mapOrderStatusToStepIndex(order.backendStatus);
                    final etaText = _formatEtaText(order);
                    
                    return SizedBox(
                      width: screenWidth, // Exact width matching constraints
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: ActiveOrderCard(
                          orderId: order.shortId,
                          activeStepIndex: stepIndex,
                          etaText: etaText,
                          onViewDetails: () => Navigator.of(context).pushNamed(AppRoutes.orders),
                          onTrackNow: () => Navigator.of(context).pushNamed(
                            AppRoutes.orderTracking,
                            arguments: OrderTrackingArgs(
                              orderId: order.id,
                              pickupAddress: order.pickupAddress,
                              pickupLat: order.pickupLat,
                              pickupLng: order.pickupLng,
                              backendStatus: order.backendStatus,
                              orderType: order.orderTypeOrBoth,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            );
          },
        ),
        if (widget.orders.length > 1)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: _Indicator(
              currentIndex: _index,
              count: widget.orders.length,
            ),
          ),
      ],
    );
  }
}

class _Indicator extends StatelessWidget {
  final int currentIndex;
  final int count;

  const _Indicator({
    required this.currentIndex,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final isActive = i == currentIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          width: isActive ? 16 : 6,
          height: 6,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: isActive ? HomeColors.primary : const Color(0xFFD6D9E7),
            borderRadius: BorderRadius.circular(999),
          ),
        );
      }),
    );
  }
}


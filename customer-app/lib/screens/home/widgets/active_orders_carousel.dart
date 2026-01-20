import 'package:flutter/material.dart';

import '../../../models/order_record.dart';
import '../../../routes/app_routes.dart';
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
  int _index = 0;

  static const int _loopMultiplier = 1000;

  @override
  void initState() {
    super.initState();
    if (widget.orders.isEmpty) return;
    // < 1.0 so users can peek previous/next banner.
    final initial = (widget.orders.length * _loopMultiplier) ~/ 2;
    final alignedInitial = initial - (initial % widget.orders.length);
    _controller = PageController(
      viewportFraction: 0.88,
      initialPage: alignedInitial,
    );
    _index = 0;
  }

  @override
  void dispose() {
    if (widget.orders.isNotEmpty) {
      _controller.dispose();
    }
    super.dispose();
  }

  int _mapOrderStatusToStepIndex(String backendStatus) {
    // Map backend order status to stepper index (0-3)
    // Step 0: Picked Up (placed, pickup_assigned, picked_up)
    // Step 1: Cleaning (received_by_collection, submitted_to_services, services_in_progress)
    // Step 2: Ready (services_completed, dispatch_assigned)
    // Step 3: Delivered (out_for_delivery, payment_pending, delivered)
    
    final status = backendStatus.toLowerCase();
    
    if (status == 'placed' || status == 'pickup_assigned' || status == 'picked_up') {
      return 0; // Picked Up
    } else if (status == 'received_by_collection' || 
               status == 'submitted_to_services' || 
               status == 'services_in_progress') {
      return 1; // Cleaning
    } else if (status == 'services_completed' || status == 'dispatch_assigned') {
      return 2; // Ready
    } else if (status == 'out_for_delivery' || 
               status == 'payment_pending' || 
               status == 'delivered' || 
               status == 'closed') {
      return 3; // Delivered
    }
    
    // Default to step 1 for unknown statuses
    return 1;
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
          orderId: order.id,
          activeStepIndex: stepIndex,
          etaText: etaText,
          onTrackNow: () => Navigator.of(context).pushNamed(
            AppRoutes.orderTracking,
            arguments: order.id,
          ),
        ),
      );
    }

    final totalPages = widget.orders.length * _loopMultiplier;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 165, // Match the actual card content height
          child: PageView.builder(
            controller: _controller,
            itemCount: totalPages,
            padEnds: true,
            onPageChanged: (v) =>
                setState(() => _index = v % widget.orders.length),
            itemBuilder: (context, i) {
              final order = widget.orders[i % widget.orders.length];
              final stepIndex = _mapOrderStatusToStepIndex(order.backendStatus);
              final etaText = _formatEtaText(order);
              
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: ActiveOrderCard(
                  orderId: order.id,
                  activeStepIndex: stepIndex,
                  etaText: etaText,
                  onTrackNow: () => Navigator.of(context).pushNamed(
                    AppRoutes.orderTracking,
                    arguments: order.id,
                  ),
                ),
              );
            },
          ),
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


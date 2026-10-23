import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import '../../models/order_record.dart';
import '../../providers/order_provider.dart';
import '../../theme/app_text_styles.dart';
import '../cart/schedule_bottom_sheet.dart';
import 'cancel_pickup_screen.dart';
import '../home/widgets/home_colors.dart';
import '../../routes/app_routes.dart';
import '../../routes/route_args.dart';
import '../../services/order_tracking_service.dart';
import '../../services/google_directions_service.dart';
import '../../utils/polling_config.dart';

class OrderTrackingScreen extends StatefulWidget {
  const OrderTrackingScreen({super.key});

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  // 0..4 (0 = Pickup)
  int _activeIndex = 0;
  String? _backendStatus;
  String _orderType = 'both';

  String? _orderId;
  OrderTrackingArgs? _args;
  Timer? _trackingPollTimer;

  final _trackingService = OrderTrackingService();
  final _directionsService = GoogleDirectionsService();

  OrderTrackingData? _tracking;
  bool _isLoading = true;
  String? _error;

  LatLng? _driverLatLng;
  DirectionsRoute? _route;
  Timer? _routeDebounce;
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Read orderId from route arguments once and start polling.
    if (_orderId == null) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is OrderTrackingArgs) {
        _args = args;
        _orderId = args.orderId;
        if (args.backendStatus != null && args.backendStatus!.trim().isNotEmpty) {
          _backendStatus = args.backendStatus!.trim();
          _activeIndex = _mapStatusToStepIndex(_backendStatus!, _orderType);
        }
        if (args.orderType != null && args.orderType!.trim().isNotEmpty) {
          _orderType = args.orderType!.trim();
        }

        // Phone-only orders are not on the server. Draw the screen now
        // instead of waiting out the API timeout.
        if (_isLocalOrder(args.orderId)) {
          _tracking = _fallbackTracking();
          _isLoading = false;
        } else {
          _startPolling();
          _loadTracking();
        }
      }
    }
  }

  bool _isLocalOrder(String id) => id.trim().toUpperCase().startsWith('LD');

  void _startPolling() {
    _trackingPollTimer?.cancel();
    _trackingPollTimer = Timer.periodic(PollingConfig.orderTracking, (_) {
      _pollTracking(silent: true);
    });
  }

  void _stopPolling() {
    _trackingPollTimer?.cancel();
    _trackingPollTimer = null;
  }

  @override
  void dispose() {
    _stopPolling();
    _routeDebounce?.cancel();
    super.dispose();
  }

  Future<void> _pollTracking({bool silent = false}) async {
    final id = _orderId;
    if (id == null || id.isEmpty) return;

    try {
      final data = await _trackingService.getOrderTracking(orderId: id);
      if (!mounted) return;

      final leg = _activeLeg(data);
      final staff = leg?.staff;
      LatLng? nextDriver;
      if (staff?.latitude != null && staff?.longitude != null) {
        nextDriver = LatLng(staff!.latitude!, staff.longitude!);
      }

      setState(() {
        _tracking = data;
        _orderType = data.orderType;
        _backendStatus = data.orderStatus;
        _activeIndex = _mapStatusToStepIndex(data.orderStatus, data.orderType);
        if (!silent) _isLoading = false;
        if (nextDriver != null) _driverLatLng = nextDriver;
      });

      await _refreshRoute();
    } catch (e) {
      if (!mounted || silent) return;
      setState(() {
        _tracking ??= _fallbackTracking();
        _error = _tracking == null
            ? e.toString().replaceFirst('Exception: ', '').trim()
            : null;
        _isLoading = false;
      });
    }
  }

  OrderTrackingData? _fallbackTracking() {
    final args = _args;
    if (args == null) return null;
    final address = (args.pickupAddress ?? '').trim();
    final point = OrderTrackingPoint(
      address: address.isEmpty ? null : address,
      latitude: args.pickupLat,
      longitude: args.pickupLng,
    );
    return OrderTrackingData(
      orderId: args.orderId,
      orderStatus: (args.backendStatus ?? 'placed').trim(),
      orderType: (args.orderType ?? 'both').trim(),
      shopName: 'Laundry Shop',
      shop: point,
      pickup: point,
      delivery: point,
      pickupLeg: null,
      dropLeg: null,
    );
  }

  Future<void> _loadTracking() async {
    final id = _orderId;
    if (id == null || id.isEmpty || _isLocalOrder(id)) {
      if (!mounted) return;
      setState(() {
        _tracking ??= _fallbackTracking();
        _isLoading = false;
      });
      return;
    }

    final fallback = _fallbackTracking();
    if (!mounted) return;
    setState(() {
      _tracking ??= fallback;
      _isLoading = _tracking == null;
      _error = null;
    });

    await _pollTracking(silent: _tracking != null);
  }

  OrderTrackingDeliveryLeg? _activeLeg(OrderTrackingData data) {
    final s = (data.orderStatus).toLowerCase().trim();

    // Prefer pickup leg early in lifecycle; prefer drop leg once dispatch starts.
    final isDropPhase = s == 'dispatch_assigned' ||
        s == 'out_for_delivery' ||
        s == 'payment_pending' ||
        s == 'delivered' ||
        s == 'closed';

    if (isDropPhase) return data.dropLeg ?? data.pickupLeg;
    return data.pickupLeg ?? data.dropLeg;
  }

  void _scheduleRouteRefresh() {
    _routeDebounce?.cancel();
    _routeDebounce = Timer(const Duration(seconds: 2), () {
      _refreshRoute();
    });
  }

  Future<void> _refreshRoute() async {
    final t = _tracking;
    if (t == null) return;
    final leg = _activeLeg(t);

    // Case 1: no driver assigned (static markers only)
    if (leg?.staffId == null || leg!.staffId!.isEmpty) {
      if (!mounted) return;
      setState(() => _route = null);
      return;
    }

    final driver = _driverLatLng;
    if (driver == null) return;

    final shop = _toLatLng(t.shop);
    final pickup = t.pickup == null ? null : _toLatLng(t.pickup!);
    final delivery = t.delivery == null ? null : _toLatLng(t.delivery!);

    if (shop == null) return;

    final deliveryType = (leg.deliveryType).toLowerCase().trim();
    if (deliveryType == 'pickup') {
      if (pickup == null) return;
      final r = await _directionsService.getRoute(
        origin: driver,
        destination: shop,
        waypoints: [pickup],
      );
      if (!mounted) return;
      setState(() => _route = r);
      return;
    }

    // drop
    if (delivery == null) return;
    final r = await _directionsService.getRoute(
      origin: driver,
      destination: delivery,
      waypoints: [shop],
    );
    if (!mounted) return;
    setState(() => _route = r);
  }

  LatLng? _toLatLng(OrderTrackingPoint p) {
    final lat = p.latitude;
    final lng = p.longitude;
    if (lat == null || lng == null) return null;
    return LatLng(lat, lng);
  }

  _OrderFlowType _resolveOrderFlowType(String rawOrderType) {
    final t = rawOrderType.toLowerCase().trim();
    if (t.contains('both')) return _OrderFlowType.both;
    if (t.contains('pickup')) return _OrderFlowType.pickupOnly;
    if (t.contains('drop') || t.contains('delivery')) return _OrderFlowType.deliveryOnly;
    return _OrderFlowType.both;
  }

  int _mapStatusToStepIndex(String statusRaw, String rawOrderType) {
    final status = statusRaw.toLowerCase().trim();
    final flow = _resolveOrderFlowType(rawOrderType);

    if (flow == _OrderFlowType.pickupOnly) {
      if (status == 'placed' || status == 'pickup_assigned' || status == 'picked_up') return 0; // Pickup
      if (status == 'received_by_collection' || status == 'submitted_to_services' || status == 'services_in_progress') {
        return 1; // In Process
      }
      if (status == 'services_completed' || status == 'dispatch_assigned' || status == 'out_for_delivery' || status == 'payment_pending') {
        return 2; // Ready for Takeaway
      }
      if (status == 'delivered' || status == 'closed' || status == 'cancelled') return 3; // Delivered/Closed
      return 0;
    }

    if (flow == _OrderFlowType.deliveryOnly) {
      // "Pickup" does not apply; we treat early + store receipt as the first step.
      if (status == 'placed' ||
          status == 'pickup_assigned' ||
          status == 'picked_up' ||
          status == 'received_by_collection') {
        return 0; // Submitted to Store
      }
      if (status == 'submitted_to_services' ||
          status == 'services_in_progress' ||
          status == 'services_completed' ||
          status == 'dispatch_assigned') {
        return 1; // In Process
      }
      if (status == 'out_for_delivery' || status == 'payment_pending') return 2; // Out for Delivery
      if (status == 'delivered' || status == 'closed' || status == 'cancelled') return 3; // Delivered/Closed
      return 0;
    }

    // Both (default): Pickup → In Process → Ready → Out for Delivery → Delivered
    if (status == 'placed' || status == 'pickup_assigned' || status == 'picked_up') return 0;
    if (status == 'received_by_collection' || status == 'submitted_to_services' || status == 'services_in_progress') return 1;
    if (status == 'services_completed' || status == 'dispatch_assigned') return 2;
    if (status == 'out_for_delivery') return 3;
    if (status == 'payment_pending' || status == 'delivered' || status == 'closed' || status == 'cancelled') return 4;
    return 0;
  }

  OrderRecord? _scheduleOrder(BuildContext context) {
    final id = _orderId ?? _args?.orderId;
    if (id == null || id.isEmpty) return null;
    final marked = _args?.scheduleOnly == true || _args?.orderType == 'schedule_pickup';
    for (final order in context.read<OrderProvider>().orders) {
      if (order.id != id) continue;
      if (marked || order.orderType == 'schedule_pickup') return order;
    }
    return null;
  }

  bool _showScheduleTimeline(BuildContext context) {
    if (_args?.scheduleOnly == true || _args?.orderType == 'schedule_pickup') return true;
    return _scheduleOrder(context) != null;
  }

  @override
  Widget build(BuildContext context) {
    if (_showScheduleTimeline(context)) {
      return _SchedulePickupTracking(
        order: _scheduleOrder(context),
        orderId: _orderId ?? _args?.orderId ?? '',
        slotLabel: _args?.slotLabel,
        pickupAddress: _args?.pickupAddress,
      );
    }

    final t = _tracking;

    return Scaffold(
      backgroundColor: HomeColors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: HomeColors.background,
        leading: InkWell(
          onTap: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
              return;
            }
            Navigator.of(context).pushNamedAndRemoveUntil(
              AppRoutes.home,
              (r) => false,
            );
          },
          borderRadius: BorderRadius.circular(999),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: const Color(0xFFE5E7EB)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x14000000),
                  blurRadius: 12,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 16,
              color: HomeColors.text,
            ),
          ),
        ),
        title: Text(
          'Order Tracking',
          style: AppTextStyles.header(color: HomeColors.text).copyWith(fontSize: 16),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : (t == null)
              ? Center(
                  child: Text(
                    _error ?? 'Failed to load tracking',
                    style: AppTextStyles.body(color: HomeColors.muted),
                    textAlign: TextAlign.center,
                  ),
                )
              : Column(
                  children: [
                    // Top half: live Google Map showing shop, pickup and delivery locations (and driver when available)
                    SizedBox(
                      // Show map on roughly 30% of the screen height
                      // so that the bottom sheet gets more space for details.
                      height: MediaQuery.of(context).size.height * 0.3,
                      child: _TrackingMap(
                        onMapCreated: (c) => _mapController = c,
                        tracking: t,
                        driver: _driverLatLng,
                        route: _route,
                      ),
                    ),
                    // Bottom half: timeline + addresses + rider info
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(22),
                            topRight: Radius.circular(22),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Color(0x1A000000),
                              blurRadius: 18,
                              offset: Offset(0, -8),
                            ),
                          ],
                        ),
                        child: SafeArea(
                          top: false,
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 56,
                                  height: 5,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE5E7EB),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(color: HomeColors.borderSoft),
                                  ),
                                  child: _Timeline(
                                    activeIndex: _activeIndex,
                                    pickupAddress: t.pickup?.address,
                                    orderType: t.orderType,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                _AddressesCard(tracking: t),
                                const SizedBox(height: 12),
                                _RiderCard(
                                  name: _activeLeg(t)?.staff?.fullName ?? 'Driver not assigned',
                                  role: (() {
                                    final leg = _activeLeg(t);
                                    final staffId = leg?.staffId ?? '';
                                    if (staffId.isEmpty) return 'Not assigned';
                                    final type = (leg?.deliveryType ?? '').toLowerCase().trim();
                                    if (type == 'pickup') return 'Pickup Partner';
                                    return 'Delivery Partner';
                                  })(),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}

enum _OrderFlowType { pickupOnly, deliveryOnly, both }


class _Timeline extends StatelessWidget {
  final int activeIndex;
  final String? pickupAddress;
  final String orderType;

  const _Timeline({
    required this.activeIndex,
    this.pickupAddress,
    required this.orderType,
  });

  _OrderFlowType _resolveOrderFlowType() {
    final t = orderType.toLowerCase().trim();
    if (t.contains('both')) return _OrderFlowType.both;
    if (t.contains('pickup')) return _OrderFlowType.pickupOnly;
    if (t.contains('drop') || t.contains('delivery')) return _OrderFlowType.deliveryOnly;
    return _OrderFlowType.both;
  }

  @override
  Widget build(BuildContext context) {
    final flow = _resolveOrderFlowType();

    final items = switch (flow) {
      _OrderFlowType.pickupOnly => <_TimelineItemData>[
          _TimelineItemData(
            title: 'Pickup',
            subtitle: pickupAddress,
            iconAsset: 'assets/icons/order_track/pickup.png',
          ),
          const _TimelineItemData(
            title: 'In Process',
            subtitle: null,
            iconAsset: 'assets/icons/order_track/in_process.png',
          ),
          const _TimelineItemData(
            title: 'Ready for Takeaway',
            subtitle: null,
            iconAsset: 'assets/icons/order_track/ready.png',
          ),
          const _TimelineItemData(
            title: 'Delivered',
            subtitle: null,
            iconAsset: 'assets/icons/order_track/delivered.png',
          ),
        ],
      _OrderFlowType.deliveryOnly => const <_TimelineItemData>[
          _TimelineItemData(
            title: 'Submitted to Store',
            subtitle: null,
            iconAsset: 'assets/icons/order_track/pickup.png',
          ),
          _TimelineItemData(
            title: 'In Process',
            subtitle: null,
            iconAsset: 'assets/icons/order_track/in_process.png',
          ),
          _TimelineItemData(
            title: 'Out for Delivery',
            subtitle: null,
            iconAsset: 'assets/icons/order_track/out_for_delivery.png',
          ),
          _TimelineItemData(
            title: 'Delivered',
            subtitle: null,
            iconAsset: 'assets/icons/order_track/delivered.png',
          ),
        ],
      _OrderFlowType.both => <_TimelineItemData>[
          _TimelineItemData(
            title: 'Pickup',
            subtitle: pickupAddress,
            iconAsset: 'assets/icons/order_track/pickup.png',
          ),
          const _TimelineItemData(
            title: 'In Process',
            subtitle: null,
            iconAsset: 'assets/icons/order_track/in_process.png',
          ),
          const _TimelineItemData(
            title: 'Ready',
            subtitle: null,
            iconAsset: 'assets/icons/order_track/ready.png',
          ),
          const _TimelineItemData(
            title: 'Out for Delivery',
            subtitle: null,
            iconAsset: 'assets/icons/order_track/out_for_delivery.png',
          ),
          const _TimelineItemData(
            title: 'Delivered',
            subtitle: null,
            iconAsset: 'assets/icons/order_track/delivered.png',
          ),
        ],
    };

    final clampedActive = activeIndex.clamp(0, items.length - 1);

    return Column(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          _TimelineRow(
            data: items[i],
            isActive: i <= clampedActive,
            isLast: i == items.length - 1,
          ),
          if (i != items.length - 1) const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _TimelineItemData {
  final String title;
  final String? subtitle;
  final String iconAsset;

  const _TimelineItemData({
    required this.title,
    required this.subtitle,
    required this.iconAsset,
  });
}

class _TimelineRow extends StatelessWidget {
  final _TimelineItemData data;
  final bool isActive;
  final bool isLast;

  const _TimelineRow({
    required this.data,
    required this.isActive,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final titleStyle = AppTextStyles.stepTitle(
      color: isActive ? HomeColors.text : const Color(0xFF98A0B5),
    );
    final subtitleStyle = AppTextStyles.body(
      color: isActive ? HomeColors.muted : const Color(0xFFB8BDCF),
    ).copyWith(fontSize: 10);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 32,
          child: Column(
            children: [
              Opacity(
                opacity: isActive ? 1 : 0.35,
                child: Image.asset(
                  data.iconAsset,
                  width: 24,
                  height: 24,
                  fit: BoxFit.contain,
                ),
              ),
              if (!isLast)
                Container(
                  width: 3,
                  height: 36,
                  margin: const EdgeInsets.only(top: 6),
                  decoration: BoxDecoration(
                    color: isActive ? HomeColors.primary : const Color(0xFFE5E7EB),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(data.title, style: titleStyle),
                if (data.subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(data.subtitle!, style: subtitleStyle),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _RiderCard extends StatelessWidget {
  final String name;
  final String role;

  const _RiderCard({
    required this.name,
    required this.role,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: HomeColors.borderSoft),
      ),
      child: Row(
        children: [
          ClipOval(
            child: Container(
              width: 40,
              height: 40,
              color: const Color(0xFFEFF1FF),
              child: Image.asset(
                'assets/icons/profile_pic_demo.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: AppTextStyles.header(color: HomeColors.text)),
                const SizedBox(height: 2),
                Text(role, style: AppTextStyles.body(color: HomeColors.muted)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          _IconCircle(
            icon: Icons.chat_bubble_outline_rounded,
            onTap: () {},
          ),
          const SizedBox(width: 10),
          _IconCircle(
            icon: Icons.phone_outlined,
            onTap: () {},
          ),
        ],
      ),
    );
  }
}

class _AddressesCard extends StatelessWidget {
  final OrderTrackingData tracking;

  const _AddressesCard({required this.tracking});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: HomeColors.borderSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _AddressRow(
            icon: Icons.storefront_outlined,
            title: tracking.shopName.isEmpty ? 'Laundry Shop' : tracking.shopName,
            subtitle: tracking.shop.address ?? '',
          ),
          const SizedBox(height: 10),
          if (tracking.pickup != null)
            _AddressRow(
              icon: Icons.location_on_outlined,
              title: 'Pickup address',
              subtitle: tracking.pickup?.address ?? '',
            ),
          if (tracking.delivery != null) ...[
            const SizedBox(height: 10),
            _AddressRow(
              icon: Icons.location_on_outlined,
              title: 'Delivery address',
              subtitle: tracking.delivery?.address ?? '',
            ),
          ],
        ],
      ),
    );
  }
}

class _AddressRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _AddressRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: const Color(0xFFF0F2FF),
            shape: BoxShape.circle,
            border: Border.all(color: HomeColors.borderSoft),
          ),
          child: Icon(icon, size: 18, color: HomeColors.text),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.body(color: HomeColors.text).copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.body(color: HomeColors.muted).copyWith(fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TrackingMap extends StatelessWidget {
  final OrderTrackingData tracking;
  final LatLng? driver;
  final DirectionsRoute? route;
  final void Function(GoogleMapController controller) onMapCreated;

  const _TrackingMap({
    required this.tracking,
    required this.driver,
    required this.route,
    required this.onMapCreated,
  });

  @override
  Widget build(BuildContext context) {
    LatLng? toLatLng(OrderTrackingPoint p) {
      final lat = p.latitude;
      final lng = p.longitude;
      if (lat == null || lng == null) return null;
      return LatLng(lat, lng);
    }

    final shop = toLatLng(tracking.shop);
    final pickup = tracking.pickup == null ? null : toLatLng(tracking.pickup!);
    final drop = tracking.delivery == null ? null : toLatLng(tracking.delivery!);

    final markers = <Marker>{};
    if (shop != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('shop'),
          position: shop,
          infoWindow: InfoWindow(title: tracking.shopName.isEmpty ? 'Laundry Shop' : tracking.shopName),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
        ),
      );
    }
    if (pickup != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('pickup'),
          position: pickup,
          infoWindow: const InfoWindow(title: 'Pickup'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        ),
      );
    }
    if (drop != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('drop'),
          position: drop,
          infoWindow: const InfoWindow(title: 'Delivery'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
        ),
      );
    }
    if (driver != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('driver'),
          position: driver!,
          infoWindow: const InfoWindow(title: 'Delivery Partner'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        ),
      );
    }

    final polylines = <Polyline>{};
    final r = route;
    if (r != null && r.polylinePoints.isNotEmpty) {
      polylines.add(
        Polyline(
          polylineId: const PolylineId('route'),
          points: r.polylinePoints,
          color: HomeColors.primary,
          width: 5,
        ),
      );
    }

    final initialTarget = driver ?? pickup ?? drop ?? shop ?? const LatLng(20.5937, 78.9629);

    return GoogleMap(
      onMapCreated: onMapCreated,
      initialCameraPosition: CameraPosition(target: initialTarget, zoom: 13),
      markers: markers,
      polylines: polylines,
      myLocationEnabled: false,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      compassEnabled: false,
      mapToolbarEnabled: false,
    );
  }
}

class _SchedulePickupTracking extends StatelessWidget {
  final OrderRecord? order;
  final String orderId;
  final String? slotLabel;
  final String? pickupAddress;

  const _SchedulePickupTracking({
    required this.order,
    required this.orderId,
    this.slotLabel,
    this.pickupAddress,
  });

  @override
  Widget build(BuildContext context) {
    final live = _liveOrder(context);
    final placed = live?.placedAt ?? order?.placedAt ?? DateTime.now();
    final pickupAt = live?.scheduledPickupAt ?? order?.scheduledPickupAt;
    final slot = (live?.timeLabel ?? order?.timeLabel ?? '');
    final headline = pickupAt != null && slot.isNotEmpty
        ? schedulePickupHeadline(pickupAt, slot)
        : (slotLabel ?? slot);
    final address = (live?.pickupAddress ?? order?.pickupAddress ?? pickupAddress ?? '').trim();
    final status = (live?.backendStatus ?? order?.backendStatus ?? 'placed').toLowerCase();
    final canCancel = status == 'placed';

    return Scaffold(
      backgroundColor: HomeColors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: HomeColors.background,
        foregroundColor: HomeColors.text,
        leading: IconButton(
          onPressed: () => _backToOrders(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: HomeColors.text),
        ),
        title: Text(
          'Track order',
          style: AppTextStyles.header(color: HomeColors.text).copyWith(fontSize: 18),
        ),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Text(
                _orderCode(live, order, orderId),
                style: AppTextStyles.body(color: HomeColors.muted).copyWith(fontSize: 13),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(14, 16, 14, 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: HomeColors.borderSoft),
            ),
            child: Column(
              children: [
                _ScheduleStep(
                  state: _StepState.done,
                  title: 'Booked',
                  subtitle: 'Scheduled pickup',
                  trailing: _placedLine(placed),
                ),
                _ScheduleStep(
                  state: _StepState.current,
                  title: 'Pickup',
                  subtitle: 'A Layrr partner will be assigned before your slot',
                  trailing: headline,
                  highlight: true,
                  action: 'Reschedule',
                  onAction: () => _reschedule(context),
                ),
                const _ScheduleStep(
                  state: _StepState.upcoming,
                  title: 'Cleaning',
                  subtitle: 'Weighed and priced at the hub',
                  trailing: 'Priced after pickup',
                ),
                _ScheduleStep(
                  state: _StepState.upcoming,
                  title: 'Delivery',
                  subtitle: address.isEmpty ? 'Back to your saved address' : address,
                  trailing: pickupAt == null ? 'After pickup' : _returnWindow(pickupAt),
                  isLast: true,
                ),
              ],
            ),
          ),
          if (canCancel) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton(
                onPressed: () => _cancel(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: HomeColors.text,
                  side: const BorderSide(color: HomeColors.borderSoft),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                  backgroundColor: Colors.white,
                ),
                child: Text(
                  'Cancel order',
                  style: AppTextStyles.header(color: HomeColors.text).copyWith(fontSize: 15),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  OrderRecord? _liveOrder(BuildContext context) {
    if (orderId.isEmpty) return order;
    for (final item in context.watch<OrderProvider>().orders) {
      if (item.id == orderId) return item;
    }
    return order;
  }

  Future<void> _reschedule(BuildContext context) async {
    final picked = await showScheduleBottomSheet(context);
    if (picked == null || !context.mounted || orderId.isEmpty) return;
    context.read<OrderProvider>().updateOrderSchedule(
          orderId,
          '${_monthName(picked.date.month)} ${picked.date.day}',
          picked.slot,
          at: scheduleSlotStart(picked.date, picked.slot),
        );
  }

  void _backToOrders(BuildContext context) {
    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRoutes.orders,
      (route) => false,
    );
  }

  String _orderCode(OrderRecord? live, OrderRecord? fallback, String id) {
    final value = (live?.id ?? fallback?.id ?? id).trim();
    if (value.toUpperCase().startsWith('LD')) return '#$value';
    return '#${live?.shortId ?? fallback?.shortId ?? value}';
  }

  void _cancel(BuildContext context) {
    OrderRecord? live;
    for (final item in context.read<OrderProvider>().orders) {
      if (item.id == orderId) {
        live = item;
        break;
      }
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CancelPickupScreen(
          orderId: orderId,
          orderCode: _orderCode(live, order, orderId),
        ),
      ),
    );
  }
}

enum _StepState { done, current, upcoming }

class _ScheduleStep extends StatelessWidget {
  final _StepState state;
  final String title;
  final String subtitle;
  final String trailing;
  final bool highlight;
  final bool isLast;
  final String? action;
  final VoidCallback? onAction;

  const _ScheduleStep({
    required this.state,
    required this.title,
    required this.subtitle,
    required this.trailing,
    this.highlight = false,
    this.isLast = false,
    this.action,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final body = Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 22,
            child: Column(
              children: [
                _marker(),
                if (!isLast)
                  Container(
                    width: 2,
                    height: highlight ? 78 : 42,
                    color: HomeColors.borderSoft,
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              padding: highlight ? const EdgeInsets.fromLTRB(12, 10, 12, 10) : EdgeInsets.zero,
              decoration: highlight
                  ? BoxDecoration(
                      color: HomeColors.primary.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: HomeColors.primary),
                    )
                  : null,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: AppTextStyles.header(color: HomeColors.text).copyWith(fontSize: 15),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          trailing,
                          textAlign: TextAlign.right,
                          style: AppTextStyles.body(color: HomeColors.text).copyWith(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: AppTextStyles.body(color: HomeColors.muted).copyWith(fontSize: 12),
                  ),
                  if (action != null)
                    TextButton(
                      onPressed: onAction,
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 28),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        action!,
                        style: AppTextStyles.button(color: HomeColors.primary).copyWith(fontSize: 13),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
    return body;
  }

  Widget _marker() {
    if (state == _StepState.done) {
      return Container(
        width: 18,
        height: 18,
        decoration: const BoxDecoration(color: HomeColors.primary, shape: BoxShape.circle),
        child: const Icon(Icons.check, size: 12, color: Colors.white),
      );
    }
    if (state == _StepState.current) {
      return Container(
        width: 18,
        height: 18,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: HomeColors.primary, width: 2),
        ),
        child: Center(
          child: Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(color: HomeColors.primary, shape: BoxShape.circle),
          ),
        ),
      );
    }
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: HomeColors.borderSoft, width: 2),
      ),
    );
  }
}

String _placedLine(DateTime placed) {
  final now = DateTime.now();
  final isToday = placed.year == now.year && placed.month == now.month && placed.day == now.day;
  final hour12 = placed.hour % 12 == 0 ? 12 : placed.hour % 12;
  final minute = placed.minute.toString().padLeft(2, '0');
  final period = placed.hour >= 12 ? 'pm' : 'am';
  final clock = '$hour12:$minute $period';
  if (isToday) return 'Today, $clock';
  return '${_monthName(placed.month)} ${placed.day}, $clock';
}

String _returnWindow(DateTime pickup) {
  final from = pickup.add(const Duration(hours: 6));
  final to = from.add(const Duration(minutes: 30));
  const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  String clock(DateTime time) {
    final hour12 = time.hour % 12 == 0 ? 12 : time.hour % 12;
    if (time.minute == 0) return '$hour12';
    return '$hour12:${time.minute.toString().padLeft(2, '0')}';
  }

  final period = to.hour >= 12 ? 'pm' : 'am';
  return '${days[from.weekday - 1]}, ${clock(from)} – ${clock(to)} $period';
}

String _monthName(int month) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return months[month - 1];
}

class _IconCircle extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _IconCircle({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: const Color(0xFFF0F2FF),
          shape: BoxShape.circle,
          border: Border.all(color: HomeColors.borderSoft),
        ),
        child: Icon(icon, size: 18, color: HomeColors.text),
      ),
    );
  }
}



import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../theme/app_text_styles.dart';
import '../home/widgets/home_colors.dart';
import '../../routes/app_routes.dart';
import '../../routes/route_args.dart';
import '../../services/customer_info_service.dart';
import '../../utils/supabase_config.dart';

class OrderTrackingScreen extends StatefulWidget {
  const OrderTrackingScreen({super.key});

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  // 0..4 (0 = Pickup)
  int _activeIndex = 0;

  LatLng? _pickupLatLng;
  LatLng? _riderLatLng;
  bool _isLoadingLocation = true;
  String? _orderId;
  String? _pickupAddressText;
  RealtimeChannel? _orderChannel;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Read orderId from route arguments once and subscribe to realtime updates.
    if (_orderId == null) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is OrderTrackingArgs) {
        _orderId = args.orderId;
        _pickupAddressText = args.pickupAddress;

        if (args.pickupLat != null && args.pickupLng != null) {
          final lat = args.pickupLat!;
          final lng = args.pickupLng!;
          _pickupLatLng = LatLng(lat, lng);
          _riderLatLng = LatLng(lat + 0.0007, lng + 0.0007);
        }

        _subscribeToOrderRealtime();
      }
    }
  }

  @override
  void dispose() {
    _orderChannel?.unsubscribe();
    super.dispose();
  }

  void _subscribeToOrderRealtime() {
    if (!SupabaseConfig.isEnabled) return;
    final id = _orderId;
    if (id == null || id.isEmpty) return;

    try {
      final client = Supabase.instance.client;
      _orderChannel = client
          .channel('orders:track:$id')
          .onPostgresChanges(
            event: PostgresChangeEvent.update,
            schema: 'public',
            table: 'orders',
            callback: (payload) {
              // Ignore updates for other orders if the channel receives them.
              final updatedId = payload.newRecord['order_id'] as String?;
              if (updatedId == null || updatedId != id) return;

              final newStatus = payload.newRecord['order_status'] as String?;
              if (newStatus == null) return;
              final mappedIndex = _mapStatusToStepIndex(newStatus);
              if (!mounted) return;
              setState(() {
                _activeIndex = mappedIndex;
              });
            },
          )
          .subscribe();
    } catch (_) {
      // Ignore realtime errors; UI will still work with initial data.
    }
  }

  int _mapStatusToStepIndex(String status) {
    switch (status) {
      case 'placed':
      case 'pickup_assigned':
      case 'picked_up':
        return 0; // Pickup
      case 'received_by_collection':
      case 'submitted_to_services':
      case 'services_in_progress':
        return 1; // In Process
      case 'services_completed':
      case 'dispatch_assigned':
        return 2; // Ready
      case 'out_for_delivery':
        return 3; // Out for Delivery
      case 'payment_pending':
      case 'delivered':
      case 'closed':
        return 4; // Delivered
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HomeColors.background,
      body: Stack(
        children: [
          Positioned.fill(
            child: _GoogleMapBackground(
              pickup: _pickupLatLng,
              rider: _riderLatLng,
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(left: 12, top: 8),
              child: InkWell(
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
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x14000000),
                        blurRadius: 12,
                        offset: Offset(0, 6),
                      ),
                    ],
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 16,
                    color: HomeColors.text,
                  ),
                ),
              ),
            ),
          ),
          DraggableScrollableSheet(
            initialChildSize: 0.56,
            minChildSize: 0.46,
            maxChildSize: 0.72,
            builder: (context, scrollController) {
              return _BottomPanel(
                activeIndex: _activeIndex,
                riderName: 'Nadaan Sharma',
                riderRole: 'Delivery Man',
                scrollController: scrollController,
                pickupAddress: _pickupAddressText,
              );
            },
          ),
        ],
      ),
    );
  }
}

class _GoogleMapBackground extends StatelessWidget {
  final LatLng? pickup;
  final LatLng? rider;

  const _GoogleMapBackground({
    this.pickup,
    this.rider,
  });

  @override
  Widget build(BuildContext context) {
    // Fallback demo coordinates (Bengaluru-ish) if no saved address is found.
    const fallbackPickup = LatLng(12.9716, 77.5946);
    const fallbackRider = LatLng(12.9723, 77.5953);
    const fallbackDrop = LatLng(12.9352, 77.6245);

    final effectivePickup = pickup ?? fallbackPickup;
    final effectiveRider = rider ?? fallbackRider;
    final effectiveDrop = fallbackDrop;

    final markers = <Marker>{
      Marker(
        markerId: const MarkerId('pickup'),
        position: effectivePickup,
        infoWindow: const InfoWindow(title: 'Pickup'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      ),
      Marker(
        markerId: const MarkerId('rider'),
        position: effectiveRider,
        infoWindow: const InfoWindow(title: 'Delivery Partner'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      ),
      Marker(
        markerId: const MarkerId('drop'),
        position: effectiveDrop,
        infoWindow: const InfoWindow(title: 'Drop'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
      ),
    };

    final polyline = Polyline(
      polylineId: const PolylineId('route'),
      points: [effectivePickup, effectiveRider, effectiveDrop],
      color: HomeColors.primary,
      width: 4,
    );

    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: effectivePickup,
        zoom: 14,
      ),
      markers: markers,
      polylines: {polyline},
      myLocationEnabled: false,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      compassEnabled: false,
      mapToolbarEnabled: false,
    );
  }
}

class _BottomPanel extends StatelessWidget {
  final int activeIndex;
  final String riderName;
  final String riderRole;
  final ScrollController scrollController;
  final String? pickupAddress;

  const _BottomPanel({
    required this.activeIndex,
    required this.riderName,
    required this.riderRole,
    required this.scrollController,
    this.pickupAddress,
  });

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 24,
            offset: Offset(0, -10),
          ),
        ],
      ),
      child: ListView(
        controller: scrollController,
        padding: EdgeInsets.fromLTRB(18, 12, 18, 14 + bottomInset),
        children: [
          Center(
            child: Container(
              width: 56,
              height: 5,
              decoration: BoxDecoration(
                color: const Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              'Order Tracking',
              style: AppTextStyles.header(color: HomeColors.text)
                  .copyWith(fontSize: 14),
            ),
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: HomeColors.borderSoft),
            ),
            child: _Timeline(
              activeIndex: activeIndex,
              pickupAddress: pickupAddress,
            ),
          ),
          const SizedBox(height: 12),
          _RiderCard(name: riderName, role: riderRole),
        ],
      ),
    );
  }
}

class _Timeline extends StatelessWidget {
  final int activeIndex;
  final String? pickupAddress;

  const _Timeline({
    required this.activeIndex,
    this.pickupAddress,
  });

  @override
  Widget build(BuildContext context) {
    final items = <_TimelineItemData>[
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
    ];

    return Column(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          _TimelineRow(
            data: items[i],
            isActive: i <= activeIndex,
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



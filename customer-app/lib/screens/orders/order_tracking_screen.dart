import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../theme/app_text_styles.dart';
import '../home/widgets/home_colors.dart';

class OrderTrackingScreen extends StatefulWidget {
  const OrderTrackingScreen({super.key});

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  // 0..4
  final int _activeIndex = 3;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HomeColors.background,
      body: Stack(
        children: [
          const Positioned.fill(child: _OsmMapBackground()),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(left: 12, top: 8),
              child: InkWell(
                onTap: () => Navigator.of(context).maybePop(),
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
              );
            },
          ),
        ],
      ),
    );
  }
}

class _OsmMapBackground extends StatelessWidget {
  const _OsmMapBackground();

  @override
  Widget build(BuildContext context) {
    // Demo coordinates for now (Bengaluru-ish). Replace with real order coordinates later.
    const pickup = LatLng(12.9716, 77.5946);
    const rider = LatLng(12.9628, 77.6038);
    const drop = LatLng(12.9352, 77.6245);

    return FlutterMap(
      options: const MapOptions(
        initialCenter: pickup,
        initialZoom: 13.8,
        interactionOptions: InteractionOptions(
          flags: InteractiveFlag.all,
        ),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'laundry_customer_app',
        ),
        PolylineLayer(
          polylines: [
            Polyline(
              points: const [pickup, rider, drop],
              color: HomeColors.primary,
              strokeWidth: 4,
            ),
          ],
        ),
        MarkerLayer(
          markers: [
            _marker(pickup, const Color(0xFF16A34A), Icons.location_on_rounded),
            _marker(rider, const Color(0xFF2437B6), Icons.delivery_dining_rounded),
            _marker(drop, const Color(0xFFF97316), Icons.flag_rounded),
          ],
        ),
      ],
    );
  }

  Marker _marker(LatLng p, Color color, IconData icon) {
    return Marker(
      point: p,
      width: 44,
      height: 44,
      alignment: Alignment.topCenter,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: const [
            BoxShadow(
              color: Color(0x1A000000),
              blurRadius: 14,
              offset: Offset(0, 8),
            ),
          ],
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Center(
          child: Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
        ),
      ),
    );
  }
}

class _BottomPanel extends StatelessWidget {
  final int activeIndex;
  final String riderName;
  final String riderRole;
  final ScrollController scrollController;

  const _BottomPanel({
    required this.activeIndex,
    required this.riderName,
    required this.riderRole,
    required this.scrollController,
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
            child: _Timeline(activeIndex: activeIndex),
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

  const _Timeline({required this.activeIndex});

  @override
  Widget build(BuildContext context) {
    final items = <_TimelineItemData>[
      const _TimelineItemData(
        title: 'Pickup',
        subtitle: '#24, Green Meadows Apartment, MG Road..',
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
        subtitle: '#24, Green Meadows Apartment, MG Road..',
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



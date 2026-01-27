import 'dart:math';

import 'package:flutter/material.dart';

import '../../../../theme/app_colors.dart';
import '../../../../theme/app_text_styles.dart';
import '../../../../services/admin_delivery_staff_service.dart';
import '../../../../services/distribution_manager_orders_service.dart';

class DistributionDeliveryPartnersScreen extends StatefulWidget {
  final String orderId;

  const DistributionDeliveryPartnersScreen({
    super.key,
    required this.orderId,
  });

  @override
  State<DistributionDeliveryPartnersScreen> createState() => _DistributionDeliveryPartnersScreenState();
}

class _DistributionDeliveryPartnersScreenState extends State<DistributionDeliveryPartnersScreen> {
  final AdminDeliveryStaffService _staffService = AdminDeliveryStaffService();
  final DistributionManagerOrdersService _ordersService = DistributionManagerOrdersService();

  late Future<List<_DeliveryPartnerUi>> _future;
  String? _assigningStaffId;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<_DeliveryPartnerUi>> _load() async {
    // 1) Fetch delivery address for the order (drop location)
    final orderBody = await _ordersService.getOrderItems(orderId: widget.orderId);
    final orderData = orderBody['data'];
    final delivery = (orderData is Map ? orderData['deliveryAddress'] : null);

    final deliveryLat = _toDouble(delivery is Map ? delivery['latitude'] : null);
    final deliveryLng = _toDouble(delivery is Map ? delivery['longitude'] : null);

    // 2) Fetch verified, active delivery staff
    final staffBody = await _staffService.listVerifiedActiveDeliveryStaffs(page: 1, limit: 20);
    final data = staffBody['data'];
    if (data is! Map<String, dynamic>) {
      throw Exception('Invalid response: missing data');
    }

    final list = data['deliveryStaffs'];
    if (list is! List) {
      throw Exception('Invalid response: missing deliveryStaffs list');
    }

    final partners = list.whereType<Map>().map((m) => m.cast<String, dynamic>()).map((s) {
      final coords = s['currentCoordinates'];
      final lat = _toDouble(coords is Map ? coords['latitude'] : null);
      final lng = _toDouble(coords is Map ? coords['longitude'] : null);

      final km = (deliveryLat != null && deliveryLng != null && lat != null && lng != null)
          ? _distanceKm(deliveryLat, deliveryLng, lat, lng)
          : null;

      return _DeliveryPartnerUi(
        staffId: (s['staffId'] ?? '').toString(),
        name: (s['fullName'] ?? 'Delivery Partner').toString(),
        totalDeliveries: _toInt(s['totalDeliveries']),
        rating: _toDouble(s['averageRating']) ?? 0,
        distanceKm: km,
      );
    }).toList();

    partners.sort((a, b) {
      final ad = a.distanceKm;
      final bd = b.distanceKm;
      if (ad == null && bd == null) return 0;
      if (ad == null) return 1;
      if (bd == null) return -1;
      return ad.compareTo(bd); // nearest first
    });

    return partners;
  }

  static double? _toDouble(Object? v) {
    if (v is num) return v.toDouble();
    return double.tryParse(v?.toString() ?? '');
  }

  static int _toInt(Object? v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v?.toString() ?? '') ?? 0;
  }

  static double _distanceKm(double lat1, double lon1, double lat2, double lon2) {
    const earthRadiusKm = 6371.0;
    final dLat = _degToRad(lat2 - lat1);
    final dLon = _degToRad(lon2 - lon1);
    final a = (sin(dLat / 2) * sin(dLat / 2)) +
        cos(_degToRad(lat1)) * cos(_degToRad(lat2)) * (sin(dLon / 2) * sin(dLon / 2));
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadiusKm * c;
  }

  static double _degToRad(double deg) => deg * (3.141592653589793 / 180.0);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              color: const Color(0xFFF5F5F5),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: AppColors.textPrimary,
                        size: 18,
                      ),
                    ),
                    splashRadius: 20,
                  ),
                  Expanded(
                    child: Text(
                      'Delivery Partners',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.header(
                        color: AppColors.textPrimary,
                      ).copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 40), // Balance the back button
                ],
              ),
            ),
            // Delivery Partners List
            Expanded(
              child: FutureBuilder<List<_DeliveryPartnerUi>>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.error_outline, color: AppColors.error),
                            const SizedBox(height: 10),
                            Text(
                              snapshot.error.toString().replaceFirst('Exception: ', ''),
                              textAlign: TextAlign.center,
                              style: AppTextStyles.subtitle(color: AppColors.textSecondary),
                            ),
                            const SizedBox(height: 10),
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _future = _load();
                                });
                              },
                              child: Text(
                                'Retry',
                                style: AppTextStyles.subtitle(color: AppColors.primary).copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final list = snapshot.data ?? const <_DeliveryPartnerUi>[];
                  if (list.isEmpty) {
                    return Center(
                      child: Text(
                        'No delivery partners found',
                        style: AppTextStyles.subtitle(color: AppColors.textSecondary),
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final p = list[index];
                      return _DeliveryPartnerCard(
                        staffId: p.staffId,
                        name: p.name,
                        rating: p.rating,
                        totalDeliveries: p.totalDeliveries,
                        distanceKm: p.distanceKm,
                        profileImagePath: 'assets/icons/profile_pic_demo.png',
                        isAssigning: _assigningStaffId == p.staffId,
                        onAssign: () {
                          if (_assigningStaffId != null) return;
                          setState(() {
                            _assigningStaffId = p.staffId;
                          });

                          () async {
                            try {
                              await _ordersService.assignDropDirect(
                                orderId: widget.orderId,
                                deliveryStaffId: p.staffId,
                              );

                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Delivery assigned successfully')),
                              );
                              Navigator.pop(context, true);
                            } catch (e) {
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
                              );
                            } finally {
                              if (!mounted) return;
                              setState(() {
                                _assigningStaffId = null;
                              });
                            }
                          }();
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DeliveryPartnerCard extends StatelessWidget {
  final String staffId;
  final String name;
  final double rating;
  final int totalDeliveries;
  final double? distanceKm;
  final String profileImagePath;
  final VoidCallback onAssign;
  final bool isAssigning;

  const _DeliveryPartnerCard({
    required this.staffId,
    required this.name,
    required this.rating,
    required this.totalDeliveries,
    required this.distanceKm,
    required this.profileImagePath,
    required this.onAssign,
    required this.isAssigning,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Profile Picture Section
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: 2,
                  ),
                ),
                child: ClipOval(
                  child: Image.asset(
                    profileImagePath,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: AppColors.primary.withOpacity(0.1),
                        child: Icon(
                          Icons.person,
                          size: 30,
                          color: AppColors.primary,
                        ),
                      );
                    },
                  ),
                ),
              ),
              // Green online status dot
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white,
                      width: 2,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          // Details Section
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: AppTextStyles.title(
                    color: AppColors.textPrimary,
                  ).copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.star,
                      size: 14,
                      color: Colors.amber,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$rating ($totalDeliveries deliveries)',
                      style: AppTextStyles.subtitle(
                        color: AppColors.textSecondary,
                      ).copyWith(
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  distanceKm == null ? 'Distance: —' : 'Distance: ${distanceKm!.toStringAsFixed(1)} km',
                  style: AppTextStyles.subtitle(
                    color: AppColors.textSecondary,
                  ).copyWith(
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Completed Today & Assign Button Section
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const SizedBox(height: 38),
              SizedBox(
                width: 100,
                height: 36,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Color(0xFF283897),
                        Color(0xFF0F73F7),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextButton(
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: isAssigning ? null : onAssign,
                    child: Text(
                      isAssigning ? 'Assigning...' : 'Assign',
                      style: AppTextStyles.button(
                        color: Colors.white,
                      ).copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
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

class _DeliveryPartnerUi {
  final String staffId;
  final String name;
  final int totalDeliveries;
  final double rating;
  final double? distanceKm;

  const _DeliveryPartnerUi({
    required this.staffId,
    required this.name,
    required this.totalDeliveries,
    required this.rating,
    required this.distanceKm,
  });
}


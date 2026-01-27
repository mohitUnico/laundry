import 'package:flutter/material.dart';

import '../../../../routes/app_routes.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_text_styles.dart';
import '../../../../services/delivery_staff_app_service.dart';
import '../../../common/widgets/bottom_nav_bar.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final DeliveryStaffAppService _service = DeliveryStaffAppService();
  late Future<List<_OrderHistoryUi>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load(page: 1, limit: 20);
  }

  Future<List<_OrderHistoryUi>> _load({required int page, required int limit}) async {
    final body = await _service.listOrderHistory(page: page, limit: limit);
    final data = body['data'];
    if (data is! List) throw Exception('Invalid response: missing data list');

    final rows = data.whereType<Map>().map((m) => m.cast<String, dynamic>()).toList();

    rows.sort((a, b) {
      final adt = _parseDate(a['date_of_delivery']);
      final bdt = _parseDate(b['date_of_delivery']);
      if (adt == null && bdt == null) return 0;
      if (adt == null) return 1;
      if (bdt == null) return -1;
      return bdt.compareTo(adt);
    });

    return rows.map((r) {
      final orderId = (r['order_id'] ?? '').toString();
      final name = (r['customer_name'] ?? 'Customer').toString();
      final itemsRaw = r['number_of_order_items'];
      final items = (itemsRaw is num) ? itemsRaw.toInt() : int.tryParse(itemsRaw?.toString() ?? '') ?? 0;
      final deliveryType = (r['delivery_type'] ?? '').toString(); // pickup | delivery
      final dt = _parseDate(r['date_of_delivery']);
      final statusRaw = (r['delivery_request_status'] ?? '').toString(); // accepted/rejected/null

      final status = statusRaw == 'rejected' ? OrderStatus.rejected : OrderStatus.completed;

      return _OrderHistoryUi(
        orderId: _formatOrderId(orderId),
        name: name,
        date: _formatDate(dt),
        items: items,
        status: status,
        serviceType: deliveryType == 'pickup' ? 'Pickup' : 'Delivery',
        amount: '—',
      );
    }).toList();
  }

  static DateTime? _parseDate(Object? raw) {
    if (raw is DateTime) return raw;
    if (raw is String && raw.isNotEmpty) return DateTime.tryParse(raw);
    return null;
  }

  static String _formatDate(DateTime? dt) {
    if (dt == null) return '--';
    final dd = dt.day.toString().padLeft(2, '0');
    final mm = dt.month.toString().padLeft(2, '0');
    final yyyy = dt.year.toString();
    return '$dd-$mm-$yyyy';
  }

  static String _formatOrderId(String orderId) {
    final normalized = orderId.replaceAll('-', '').toUpperCase();
    if (normalized.length >= 6) return 'ORD${normalized.substring(0, 6)}';
    if (normalized.isNotEmpty) return 'ORD$normalized';
    return 'ORDER';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _Header(
              onBack: () => Navigator.pop(context),
              onFilter: () {
                // TODO: add date filter (from/to) if needed
              },
            ),
            Expanded(
              child: FutureBuilder<List<_OrderHistoryUi>>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2)),
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
                              style: AppTextStyles.subtitle(color: AppColors.textSecondary),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 10),
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _future = _load(page: 1, limit: 20);
                                });
                              },
                              child: Text(
                                'Retry',
                                style: AppTextStyles.subtitle(color: AppColors.primary).copyWith(fontWeight: FontWeight.w700),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final list = snapshot.data ?? const <_OrderHistoryUi>[];
                  if (list.isEmpty) {
                    return Center(
                      child: Text(
                        'No order history found',
                        style: AppTextStyles.subtitle(color: AppColors.textSecondary),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: list.length,
                    itemBuilder: (context, index) {
                      final o = list[index];
                      return _OrderCard(
                        orderId: o.orderId,
                        name: o.name,
                        date: o.date,
                        items: o.items,
                        status: o.status,
                        serviceType: o.serviceType,
                        amount: o.amount,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: 1,
        onTap: (index) {
          switch (index) {
            case 0:
              Navigator.pushReplacementNamed(context, AppRoutes.home);
              break;
            case 1:
              break;
            case 2:
              Navigator.pushReplacementNamed(context, AppRoutes.help);
              break;
            case 3:
              Navigator.pushReplacementNamed(context, AppRoutes.profile);
              break;
          }
        },
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final VoidCallback onBack;
  final VoidCallback onFilter;

  const _Header({
    required this.onBack,
    required this.onFilter,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            splashRadius: 20,
          ),
          Text(
            'Order History',
            style: AppTextStyles.title(color: AppColors.textPrimary),
          ),
          IconButton(
            onPressed: onFilter,
            icon: const Icon(Icons.more_horiz, size: 22),
            splashRadius: 20,
          ),
        ],
      ),
    );
  }
}

enum OrderStatus { inProgress, completed, rejected }

class _OrderHistoryUi {
  final String orderId;
  final String name;
  final String date;
  final int items;
  final OrderStatus status;
  final String serviceType;
  final String amount;

  const _OrderHistoryUi({
    required this.orderId,
    required this.name,
    required this.date,
    required this.items,
    required this.status,
    required this.serviceType,
    required this.amount,
  });
}

class _OrderCard extends StatelessWidget {
  final String orderId;
  final String name;
  final String date;
  final int items;
  final OrderStatus status;
  final String serviceType;
  final String amount;

  const _OrderCard({
    required this.orderId,
    required this.name,
    required this.date,
    required this.items,
    required this.status,
    required this.serviceType,
    required this.amount,
  });

  Color get _statusColor {
    switch (status) {
      case OrderStatus.inProgress:
        return const Color(0xFFF5A623);
      case OrderStatus.completed:
        return const Color(0xFF2DBE7F);
      case OrderStatus.rejected:
        return const Color(0xFFE74C3C);
    }
  }

  String get _statusLabel {
    switch (status) {
      case OrderStatus.inProgress:
        return 'In progress';
      case OrderStatus.completed:
        return 'Completed';
      case OrderStatus.rejected:
        return 'Rejected';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider.withOpacity(0.35)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      constraints: const BoxConstraints(minHeight: 126),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                orderId,
                style: AppTextStyles.subtitle(
                  color: const Color(0xFF2B59FF),
                ).copyWith(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      status == OrderStatus.inProgress
                          ? Icons.timelapse
                          : status == OrderStatus.completed
                              ? Icons.check_circle
                              : Icons.close,
                      size: 14,
                      color: _statusColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _statusLabel,
                      style: AppTextStyles.smallText(
                        color: _statusColor,
                      ).copyWith(fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: AppTextStyles.title(
                        color: AppColors.textPrimary,
                      ).copyWith(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(Icons.calendar_today_outlined,
                            size: 14, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          date,
                          style: AppTextStyles.smallText(
                            color: AppColors.textSecondary,
                      ).copyWith(fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(width: 12),
                        Icon(Icons.shopping_bag_outlined,
                            size: 14, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          'Qty: ${items.toString().padLeft(2, '0')}',
                          style: AppTextStyles.smallText(
                            color: AppColors.textSecondary,
                          ).copyWith(fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    serviceType,
                    style: AppTextStyles.subtitle(
                      color: AppColors.textSecondary,
                    ).copyWith(fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    amount,
                    style: AppTextStyles.price(
                      color: AppColors.primary,
                    ).copyWith(fontSize: 20, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}


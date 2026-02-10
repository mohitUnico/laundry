import 'package:flutter/material.dart';

import '../../../../theme/app_colors.dart';
import '../../../../theme/app_text_styles.dart';
import '../../../../services/collection_manager_orders_service.dart';
import '../../../../utils/date_time_ist.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final CollectionManagerOrdersService _ordersService = CollectionManagerOrdersService();

  late Future<List<_HistoryOrderUi>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load(page: 1, limit: 20);
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _load(page: 1, limit: 20);
    });
    await _future;
  }

  Future<List<_HistoryOrderUi>> _load({required int page, required int limit}) async {
    final body = await _ordersService.listSubmissionHistory(page: page, limit: limit);
    final data = body['data'];
    if (data is! List) {
      throw Exception('Invalid response: missing data list');
    }

    final orders = data.whereType<Map>().map((m) => m.cast<String, dynamic>()).toList()
      ..sort((a, b) {
        final adt = _parseCreatedAt(a);
        final bdt = _parseCreatedAt(b);
        if (adt == null && bdt == null) return 0;
        if (adt == null) return 1;
        if (bdt == null) return -1;
        return bdt.compareTo(adt);
      });

    Future<_HistoryOrderUi> mapOne(Map<String, dynamic> o) async {
      final orderId = (o['orderId'] ?? '').toString();
      final createdAt = parseUtc(o['createdAt']);

      final customer = o['customer'];
      final customerName = (customer is Map ? customer['fullName'] : null)?.toString() ?? 'Customer';

      // Pull pickup delivery staff if present in history payload
      final pickupDelivery = o['pickupDelivery'];
      final deliveryStaff = (pickupDelivery is Map ? pickupDelivery['deliveryStaff'] : null);
      final deliveryPerson = (deliveryStaff is Map ? deliveryStaff['fullName'] : null)?.toString() ?? '—';
      final deliveryPersonId = (deliveryStaff is Map ? deliveryStaff['staffId'] : null)?.toString() ?? '';

      // Fetch items (for items list UI)
      List<_OrderItem> items = const [];
      int itemCount = 0;
      if (orderId.isNotEmpty) {
        try {
          final itemsBody = await _ordersService.getOrderItems(orderId: orderId);
          final itemsData = itemsBody['data'];
          final mapped = _mapItemsForUi(itemsData);
          items = mapped.items;
          itemCount = mapped.totalCount;
        } catch (_) {
          // keep empty items
        }
      }

      return _HistoryOrderUi(
        backendOrderId: orderId,
        orderIdDisplay: _formatOrderId(orderId),
        customerName: customerName,
        date: formatDateIst(createdAt),
        time: formatTimeIst(createdAt),
        itemCount: itemCount,
        deliveryPerson: deliveryPerson,
        deliveryPersonId: deliveryPersonId,
        assignedTo: '—',
        items: items,
      );
    }

    return Future.wait(orders.map(mapOne));
  }

  static DateTime? _parseCreatedAt(Map<String, dynamic> o) {
    return parseUtc(o['createdAt']);
  }

  static String _formatOrderId(String orderId) {
    final normalized = orderId.replaceAll('-', '').toUpperCase();
    if (normalized.length >= 6) return 'ORD${normalized.substring(0, 6)}';
    if (normalized.isNotEmpty) return 'ORD$normalized';
    return 'ORDER';
  }

  static _ItemsUiMapping _mapItemsForUi(Object? itemsData) {
    final items = <_OrderItem>[];
    final aggregated = <String, int>{};

    if (itemsData is Map) {
      final map = itemsData.cast<String, dynamic>();
      final list = map['items'];
      if (list is List) {
        for (final rawItem in list) {
          if (rawItem is! Map) continue;
          final item = rawItem.cast<String, dynamic>();
          final serviceName = (item['serviceName'] ?? '').toString().trim();
          final categoryName = (item['categoryName'] ?? '').toString().trim();
          final key = _formatServiceKey(categoryName, serviceName);

          int qty = 0;
          final selections = item['selections'];
          if (selections is List && selections.isNotEmpty) {
            for (final rawSel in selections) {
              if (rawSel is! Map) continue;
              final sel = rawSel.cast<String, dynamic>();
              final qtyNum = sel['quantity'];
              final q = (qtyNum is num) ? qtyNum.toInt() : int.tryParse(qtyNum?.toString() ?? '') ?? 0;
              if (q > 0) qty += q;
            }
          } else {
            final qtyNum = item['quantity'];
            qty = (qtyNum is num) ? qtyNum.toInt() : int.tryParse(qtyNum?.toString() ?? '') ?? 0;
          }

          if (key.isEmpty || qty <= 0) continue;
          aggregated[key] = (aggregated[key] ?? 0) + qty;
        }
      }
    }

    final entries = aggregated.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    int total = 0;
    for (final e in entries) {
      total += e.value;
      items.add(_OrderItem(name: e.key, quantity: e.value));
    }

    return _ItemsUiMapping(items: items, totalCount: total);
  }

  static String _formatServiceKey(String categoryName, String serviceName) {
    final c = categoryName.trim();
    final s = serviceName.trim();
    if (c.isNotEmpty && s.isNotEmpty) return '$c • $s';
    if (s.isNotEmpty) return s;
    return c;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: AppColors.textPrimary,
                      size: 20,
                    ),
                    splashRadius: 20,
                  ),
                  Expanded(
                    child: Text(
                      'History',
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
            // History Orders List
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refresh,
                color: AppColors.primary,
                child: FutureBuilder<List<_HistoryOrderUi>>(
                  future: _future,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.4,
                            child: const Center(
                              child: SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ),
                          ),
                        ],
                      );
                    }

                    if (snapshot.hasError) {
                      return ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          Padding(
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
                                      _future = _load(page: 1, limit: 20);
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
                        ],
                      );
                    }

                    final list = snapshot.data ?? const <_HistoryOrderUi>[];
                    if (list.isEmpty) {
                      return ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.4,
                            child: Center(
                              child: Text(
                                'No history found',
                                style: AppTextStyles.subtitle(color: AppColors.textSecondary),
                              ),
                            ),
                          ),
                        ],
                      );
                    }

                    return ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      itemCount: list.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final o = list[index];
                        return _HistoryOrderCard(
                          orderId: o.orderIdDisplay,
                          customerName: o.customerName,
                          date: o.date,
                          time: o.time,
                          itemCount: o.itemCount,
                          deliveryPerson: o.deliveryPerson,
                          deliveryPersonId: o.deliveryPersonId,
                          assignedTo: o.assignedTo,
                          items: o.items,
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderItem {
  final String name;
  final int quantity;

  const _OrderItem({required this.name, required this.quantity});
}

class _ItemsUiMapping {
  final List<_OrderItem> items;
  final int totalCount;

  const _ItemsUiMapping({required this.items, required this.totalCount});
}

class _HistoryOrderUi {
  final String backendOrderId;
  final String orderIdDisplay;
  final String customerName;
  final String date;
  final String time;
  final int itemCount;
  final String deliveryPerson;
  final String deliveryPersonId;
  final String assignedTo;
  final List<_OrderItem> items;

  const _HistoryOrderUi({
    required this.backendOrderId,
    required this.orderIdDisplay,
    required this.customerName,
    required this.date,
    required this.time,
    required this.itemCount,
    required this.deliveryPerson,
    required this.deliveryPersonId,
    required this.assignedTo,
    required this.items,
  });
}

class _HistoryOrderCard extends StatefulWidget {
  final String orderId;
  final String customerName;
  final String date;
  final String time;
  final int itemCount;
  final String deliveryPerson;
  final String deliveryPersonId;
  final String assignedTo;
  final List<_OrderItem> items;
  final bool isExpanded;

  const _HistoryOrderCard({
    required this.orderId,
    required this.customerName,
    required this.date,
    required this.time,
    required this.itemCount,
    required this.deliveryPerson,
    required this.deliveryPersonId,
    required this.assignedTo,
    required this.items,
    this.isExpanded = false,
  });

  @override
  State<_HistoryOrderCard> createState() => _HistoryOrderCardState();
}

class _HistoryOrderCardState extends State<_HistoryOrderCard> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.isExpanded;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.divider.withOpacity(0.4),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order ID and Items Count Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.orderId,
                style: AppTextStyles.subtitle(
                  color: AppColors.primary,
                ).copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${widget.itemCount} items',
                style: AppTextStyles.subtitle(
                  color: AppColors.primary,
                ).copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Customer Name
          Text(
            widget.customerName,
            style: AppTextStyles.title(
              color: AppColors.textPrimary,
            ).copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          // Date & Time
          Row(
            children: [
              Icon(
                Icons.calendar_today_outlined,
                size: 14,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                '${widget.date} at ${widget.time}',
                style: AppTextStyles.subtitle(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Delivered By
          Row(
            children: [
              Icon(
                Icons.person_outline,
                size: 14,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                'Delivered by: ${widget.deliveryPerson} (${widget.deliveryPersonId})',
                style: AppTextStyles.subtitle(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Assigned To
          Row(
            children: [
              Icon(
                Icons.assignment_outlined,
                size: 14,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                'Assigned to: ${widget.assignedTo}',
                style: AppTextStyles.subtitle(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          // Expandable Items List
          if (!_isExpanded) ...[
            const SizedBox(height: 12),
            InkWell(
              onTap: () {
                setState(() {
                  _isExpanded = true;
                });
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.keyboard_arrow_down,
                    size: 18,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Items list',
                    style: AppTextStyles.subtitle(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    Icons.keyboard_arrow_down,
                    size: 18,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ],
          if (_isExpanded) ...[
            const SizedBox(height: 16),
            // Items List
            ...widget.items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      // Bullet point
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: AppColors.textSecondary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Item name
                      Text(
                        item.name,
                        style: AppTextStyles.subtitle(
                          color: AppColors.textPrimary,
                        ).copyWith(
                          fontSize: 13,
                        ),
                      ),
                      // Dotted line
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: CustomPaint(
                            painter: DottedLinePainter(),
                            child: const SizedBox(height: 1),
                          ),
                        ),
                      ),
                      // Quantity
                      Text(
                        item.quantity.toString().padLeft(2, '0'),
                        style: AppTextStyles.subtitle(
                          color: AppColors.textPrimary,
                        ).copyWith(
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                )),
            const SizedBox(height: 12),
            // Items list footer with upward chevrons
            InkWell(
              onTap: () {
                setState(() {
                  _isExpanded = false;
                });
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.keyboard_arrow_up,
                    size: 18,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Items list',
                    style: AppTextStyles.subtitle(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    Icons.keyboard_arrow_up,
                    size: 18,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class DottedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.divider
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    const dashWidth = 4.0;
    const dashSpace = 3.0;
    double startX = 0;

    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, size.height / 2),
        Offset(startX + dashWidth, size.height / 2),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}


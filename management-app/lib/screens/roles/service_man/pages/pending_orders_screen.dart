import 'package:flutter/material.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_text_styles.dart';
import '../../../../routes/app_routes.dart';
import '../../../../utils/auth_storage.dart';
import '../../../../utils/date_time_ist.dart';
import '../../../../utils/role_manager.dart';
import '../../../../services/service_man_queue_service.dart';
import '../../../common/widgets/success_popup.dart';

class PendingOrdersServicemenScreen extends StatefulWidget {
  const PendingOrdersServicemenScreen({super.key});

  @override
  State<PendingOrdersServicemenScreen> createState() => _PendingOrdersServicemenScreenState();
}

class _PendingOrdersServicemenScreenState extends State<PendingOrdersServicemenScreen> {
  int _selectedTabIndex = 0; // 0: Pending, 1: Completed

  final ServiceManQueueService _queueService = ServiceManQueueService();
  Future<List<_QueueOrderUi>> _queueFuture = Future.value(const <_QueueOrderUi>[]);
  Future<List<_CompletedOrderUi>> _completedFuture = Future.value(const <_CompletedOrderUi>[]);
  Future<Map<String, dynamic>?> _userFuture = AuthStorage.getCurrentUser();

  static int _sumQuantityOrFallbackToRowCount(List<Map<String, dynamic>> rows) {
    int sum = 0;
    for (final r in rows) {
      final qtyRaw = r['quantity'];
      final qty = (qtyRaw is num) ? qtyRaw.toInt() : int.tryParse(qtyRaw?.toString() ?? '') ?? 0;
      if (qty > 0) sum += qty;
    }
    return sum > 0 ? sum : rows.length;
  }

  @override
  void initState() {
    super.initState();
    _queueFuture = _loadQueue();
    _completedFuture = _loadCompleted();
    _userFuture = AuthStorage.getCurrentUser();
  }

  Future<void> _handleLogout() async {
    await RoleManager.clearRole();
    await AuthStorage.clearAll();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRoutes.roleSelection,
      (route) => false,
    );
  }

  Future<void> _refreshQueue() async {
    setState(() {
      _queueFuture = _loadQueue();
      _userFuture = AuthStorage.getCurrentUser();
    });
    await _queueFuture;
  }

  Future<void> _refreshCompleted() async {
    setState(() {
      _completedFuture = _loadCompleted();
      _userFuture = AuthStorage.getCurrentUser();
    });
    await _completedFuture;
  }

  Future<List<_QueueOrderUi>> _loadQueue() async {
    final body = await _queueService.listQueue(statusCsv: 'pending,in_progress', page: 1, limit: 20);
    final data = body['data'];
    if (data is! List) throw Exception('Invalid response: missing data list');

    final items = data.whereType<Map>().map((m) => m.cast<String, dynamic>()).toList();

    // Group queue items by orderId (UI is order-card based).
    final byOrder = <String, List<Map<String, dynamic>>>{};
    for (final q in items) {
      final orderId = (q['orderId'] ?? '').toString();
      if (orderId.isEmpty) continue;
      byOrder.putIfAbsent(orderId, () => []).add(q);
    }

    final result = <_QueueOrderUi>[];
    for (final entry in byOrder.entries) {
      final orderId = entry.key;
      final rows = entry.value;

      rows.sort((a, b) {
        final adt = _parseDate(a['assignedAt']) ?? _parseDate(a['startedAt']);
        final bdt = _parseDate(b['assignedAt']) ?? _parseDate(b['startedAt']);
        if (adt == null && bdt == null) return 0;
        if (adt == null) return 1;
        if (bdt == null) return -1;
        return adt.compareTo(bdt); // older first inside group
      });

      final first = rows.first;
      final assignedAt = _parseDate(first['assignedAt']) ?? _parseDate(first['startedAt']);
      final customer = (first['order'] is Map ? (first['order'] as Map)['customer'] : null);
      final customerName = (customer is Map ? customer['fullName'] : null)?.toString() ?? 'Customer';

      final queueIds = rows.map((r) => (r['queueId'] ?? '').toString()).where((s) => s.isNotEmpty).toList();

      // Build item lines from queue items (itemName + quantity/weight)
      final mappedItems = <_OrderItem>[];
      final totalQty = _sumQuantityOrFallbackToRowCount(rows);
      for (final r in rows) {
        final name = (r['itemName'] ?? '').toString().trim();
        final qtyRaw = r['quantity'];
        final qty = (qtyRaw is num) ? qtyRaw.toInt() : int.tryParse(qtyRaw?.toString() ?? '') ?? 0;
        final weightRaw = r['weightKg'];
        final weight = (weightRaw is num) ? weightRaw.toDouble() : double.tryParse(weightRaw?.toString() ?? '');

        if (name.isEmpty) continue;

        // Extract cloth items if available
        final List<_ClothItem> clothItemsList = [];
        final clothItemsRaw = r['clothItems'];
        if (clothItemsRaw is List) {
          for (final clothRaw in clothItemsRaw) {
            if (clothRaw is Map) {
              final clothMap = clothRaw.cast<String, dynamic>();
              final clothName = (clothMap['clothName'] ?? '').toString().trim();
              final clothQty = (clothMap['quantity'] is num)
                  ? (clothMap['quantity'] as num).toInt()
                  : int.tryParse(clothMap['quantity']?.toString() ?? '') ?? 0;
              if (clothName.isNotEmpty && clothQty > 0) {
                clothItemsList.add(_ClothItem(clothName: clothName, quantity: clothQty));
              }
            }
          }
        }
        final clothItems = clothItemsList.isNotEmpty ? clothItemsList : null;

        if (qty > 0) {
          mappedItems.add(_OrderItem(
            name: name,
            valueText: qty.toString().padLeft(2, '0'),
            clothItems: clothItems,
          ));
        } else if (weight != null && weight > 0) {
          mappedItems.add(_OrderItem(
            name: name,
            valueText: '${weight.toStringAsFixed(1)} kg',
            clothItems: clothItems,
          ));
        } else {
          mappedItems.add(_OrderItem(
            name: name,
            valueText: '01',
            clothItems: clothItems,
          ));
        }
      }

      // Sort groups by assigned time (newest first)
      result.add(
        _QueueOrderUi(
          backendOrderId: orderId,
          orderIdDisplay: _formatOrderId(orderId),
          customerName: customerName,
          date: formatDateIst(assignedAt),
          time: formatTimeIst(assignedAt),
          itemCount: totalQty,
          items: mappedItems,
          queueIds: queueIds,
          sortAt: assignedAt,
        ),
      );
    }

    result.sort((a, b) {
      final adt = a.sortAt;
      final bdt = b.sortAt;
      if (adt == null && bdt == null) return 0;
      if (adt == null) return 1;
      if (bdt == null) return -1;
      return bdt.compareTo(adt); // newest first
    });

    return result;
  }

  Future<List<_CompletedOrderUi>> _loadCompleted() async {
    final body = await _queueService.listCompleted(page: 1, limit: 20);
    final data = body['data'];
    if (data is! List) throw Exception('Invalid response: missing data list');

    final rows = data.whereType<Map>().map((m) => m.cast<String, dynamic>()).toList();

    // Group completed items by orderId for UI cards
    final byOrder = <String, List<Map<String, dynamic>>>{};
    for (final r in rows) {
      final orderId = (r['orderId'] ?? '').toString();
      if (orderId.isEmpty) continue;
      byOrder.putIfAbsent(orderId, () => []).add(r);
    }

    final out = <_CompletedOrderUi>[];
    for (final e in byOrder.entries) {
      final orderId = e.key;
      final items = e.value;

      items.sort((a, b) {
        final adt = _parseDate(a['completedOn']);
        final bdt = _parseDate(b['completedOn']);
        if (adt == null && bdt == null) return 0;
        if (adt == null) return 1;
        if (bdt == null) return -1;
        return bdt.compareTo(adt); // newest first
      });

      final first = items.first;
      final addedOn = _parseDate(first['addedOn']);
      final completedOn = _parseDate(first['completedOn']);
      final order = first['order'];
      final customer = (order is Map ? order['customer'] : null);
      final customerName = (customer is Map ? customer['fullName'] : null)?.toString() ?? 'Customer';

      int qtySum = 0;
      for (final r in items) {
        final c = r['clothItemsCount'];
        final q = (c is num) ? c.toInt() : int.tryParse(c?.toString() ?? '') ?? 0;
        if (q > 0) qtySum += q;
      }
      final count = qtySum > 0 ? qtySum : items.length;

      out.add(
        _CompletedOrderUi(
          backendOrderId: orderId,
          orderIdDisplay: _formatOrderId(orderId),
          customerName: customerName,
          addedDate: formatDateIst(addedOn),
          addedTime: formatTimeIst(addedOn),
          completedDate: formatDateIst(completedOn),
          completedTime: formatTimeIst(completedOn),
          itemCount: count,
        ),
      );
    }

    return out;
  }

  Future<void> _bulkUpdateQueueItems({
    required List<String> queueIds,
    required String action,
  }) async {
    // Update each queue item; keep it simple and robust.
    for (final qid in queueIds) {
      await _queueService.updateQueueItem(queueId: qid, action: action);
    }
    // Refresh both tabs so completed moves across.
    await Future.wait([_refreshQueue(), _refreshCompleted()]);
  }

  static DateTime? _parseDate(Object? raw) {
    return parseUtc(raw);
  }

  static String _formatOrderId(String orderId) {
    final normalized = orderId.replaceAll('-', '').toUpperCase();
    if (normalized.length >= 6) return 'ORD${normalized.substring(0, 6)}';
    if (normalized.isNotEmpty) return 'ORD$normalized';
    return 'ORDER';
  }

  Future<void> _markInProgress(List<String> queueIds) async {
    try {
      await _bulkUpdateQueueItems(queueIds: queueIds, action: 'in_progress');
      if (!mounted) return;
      showSuccessPopup(context, message: 'Marked in progress ✓');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '').trim())),
      );
    }
  }

  Future<void> _markCompleted(List<String> queueIds) async {
    try {
      await _bulkUpdateQueueItems(queueIds: queueIds, action: 'completed');
      if (!mounted) return;
      showSuccessPopup(context, message: 'Marked completed ✓');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '').trim())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: IndexedStack(
          index: _selectedTabIndex,
          children: [
            _PendingOrdersView(
              queueFuture: _queueFuture,
              userFuture: _userFuture,
              onLogout: _handleLogout,
              onRefresh: _refreshQueue,
              onInProgress: _markInProgress,
              onMarkComplete: _markCompleted,
            ),
            _CompletedOrdersView(
              completedFuture: _completedFuture,
              onRefresh: _refreshCompleted,
            ),
          ],
        ),
      ),
      bottomNavigationBar: _BottomNavBar(
        selectedIndex: _selectedTabIndex,
        onTabSelected: (index) {
          setState(() {
            _selectedTabIndex = index;
          });
        },
      ),
    );
  }
}

class _PendingOrdersView extends StatelessWidget {
  final Future<List<_QueueOrderUi>> queueFuture;
  final Future<Map<String, dynamic>?> userFuture;
  final VoidCallback onLogout;
  final Future<void> Function() onRefresh;
  final Future<void> Function(List<String> queueIds) onInProgress;
  final Future<void> Function(List<String> queueIds) onMarkComplete;

  const _PendingOrdersView({
    required this.queueFuture,
    required this.userFuture,
    required this.onLogout,
    required this.onRefresh,
    required this.onInProgress,
    required this.onMarkComplete,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header Section
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/icons/profile_pic_demo.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FutureBuilder<Map<String, dynamic>?>(
                        future: userFuture,
                        builder: (context, snapshot) {
                          final user = snapshot.data;
                          final fullName = (user?['fullName'] ?? '').toString().trim();
                          final firstName = fullName.isNotEmpty
                              ? fullName.split(RegExp(r'\s+')).first.trim()
                              : '';

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                firstName.isNotEmpty ? 'Hi, $firstName' : 'Hi',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.title(
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              // Log Out Button
              InkWell(
                onTap: onLogout,
                borderRadius: BorderRadius.circular(26),
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
                child: SizedBox(
                  height: 44,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        height: 44,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(26),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Image.asset(
                              'assets/icons/home_screen/end_shift.png',
                              width: 18,
                              height: 18,
                              fit: BoxFit.contain,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Log Out',
                              style: AppTextStyles.button(
                                color: AppColors.error,
                              ).copyWith(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        left: 10,
                        right: 10,
                        bottom: 0,
                        child: Container(
                          height: 2,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [
                                Color(0x00FF3B30),
                                Color(0xFFFF3B30),
                                Color(0x00FF3B30),
                              ],
                              stops: [0.0, 0.5, 1.0],
                            ),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        // Title Section – category/service name from profile
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          child: Center(
            child: FutureBuilder<Map<String, dynamic>?>(
              future: userFuture,
              builder: (context, snapshot) {
                final user = snapshot.data;
                final serviceName = (user?['serviceName'] ?? user?['service_name'] ?? '')
                    .toString()
                    .trim();
                final categoryLabel = serviceName.isNotEmpty
                    ? 'Category: $serviceName'
                    : 'Category: Wash & Fold';
                return Text(
                  categoryLabel,
                  style: AppTextStyles.header(
                    color: AppColors.textPrimary,
                  ).copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                );
              },
            ),
          ),
        ),
        // Orders List
        Expanded(
          child: _buildPendingOrdersList(),
        ),
      ],
    );
  }

  Widget _buildPendingOrdersList() {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: FutureBuilder<List<_QueueOrderUi>>(
        future: queueFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SingleChildScrollView(
              physics: AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: 300,
                child: Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
            );
          }

          if (snapshot.hasError) {
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: 300,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      snapshot.error.toString().replaceFirst('Exception: ', ''),
                      style: AppTextStyles.subtitle(color: AppColors.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            );
          }

          final list = snapshot.data ?? const <_QueueOrderUi>[];
          if (list.isEmpty) {
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: 300,
                child: Center(
                  child: Text(
                    'No pending items',
                    style: AppTextStyles.subtitle(color: AppColors.textSecondary),
                  ),
                ),
              ),
            );
          }

          return ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 18),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final o = list[index];
              return _OrderCard(
                orderId: o.orderIdDisplay,
                customerName: o.customerName,
                date: o.date,
                time: o.time,
                itemCount: o.itemCount,
                items: o.items,
                onInProgress: () => onInProgress(o.queueIds),
                onMarkComplete: () => onMarkComplete(o.queueIds),
              );
            },
          );
        },
      ),
    );
  }
}

class _CompletedOrdersView extends StatelessWidget {
  final Future<List<_CompletedOrderUi>> completedFuture;
  final Future<void> Function() onRefresh;

  const _CompletedOrdersView({
    required this.completedFuture,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Title Section
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Center(
            child: Text(
              'Service Man Completed',
              style: AppTextStyles.header(
                color: AppColors.textPrimary,
              ).copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        // Completed Orders List
        Expanded(
          child: _buildCompletedOrdersList(),
        ),
      ],
    );
  }

  Widget _buildCompletedOrdersList() {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: FutureBuilder<List<_CompletedOrderUi>>(
        future: completedFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SingleChildScrollView(
              physics: AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: 300,
                child: Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
            );
          }

          if (snapshot.hasError) {
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: 300,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      snapshot.error.toString().replaceFirst('Exception: ', ''),
                      style: AppTextStyles.subtitle(color: AppColors.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            );
          }

          final list = snapshot.data ?? const <_CompletedOrderUi>[];
          if (list.isEmpty) {
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: 300,
                child: Center(
                  child: Text(
                    'No completed items',
                    style: AppTextStyles.subtitle(color: AppColors.textSecondary),
                  ),
                ),
              ),
            );
          }

          return ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 18),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final o = list[index];
              return _CompletedOrderCard(
                orderId: o.orderIdDisplay,
                customerName: o.customerName,
                addedDate: o.addedDate,
                addedTime: o.addedTime,
                completedDate: o.completedDate,
                completedTime: o.completedTime,
                itemCount: o.itemCount,
              );
            },
          );
        },
      ),
    );
  }
}

class _OrderItem {
  final String name;
  final String valueText;
  final List<_ClothItem>? clothItems; // Cloth items for this service

  const _OrderItem({
    required this.name,
    required this.valueText,
    this.clothItems,
  });
}

class _ClothItem {
  final String clothName;
  final int quantity;

  const _ClothItem({
    required this.clothName,
    required this.quantity,
  });
}

class _QueueOrderUi {
  final String backendOrderId;
  final String orderIdDisplay;
  final String customerName;
  final String date;
  final String time;
  final int itemCount;
  final List<_OrderItem> items;
  final List<String> queueIds;
  final DateTime? sortAt;

  _QueueOrderUi({
    required this.backendOrderId,
    required this.orderIdDisplay,
    required this.customerName,
    required this.date,
    required this.time,
    required this.itemCount,
    required this.items,
    required this.queueIds,
    required this.sortAt,
  });
}

class _CompletedOrderUi {
  final String backendOrderId;
  final String orderIdDisplay;
  final String customerName;
  final String addedDate;
  final String addedTime;
  final String completedDate;
  final String completedTime;
  final int itemCount;

  const _CompletedOrderUi({
    required this.backendOrderId,
    required this.orderIdDisplay,
    required this.customerName,
    required this.addedDate,
    required this.addedTime,
    required this.completedDate,
    required this.completedTime,
    required this.itemCount,
  });
}

class _OrderCard extends StatefulWidget {
  final String orderId;
  final String customerName;
  final String date;
  final String time;
  final int itemCount;
  final List<_OrderItem> items;
  final VoidCallback onInProgress;
  final VoidCallback onMarkComplete;

  const _OrderCard({
    required this.orderId,
    required this.customerName,
    required this.date,
    required this.time,
    required this.itemCount,
    required this.items,
    required this.onInProgress,
    required this.onMarkComplete,
  });

  @override
  State<_OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends State<_OrderCard> {
  bool _isExpanded = false;

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
          // Order ID
          Text(
            widget.orderId,
            style: AppTextStyles.subtitle(
              color: AppColors.primary,
            ).copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
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
          // Date & Time with Items
          Row(
            children: [
              // Date & Time Section
              Expanded(
                child: Row(
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
              ),
              // Items Count
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    widget.itemCount.toString().padLeft(2, '0'),
                    style: AppTextStyles.largeNumber(
                      color: AppColors.primary,
                    ),
                  ),
                  Text(
                    'qty',
                    style: AppTextStyles.subtitle(
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Action Buttons
          Row(
            children: [
              Expanded(
                child: _InProgressButton(
                  onTap: widget.onInProgress,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MarkCompleteButton(
                  onTap: widget.onMarkComplete,
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
                ],
              ),
            ),
          ],
          if (_isExpanded) ...[
            const SizedBox(height: 16),
            // Items List
            ...widget.items.map((item) {
              final hasClothItems = item.clothItems != null && item.clothItems!.isNotEmpty;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.only(bottom: hasClothItems ? 8 : 12),
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
                        Expanded(
                          child: Text(
                            item.name,
                            style: AppTextStyles.subtitle(
                              color: AppColors.textPrimary,
                            ).copyWith(
                              fontSize: 13,
                            ),
                          ),
                        ),
                        // Dotted line
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: CustomPaint(
                            painter: DottedLinePainter(),
                            child: const SizedBox(height: 1),
                          ),
                        ),
                        // Quantity
                        Text(
                          item.valueText,
                          style: AppTextStyles.subtitle(
                            color: AppColors.textPrimary,
                          ).copyWith(
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Show cloth items nested under service
                  if (hasClothItems)
                    ...item.clothItems!.map((clothItem) => Padding(
                          padding: const EdgeInsets.only(left: 18, bottom: 8),
                          child: Row(
                            children: [
                              Container(
                                width: 4,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: AppColors.textSecondary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  clothItem.clothName,
                                  style: AppTextStyles.subtitle(
                                    color: AppColors.textSecondary,
                                  ).copyWith(
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                child: CustomPaint(
                                  painter: DottedLinePainter(),
                                  child: const SizedBox(height: 1),
                                ),
                              ),
                              Text(
                                clothItem.quantity.toString().padLeft(2, '0'),
                                style: AppTextStyles.subtitle(
                                  color: AppColors.textSecondary,
                                ).copyWith(
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        )),
                ],
              );
            }),
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

class _InProgressButton extends StatelessWidget {
  final VoidCallback onTap;

  const _InProgressButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: AppColors.primary,
            width: 1.4,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          'In-Progress',
          style: AppTextStyles.button(
            color: AppColors.primary,
          ).copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _MarkCompleteButton extends StatelessWidget {
  final VoidCallback onTap;

  const _MarkCompleteButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              Color(0xFF283897),
              Color(0xFF0F73F7),
            ],
          ),
          borderRadius: BorderRadius.circular(18),
        ),
        alignment: Alignment.center,
        child: Text(
          'Mark as Complete',
          style: AppTextStyles.button(
            color: Colors.white,
          ).copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _CompletedOrderCard extends StatelessWidget {
  final String orderId;
  final String customerName;
  final String addedDate;
  final String addedTime;
  final String completedDate;
  final String completedTime;
  final int itemCount;

  const _CompletedOrderCard({
    required this.orderId,
    required this.customerName,
    required this.addedDate,
    required this.addedTime,
    required this.completedDate,
    required this.completedTime,
    required this.itemCount,
  });

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
              // Order ID (Green)
              Text(
                orderId,
                style: AppTextStyles.subtitle(
                  color: AppColors.success,
                ).copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              // Items Count (Green)
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    itemCount.toString().padLeft(2, '0'),
                    style: AppTextStyles.largeNumber(
                      color: AppColors.success,
                    ),
                  ),
                  Text(
                    'qty',
                    style: AppTextStyles.subtitle(
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Customer Name
          Text(
            customerName,
            style: AppTextStyles.title(
              color: AppColors.textPrimary,
            ).copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          // Added Date & Time
          Row(
            children: [
              Text(
                'Added: ',
                style: AppTextStyles.subtitle(
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                '$addedDate at $addedTime',
                style: AppTextStyles.subtitle(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Completed Date & Time
          Row(
            children: [
              Text(
                'Completed: ',
                style: AppTextStyles.subtitle(
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                '$completedDate at $completedTime',
                style: AppTextStyles.subtitle(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;

  const _BottomNavBar({
    required this.selectedIndex,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    const barHeight = 82.0;
    const topRadius = Radius.circular(36);
    const topOnlyRadius = BorderRadius.only(
      topLeft: topRadius,
      topRight: topRadius,
    );

    return SizedBox(
      height: barHeight + bottomInset,
      child: Material(
        color: AppColors.surface,
        elevation: 14,
        borderRadius: topOnlyRadius,
        shadowColor: const Color(0x26000000),
        child: ClipRRect(
          borderRadius: topOnlyRadius,
          child: Stack(
            children: [
              // Bottom inset filler so bar sits flush with screen bottom.
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: bottomInset,
                child: const ColoredBox(color: Colors.white),
              ),
              // Main bar content.
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                height: barHeight,
                child: Stack(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 10, 18, 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: _NavTab(
                              icon: Icons.access_time_rounded,
                              label: 'Pending',
                              isSelected: selectedIndex == 0,
                              onTap: () => onTabSelected(0),
                            ),
                          ),
                          Expanded(
                            child: _NavTab(
                              icon: Icons.check_circle,
                              label: 'Completed',
                              isSelected: selectedIndex == 1,
                              onTap: () => onTabSelected(1),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Top accent line (inset from both ends) - rendered on top
                    Positioned(
                      left: 10,
                      right: 10,
                      top: 1,
                      child: IgnorePointer(
                        child: Container(
                          height: 2,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [
                                Color(0x002C3CA5), // transparent
                                Color(0xFF2C3CA5), // sharp in center
                                Color(0x002C3CA5), // transparent
                              ],
                              stops: [0.0, 0.5, 1.0],
                            ),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavTab extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavTab({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? AppColors.primary : const Color(0xFF98A0B5);
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: SizedBox(
        height: 56,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 26,
              color: color,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                height: 1.0,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


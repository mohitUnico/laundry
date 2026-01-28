import 'package:flutter/material.dart';

import '../../../../theme/app_colors.dart';
import '../../../../theme/app_text_styles.dart';
import '../../../../routes/app_routes.dart';
import '../../../../utils/auth_storage.dart';
import '../../../../utils/role_manager.dart';
import '../../../../services/distribution_manager_orders_service.dart';
import 'delivery_partners_screen.dart';
import 'history_screen.dart';

class DistributionManagerHomeScreen extends StatefulWidget {
  const DistributionManagerHomeScreen({super.key});

  @override
  State<DistributionManagerHomeScreen> createState() => _DistributionManagerHomeScreenState();
}

class _DistributionManagerHomeScreenState extends State<DistributionManagerHomeScreen> {
  int _selectedTabIndex = 0; // 0: Home, 1: Dispatch

  final DistributionManagerOrdersService _ordersService = DistributionManagerOrdersService();

  Future<List<_DmOrderUi>> _readyFuture = Future.value(const <_DmOrderUi>[]);
  Future<List<_DmOrderUi>> _verifiedFuture = Future.value(const <_DmOrderUi>[]);
  Future<Map<String, dynamic>?> _userFuture = AuthStorage.getCurrentUser();

  @override
  void initState() {
    super.initState();
    _readyFuture = _fetchReadyToVerify(page: 1, limit: 20);
    _verifiedFuture = _fetchVerified(page: 1, limit: 20);
    _userFuture = AuthStorage.getCurrentUser();
  }

  Future<void> _refreshReady() async {
    setState(() {
      _readyFuture = _fetchReadyToVerify(page: 1, limit: 20);
      _userFuture = AuthStorage.getCurrentUser();
    });
    await _readyFuture;
  }

  Future<void> _refreshVerified() async {
    setState(() {
      _verifiedFuture = _fetchVerified(page: 1, limit: 20);
      _userFuture = AuthStorage.getCurrentUser();
    });
    await _verifiedFuture;
  }

  Future<List<_DmOrderUi>> _fetchReadyToVerify({required int page, required int limit}) async {
    final body = await _ordersService.listReadyToVerify(page: page, limit: limit);
    final data = body['data'];
    if (data is! List) throw Exception('Invalid response: missing data list');

    final orders = data.whereType<Map>().map((m) => m.cast<String, dynamic>()).toList()
      ..sort((a, b) {
        final adt = _parseDate(a['createdAt']);
        final bdt = _parseDate(b['createdAt']);
        if (adt == null && bdt == null) return 0;
        if (adt == null) return 1;
        if (bdt == null) return -1;
        return bdt.compareTo(adt);
      });

    Future<_DmOrderUi> mapOne(Map<String, dynamic> o) async {
      final orderId = (o['orderId'] ?? '').toString();
      final orderType = (o['orderType'] ?? '').toString();
      final createdAt = _parseDate(o['createdAt']);
      final customer = o['customer'];
      final customerName = (customer is Map ? customer['fullName'] : null)?.toString() ?? 'Customer';

      final itemsMapped = await _safeFetchItems(orderId);

      return _DmOrderUi(
        backendOrderId: orderId,
        orderIdDisplay: _formatOrderId(orderId),
        customerName: customerName,
        date: _formatDate(createdAt),
        time: _formatTime(createdAt),
        itemCount: itemsMapped.totalCount,
        items: itemsMapped.items,
        assignedTo: '—',
        orderType: orderType,
        buttonText: 'Mark as Verified',
        isVerifyButton: true,
      );
    }

    return Future.wait(orders.map(mapOne));
  }

  Future<List<_DmOrderUi>> _fetchVerified({required int page, required int limit}) async {
    final body = await _ordersService.listVerified(page: page, limit: limit);
    final data = body['data'];
    if (data is! List) throw Exception('Invalid response: missing data list');

    final orders = data.whereType<Map>().map((m) => m.cast<String, dynamic>()).toList()
      ..sort((a, b) {
        final adt = _parseDate(a['verifiedAt']) ?? _parseDate(a['createdAt']);
        final bdt = _parseDate(b['verifiedAt']) ?? _parseDate(b['createdAt']);
        if (adt == null && bdt == null) return 0;
        if (adt == null) return 1;
        if (bdt == null) return -1;
        return bdt.compareTo(adt);
      });

    Future<_DmOrderUi> mapOne(Map<String, dynamic> o) async {
      final orderId = (o['orderId'] ?? '').toString();
      final orderType = (o['orderType'] ?? '').toString();
      final createdAt = _parseDate(o['createdAt']);
      final customer = o['customer'];
      final customerName = (customer is Map ? customer['fullName'] : null)?.toString() ?? 'Customer';

      final itemsMapped = await _safeFetchItems(orderId);

      String assignedTo = '—';
      final dropDelivery = o['dropDelivery'];
      if (dropDelivery is Map) {
        final staff = dropDelivery['deliveryStaff'];
        final name = (staff is Map ? staff['fullName'] : null)?.toString().trim();
        if (name != null && name.isNotEmpty) assignedTo = name;
      }

      return _DmOrderUi(
        backendOrderId: orderId,
        orderIdDisplay: _formatOrderId(orderId),
        customerName: customerName,
        date: _formatDate(createdAt),
        time: _formatTime(createdAt),
        itemCount: itemsMapped.totalCount,
        items: itemsMapped.items,
        assignedTo: assignedTo,
        orderType: orderType,
        buttonText: orderType == 'pickup_only'
            ? 'Submitted to Customer'
            : (assignedTo == '—' ? 'Assign Delivery Partner' : 'Assigned'),
        isVerifyButton: false,
      );
    }

    return Future.wait(orders.map(mapOne));
  }

  Future<_ItemsUiMapping> _safeFetchItems(String orderId) async {
    if (orderId.isEmpty) return const _ItemsUiMapping(items: <_OrderItem>[], totalCount: 0);
    try {
      final body = await _ordersService.getOrderItems(orderId: orderId);
      final data = body['data'];
      return _mapItemsForUi(data);
    } catch (_) {
      return const _ItemsUiMapping(items: <_OrderItem>[], totalCount: 0);
    }
  }

  Future<void> _verifyAndRefresh(String orderId) async {
    try {
      await _ordersService.verifyOrder(orderId: orderId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order verified')),
      );
      // Refresh both lists so the order moves to dispatch tab.
      await Future.wait([_refreshReady(), _refreshVerified()]);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '').trim())),
      );
    }
  }

  Future<void> _submitToCustomerAndRefresh(String orderId) async {
    try {
      await _ordersService.submitToCustomer(orderId: orderId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order submitted to customer')),
      );
      await _refreshVerified();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '').trim())),
      );
    }
  }

  static DateTime? _parseDate(Object? raw) {
    if (raw is DateTime) return raw;
    if (raw is String && raw.isNotEmpty) return DateTime.tryParse(raw);
    return null;
  }

  static String _formatOrderId(String orderId) {
    final normalized = orderId.replaceAll('-', '').toUpperCase();
    if (normalized.length >= 6) return 'ORD${normalized.substring(0, 6)}';
    if (normalized.isNotEmpty) return 'ORD$normalized';
    return 'ORDER';
  }

  static String _formatDate(DateTime? dt) {
    if (dt == null) return '--';
    final dd = dt.day.toString().padLeft(2, '0');
    final mm = dt.month.toString().padLeft(2, '0');
    final yyyy = dt.year.toString();
    return '$dd-$mm-$yyyy';
  }

  static String _formatTime(DateTime? dt) {
    if (dt == null) return '--';
    int hour = dt.hour;
    final minute = dt.minute.toString().padLeft(2, '0');
    final suffix = hour >= 12 ? 'PM' : 'AM';
    hour = hour % 12;
    if (hour == 0) hour = 12;
    return '${hour.toString().padLeft(2, '0')}:$minute $suffix';
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

    final entries = aggregated.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
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
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  // Profile Section
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
                            future: _userFuture,
                            builder: (context, snapshot) {
                              final user = snapshot.data;
                              final fullName = (user?['fullName'] ?? '').toString().trim();
                              final firstName = fullName.isNotEmpty
                                  ? fullName.split(RegExp(r'\s+')).first.trim()
                                  : '';
                              final userId = (user?['userId'] ?? '').toString().trim();

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
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      Text(
                                        'ID: ',
                                        style: AppTextStyles.subtitle(
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                      Expanded(
                                        child: userId.isNotEmpty
                                            ? SingleChildScrollView(
                                                scrollDirection: Axis.horizontal,
                                                child: Text(
                                                  userId,
                                                  maxLines: 1,
                                                  softWrap: false,
                                                  style: AppTextStyles.subtitle(
                                                    color: AppColors.textSecondary,
                                                  ),
                                                ),
                                              )
                                            : Text(
                                                '—',
                                                style: AppTextStyles.subtitle(
                                                  color: AppColors.textSecondary,
                                                ),
                                              ),
                                      ),
                                    ],
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  // History Icon
                  IconButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const DistributionHistoryScreen(),
                        ),
                      );
                    },
                    icon: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE3F2FD),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.history,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                    splashRadius: 20,
                  ),
                  const SizedBox(width: 8),
                  // Log Out Button
                  InkWell(
                    onTap: () async {
                      // Get role before clearing, then navigate to login with role argument
                      final role = await RoleManager.getRole();
                      await RoleManager.clearRole();
                      if (context.mounted) {
                        Navigator.of(context).pushNamedAndRemoveUntil(
                          AppRoutes.login,
                          (route) => false,
                          arguments: {'role': role},
                        );
                      }
                    },
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
            const SizedBox(height: 8),
            // Orders List
            Expanded(
              child: _selectedTabIndex == 0
                  ? _buildHomeOrdersList()
                  : _buildDispatchOrdersList(),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _DistributionManagerBottomNavBar(
        selectedIndex: _selectedTabIndex,
        onTabSelected: (index) {
          setState(() {
            _selectedTabIndex = index;
          });
        },
      ),
    );
  }

  Widget _buildHomeOrdersList() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        FutureBuilder<List<_DmOrderUi>>(
          future: _readyFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2)),
                ),
              );
            }

            if (snapshot.hasError) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Center(
                  child: Text(
                    snapshot.error.toString().replaceFirst('Exception: ', ''),
                    style: AppTextStyles.subtitle(color: AppColors.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            final list = snapshot.data ?? const <_DmOrderUi>[];
            if (list.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 18),
                child: Center(
                  child: Text(
                    'No orders to verify',
                    style: AppTextStyles.subtitle(color: AppColors.textSecondary),
                  ),
                ),
              );
            }

            return Column(
              children: [
                for (final o in list) ...[
                  _OrderCard(
                    backendOrderId: o.backendOrderId,
                    orderId: o.orderIdDisplay,
                    customerName: o.customerName,
                    date: o.date,
                    time: o.time,
                    itemCount: o.itemCount,
                    assignedTo: o.assignedTo,
                    orderType: o.orderType,
                    buttonText: o.buttonText,
                    items: o.items,
                    isVerifyButton: o.isVerifyButton,
                    onVerify: _verifyAndRefresh,
                  ),
                  const SizedBox(height: 12),
                ],
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildDispatchOrdersList() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        FutureBuilder<List<_DmOrderUi>>(
          future: _verifiedFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2)),
                ),
              );
            }

            if (snapshot.hasError) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Center(
                  child: Text(
                    snapshot.error.toString().replaceFirst('Exception: ', ''),
                    style: AppTextStyles.subtitle(color: AppColors.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            final list = snapshot.data ?? const <_DmOrderUi>[];
            if (list.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 18),
                child: Center(
                  child: Text(
                    'No verified orders',
                    style: AppTextStyles.subtitle(color: AppColors.textSecondary),
                  ),
                ),
              );
            }

            return Column(
              children: [
                for (final o in list) ...[
                  _OrderCard(
                    backendOrderId: o.backendOrderId,
                    orderId: o.orderIdDisplay,
                    customerName: o.customerName,
                    date: o.date,
                    time: o.time,
                    itemCount: o.itemCount,
                    assignedTo: o.assignedTo,
                    orderType: o.orderType,
                    buttonText: o.buttonText,
                    items: o.items,
                    isVerifyButton: o.isVerifyButton,
                    onVerify: _verifyAndRefresh,
                    onAssigned: _refreshVerified,
                    onSubmitToCustomer: _submitToCustomerAndRefresh,
                  ),
                  const SizedBox(height: 12),
                ],
              ],
            );
          },
        ),
      ],
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

class _DmOrderUi {
  final String backendOrderId;
  final String orderIdDisplay;
  final String customerName;
  final String date;
  final String time;
  final int itemCount;
  final List<_OrderItem> items;
  final String assignedTo;
  final String orderType;
  final String buttonText;
  final bool isVerifyButton;

  const _DmOrderUi({
    required this.backendOrderId,
    required this.orderIdDisplay,
    required this.customerName,
    required this.date,
    required this.time,
    required this.itemCount,
    required this.items,
    required this.assignedTo,
    required this.orderType,
    required this.buttonText,
    required this.isVerifyButton,
  });
}

class _OrderCard extends StatefulWidget {
  final String backendOrderId;
  final String orderId;
  final String customerName;
  final String date;
  final String time;
  final int itemCount;
  final String assignedTo;
  final String orderType;
  final String buttonText;
  final List<_OrderItem> items;
  final bool isExpanded;
  final bool isVerifyButton;
  final Future<void> Function(String orderId)? onVerify;
  final VoidCallback? onAssigned;
  final Future<void> Function(String orderId)? onSubmitToCustomer;

  const _OrderCard({
    required this.backendOrderId,
    required this.orderId,
    required this.customerName,
    required this.date,
    required this.time,
    required this.itemCount,
    required this.assignedTo,
    required this.orderType,
    required this.buttonText,
    required this.items,
    this.isExpanded = false,
    required this.isVerifyButton,
    this.onVerify,
    this.onAssigned,
    this.onSubmitToCustomer,
  });

  @override
  State<_OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends State<_OrderCard> {
  late bool _isExpanded;
  bool _isVerifying = false;

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
          // Assigned To
          Row(
            children: [
              Icon(
                Icons.check_box_outlined,
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
          const SizedBox(height: 16),
          // Action Button
          SizedBox(
            width: double.infinity,
            height: 48,
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
                borderRadius: BorderRadius.circular(18),
              ),
              child: TextButton(
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                onPressed: () async {
                  if (!widget.isVerifyButton) {
                    final normalized = widget.assignedTo.trim();
                    final alreadyAssigned = normalized.isNotEmpty && normalized != '—';
                    if (alreadyAssigned) return;

                    if (widget.orderType == 'pickup_only') {
                      final handler = widget.onSubmitToCustomer;
                      if (handler == null) return;
                      await handler(widget.backendOrderId);
                      return;
                    }

                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DistributionDeliveryPartnersScreen(orderId: widget.backendOrderId),
                      ),
                    );
                    if (!mounted) return;
                    if (result == true) widget.onAssigned?.call();
                  } else {
                    final handler = widget.onVerify;
                    if (handler == null) return;
                    if (_isVerifying) return;
                    setState(() {
                      _isVerifying = true;
                    });
                    handler(widget.backendOrderId).whenComplete(() {
                      if (mounted) {
                        setState(() {
                          _isVerifying = false;
                        });
                      }
                    });
                  }
                },
                child: _isVerifying
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        (!widget.isVerifyButton && widget.assignedTo.trim().isNotEmpty && widget.assignedTo.trim() != '—')
                            ? 'Assigned: ${widget.assignedTo}'
                            : widget.buttonText,
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

class _DistributionManagerBottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;

  const _DistributionManagerBottomNavBar({
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
                              icon: Icons.home_rounded,
                              label: 'Home',
                              isSelected: selectedIndex == 0,
                              onTap: () => onTabSelected(0),
                            ),
                          ),
                          Expanded(
                            child: _NavTab(
                              icon: Icons.local_shipping_rounded,
                              label: 'Dispatch',
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
            const SizedBox(height: 2),
          ],
        ),
      ),
    );
  }
}


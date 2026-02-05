import 'package:flutter/material.dart';

import '../../../../theme/app_colors.dart';
import '../../../../theme/app_text_styles.dart';
import '../../../../routes/app_routes.dart';
import '../../../../utils/auth_storage.dart';
import '../../../../utils/role_manager.dart';
import '../../../../services/collection_manager_orders_service.dart';
import '../../../common/widgets/bottom_nav_bar.dart';
import '../../../common/widgets/success_popup.dart';
import 'delivery_partners_screen.dart';
import 'history_screen.dart';

class CollectionManagerHomeScreen extends StatefulWidget {
  const CollectionManagerHomeScreen({super.key});

  @override
  State<CollectionManagerHomeScreen> createState() => _CollectionManagerHomeScreenState();
}

class _CollectionManagerHomeScreenState extends State<CollectionManagerHomeScreen> {
  int _selectedTabIndex = 0; // 0: New Orders, 1: Received

  final CollectionManagerOrdersService _ordersService = CollectionManagerOrdersService();
  Future<List<_IncomingOrderUi>> _incomingOrdersFuture = Future.value(const <_IncomingOrderUi>[]);
  Future<List<_ReceivedOrderUi>> _receivedOrdersFuture = Future.value(const <_ReceivedOrderUi>[]);
  Future<Map<String, dynamic>?> _userFuture = AuthStorage.getCurrentUser();

  @override
  void initState() {
    super.initState();
    _incomingOrdersFuture = _fetchIncomingOrdersWithItems(page: 1, limit: 20);
    _receivedOrdersFuture = _fetchReceivedOrdersWithItems(page: 1, limit: 20);
    _userFuture = AuthStorage.getCurrentUser();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Auto-refresh received orders when navigating to received tab
    if (_selectedTabIndex == 1) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _refreshReceived();
      });
    }
  }

  Future<void> _refreshIncoming() async {
    setState(() {
      _incomingOrdersFuture = _fetchIncomingOrdersWithItems(page: 1, limit: 20);
      _userFuture = AuthStorage.getCurrentUser();
    });
    await _incomingOrdersFuture;
  }

  Future<void> _refreshReceived() async {
    setState(() {
      _receivedOrdersFuture = _fetchReceivedOrdersWithItems(page: 1, limit: 20);
      _userFuture = AuthStorage.getCurrentUser();
    });
    await _receivedOrdersFuture;
  }

  Future<List<_ReceivedOrderUi>> _fetchReceivedOrdersWithItems({
    required int page,
    required int limit,
  }) async {
    final body = await _ordersService.listReceivedOrders(page: page, limit: limit);
    final data = body['data'];
    if (data is! List) {
      throw Exception('Invalid response: missing data list');
    }

    // Safety: Received screen should only show "received_by_collection" status.
    final orders = data
        .whereType<Map>()
        .map((m) => m.cast<String, dynamic>())
        .where((o) => (o['orderStatus'] ?? '').toString() == 'received_by_collection')
        .toList()
      ..sort((a, b) {
        final adt = _parseCreatedAt(a);
        final bdt = _parseCreatedAt(b);
        if (adt == null && bdt == null) return 0;
        if (adt == null) return 1;
        if (bdt == null) return -1;
        return bdt.compareTo(adt);
      });

    Future<_ReceivedOrderUi> mapOne(Map<String, dynamic> o) async {
      final orderId = (o['orderId'] ?? '').toString();
      final createdAtRaw = o['createdAt'];
      final createdAt = (createdAtRaw is String && createdAtRaw.isNotEmpty)
          ? DateTime.tryParse(createdAtRaw)
          : null;

      final customer = o['customer'];
      final customerName = (customer is Map ? customer['fullName'] : null)?.toString() ?? 'Customer';

      // Extract delivery boy information from pickup delivery
      final pickupDelivery = o['pickupDelivery'];
      final deliveryStaff = (pickupDelivery is Map ? pickupDelivery['deliveryStaff'] : null);
      final deliveryPersonRaw = (deliveryStaff is Map ? deliveryStaff['fullName'] : null);
      final deliveryPerson = (deliveryPersonRaw != null) ? deliveryPersonRaw.toString().trim() : '—';
      final deliveryPersonIdRaw = (deliveryStaff is Map ? deliveryStaff['staffId'] : null);
      final deliveryPersonId = (deliveryPersonIdRaw != null) ? deliveryPersonIdRaw.toString().trim() : '';

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

      return _ReceivedOrderUi(
        backendOrderId: orderId,
        orderIdDisplay: _formatOrderId(orderId),
        customerName: customerName,
        date: _formatDate(createdAt),
        time: _formatTime(createdAt),
        itemCount: itemCount,
        items: items,
        deliveryPerson: deliveryPerson,
        deliveryPersonId: deliveryPersonId,
      );
    }

    return Future.wait(orders.map(mapOne));
  }

  Future<void> _markReceivedAndRefresh(String orderId) async {
    try {
      // Step 1: Mark order as verified & received
      await _ordersService.markOrderReceived(orderId: orderId);

      if (!mounted) return;

      // Refresh both incoming and received lists so the order moves
      // from the incoming list into the received list.
      await Future.wait([_refreshIncoming(), _refreshReceived()]);

      // Step 2: Generate invoice (best-effort). Even if invoice generation fails
      // (e.g. kg-weights missing), we still want the order to move to Received.
      try {
        await _ordersService.generateInvoice(orderId: orderId);
        if (!mounted) return;
        showSuccessPopup(context, message: 'Order received and invoice generated ✓');
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Order received. Invoice not generated: ${e.toString().replaceFirst('Exception: ', '').trim()}',
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '').trim())),
      );
    }
  }

  Future<void> _handleUpdateWeights(BuildContext ctx, String orderId) async {
    final completed = await _showWeightDialog(ctx, orderId);
    if (completed && mounted) _refreshIncoming();
  }

  Future<void> _handleVerifiedAndReceived(
    BuildContext ctx,
    String orderId,
    bool isPerKg,
    bool perKgWeightsComplete,
  ) async {
    if (isPerKg && !perKgWeightsComplete) {
      final completed = await _showWeightDialog(ctx, orderId);
      if (!completed || !mounted) return;
    }
    await _markReceivedAndRefresh(orderId);
  }

  Future<bool> _showWeightDialog(BuildContext ctx, String orderId) async {
    List<Map<String, dynamic>>? perKgItems;
    try {
      final body = await _ordersService.getPerKgItems(orderId: orderId);
      final data = body['data'];
      if (data is Map) {
        final items = data['perKgItems'];
        if (items is List && items.isNotEmpty) {
          perKgItems = items.whereType<Map>().map((m) => m.cast<String, dynamic>()).toList();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(content: Text('Failed to load items: ${e.toString().replaceFirst('Exception: ', '')}')),
        );
      }
      return false;
    }

    if (perKgItems == null || perKgItems.isEmpty) {
      // No per_kg items - proceed without weight dialog
      return true;
    }

    final Map<String, TextEditingController> weightControllers = {};
    for (final item in perKgItems) {
      final itemId = (item['orderItemId'] ?? '').toString();
      final currentWeight = item['weightKg'];
      final weightStr = (currentWeight is num)
          ? currentWeight.toString()
          : (currentWeight?.toString() ?? '');
      weightControllers[itemId] = TextEditingController(text: weightStr);
    }

    final result = await showDialog<bool>(
      context: ctx,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              backgroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(ctx).size.height * 0.7,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Enter Weights (kg)',
                              style: AppTextStyles.header(color: AppColors.textPrimary),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close),
                              splashRadius: 20,
                              onPressed: () => Navigator.of(dialogContext).pop(false),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Enter weight for each per-kg item before marking as received.',
                          style: AppTextStyles.subtitle(color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 18),
                        ...perKgItems!.map((item) {
                          final itemId = (item['orderItemId'] ?? '').toString();
                          final serviceName = (item['serviceName'] ?? 'Item').toString();
                          final categoryName = (item['categoryName'] ?? '').toString();
                          final itemName =
                              categoryName.isNotEmpty ? '$categoryName • $serviceName' : serviceName;
                          final controller = weightControllers[itemId] ?? TextEditingController();

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  itemName,
                                  style: AppTextStyles.body(color: AppColors.textPrimary)
                                      .copyWith(fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 6),
                                TextField(
                                  controller: controller,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  decoration: InputDecoration(
                                    hintText: 'Enter weight in kg',
                                    filled: true,
                                    fillColor: AppColors.background,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(18),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: StatefulBuilder(
                            builder: (context, setInnerState) {
                              bool isSaving = false;

                              Future<void> handleSave() async {
                                if (isSaving) return;
                                setInnerState(() => isSaving = true);

                                bool allValid = true;
                                final itemsToUpdate = <Map<String, dynamic>>[];

                                for (final item in perKgItems!) {
                                  final itemId = (item['orderItemId'] ?? '').toString();
                                  final controller = weightControllers[itemId];
                                  final weightStr = controller?.text.trim() ?? '';
                                  final weight = double.tryParse(weightStr);

                                  if (weight == null || weight <= 0) {
                                    allValid = false;
                                    break;
                                  }
                                  itemsToUpdate.add({
                                    'orderItemId': itemId,
                                    'weightKg': weight,
                                  });
                                }

                                if (!allValid || itemsToUpdate.isEmpty) {
                                  if (ctx.mounted) {
                                    ScaffoldMessenger.of(ctx).showSnackBar(
                                      const SnackBar(
                                        content: Text('Please enter valid weights for all items'),
                                      ),
                                    );
                                  }
                                  setInnerState(() => isSaving = false);
                                  return;
                                }

                                try {
                                  await _ordersService.updatePerKgWeights(
                                    orderId: orderId,
                                    items: itemsToUpdate,
                                  );
                                  if (ctx.mounted) {
                                    ScaffoldMessenger.of(ctx).showSnackBar(
                                      const SnackBar(
                                        content: Text('Weights saved successfully'),
                                      ),
                                    );
                                  }
                                  Navigator.of(dialogContext).pop(true);
                                } catch (e) {
                                  if (ctx.mounted) {
                                    ScaffoldMessenger.of(ctx).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          e.toString().replaceFirst('Exception: ', ''),
                                        ),
                                      ),
                                    );
                                  }
                                } finally {
                                  if (ctx.mounted) {
                                    setInnerState(() => isSaving = false);
                                  }
                                }
                              }

                              return ElevatedButton(
                                onPressed: isSaving ? null : handleSave,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  disabledBackgroundColor: AppColors.primary.withOpacity(0.7),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                ),
                                child: isSaving
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(Colors.white),
                                        ),
                                      )
                                    : Text(
                                        'Save Weights & Continue',
                                        style: AppTextStyles.button(color: Colors.white),
                                      ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    return result ?? false;
  }

  Future<void> _submitToServicesAndRefresh(String orderId) async {
    try {
      await _ordersService.submitToServices(orderId: orderId);
      if (!mounted) return;
      showSuccessPopup(context, message: 'Order submitted to service men ✓');
      await _refreshReceived();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '').trim())),
      );
    }
  }

  Future<void> _generateInvoiceAndRefresh(String orderId) async {
    try {
      await _ordersService.generateInvoice(orderId: orderId);
      if (!mounted) return;
      showSuccessPopup(context, message: 'Invoice generated successfully ✓');
      await _refreshReceived();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '').trim())),
      );
    }
  }

  Future<List<_IncomingOrderUi>> _fetchIncomingOrdersWithItems({
    required int page,
    required int limit,
  }) async {
    final body = await _ordersService.listIncomingOrders(page: page, limit: limit);
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
        return bdt.compareTo(adt); // descending time-wise
      });

    Future<_IncomingOrderUi> mapOne(Map<String, dynamic> o) async {
      final orderId = (o['orderId'] ?? '').toString();
      final createdAtRaw = o['createdAt'];
      final createdAt = (createdAtRaw is String && createdAtRaw.isNotEmpty)
          ? DateTime.tryParse(createdAtRaw)
          : null;

      final customer = o['customer'];
      final customerName = (customer is Map ? customer['fullName'] : null)?.toString() ?? 'Customer';

      final pickupDelivery = o['pickupDelivery'];
      final deliveryStaff = (pickupDelivery is Map ? pickupDelivery['deliveryStaff'] : null);
      final isAssigned = deliveryStaff is Map;
      final deliveryPerson = isAssigned ? (deliveryStaff['fullName']?.toString() ?? 'Staff') : null;
      final deliveryPersonId = isAssigned ? (deliveryStaff['staffId']?.toString() ?? '') : null;

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
          // keep empty items; list should still render
        }
      }

      final orderType = (o['orderType'] ?? '').toString().trim();
      final pricingModel = (o['pricingModel'] ?? '').toString().trim().toLowerCase();
      final perKgWeightsComplete = o['perKgWeightsComplete'] == true;

      return _IncomingOrderUi(
        backendOrderId: orderId,
        orderIdDisplay: _formatOrderId(orderId),
        customerName: customerName,
        date: _formatDate(createdAt),
        time: _formatTime(createdAt),
        itemCount: itemCount,
        isAssigned: isAssigned,
        deliveryPerson: deliveryPerson,
        deliveryPersonId: deliveryPersonId,
        items: items,
        orderType: orderType,
        pricingModel: pricingModel,
        perKgWeightsComplete: perKgWeightsComplete,
      );
    }

    return Future.wait(orders.map(mapOne));
  }

  static DateTime? _parseCreatedAt(Map<String, dynamic> o) {
    final raw = o['createdAt'];
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
    final perPieceItems = <_OrderItem>[];
    final perKgItems = <_OrderItem>[];
    final perPieceAggregated = <String, int>{};
    final perKgAggregated = <String, int>{};

    if (itemsData is Map) {
      final map = itemsData.cast<String, dynamic>();
      final list = map['items'];
      if (list is List) {
        for (final rawItem in list) {
          if (rawItem is! Map) continue;
          final item = rawItem.cast<String, dynamic>();
          final pricingType = (item['pricingType'] ?? '').toString().trim().toLowerCase();
          final serviceName = (item['serviceName'] ?? '').toString().trim();
          final categoryName = (item['categoryName'] ?? '').toString().trim();
          final key = _formatServiceKey(categoryName, serviceName);

          int qty = 0;
          final selections = item['selections'];
          if (selections is List && selections.isNotEmpty) {
            // For per_piece orders we still aggregate by service, but count total pieces in that service.
            for (final rawSel in selections) {
              if (rawSel is! Map) continue;
              final sel = rawSel.cast<String, dynamic>();
              final qtyNum = sel['quantity'];
              final q = (qtyNum is num) ? qtyNum.toInt() : int.tryParse(qtyNum?.toString() ?? '') ?? 0;
              if (q > 0) qty += q;
            }
          } else {
            // Fallback for per_kg / service-level items
            final qtyNum = item['quantity'];
            qty = (qtyNum is num) ? qtyNum.toInt() : int.tryParse(qtyNum?.toString() ?? '') ?? 0;
          }

          if (key.isEmpty || qty <= 0) continue;

          // Categorize by pricing type
          if (pricingType == 'per_kg' || pricingType == 'per-kg') {
            perKgAggregated[key] = (perKgAggregated[key] ?? 0) + qty;
          } else {
            // Default to per_piece
            perPieceAggregated[key] = (perPieceAggregated[key] ?? 0) + qty;
          }
        }
      }
    }

    // Sort and add per-piece items
    final perPieceEntries = perPieceAggregated.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    for (final e in perPieceEntries) {
      perPieceItems.add(_OrderItem(name: e.key, quantity: e.value, pricingType: 'per_piece'));
    }

    // Sort and add per-kg items
    final perKgEntries = perKgAggregated.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    for (final e in perKgEntries) {
      perKgItems.add(_OrderItem(name: e.key, quantity: e.value, pricingType: 'per_kg'));
    }

    // Combine items: per-piece first, then per-kg
    final items = <_OrderItem>[...perPieceItems, ...perKgItems];
    final total = perPieceItems.fold<int>(0, (sum, item) => sum + item.quantity) +
        perKgItems.fold<int>(0, (sum, item) => sum + item.quantity);

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
                          builder: (context) => const HistoryScreen(),
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
            // Orders List
            Expanded(
              child: _selectedTabIndex == 0
                  ? _buildNewOrdersList()
                  : _buildReceivedOrdersList(),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _CollectionManagerBottomNavBar(
        selectedIndex: _selectedTabIndex,
        onTabSelected: (index) {
          setState(() {
            _selectedTabIndex = index;
          });
        },
      ),
    );
  }

  Widget _buildNewOrdersList() {
    return RefreshIndicator(
      onRefresh: _refreshIncoming,
      color: AppColors.primary,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          // Incoming orders list from backend (sorted by createdAt desc)
          FutureBuilder<List<_IncomingOrderUi>>(
            future: _incomingOrdersFuture,
            builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Column(
                    children: [
                      const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Loading incoming orders...',
                        style: AppTextStyles.subtitle(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              );
            }

            if (snapshot.hasError) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.divider.withOpacity(0.4)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: AppColors.error, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          snapshot.error.toString().replaceFirst('Exception: ', ''),
                          style: AppTextStyles.subtitle(color: AppColors.textSecondary),
                        ),
                      ),
                      TextButton(
                        onPressed: _refreshIncoming,
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

            // Show cached data while loading new data
            final list = snapshot.data ?? const <_IncomingOrderUi>[];
            
            if (snapshot.connectionState == ConnectionState.waiting && list.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Column(
                    children: [
                      const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Loading incoming orders...',
                        style: AppTextStyles.subtitle(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              );
            }

            if (list.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 18),
                child: Center(
                  child: Text(
                    'No incoming orders',
                    style: AppTextStyles.subtitle(color: AppColors.textSecondary),
                  ),
                ),
              );
            }

            return Column(
              children: [
                for (final o in list) ...[
                  _NewOrderCard(
                    backendOrderId: o.backendOrderId,
                    orderId: o.orderIdDisplay,
                    customerName: o.customerName,
                    date: o.date,
                    time: o.time,
                    itemCount: o.itemCount,
                    isAssigned: o.isAssigned,
                    isDeliveryOnly: o.isDeliveryOnly,
                    isPerKg: o.isPerKg,
                    perKgWeightsComplete: o.perKgWeightsComplete,
                    deliveryPerson: o.deliveryPerson,
                    deliveryPersonId: o.deliveryPersonId,
                    items: o.items,
                    onUpdateWeights: _handleUpdateWeights,
                    onVerifiedAndReceived: _handleVerifiedAndReceived,
                    onAssigned: _refreshIncoming,
                  ),
                  const SizedBox(height: 12),
                ],
              ],
            );
          },
        ),
      ],
    ),
    );
  }

  Widget _buildReceivedOrdersList() {
    return RefreshIndicator(
      onRefresh: _refreshReceived,
      color: AppColors.primary,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          FutureBuilder<List<_ReceivedOrderUi>>(
            future: _receivedOrdersFuture,
            builder: (context, snapshot) {
              // Show cached data while loading new data
              final list = snapshot.data ?? const <_ReceivedOrderUi>[];
              
              if (snapshot.connectionState == ConnectionState.waiting && list.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Column(
                      children: [
                        const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Loading received orders...',
                          style: AppTextStyles.subtitle(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                );
              }

              if (snapshot.hasError) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.divider.withOpacity(0.4)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: AppColors.error, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            snapshot.error.toString().replaceFirst('Exception: ', ''),
                            style: AppTextStyles.subtitle(color: AppColors.textSecondary),
                          ),
                        ),
                        TextButton(
                          onPressed: _refreshReceived,
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

            if (list.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 18),
                child: Center(
                  child: Text(
                    'No received orders',
                    style: AppTextStyles.subtitle(color: AppColors.textSecondary),
                  ),
                ),
              );
            }

            return Column(
              children: [
                for (final o in list) ...[
                  _ReceivedOrderCard(
                    backendOrderId: o.backendOrderId,
                    orderId: o.orderIdDisplay,
                    customerName: o.customerName,
                    date: o.date,
                    time: o.time,
                    itemCount: o.itemCount,
                    deliveryPerson: o.deliveryPerson,
                    deliveryPersonId: o.deliveryPersonId,
                    items: o.items,
                    onSubmitToServices: _submitToServicesAndRefresh,
                    onGenerateInvoice: _generateInvoiceAndRefresh,
                  ),
                  const SizedBox(height: 12),
                ],
              ],
            );
          },
        ),
      ],
    ),
    );
  }
}

class _OrderItem {
  final String name;
  final int quantity;
  final String pricingType; // 'per_piece' or 'per_kg'

  const _OrderItem({
    required this.name,
    required this.quantity,
    this.pricingType = 'per_piece',
  });
}

class _ItemsUiMapping {
  final List<_OrderItem> items;
  final int totalCount;

  const _ItemsUiMapping({required this.items, required this.totalCount});
}

class _IncomingOrderUi {
  final String backendOrderId;
  final String orderIdDisplay;
  final String customerName;
  final String date;
  final String time;
  final int itemCount;
  final bool isAssigned;
  final String? deliveryPerson;
  final String? deliveryPersonId;
  final List<_OrderItem> items;
  final String orderType;
  final String pricingModel;
  final bool perKgWeightsComplete;

  const _IncomingOrderUi({
    required this.backendOrderId,
    required this.orderIdDisplay,
    required this.customerName,
    required this.date,
    required this.time,
    required this.itemCount,
    required this.isAssigned,
    required this.deliveryPerson,
    required this.deliveryPersonId,
    required this.items,
    this.orderType = '',
    this.pricingModel = '',
    this.perKgWeightsComplete = true,
  });

  bool get isDeliveryOnly =>
      orderType == 'drop_only' || orderType == 'delivery_only';

  bool get isPerKg => pricingModel == 'per_kg';
}

class _ReceivedOrderUi {
  final String backendOrderId;
  final String orderIdDisplay;
  final String customerName;
  final String date;
  final String time;
  final int itemCount;
  final List<_OrderItem> items;
  final String deliveryPerson;
  final String deliveryPersonId;

  const _ReceivedOrderUi({
    required this.backendOrderId,
    required this.orderIdDisplay,
    required this.customerName,
    required this.date,
    required this.time,
    required this.itemCount,
    required this.items,
    this.deliveryPerson = '—',
    this.deliveryPersonId = '',
  });
}

class _NewOrderCard extends StatefulWidget {
  final String backendOrderId;
  final String orderId;
  final String customerName;
  final String date;
  final String time;
  final int itemCount;
  final bool isAssigned;
  final bool isDeliveryOnly;
  final bool isPerKg;
  final bool perKgWeightsComplete;
  final String? deliveryPerson;
  final String? deliveryPersonId;
  final List<_OrderItem> items;
  final bool isExpanded;
  final Future<void> Function(BuildContext context, String orderId)? onUpdateWeights;
  final Future<void> Function(BuildContext context, String orderId, bool isPerKg, bool perKgWeightsComplete)? onVerifiedAndReceived;
  final VoidCallback? onAssigned;

  const _NewOrderCard({
    required this.backendOrderId,
    required this.orderId,
    required this.customerName,
    required this.date,
    required this.time,
    required this.itemCount,
    required this.isAssigned,
    this.isDeliveryOnly = false,
    this.isPerKg = false,
    this.perKgWeightsComplete = true,
    this.deliveryPerson,
    this.deliveryPersonId,
    required this.items,
    this.isExpanded = false,
    this.onUpdateWeights,
    this.onVerifiedAndReceived,
    this.onAssigned,
  });

  @override
  State<_NewOrderCard> createState() => _NewOrderCardState();
}

List<Widget> _buildCategorizedItemsList(List<_OrderItem> items) {
  final perPieceItems = items.where((item) => item.pricingType == 'per_piece').toList();
  final perKgItems = items.where((item) => item.pricingType == 'per_kg').toList();

  final widgets = <Widget>[];

  // Per-Piece Section
  if (perPieceItems.isNotEmpty) {
    widgets.add(
      Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.primary.withOpacity(0.3)),
              ),
              child: Text(
                'Per Piece',
                style: AppTextStyles.subtitle(color: AppColors.primary).copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
    widgets.addAll(perPieceItems.map((item) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  item.name,
                  style: AppTextStyles.subtitle(color: AppColors.textPrimary).copyWith(
                    fontSize: 13,
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
                item.quantity.toString().padLeft(2, '0'),
                style: AppTextStyles.subtitle(color: AppColors.textPrimary).copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        )));
  }

  // Per-Kg Section
  if (perKgItems.isNotEmpty) {
    if (perPieceItems.isNotEmpty) {
      widgets.add(const SizedBox(height: 8));
    }
    widgets.add(
      Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
              ),
              child: Text(
                'Per Kg',
                style: AppTextStyles.subtitle(color: const Color(0xFF10B981)).copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
    widgets.addAll(perKgItems.map((item) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: Color(0xFF10B981),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  item.name,
                  style: AppTextStyles.subtitle(color: AppColors.textPrimary).copyWith(
                    fontSize: 13,
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
                item.quantity.toString().padLeft(2, '0'),
                style: AppTextStyles.subtitle(color: AppColors.textPrimary).copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        )));
  }

  return widgets;
}

class _NewOrderCardState extends State<_NewOrderCard> {
  late bool _isExpanded;
  bool _isMarkingReceived = false;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.isExpanded;
  }

  @override
  Widget build(BuildContext context) {
    final orderIdColor = widget.isAssigned ? AppColors.primary : AppColors.error;
    final itemCountColor = widget.isAssigned ? AppColors.primary : AppColors.error;

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
                  color: orderIdColor,
                ).copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    widget.itemCount.toString().padLeft(2, '0'),
                    style: AppTextStyles.largeNumber(
                      color: itemCountColor,
                    ),
                  ),
                  Text(
                    'items',
                    style: AppTextStyles.subtitle(
                      color: itemCountColor,
                    ),
                  ),
                ],
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
          // Delivery Status
          Row(
            children: [
              Icon(
                Icons.person_outline,
                size: 14,
                color: widget.isAssigned ? AppColors.textSecondary : AppColors.error,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  widget.isAssigned
                      ? 'Assigned: ${widget.deliveryPerson} (${widget.deliveryPersonId})'
                      : 'Not assigned',
                  style: AppTextStyles.subtitle(
                    color: widget.isAssigned ? AppColors.textSecondary : AppColors.error,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Action Buttons: For delivery_only orders, no pickup.
          // For delivery_only + per_kg: step 1 = Update Weights, step 2 = Verified & Received.
          // For pickup orders: show Assign Delivery when not assigned, else Verified & Received.
          if (!widget.isAssigned && !widget.isDeliveryOnly)
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton(
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DeliveryPartnersScreen(orderId: widget.backendOrderId),
                    ),
                  );
                  if (!mounted) return;
                  if (result == true) widget.onAssigned?.call();
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: BorderSide(color: AppColors.primary, width: 1.4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: Text(
                  'Assign Delivery Partner',
                  style: AppTextStyles.button(
                    color: AppColors.primary,
                  ).copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            )
          else
            Column(
              children: [
                if (!widget.isDeliveryOnly)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Assigned: ${widget.deliveryPerson ?? 'Staff'}',
                      style: AppTextStyles.subtitle(color: AppColors.success).copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  )
                else
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Drop-off / delivery only (no pickup)',
                      style: AppTextStyles.subtitle(color: AppColors.textSecondary).copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: Builder(
                          builder: (context) {
                            final showUpdateWeights = widget.isDeliveryOnly &&
                                widget.isPerKg &&
                                !widget.perKgWeightsComplete;
                            final buttonLabel =
                                showUpdateWeights ? 'Update Weights' : 'Verified & Received';
                            return DecoratedBox(
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
                                onPressed: _isMarkingReceived
                                    ? null
                                    : () async {
                                        if (showUpdateWeights) {
                                          final handler = widget.onUpdateWeights;
                                          if (handler == null) return;
                                          setState(() => _isMarkingReceived = true);
                                          try {
                                            await handler(context, widget.backendOrderId);
                                          } finally {
                                            if (mounted) {
                                              setState(() => _isMarkingReceived = false);
                                            }
                                          }
                                        } else {
                                          final handler = widget.onVerifiedAndReceived;
                                          if (handler == null) return;
                                          setState(() => _isMarkingReceived = true);
                                          try {
                                            await handler(
                                              context,
                                              widget.backendOrderId,
                                              widget.isPerKg,
                                              widget.perKgWeightsComplete,
                                            );
                                          } finally {
                                            if (mounted) {
                                              setState(() => _isMarkingReceived = false);
                                            }
                                          }
                                        }
                                      },
                                child: _isMarkingReceived
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(Colors.white),
                                        ),
                                      )
                                    : Text(
                                        buttonLabel,
                                        style: AppTextStyles.button(
                                          color: Colors.white,
                                        ).copyWith(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: AppColors.primary,
                          width: 1.4,
                        ),
                      ),
                      child: IconButton(
                        onPressed: () {
                          // Handle phone call
                        },
                        icon: Icon(
                          Icons.phone,
                          color: AppColors.primary,
                          size: 20,
                        ),
                        splashRadius: 20,
                      ),
                    ),
                  ],
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
            // Items List - Categorized by Pricing Type
            ..._buildCategorizedItemsList(widget.items),
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

class _ReceivedOrderCard extends StatefulWidget {
  final String backendOrderId;
  final String orderId;
  final String customerName;
  final String date;
  final String time;
  final int itemCount;
  final String deliveryPerson;
  final String deliveryPersonId;
  final List<_OrderItem> items;
  final bool isExpanded;
  final Future<void> Function(String orderId)? onSubmitToServices;
  final Future<void> Function(String orderId)? onGenerateInvoice;

  const _ReceivedOrderCard({
    required this.backendOrderId,
    required this.orderId,
    required this.customerName,
    required this.date,
    required this.time,
    required this.itemCount,
    required this.deliveryPerson,
    required this.deliveryPersonId,
    required this.items,
    this.isExpanded = false,
    this.onSubmitToServices,
    this.onGenerateInvoice,
  });

  @override
  State<_ReceivedOrderCard> createState() => _ReceivedOrderCardState();
}

class _ReceivedOrderCardState extends State<_ReceivedOrderCard> {
  late bool _isExpanded;
  bool _isSubmittingToServices = false;
  bool _isGeneratingInvoice = false;

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
                    'items',
                    style: AppTextStyles.subtitle(
                      color: AppColors.primary,
                    ),
                  ),
                ],
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
          // Delivery Information
          Row(
            children: [
              Icon(
                Icons.person_outline,
                size: 14,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                'Delivered by : ${widget.deliveryPerson}',
                style: AppTextStyles.subtitle(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Generate Invoice Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.primary, width: 1.2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              onPressed: _isGeneratingInvoice
                  ? null
                  : () async {
                      final handler = widget.onGenerateInvoice;
                      if (handler == null) return;
                      setState(() {
                        _isGeneratingInvoice = true;
                      });
                      try {
                        await handler(widget.backendOrderId);
                      } finally {
                        if (mounted) {
                          setState(() {
                            _isGeneratingInvoice = false;
                          });
                        }
                      }
                    },
              child: _isGeneratingInvoice
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      'Generate Invoice',
                      style: AppTextStyles.button(color: AppColors.primary).copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 12),
          // Assign to Service Man Button
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
                onPressed: _isSubmittingToServices
                    ? null
                    : () async {
                        final handler = widget.onSubmitToServices;
                        if (handler == null) return;
                        setState(() {
                          _isSubmittingToServices = true;
                        });
                        try {
                          await handler(widget.backendOrderId);
                        } finally {
                          if (mounted) {
                            setState(() {
                              _isSubmittingToServices = false;
                            });
                          }
                        }
                      },
                child: _isSubmittingToServices
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        'Assign to Service Man',
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
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                ),
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
            ),
          ],
          if (_isExpanded) ...[
            const SizedBox(height: 16),
            // Items List - Categorized by Pricing Type
            ..._buildCategorizedItemsList(widget.items),
            const SizedBox(height: 12),
            // Items list footer with upward chevrons
            InkWell(
              onTap: () {
                setState(() {
                  _isExpanded = false;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                ),
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

class _CollectionManagerBottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;

  const _CollectionManagerBottomNavBar({
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
                              icon: Icons.access_time_rounded,
                              label: 'Received',
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


import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/order_record.dart';
import '../repositories/order_repository.dart';
import '../models/cart_item.dart';

class OrderProvider with ChangeNotifier {
  final List<OrderRecord> _orders = [];
  final OrderRepository _repo;
  bool _isLoading = false;
  String? _error;
  bool _isFetching = false; // Prevent concurrent fetches

  Timer? _reconcileDebounce;
  static const Duration _reconcileDebounceWindow = Duration(milliseconds: 500);

  OrderProvider({OrderRepository? repo}) : _repo = repo ?? OrderRepository();

  List<OrderRecord> get orders => List.unmodifiable(_orders);
  bool get isLoading => _isLoading;
  String? get error => _error;

  void addOrder(OrderRecord order) {
    _orders.insert(0, order);
    notifyListeners();
  }

  /// Apply Supabase Realtime payload to local orders list without fetching.
  /// Reduces egress by updating in-place from Realtime events instead of polling.
  void applyOrdersRealtimeChange({
    required String eventType,
    required Map<String, dynamic>? newRow,
    required Map<String, dynamic>? oldRow,
  }) {
    final type = eventType.toLowerCase();

    if (type == 'delete') {
      final orderId = _readString(oldRow, 'order_id');
      if (orderId.isNotEmpty) {
        _orders.removeWhere((o) => o.id == orderId);
        notifyListeners();
      }
      return;
    }

    // INSERT / UPDATE
    final row = newRow ?? const <String, dynamic>{};
    if (row.isEmpty) {
      _scheduleReconcile();
      return;
    }

    final orderId = _readString(row, 'order_id');
    if (orderId.isEmpty) return;

    final orderStatus = _readString(row, 'order_status');
    if (orderStatus.isEmpty && type == 'insert') {
      _scheduleReconcile();
      return;
    }

    final idx = _orders.indexWhere((o) => o.id == orderId);

    if (type == 'insert') {
      // New order - schedule debounced fetch to get full order with items
      _scheduleReconcile();
      return;
    }

    if (type == 'update' && idx >= 0) {
      // Update existing order in-place from payload (no fetch - reduces egress)
      final existing = _orders[idx];
      final newStatus = _mapOrderStatus(orderStatus);
      final totalAmountStr = _readString(row, 'total_amount');
      final parsedTotal = double.tryParse(totalAmountStr);
      final totalInr = parsedTotal != null ? parsedTotal.toInt() : null;

      final updated = existing.copyWith(
        status: newStatus,
        backendStatus:
            orderStatus.isEmpty ? existing.backendStatus : orderStatus,
        totalInr: totalInr,
      );
      _orders[idx] = updated;
      notifyListeners();
    }
  }

  String _readString(Map<String, dynamic>? map, String key) {
    final v = map?[key];
    return v == null ? '' : v.toString().trim();
  }

  void _scheduleReconcile() {
    _reconcileDebounce?.cancel();
    _reconcileDebounce = Timer(_reconcileDebounceWindow, () {
      fetchOrders(page: 1, limit: 10);
    });
  }

  @override
  void dispose() {
    _reconcileDebounce?.cancel();
    super.dispose();
  }

  void updateOrderSchedule(String orderId, String dateLabel, String timeLabel) {
    final index = _orders.indexWhere((o) => o.id == orderId);
    if (index >= 0) {
      _orders[index] = _orders[index].copyWith(
        dateLabel: dateLabel,
        timeLabel: timeLabel,
      );
      notifyListeners();
    }
  }

  void clear() {
    _orders.clear();
    notifyListeners();
  }

  Future<void> fetchOrders(
      {int page = 1, int limit = 10, String? status}) async {
    // Prevent concurrent fetches
    if (_isFetching) {
      debugPrint('Order fetch already in progress, skipping...');
      return;
    }

    _isFetching = true;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result =
          await _repo.getOrders(page: page, limit: limit, status: status);
      final ordersList = (result['orders'] as List?) ?? [];

      // Only clear orders if fetch was successful
      // This prevents clearing orders if there's a network issue or error
      final newOrders = <OrderRecord>[];
      for (final orderData in ordersList) {
        final order =
            _mapBackendOrderToOrderRecord(orderData as Map<String, dynamic>);
        if (order != null) {
          newOrders.add(order);
        }
      }

      // Store previous orders count for validation
      final hadPreviousOrders = _orders.isNotEmpty;

      // Only update orders list if we successfully fetched data
      // If we get an empty response but previously had orders, it might be a temporary backend issue
      // In that case, we'll keep the existing orders to prevent flickering "no orders" state
      // However, if we explicitly get an empty response and never had orders, that's valid
      if (newOrders.isNotEmpty || !hadPreviousOrders) {
        // Only clear if we have new orders OR if we never had orders before
        // This prevents clearing existing orders when backend returns empty due to timing issues
        _orders.clear();
        _orders.addAll(newOrders);
      } else {
        // If we had orders before but got empty response, log it but don't clear
        // This handles cases where backend might return empty temporarily
        debugPrint(
            'Received empty orders list but had previous orders. Keeping existing orders to prevent flickering.');
      }

      _error = null;
    } catch (e) {
      _error = e.toString();
      // Keep existing orders on error - don't clear them
      // This ensures UI doesn't show "no orders" when there's a network issue
      debugPrint('Error fetching orders: $e');
    } finally {
      _isLoading = false;
      _isFetching = false;
      notifyListeners();
    }
  }

  OrderRecord? _mapBackendOrderToOrderRecord(Map<String, dynamic> data) {
    try {
      final orderId = (data['order_id'] ?? '') as String;
      final orderType = (data['order_type'] ?? '') as String;
      final orderStatusRaw = (data['order_status'] ?? '') as String;
      // Default to "placed" if status is empty or null
      final orderStatus = orderStatusRaw.isEmpty ? 'placed' : orderStatusRaw;
      final createdAt = data['created_at'] as String?;
      final pickupDate = data['pickup_date'] as String?;
      final pickupTimeFrom = data['pickup_time_from'] as String?;
      final deliveryTimeFrom = data['delivery_time_from'] as String?;
      final pickupAddressMap = data['pickup_address'] as Map<String, dynamic>?;
      final totalAmount = (data['total_amount'] ?? '0') as String;
      final items = (data['items'] as List?) ?? [];
      final bill = data['bill'] as Map<String, dynamic>?;
      final billingStatus = (data['billing_status'] ?? '') as String;
      final billPaymentStatus =
          bill != null ? (bill['payment_status'] ?? '') as String : '';

      // Map order status
      final status = _mapOrderStatus(orderStatus);

      // Parse dates
      late final DateTime placedAt;
      String placedDateLabel = '';
      String placedTimeLabel = '';
      if (createdAt != null) {
        try {
          placedAt = DateTime.parse(createdAt).toLocal();
          placedDateLabel = _formatDateLabel(placedAt);
          placedTimeLabel = _formatTimeLabel(placedAt);
        } catch (_) {
          placedAt = DateTime.now();
          placedDateLabel = _formatDateLabel(placedAt);
          placedTimeLabel = _formatTimeLabel(placedAt);
        }
      } else {
        placedAt = DateTime.now();
        placedDateLabel = _formatDateLabel(placedAt);
        placedTimeLabel = _formatTimeLabel(placedAt);
      }

      // Parse schedule window:
      // Prefer pickup_time_from when available; fallback to pickup_date.
      String dateLabel = '';
      String timeLabel = '';
      DateTime? scheduleDt;
      final scheduleSource = pickupTimeFrom ?? pickupDate;
      if (scheduleSource != null) {
        try {
          scheduleDt = DateTime.parse(scheduleSource).toLocal();
          dateLabel = _formatDateLabel(scheduleDt);
          timeLabel = _formatTimeLabel(scheduleDt);
        } catch (_) {
          dateLabel = 'TBD';
          timeLabel = 'TBD';
        }
      } else {
        dateLabel = 'TBD';
        timeLabel = 'TBD';
      }

      // Parse delivery date/time (for "both" orders)
      String? deliveryDateLabel;
      String? deliveryTimeLabel;
      DateTime? scheduledDeliveryAt;
      if (orderType == 'both' && deliveryTimeFrom != null) {
        try {
          final deliveryDateTime = DateTime.parse(deliveryTimeFrom).toLocal();
          deliveryDateLabel = _formatDateLabel(deliveryDateTime);
          deliveryTimeLabel = _formatTimeLabel(deliveryDateTime);
          scheduledDeliveryAt = deliveryDateTime;
        } catch (_) {
          deliveryDateLabel = 'TBD';
          deliveryTimeLabel = 'TBD';
        }
      }

      // Map items to CartItems
      final cartItems = <CartItem>[];
      String? title;
      int totalItems = 0;

      for (final itemData in items) {
        final item = itemData as Map<String, dynamic>;
        final pricingType = (item['pricing_type'] ?? '') as String;
        final selections = (item['selections'] as List?) ?? [];
        final categoryName = selections.isNotEmpty
            ? (selections.first as Map<String, dynamic>)['category_name']
                as String?
            : null;

        if (categoryName != null && title == null) {
          title = categoryName;
        }

        if (pricingType == 'per_unit') {
          // Per-unit items
          final quantities = <String, int>{};
          final unitPrices = <String, int>{};

          for (final sel in selections) {
            final selection = sel as Map<String, dynamic>;
            final clothName = (selection['cloth_name'] ?? '') as String;
            final qty = (selection['quantity'] ?? 0) as int;

            // Aggregate quantities by cloth name
            quantities[clothName] = (quantities[clothName] ?? 0) + qty;
            totalItems += qty;

            // Extract per-unit price from backend (string or num)
            final priceRaw = selection['per_unit_price'];
            if (priceRaw != null) {
              int priceInr = 0;
              if (priceRaw is num) {
                priceInr = priceRaw.toInt();
              } else if (priceRaw is String) {
                priceInr = (double.tryParse(priceRaw) ?? 0).toInt();
              }
              if (priceInr > 0) {
                unitPrices[clothName] = priceInr;
              }
            }
          }

          if (quantities.isNotEmpty) {
            final serviceName = selections.isNotEmpty
                ? (selections.first as Map<String, dynamic>)['service_name']
                    as String?
                : 'Service';
            cartItems.add(
              CartItem(
                id: (item['item_id'] ?? '') as String,
                category: categoryName ?? 'Unknown',
                serviceName: serviceName ?? 'Service',
                quantities: quantities,
                unitPricesInr: unitPrices.isNotEmpty ? unitPrices : null,
                isPerPiece: true,
              ),
            );
          }
        } else {
          // Per-kg items - extract quantities from selections (similar to cart)
          final quantities = <String, int>{};
          final clothIdByItemName = <String, String>{};

          // Get service name and category from item level (fallback) or from selections
          final serviceNameFromItem = item['service_name'] as String?;
          final categoryNameFromItem = item['category_name'] as String?;

          // Extract service name and category from first selection (preferred)
          String? serviceName;
          String? finalCategoryName = categoryName;

          for (final sel in selections) {
            final selection = sel as Map<String, dynamic>;
            final clothName = (selection['cloth_name'] ?? '') as String;
            final qty = (selection['quantity'] ?? 0) as int;

            // Extract service name and category from first valid selection
            if (serviceName == null && clothName.isNotEmpty) {
              serviceName = selection['service_name'] as String?;
              finalCategoryName =
                  selection['category_name'] as String? ?? categoryName;
            }

            // Aggregate quantities by cloth name
            if (clothName.isNotEmpty && qty > 0) {
              quantities[clothName] = (quantities[clothName] ?? 0) + qty;
              totalItems += qty;
            }
          }

          // Use service name from selections first, then from item level, then fallback
          final finalServiceName =
              serviceName ?? serviceNameFromItem ?? 'Service';
          final finalCategory = finalCategoryName ??
              categoryNameFromItem ??
              categoryName ??
              'Unknown';

          // Always add the item, even if quantities are empty (for display purposes)
          // This ensures service name and category are shown
          cartItems.add(
            CartItem(
              id: (item['item_id'] ?? '') as String,
              category: finalCategory,
              serviceName: finalServiceName,
              quantities:
                  quantities, // Include quantities for kg-wise items to show cloth items
              clothIdByItemName: clothIdByItemName,
              isPerPiece: false,
              weightKg: (item['weight_kg'] as String?) != null
                  ? double.tryParse(item['weight_kg'] as String)
                  : null,
            ),
          );
          // If no quantities, count as 1 item
          if (quantities.isEmpty) {
            totalItems += 1;
          }
        }
      }

      // Map payment method
      PaymentMethod? paymentMethod;
      if (bill != null) {
        final paymentMethodStr = (bill['payment_method'] ?? '') as String;
        if (paymentMethodStr == 'cod') {
          paymentMethod = PaymentMethod.cod;
        } else if (paymentMethodStr.contains('visa') ||
            paymentMethodStr.contains('card')) {
          paymentMethod = PaymentMethod.visa;
        } else if (paymentMethodStr.contains('mastercard')) {
          paymentMethod = PaymentMethod.mastercard;
        }
      }

      // Calculate total amount
      final totalInr = (double.tryParse(totalAmount) ?? 0.0).toInt();

      // Pickup address (for tracking)
      String? pickupAddress;
      double? pickupLat;
      double? pickupLng;
      if (pickupAddressMap != null) {
        pickupAddress = (pickupAddressMap['full_address'] ?? '') as String;
        final lat = pickupAddressMap['latitude'];
        final lng = pickupAddressMap['longitude'];
        if (lat is num) pickupLat = lat.toDouble();
        if (lng is num) pickupLng = lng.toDouble();
      }

      // Derive a human-friendly title. If backend provided a title, use it;
      // otherwise show category/service or "Mixed" when multiple services exist.
      String computedTitle;
      if (title != null && title.trim().isNotEmpty) {
        computedTitle = title.trim();
      } else {
        final serviceNames = cartItems
            .map((c) => c.serviceName.trim())
            .where((s) => s.isNotEmpty)
            .toSet();
        final categories = cartItems
            .map((c) => c.category.trim())
            .where((s) => s.isNotEmpty)
            .toSet();
        final hasMultipleServices = serviceNames.length > 1;
        final hasMultipleCategories = categories.length > 1;

        if (hasMultipleServices || hasMultipleCategories) {
          computedTitle = 'Mixed';
        } else if (categories.isNotEmpty) {
          computedTitle = categories.first;
        } else if (serviceNames.isNotEmpty) {
          computedTitle = serviceNames.first;
        } else {
          computedTitle = 'Order';
        }
      }

      return OrderRecord(
        id: orderId,
        title: computedTitle,
        items: cartItems,
        totalItems: totalItems,
        totalInr: totalInr,
        orderType: orderType.isEmpty ? 'both' : orderType,
        dateLabel: dateLabel,
        timeLabel: timeLabel,
        deliveryDateLabel: deliveryDateLabel,
        deliveryTimeLabel: deliveryTimeLabel,
        scheduledPickupAt: scheduleDt,
        scheduledDeliveryAt: scheduledDeliveryAt,
        placedAt: placedAt,
        placedDateLabel: placedDateLabel,
        placedTimeLabel: placedTimeLabel,
        status: status,
        backendStatus: orderStatus, // Store original backend status string
        paymentMethod: paymentMethod,
        pickupAddress: pickupAddress,
        pickupLat: pickupLat,
        pickupLng: pickupLng,
        billingStatus: billingStatus.isEmpty ? null : billingStatus,
        billPaymentStatus: billPaymentStatus.isEmpty ? null : billPaymentStatus,
      );
    } catch (e) {
      debugPrint('Error mapping order: $e');
      return null;
    }
  }

  OrderStatus _mapOrderStatus(String status) {
    // Handle null or empty status
    if (status.isEmpty || status.toLowerCase() == 'null') {
      return OrderStatus.inProgress; // Default to inProgress for null/empty
    }

    switch (status.toLowerCase()) {
      // Active/In Progress statuses - these should show in active orders
      case 'placed':
      case 'pickup_assigned':
      case 'picked_up':
      case 'received_by_collection':
      case 'submitted_to_services':
      case 'services_in_progress':
      case 'services_completed':
      case 'dispatch_assigned':
      case 'out_for_delivery':
      case 'payment_pending':
        return OrderStatus.inProgress;

      // Completed/Delivered statuses - these should NOT show in active orders
      case 'delivered':
      case 'closed':
        return OrderStatus.delivered;

      // Cancelled status - should NOT show in active orders
      case 'cancelled':
        return OrderStatus
            .delivered; // Map to delivered so it's excluded from active orders

      // Draft status - not an active order yet
      case 'draft':
        return OrderStatus
            .inProgress; // Draft orders can be considered in progress

      // Unknown status - default to inProgress
      default:
        return OrderStatus.inProgress;
    }
  }

  String _formatDateLabel(DateTime date) {
    final d = date.toLocal();
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${months[d.month - 1]} ${d.day}';
  }

  String _formatTimeLabel(DateTime date) {
    final d = date.toLocal();
    final hour = d.hour > 12 ? d.hour - 12 : (d.hour == 0 ? 12 : d.hour);
    final minute = d.minute.toString().padLeft(2, '0');
    final amPm = d.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $amPm';
  }
}

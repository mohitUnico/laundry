import 'package:flutter/foundation.dart';

import '../models/order_record.dart';
import '../repositories/order_repository.dart';
import '../models/cart_item.dart';

class OrderProvider with ChangeNotifier {
  final List<OrderRecord> _orders = [];
  final OrderRepository _repo;
  bool _isLoading = false;
  String? _error;

  OrderProvider({OrderRepository? repo}) : _repo = repo ?? OrderRepository();

  List<OrderRecord> get orders => List.unmodifiable(_orders);
  bool get isLoading => _isLoading;
  String? get error => _error;

  void addOrder(OrderRecord order) {
    _orders.insert(0, order);
    notifyListeners();
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

  Future<void> fetchOrders({int page = 1, int limit = 10, String? status}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _repo.getOrders(page: page, limit: limit, status: status);
      final ordersList = (result['orders'] as List?) ?? [];
      
      _orders.clear();
      for (final orderData in ordersList) {
        final order = _mapBackendOrderToOrderRecord(orderData as Map<String, dynamic>);
        if (order != null) {
          _orders.add(order);
        }
      }
      _error = null;
    } catch (e) {
      _error = e.toString();
      // Keep existing orders on error
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  OrderRecord? _mapBackendOrderToOrderRecord(Map<String, dynamic> data) {
    try {
      final orderId = (data['order_id'] ?? '') as String;
      final orderStatus = (data['order_status'] ?? '') as String;
      final createdAt = data['created_at'] as String?;
      final pickupDate = data['pickup_date'] as String?;
      final totalAmount = (data['total_amount'] ?? '0') as String;
      final items = (data['items'] as List?) ?? [];
      final bill = data['bill'] as Map<String, dynamic>?;

      // Map order status
      final status = _mapOrderStatus(orderStatus);

      // Parse dates
      DateTime? placedAt;
      String placedDateLabel = '';
      String placedTimeLabel = '';
      if (createdAt != null) {
        try {
          placedAt = DateTime.parse(createdAt);
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

      // Parse pickup date
      String dateLabel = '';
      String timeLabel = '';
      if (pickupDate != null) {
        try {
          final pickupDateTime = DateTime.parse(pickupDate);
          dateLabel = _formatDateLabel(pickupDateTime);
          timeLabel = _formatTimeLabel(pickupDateTime);
        } catch (_) {
          dateLabel = 'TBD';
          timeLabel = 'TBD';
        }
      } else {
        dateLabel = 'TBD';
        timeLabel = 'TBD';
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
            ? (selections.first as Map<String, dynamic>)['category_name'] as String?
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
                ? (selections.first as Map<String, dynamic>)['service_name'] as String?
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
          // Per-kg items
          final serviceName = selections.isNotEmpty
              ? (selections.first as Map<String, dynamic>)['service_name'] as String?
              : 'Service';
          cartItems.add(
            CartItem(
              id: (item['item_id'] ?? '') as String,
              category: categoryName ?? 'Unknown',
              serviceName: serviceName ?? 'Service',
              quantities: const {},
              isPerPiece: false,
              weightKg: (item['weight_kg'] as String?) != null
                  ? double.tryParse(item['weight_kg'] as String)
                  : null,
            ),
          );
          totalItems += 1;
        }
      }

      // Map payment method
      PaymentMethod? paymentMethod;
      if (bill != null) {
        final paymentMethodStr = (bill['payment_method'] ?? '') as String;
        if (paymentMethodStr == 'cod') {
          paymentMethod = PaymentMethod.cod;
        } else if (paymentMethodStr.contains('visa') || paymentMethodStr.contains('card')) {
          paymentMethod = PaymentMethod.visa;
        } else if (paymentMethodStr.contains('mastercard')) {
          paymentMethod = PaymentMethod.mastercard;
        }
      }

      // Calculate total amount
      final totalInr = (double.tryParse(totalAmount) ?? 0.0).toInt();

      return OrderRecord(
        id: orderId,
        title: title ?? (cartItems.length == 1 ? cartItems.first.category : 'Mixed'),
        items: cartItems,
        totalItems: totalItems,
        totalInr: totalInr,
        dateLabel: dateLabel,
        timeLabel: timeLabel,
        placedAt: placedAt ?? DateTime.now(),
        placedDateLabel: placedDateLabel,
        placedTimeLabel: placedTimeLabel,
        status: status,
        backendStatus: orderStatus, // Store original backend status string
        paymentMethod: paymentMethod,
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
        return OrderStatus.delivered; // Map to delivered so it's excluded from active orders

      // Draft status - not an active order yet
      case 'draft':
        return OrderStatus.inProgress; // Draft orders can be considered in progress

      // Unknown status - default to inProgress
      default:
        return OrderStatus.inProgress;
    }
  }

  String _formatDateLabel(DateTime date) {
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
    return '${months[date.month - 1]} ${date.day}';
  }

  String _formatTimeLabel(DateTime date) {
    final hour = date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour);
    final minute = date.minute.toString().padLeft(2, '0');
    final amPm = date.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $amPm';
  }
}

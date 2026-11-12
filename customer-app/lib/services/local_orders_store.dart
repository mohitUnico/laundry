import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/cart_item.dart';
import '../models/order_record.dart';

/// Orders kept on the device until the customer order API is used again.
class LocalOrdersStore {
  static const _key = 'local_customer_orders';
  static const _scheduleLockKey = 'local_order_schedule_locks';
  Future<void> _tail = Future<void>.value();

  Future<T> _enqueue<T>(Future<T> Function() action) {
    final result = _tail.then((_) => action());
    _tail = result.then((_) {}, onError: (_) {});
    return result;
  }

  static const _seedIds = {
    'LD90021',
    'LD90022',
    'LD90023',
    'LD90024',
    'LD90025',
    'LD90026',
    'LD90027',
  };

  Future<List<OrderRecord>> load() => _enqueue(_load);

  Future<void> saveChangedSchedule(OrderRecord order) => _enqueue(() => _saveChangedSchedule(order));

  Future<void> upsert(OrderRecord order) => _enqueue(() => _upsert(order));

  Future<List<OrderRecord>> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = _decode(prefs.getString(_key));
    final orders = stored.where((order) => !_seedIds.contains(order.id)).toList();
    orders.sort(_sortForList);
    await prefs.setString(_key, jsonEncode(orders.map(_orderToJson).toList()));
    await prefs.remove(_scheduleLockKey);
    return orders;
  }

  Future<void> _saveChangedSchedule(OrderRecord order) async {
    final prefs = await SharedPreferences.getInstance();
    final locks = prefs.getStringList(_scheduleLockKey)?.toSet() ?? {};
    locks.add(order.id);
    await prefs.setStringList(_scheduleLockKey, locks.toList());
    await _upsert(order);
  }

  Future<void> _upsert(OrderRecord order) async {
    final prefs = await SharedPreferences.getInstance();
    final stored = _decode(prefs.getString(_key));
    final next = [
      order,
      ...stored.where((existing) => existing.id != order.id),
    ];
    await prefs.setString(_key, jsonEncode(next.map(_orderToJson).toList()));
  }

  static int _sortForList(OrderRecord a, OrderRecord b) {
    if (a.status != b.status) {
      return a.status == OrderStatus.inProgress ? -1 : 1;
    }
    final aAt = a.scheduledPickupAt ?? a.placedAt;
    final bAt = b.scheduledPickupAt ?? b.placedAt;
    if (a.status == OrderStatus.inProgress) return aAt.compareTo(bAt);
    return b.placedAt.compareTo(a.placedAt);
  }

  static List<OrderRecord> _decode(String? raw) {
    if (raw == null || raw.isEmpty) return [];
    final decoded = jsonDecode(raw);
    if (decoded is! List) return [];
    return decoded
        .whereType<Map>()
        .map((json) => _orderFromJson(Map<String, dynamic>.from(json)))
        .toList();
  }

  static Map<String, dynamic> _orderToJson(OrderRecord order) {
    return {
      'id': order.id,
      'title': order.title,
      'items': order.items.map(_itemToJson).toList(),
      'total_items': order.totalItems,
      'total_inr': order.totalInr,
      'order_type': order.orderType,
      'date_label': order.dateLabel,
      'time_label': order.timeLabel,
      'delivery_date_label': order.deliveryDateLabel,
      'delivery_time_label': order.deliveryTimeLabel,
      'scheduled_pickup_at': order.scheduledPickupAt?.toIso8601String(),
      'scheduled_delivery_at': order.scheduledDeliveryAt?.toIso8601String(),
      'placed_at': order.placedAt.toIso8601String(),
      'placed_date_label': order.placedDateLabel,
      'placed_time_label': order.placedTimeLabel,
      'status': order.status.name,
      'backend_status': order.backendStatus,
      'payment_method': order.paymentMethod?.name,
      'pickup_address': order.pickupAddress,
      'pickup_lat': order.pickupLat,
      'pickup_lng': order.pickupLng,
      'billing_status': order.billingStatus,
      'bill_payment_status': order.billPaymentStatus,
      'is_express': order.isExpress,
    };
  }

  static OrderRecord _orderFromJson(Map<String, dynamic> json) {
    final items = (json['items'] as List? ?? [])
        .whereType<Map>()
        .map((item) => _itemFromJson(Map<String, dynamic>.from(item)))
        .toList();
    return OrderRecord(
      id: (json['id'] ?? '') as String,
      title: (json['title'] ?? '') as String,
      items: items,
      totalItems: (json['total_items'] as num?)?.toInt() ?? 0,
      totalInr: (json['total_inr'] as num?)?.toInt() ?? 0,
      orderType: json['order_type'] as String?,
      dateLabel: (json['date_label'] ?? '') as String,
      timeLabel: (json['time_label'] ?? '') as String,
      deliveryDateLabel: json['delivery_date_label'] as String?,
      deliveryTimeLabel: json['delivery_time_label'] as String?,
      scheduledPickupAt: _date(json['scheduled_pickup_at']),
      scheduledDeliveryAt: _date(json['scheduled_delivery_at']),
      placedAt: _date(json['placed_at']) ?? DateTime.now(),
      placedDateLabel: (json['placed_date_label'] ?? '') as String,
      placedTimeLabel: (json['placed_time_label'] ?? '') as String,
      status: (json['status'] ?? '') == OrderStatus.delivered.name
          ? OrderStatus.delivered
          : OrderStatus.inProgress,
      backendStatus: (json['backend_status'] ?? 'placed') as String,
      paymentMethod: _payment(json['payment_method'] as String?),
      pickupAddress: json['pickup_address'] as String?,
      pickupLat: (json['pickup_lat'] as num?)?.toDouble(),
      pickupLng: (json['pickup_lng'] as num?)?.toDouble(),
      billingStatus: json['billing_status'] as String?,
      billPaymentStatus: json['bill_payment_status'] as String?,
      isExpress: json['is_express'] == true,
    );
  }

  static Map<String, dynamic> _itemToJson(CartItem item) {
    return {
      'id': item.id,
      'category': item.category,
      'service_name': item.serviceName,
      'quantities': item.quantities,
      'unit_prices_inr': item.unitPricesInr,
      'is_per_piece': item.isPerPiece,
      'weight_kg': item.weightKg,
      'note': item.note,
    };
  }

  static CartItem _itemFromJson(Map<String, dynamic> json) {
    final quantities = <String, int>{};
    final rawQuantities = json['quantities'];
    if (rawQuantities is Map) {
      rawQuantities.forEach((key, value) {
        quantities[key.toString()] = (value as num?)?.toInt() ?? 0;
      });
    }
    Map<String, int>? prices;
    final rawPrices = json['unit_prices_inr'];
    if (rawPrices is Map) {
      prices = {};
      rawPrices.forEach((key, value) {
        prices![key.toString()] = (value as num?)?.toInt() ?? 0;
      });
    }
    return CartItem(
      id: (json['id'] ?? '') as String,
      category: (json['category'] ?? '') as String,
      serviceName: (json['service_name'] ?? '') as String,
      quantities: quantities,
      unitPricesInr: prices,
      isPerPiece: json['is_per_piece'] != false,
      weightKg: (json['weight_kg'] as num?)?.toDouble(),
      note: json['note'] as String?,
    );
  }

  static DateTime? _date(Object? value) {
    if (value is! String || value.isEmpty) return null;
    return DateTime.tryParse(value);
  }

  static PaymentMethod? _payment(String? value) {
    switch (value) {
      case 'visa':
        return PaymentMethod.visa;
      case 'mastercard':
        return PaymentMethod.mastercard;
      case 'cod':
        return PaymentMethod.cod;
      default:
        return null;
    }
  }
}

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/cart_item.dart';
import '../models/order_record.dart';

/// Orders kept on the device until the customer order API is used again.
class LocalOrdersStore {
  static const _key = 'local_customer_orders';
  static const _scheduleLockKey = 'local_order_schedule_locks';

  static const _seedIds = {
    'LD90021',
    'LD90022',
    'LD90023',
    'LD90024',
    'LD90025',
    'LD90026',
  };

  Future<List<OrderRecord>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = _decode(prefs.getString(_key));
    final locked = prefs.getStringList(_scheduleLockKey)?.toSet() ?? {};
    final storedById = {for (final order in stored) order.id: order};
    final placed = stored.where((order) => !_seedIds.contains(order.id)).toList();
    final samples = _sampleOrders(DateTime.now()).map((sample) {
      final saved = storedById[sample.id];
      if (saved == null || !locked.contains(sample.id)) return sample;
      return sample.copyWith(
        dateLabel: saved.dateLabel,
        timeLabel: saved.timeLabel,
        deliveryDateLabel: saved.deliveryDateLabel,
        deliveryTimeLabel: saved.deliveryTimeLabel,
        scheduledPickupAt: saved.scheduledPickupAt,
        scheduledDeliveryAt: saved.scheduledDeliveryAt,
      );
    }).toList();
    final orders = [...placed, ...samples];
    orders.sort(_sortForList);
    await prefs.setString(_key, jsonEncode(orders.map(_orderToJson).toList()));
    return orders;
  }

  Future<void> saveChangedSchedule(OrderRecord order) async {
    final prefs = await SharedPreferences.getInstance();
    final locks = prefs.getStringList(_scheduleLockKey)?.toSet() ?? {};
    locks.add(order.id);
    await prefs.setStringList(_scheduleLockKey, locks.toList());
    await upsert(order);
  }

  Future<void> upsert(OrderRecord order) async {
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

  static List<OrderRecord> _sampleOrders(DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    return [
      _sample(
        id: 'LD90021',
        title: 'Pro Clean',
        category: 'Pro Clean',
        serviceName: 'Dry Cleaning',
        quantities: const {'Shirt': 4, 'Trouser': 2},
        prices: const {'Shirt': 80, 'Trouser': 90},
        isExpress: true,
        status: OrderStatus.inProgress,
        pickupAt: today.add(const Duration(days: 20, hours: 18)),
        address: '123 Main St, Apartment 4B',
        totalInr: 500,
      ),
      _sample(
        id: 'LD90022',
        title: 'Regular Wash',
        category: 'Regular Wash',
        serviceName: 'Wash & Fold',
        quantities: const {'T-shirt': 6, 'Jeans': 2},
        prices: const {'T-shirt': 40, 'Jeans': 70},
        isExpress: false,
        status: OrderStatus.inProgress,
        pickupAt: today.add(const Duration(days: 22, hours: 16)),
        address: '45 Park Avenue, Sector 12',
        totalInr: 380,
      ),
      _sample(
        id: 'LD90023',
        title: 'Luxury Care',
        category: 'Luxury Care',
        serviceName: 'Designer Wear',
        quantities: const {'Dress': 1, 'Blazer': 1},
        prices: const {'Dress': 350, 'Blazer': 280},
        isExpress: true,
        status: OrderStatus.inProgress,
        pickupAt: today.add(const Duration(days: 26, hours: 11)),
        address: '18 Lake View Road',
        totalInr: 630,
      ),
      _sample(
        id: 'LD90024',
        title: 'Quick Wash',
        category: 'Regular Wash',
        serviceName: 'Wash & Iron',
        quantities: const {'Shirt': 5, 'Trouser': 3},
        prices: const {'Shirt': 50, 'Trouser': 60},
        isExpress: false,
        status: OrderStatus.delivered,
        pickupAt: today.subtract(const Duration(days: 12)).add(const Duration(hours: 16)),
        address: '123 Main St, Apartment 4B',
        totalInr: 430,
        backendStatus: 'delivered',
      ),
      _sample(
        id: 'LD90025',
        title: 'Luxury Care',
        category: 'Luxury Care',
        serviceName: 'Steam Press',
        quantities: const {'Saree': 2, 'Kurta': 2},
        prices: const {'Saree': 180, 'Kurta': 90},
        isExpress: true,
        status: OrderStatus.delivered,
        pickupAt: today.subtract(const Duration(days: 21)).add(const Duration(hours: 18)),
        address: '9 Green Park Extension',
        totalInr: 540,
        backendStatus: 'delivered',
      ),
      _sample(
        id: 'LD90026',
        title: 'Home Linen',
        category: 'Home Linens',
        serviceName: 'Home Linen',
        quantities: const {'Bedsheet': 4, 'Curtain': 2},
        prices: const {'Bedsheet': 90, 'Curtain': 120},
        isExpress: false,
        status: OrderStatus.delivered,
        pickupAt: today.subtract(const Duration(days: 6)).add(const Duration(hours: 10)),
        address: '45 Park Avenue, Sector 12',
        totalInr: 600,
        backendStatus: 'delivered',
      ),
    ];
  }

  static OrderRecord _sample({
    required String id,
    required String title,
    required String category,
    required String serviceName,
    required Map<String, int> quantities,
    required Map<String, int> prices,
    required bool isExpress,
    required OrderStatus status,
    required DateTime pickupAt,
    required String address,
    required int totalInr,
    String backendStatus = 'placed',
  }) {
    final totalItems = quantities.values.fold<int>(0, (sum, qty) => sum + qty);
    final placedAt = status == OrderStatus.delivered
        ? pickupAt.subtract(const Duration(hours: 2))
        : pickupAt.subtract(const Duration(days: 1));
    return OrderRecord(
      id: id,
      title: title,
      items: [
        CartItem(
          id: '$id-item',
          category: category,
          serviceName: serviceName,
          quantities: quantities,
          unitPricesInr: prices,
          isPerPiece: true,
        ),
      ],
      totalItems: totalItems,
      totalInr: totalInr,
      orderType: 'both',
      dateLabel: _dateLabel(pickupAt),
      timeLabel: _timeLabel(pickupAt),
      deliveryDateLabel: _dateLabel(pickupAt.add(const Duration(days: 2))),
      deliveryTimeLabel: _timeLabel(pickupAt.add(const Duration(hours: 4))),
      scheduledPickupAt: pickupAt,
      scheduledDeliveryAt: pickupAt.add(const Duration(days: 2, hours: 4)),
      placedAt: placedAt,
      placedDateLabel: _dateLabel(placedAt),
      placedTimeLabel: _timeLabel(placedAt),
      status: status,
      backendStatus: backendStatus,
      paymentMethod: PaymentMethod.cod,
      pickupAddress: address,
      isExpress: isExpress,
    );
  }

  static String _dateLabel(DateTime date) {
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
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}';
  }

  static String _timeLabel(DateTime time) {
    final hour12 = time.hour % 12 == 0 ? 12 : time.hour % 12;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour12:$minute $period';
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

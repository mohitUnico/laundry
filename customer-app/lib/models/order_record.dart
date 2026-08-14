import 'cart_item.dart';

enum OrderStatus { inProgress, delivered }
enum PaymentMethod { visa, mastercard, cod }

class OrderRecord {
  final String id; // e.g. #LD12345
  final String title; // e.g. Regular Wash / Pro Clean / Mixed
  final List<CartItem> items;
  final int totalItems;
  final int totalInr;
  // pickup_only / drop_only / both
  //
  // NOTE: kept nullable so hot-reload / older in-memory objects don't crash when this field
  // is introduced. Always use [orderTypeOrBoth] when reading it.
  final String? orderType;
  final String dateLabel; // Scheduled pickup date e.g. Dec 20
  final String timeLabel; // Scheduled pickup time e.g. 2:30 PM
  final String? deliveryDateLabel; // Scheduled delivery date e.g. Dec 21 (null for pickup_only/drop_only)
  final String? deliveryTimeLabel; // Scheduled delivery time e.g. 3:00 PM (null for pickup_only/drop_only)
  /// Parsed pickup schedule for sorting (soonest first). Null if TBD or not set.
  final DateTime? scheduledPickupAt;
  /// Parsed delivery schedule for "both" orders. Null if TBD or not set.
  final DateTime? scheduledDeliveryAt;
  final DateTime placedAt; // When order was placed
  final String placedDateLabel; // e.g. Dec 20, 2024
  final String placedTimeLabel; // e.g. 2:30 PM
  final OrderStatus status;
  final String backendStatus; // Store actual backend status string for accurate step mapping
  final PaymentMethod? paymentMethod; // null for kg-wise only orders
  final String? pickupAddress; // Full pickup address text
  final double? pickupLat;
  final double? pickupLng;
  // Billing info from backend (orders + bill tables)
  final String? billingStatus; // e.g. generated, pending
  final String? billPaymentStatus; // e.g. completed, pending, failed

  const OrderRecord({
    required this.id,
    required this.title,
    required this.items,
    required this.totalItems,
    required this.totalInr,
    this.orderType,
    required this.dateLabel,
    required this.timeLabel,
    this.deliveryDateLabel,
    this.deliveryTimeLabel,
    this.scheduledPickupAt,
    this.scheduledDeliveryAt,
    required this.placedAt,
    required this.placedDateLabel,
    required this.placedTimeLabel,
    required this.status,
    required this.backendStatus,
    this.paymentMethod,
    this.pickupAddress,
    this.pickupLat,
    this.pickupLng,
    this.billingStatus,
    this.billPaymentStatus,
  });

  OrderRecord copyWith({
    String? id,
    String? title,
    List<CartItem>? items,
    int? totalItems,
    int? totalInr,
    String? orderType,
    String? dateLabel,
    String? timeLabel,
    String? deliveryDateLabel,
    String? deliveryTimeLabel,
    DateTime? scheduledPickupAt,
    DateTime? scheduledDeliveryAt,
    DateTime? placedAt,
    String? placedDateLabel,
    String? placedTimeLabel,
    OrderStatus? status,
    String? backendStatus,
    PaymentMethod? paymentMethod,
    String? pickupAddress,
    double? pickupLat,
    double? pickupLng,
    String? billingStatus,
    String? billPaymentStatus,
  }) {
    return OrderRecord(
      id: id ?? this.id,
      title: title ?? this.title,
      items: items ?? this.items,
      totalItems: totalItems ?? this.totalItems,
      totalInr: totalInr ?? this.totalInr,
      orderType: orderType ?? this.orderType,
      dateLabel: dateLabel ?? this.dateLabel,
      timeLabel: timeLabel ?? this.timeLabel,
      deliveryDateLabel: deliveryDateLabel ?? this.deliveryDateLabel,
      deliveryTimeLabel: deliveryTimeLabel ?? this.deliveryTimeLabel,
      scheduledPickupAt: scheduledPickupAt ?? this.scheduledPickupAt,
      scheduledDeliveryAt: scheduledDeliveryAt ?? this.scheduledDeliveryAt,
      placedAt: placedAt ?? this.placedAt,
      placedDateLabel: placedDateLabel ?? this.placedDateLabel,
      placedTimeLabel: placedTimeLabel ?? this.placedTimeLabel,
      status: status ?? this.status,
      backendStatus: backendStatus ?? this.backendStatus,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      pickupAddress: pickupAddress ?? this.pickupAddress,
      pickupLat: pickupLat ?? this.pickupLat,
      pickupLng: pickupLng ?? this.pickupLng,
      billingStatus: billingStatus ?? this.billingStatus,
      billPaymentStatus: billPaymentStatus ?? this.billPaymentStatus,
    );
  }

  String get orderTypeOrBoth {
    final t = (orderType ?? '').trim();
    return t.isEmpty ? 'both' : t;
  }

  /// Short, human-friendly ID used across apps, e.g. ORDABC123.
  /// Mirrors the format used in staff/management apps so orders
  /// are easily traceable everywhere.
  String get shortId {
    final normalized = id.replaceAll('-', '').toUpperCase().trim();
    if (normalized.isEmpty) return 'ORDER';
    if (normalized.length >= 6) return 'ORD${normalized.substring(0, 6)}';
    return 'ORD$normalized';
  }
}



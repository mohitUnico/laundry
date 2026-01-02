import 'cart_item.dart';

enum OrderStatus { inProgress, delivered }
enum PaymentMethod { visa, mastercard, cod }

class OrderRecord {
  final String id; // e.g. #LD12345
  final String title; // e.g. Regular Wash / Pro Clean / Mixed
  final List<CartItem> items;
  final int totalItems;
  final int totalInr;
  final String dateLabel; // Scheduled date e.g. Dec 20
  final String timeLabel; // Scheduled time e.g. 2:30 PM
  final DateTime placedAt; // When order was placed
  final String placedDateLabel; // e.g. Dec 20, 2024
  final String placedTimeLabel; // e.g. 2:30 PM
  final OrderStatus status;
  final PaymentMethod? paymentMethod; // null for kg-wise only orders

  const OrderRecord({
    required this.id,
    required this.title,
    required this.items,
    required this.totalItems,
    required this.totalInr,
    required this.dateLabel,
    required this.timeLabel,
    required this.placedAt,
    required this.placedDateLabel,
    required this.placedTimeLabel,
    required this.status,
    this.paymentMethod,
  });

  OrderRecord copyWith({
    String? id,
    String? title,
    List<CartItem>? items,
    int? totalItems,
    int? totalInr,
    String? dateLabel,
    String? timeLabel,
    DateTime? placedAt,
    String? placedDateLabel,
    String? placedTimeLabel,
    OrderStatus? status,
    PaymentMethod? paymentMethod,
  }) {
    return OrderRecord(
      id: id ?? this.id,
      title: title ?? this.title,
      items: items ?? this.items,
      totalItems: totalItems ?? this.totalItems,
      totalInr: totalInr ?? this.totalInr,
      dateLabel: dateLabel ?? this.dateLabel,
      timeLabel: timeLabel ?? this.timeLabel,
      placedAt: placedAt ?? this.placedAt,
      placedDateLabel: placedDateLabel ?? this.placedDateLabel,
      placedTimeLabel: placedTimeLabel ?? this.placedTimeLabel,
      status: status ?? this.status,
      paymentMethod: paymentMethod ?? this.paymentMethod,
    );
  }
}



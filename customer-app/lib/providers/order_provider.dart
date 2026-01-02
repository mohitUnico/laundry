import 'package:flutter/foundation.dart';

import '../models/order_record.dart';

class OrderProvider with ChangeNotifier {
  final List<OrderRecord> _orders = [];

  List<OrderRecord> get orders => List.unmodifiable(_orders);

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
}

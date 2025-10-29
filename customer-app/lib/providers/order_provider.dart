import 'package:flutter/foundation.dart';

class OrderProvider with ChangeNotifier {
  List<Map<String, dynamic>> _orders = [];
  bool _isLoading = false;

  List<Map<String, dynamic>> get orders => _orders;
  bool get isLoading => _isLoading;

  Future<void> fetchOrders() async {
    _isLoading = true;
    notifyListeners();

    try {
      // TODO: Fetch orders from API
      await Future.delayed(const Duration(seconds: 1));
      _orders = [];
    } catch (e) {
      debugPrint('Error fetching orders: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createOrder(Map<String, dynamic> orderData) async {
    // TODO: Implement order creation
  }
}

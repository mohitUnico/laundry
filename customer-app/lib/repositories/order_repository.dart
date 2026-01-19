import '../services/order_service.dart';

class OrderRepository {
  final OrderService _service;

  OrderRepository({OrderService? service}) : _service = service ?? OrderService();

  Future<CreateOrderResult> createOrder({
    required String cartId,
    required String pickupAddressId,
    required String deliveryAddressId,
    required String orderType,
    String? pickupDate,
    String? deliveryDate,
    String? specialInstructions,
  }) {
    return _service.createOrder(
      cartId: cartId,
      pickupAddressId: pickupAddressId,
      deliveryAddressId: deliveryAddressId,
      orderType: orderType,
      pickupDate: pickupDate,
      deliveryDate: deliveryDate,
      specialInstructions: specialInstructions,
    );
  }

  Future<Map<String, dynamic>> getOrders({
    int page = 1,
    int limit = 10,
    String? status,
  }) {
    return _service.getOrders(
      page: page,
      limit: limit,
      status: status,
    );
  }
}


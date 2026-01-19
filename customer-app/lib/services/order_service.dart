import 'package:dio/dio.dart';

import 'api_service.dart';

class CreateOrderResult {
  final String orderId;
  final String? pickupAddressId;
  final String? deliveryAddressId;
  final String pricingModel;
  final String orderType;
  final double totalAmount;
  final String billingStatus;

  const CreateOrderResult({
    required this.orderId,
    this.pickupAddressId,
    this.deliveryAddressId,
    required this.pricingModel,
    required this.orderType,
    required this.totalAmount,
    required this.billingStatus,
  });

  factory CreateOrderResult.fromJson(Map<String, dynamic> json) {
    return CreateOrderResult(
      orderId: (json['order_id'] ?? '') as String,
      pickupAddressId: json['pickup_address_id'] as String?,
      deliveryAddressId: json['delivery_address_id'] as String?,
      pricingModel: (json['pricing_model'] ?? '') as String,
      orderType: (json['order_type'] ?? '') as String,
      totalAmount: (json['total_amount'] is num)
          ? (json['total_amount'] as num).toDouble()
          : 0.0,
      billingStatus: (json['billing_status'] ?? '') as String,
    );
  }
}

class OrderService {
  final ApiService _api;

  OrderService({ApiService? api}) : _api = api ?? ApiService();

  Future<CreateOrderResult> createOrder({
    required String cartId,
    required String pickupAddressId,
    required String deliveryAddressId,
    required String orderType,
    String? pickupDate,
    String? deliveryDate,
    String? specialInstructions,
  }) async {
    try {
      final payload = <String, dynamic>{
        'cart_id': cartId,
        'pickup_address_id': pickupAddressId,
        'delivery_address_id': deliveryAddressId,
        'order_type': orderType,
      };

      if (pickupDate != null && pickupDate.isNotEmpty) {
        payload['pickup_date'] = pickupDate;
      }
      if (deliveryDate != null && deliveryDate.isNotEmpty) {
        payload['delivery_date'] = deliveryDate;
      }
      if (specialInstructions != null && specialInstructions.isNotEmpty) {
        payload['special_instructions'] = specialInstructions;
      }

      final res = await _api.post(
        '/orders/create_order',
        data: payload,
      );

      final data = (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
      return CreateOrderResult.fromJson(data);
    } on DioException catch (e) {
      final msg = _extractErrorMessage(e, 'Failed to create order');
      throw Exception(msg);
    } catch (e) {
      throw Exception('Failed to create order: $e');
    }
  }

  Future<Map<String, dynamic>> getOrders({
    int page = 1,
    int limit = 10,
    String? status,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
      };
      if (status != null && status.isNotEmpty) {
        queryParams['status'] = status;
      }

      final res = await _api.get(
        '/orders',
        queryParameters: queryParams,
      );

      final data = (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
      return data;
    } on DioException catch (e) {
      final msg = _extractErrorMessage(e, 'Failed to fetch orders');
      throw Exception(msg);
    } catch (e) {
      throw Exception('Failed to fetch orders: $e');
    }
  }

  String _extractErrorMessage(DioException e, String fallback) {
    try {
      final data = e.response?.data;
      if (data is Map<String, dynamic>) {
        final message = data['message'];
        if (message is String && message.isNotEmpty) return message;
      }
    } catch (_) {
      // ignore
    }
    return fallback;
  }
}


import 'package:dio/dio.dart';

import 'api_service.dart';

class PaymentResult {
  final String billId;
  final String orderId;
  final String subtotal;
  final String deliveryFee;
  final String taxAmount;
  final String discount;
  final String finalAmount;
  final String paymentMethod;
  final String paymentStatus;
  final String? transactionId;
  final String? paidAt;
  final String createdAt;
  final String updatedAt;

  const PaymentResult({
    required this.billId,
    required this.orderId,
    required this.subtotal,
    required this.deliveryFee,
    required this.taxAmount,
    required this.discount,
    required this.finalAmount,
    required this.paymentMethod,
    required this.paymentStatus,
    this.transactionId,
    this.paidAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PaymentResult.fromJson(Map<String, dynamic> json) {
    return PaymentResult(
      billId: (json['bill_id'] ?? '') as String,
      orderId: (json['order_id'] ?? '') as String,
      subtotal: (json['subtotal'] ?? '0') as String,
      deliveryFee: (json['delivery_fee'] ?? '0') as String,
      taxAmount: (json['tax_amount'] ?? '0') as String,
      discount: (json['discount'] ?? '0') as String,
      finalAmount: (json['final_amount'] ?? '0') as String,
      paymentMethod: (json['payment_method'] ?? '') as String,
      paymentStatus: (json['payment_status'] ?? 'pending') as String,
      transactionId: json['transaction_id'] as String?,
      paidAt: json['paid_at'] as String?,
      createdAt: (json['created_at'] ?? '') as String,
      updatedAt: (json['updated_at'] ?? '') as String,
    );
  }
}

class PaymentService {
  final ApiService _api;

  PaymentService({ApiService? api}) : _api = api ?? ApiService();

  /// Process payment for an order
  Future<PaymentResult> processPayment({
    required String orderId,
    required String paymentMethod,
    String? transactionId,
    String? paymentStatus,
  }) async {
    try {
      final payload = <String, dynamic>{
        'payment_method': paymentMethod,
      };

      if (transactionId != null && transactionId.isNotEmpty) {
        payload['transaction_id'] = transactionId;
      }

      if (paymentStatus != null && paymentStatus.isNotEmpty) {
        payload['payment_status'] = paymentStatus;
      }

      final res = await _api.post(
        '/payments/process/$orderId',
        data: payload,
      );

      final data = (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
      return PaymentResult.fromJson(data);
    } on DioException catch (e) {
      final msg = _extractErrorMessage(e, 'Failed to process payment');
      throw Exception(msg);
    } catch (e) {
      throw Exception('Failed to process payment: $e');
    }
  }

  /// Get bill/payment details for an order
  Future<PaymentResult?> getBillByOrderId({
    required String orderId,
  }) async {
    try {
      final res = await _api.get('/payments/bill/$orderId');

      final data = (res.data as Map<String, dynamic>)['data'];
      if (data == null) {
        return null;
      }

      return PaymentResult.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      final msg = _extractErrorMessage(e, 'Failed to fetch bill');
      throw Exception(msg);
    } catch (e) {
      throw Exception('Failed to fetch bill: $e');
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


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

class InvoiceDetails {
  final String orderId;
  final String orderStatus;
  final String orderType;
  final String pricingModel;
  final String billingStatus;
  final PaymentResult bill;
  final List<InvoiceItem> items;

  const InvoiceDetails({
    required this.orderId,
    required this.orderStatus,
    required this.orderType,
    required this.pricingModel,
    required this.billingStatus,
    required this.bill,
    required this.items,
  });

  factory InvoiceDetails.fromJson(Map<String, dynamic> json) {
    final billJson = (json['bill'] as Map).cast<String, dynamic>();
    final itemsJson = (json['items'] as List?) ?? const [];
    return InvoiceDetails(
      orderId: (json['orderId'] ?? '') as String,
      orderStatus: (json['orderStatus'] ?? '') as String,
      orderType: (json['orderType'] ?? '') as String,
      pricingModel: (json['pricingModel'] ?? '') as String,
      billingStatus: (json['billingStatus'] ?? '') as String,
      bill: PaymentResult.fromJson({
        'bill_id': billJson['billId'],
        'order_id': json['orderId'],
        'subtotal': billJson['subtotal'],
        'delivery_fee': billJson['deliveryFee'],
        'tax_amount': billJson['taxAmount'],
        'discount': billJson['discount'],
        'final_amount': billJson['finalAmount'],
        'payment_method': billJson['paymentMethod'],
        'payment_status': billJson['paymentStatus'],
        'transaction_id': billJson['transactionId'],
        'paid_at': billJson['paidAt'],
        'created_at': billJson['createdAt'],
        'updated_at': billJson['updatedAt'],
      }),
      items: itemsJson
          .whereType<Map>()
          .map((e) => InvoiceItem.fromJson(e.cast<String, dynamic>()))
          .toList(),
    );
  }
}

class InvoiceItem {
  final String orderItemId;
  final String pricingType; // per_unit | per_kg
  final String categoryName;
  final String serviceName;
  final int? quantity;
  final String? weightKg;
  final String unitPrice;
  final String subtotal;
  final List<InvoiceSelection> selections;

  const InvoiceItem({
    required this.orderItemId,
    required this.pricingType,
    required this.categoryName,
    required this.serviceName,
    required this.quantity,
    required this.weightKg,
    required this.unitPrice,
    required this.subtotal,
    required this.selections,
  });

  factory InvoiceItem.fromJson(Map<String, dynamic> json) {
    final selectionsJson = (json['selections'] as List?) ?? const [];
    return InvoiceItem(
      orderItemId: (json['orderItemId'] ?? '') as String,
      pricingType: (json['pricingType'] ?? '') as String,
      categoryName: (json['categoryName'] ?? '') as String,
      serviceName: (json['serviceName'] ?? '') as String,
      quantity: json['quantity'] is int ? (json['quantity'] as int) : null,
      weightKg: json['weightKg'] as String?,
      unitPrice: (json['unitPrice'] ?? '0') as String,
      subtotal: (json['subtotal'] ?? '0') as String,
      selections: selectionsJson
          .whereType<Map>()
          .map((e) => InvoiceSelection.fromJson(e.cast<String, dynamic>()))
          .toList(),
    );
  }
}

class InvoiceSelection {
  final String selectionId;
  final String? clothId;
  final String clothName;
  final int quantity;
  final String? unitPrice;
  final String subtotal;

  const InvoiceSelection({
    required this.selectionId,
    required this.clothId,
    required this.clothName,
    required this.quantity,
    required this.unitPrice,
    required this.subtotal,
  });

  factory InvoiceSelection.fromJson(Map<String, dynamic> json) {
    return InvoiceSelection(
      selectionId: (json['selectionId'] ?? '') as String,
      clothId: json['clothId'] as String?,
      clothName: (json['clothName'] ?? '') as String,
      quantity: (json['quantity'] ?? 0) as int,
      unitPrice: json['unitPrice'] as String?,
      subtotal: (json['subtotal'] ?? '0') as String,
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

  /// Get invoice (bill + line items) for an order
  Future<InvoiceDetails?> getInvoiceByOrderId({
    required String orderId,
  }) async {
    try {
      final res = await _api.get('/payments/invoice/$orderId');
      final data = (res.data as Map<String, dynamic>)['data'];
      if (data == null) return null;
      if (data is Map<String, dynamic>) {
        return InvoiceDetails.fromJson(data);
      }
      throw Exception('Unexpected response format');
    } on DioException catch (e) {
      final msg = _extractErrorMessage(e, 'Failed to fetch invoice');
      throw Exception(msg);
    } catch (e) {
      throw Exception('Failed to fetch invoice: $e');
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


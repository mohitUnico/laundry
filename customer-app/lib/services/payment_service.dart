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

const paymentVerificationMessage =
    "Your payment is being verified. Please don't pay again until we confirm its status.";

String describePaymentError(Object error) {
  final raw = error.toString().replaceFirst('Exception: ', '');
  final lower = raw.toLowerCase();
  if (lower.contains('being verified') ||
      lower.contains('timeout') ||
      lower.contains('socket') ||
      lower.contains('network') ||
      lower.contains('failed to confirm payment') ||
      lower.contains('failed to start payment')) {
    return paymentVerificationMessage;
  }
  return raw;
}

class PayIntentResult {
  final String provider;
  final String? providerRef;
  final Map<String, dynamic>? intent;
  final String finalAmount;
  final String paymentStatus;
  final String? paymentMethod;
  final String? transactionId;
  final String verificationState;
  final String? refundStatus;

  const PayIntentResult({
    required this.provider,
    required this.providerRef,
    required this.intent,
    required this.finalAmount,
    required this.paymentStatus,
    required this.paymentMethod,
    required this.transactionId,
    required this.verificationState,
    required this.refundStatus,
  });

  factory PayIntentResult.fromJson(Map<String, dynamic> json) {
    final attempt = json['attempt'];
    Map<String, dynamic>? intent;
    String provider = '';
    String? providerRef;
    if (attempt is Map) {
      provider = (attempt['provider'] ?? '').toString();
      providerRef = attempt['providerRef'] as String?;
      final rawIntent = attempt['intent'];
      if (rawIntent is Map) intent = rawIntent.cast<String, dynamic>();
    }
    final refund = json['refund'];
    return PayIntentResult(
      provider: provider,
      providerRef: providerRef,
      intent: intent,
      finalAmount: (json['finalAmount'] ?? '0').toString(),
      paymentStatus: (json['paymentStatus'] ?? '').toString(),
      paymentMethod: json['paymentMethod'] as String?,
      transactionId: json['transactionId'] as String?,
      verificationState: (json['verificationState'] ?? '').toString(),
      refundStatus: refund is Map ? refund['status']?.toString() : null,
    );
  }

  bool get isPaidOnline =>
      paymentStatus == 'completed' &&
      paymentMethod != 'cash' &&
      verificationState != 'refund_pending' &&
      verificationState != 'refund_completed';
}

class PaymentService {
  final ApiService _api;

  PaymentService({ApiService? api}) : _api = api ?? ApiService();

  /// The server rejects client-supplied payment status. Checkout uses createPayIntent.
  Future<PaymentResult> processPayment({
    required String orderId,
    required String paymentMethod,
    String? transactionId,
    String? paymentStatus,
  }) async {
    throw Exception(
      'Payment for $orderId is confirmed from Razorpay. The app cannot mark $paymentMethod ${paymentStatus ?? ''} ${transactionId ?? ''} as paid.',
    );
  }

  Future<PayIntentResult> createPayIntent({required String orderId}) async {
    try {
      final res = await _api.post('/payments/orders/$orderId/pay-intent');
      final data = (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
      return PayIntentResult.fromJson(data);
    } on DioException catch (e) {
      throw Exception(_extractErrorMessage(e, 'Failed to start payment'));
    }
  }

  Future<PayIntentResult> confirmRazorpay({
    required String orderId,
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
  }) async {
    try {
      final res = await _api.post(
        '/payments/orders/$orderId/razorpay/confirm',
        data: {
          'razorpayOrderId': razorpayOrderId,
          'razorpayPaymentId': razorpayPaymentId,
          'razorpaySignature': razorpaySignature,
        },
      );
      final data = (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
      return PayIntentResult.fromJson(data);
    } on DioException catch (e) {
      throw Exception(_extractErrorMessage(e, 'Failed to confirm payment'));
    }
  }

  Future<PayIntentResult> paymentStatus({required String orderId}) async {
    try {
      final res = await _api.get('/payments/orders/$orderId/payment-status');
      final data = (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
      return PayIntentResult.fromJson(data);
    } on DioException catch (e) {
      throw Exception(_extractErrorMessage(e, 'Failed to fetch payment status'));
    }
  }

  Future<PayIntentResult> cancelAttempt({required String orderId}) async {
    try {
      final res = await _api.post('/payments/orders/$orderId/cancel-attempt');
      final data = (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
      return PayIntentResult.fromJson(data);
    } on DioException catch (e) {
      throw Exception(_extractErrorMessage(e, 'Failed to cancel payment'));
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


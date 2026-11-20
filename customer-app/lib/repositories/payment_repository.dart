import '../services/payment_service.dart';

class PaymentRepository {
  final PaymentService _service;

  PaymentRepository({PaymentService? service})
      : _service = service ?? PaymentService();

  Future<PaymentResult> processPayment({
    required String orderId,
    required String paymentMethod,
    String? transactionId,
    String? paymentStatus,
  }) {
    return _service.processPayment(
      orderId: orderId,
      paymentMethod: paymentMethod,
      transactionId: transactionId,
      paymentStatus: paymentStatus,
    );
  }

  Future<PaymentResult?> getBillByOrderId({
    required String orderId,
  }) {
    return _service.getBillByOrderId(orderId: orderId);
  }

  Future<InvoiceDetails?> getInvoiceByOrderId({
    required String orderId,
  }) {
    return _service.getInvoiceByOrderId(orderId: orderId);
  }

  Future<PayIntentResult> createPayIntent({required String orderId}) {
    return _service.createPayIntent(orderId: orderId);
  }

  Future<PayIntentResult> confirmRazorpay({
    required String orderId,
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
  }) {
    return _service.confirmRazorpay(
      orderId: orderId,
      razorpayOrderId: razorpayOrderId,
      razorpayPaymentId: razorpayPaymentId,
      razorpaySignature: razorpaySignature,
    );
  }

  Future<PayIntentResult> paymentStatus({required String orderId}) {
    return _service.paymentStatus(orderId: orderId);
  }

  Future<PayIntentResult> cancelAttempt({required String orderId}) {
    return _service.cancelAttempt(orderId: orderId);
  }
}


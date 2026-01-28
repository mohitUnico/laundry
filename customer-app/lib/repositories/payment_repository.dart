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
}


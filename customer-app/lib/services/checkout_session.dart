import 'payment_service.dart';

/// Tracks one Razorpay Checkout attempt. Pausing for a UPI app does not
/// cancel the attempt or allow a second Checkout window.
enum CheckoutPhase {
  idle,
  opening,
  awaiting,
  verifying,
  successful,
  failed,
  cancelled,
  unknown,
  refundPending,
  refundCompleted,
  alreadyPaid,
}

class CheckoutLaunch {
  final String key;
  final int amount;
  final String currency;
  final String orderId;

  const CheckoutLaunch({
    required this.key,
    required this.amount,
    required this.currency,
    required this.orderId,
  });

  Map<String, dynamic> toOptions() {
    return {
      'key': key,
      'amount': amount,
      'currency': currency,
      'name': 'Laundry',
      'description': 'Bill payment',
      'order_id': orderId,
    };
  }
}

CheckoutLaunch? launchFromIntent(PayIntentResult intent) {
  final payload = intent.intent;
  final key = payload?['keyId'];
  final orderId = payload?['razorpayOrderId'];
  final rawAmount = payload?['amount'];
  if (intent.provider != 'razorpay' || key is! String || key.isEmpty || orderId is! String || rawAmount is! num) {
    return null;
  }
  return CheckoutLaunch(
    key: key,
    amount: rawAmount.round(),
    currency: (payload?['currency'] ?? 'INR').toString(),
    orderId: orderId,
  );
}

class CheckoutSession {
  CheckoutPhase phase = CheckoutPhase.idle;
  String message = '';

  bool get blocksAnotherCheckout =>
      phase == CheckoutPhase.opening ||
      phase == CheckoutPhase.awaiting ||
      phase == CheckoutPhase.verifying ||
      phase == CheckoutPhase.unknown;

  bool get showRefresh =>
      phase == CheckoutPhase.unknown || phase == CheckoutPhase.verifying || phase == CheckoutPhase.awaiting;

  String get buttonLabel {
    switch (phase) {
      case CheckoutPhase.opening:
        return 'Opening Checkout';
      case CheckoutPhase.awaiting:
        return 'Awaiting payment';
      case CheckoutPhase.verifying:
        return 'Verifying payment';
      default:
        return 'Pay Now';
    }
  }

  bool begin() {
    if (blocksAnotherCheckout) return false;
    phase = CheckoutPhase.opening;
    message = 'Opening Checkout';
    return true;
  }

  void awaitingExternalApp() {
    phase = CheckoutPhase.awaiting;
    message = 'Awaiting payment';
  }

  /// Switching to Google Pay, PhonePe, or a bank page is not cancellation.
  void pausedForExternalApp() {}

  void verifying() {
    phase = CheckoutPhase.verifying;
    message = paymentVerificationMessage;
  }

  void applyServerResult(PayIntentResult result) {
    if (result.verificationState == 'refund_completed') {
      phase = CheckoutPhase.refundCompleted;
      message = 'Refund completed';
      return;
    }
    if (result.verificationState == 'refund_pending') {
      phase = CheckoutPhase.refundPending;
      message = 'Refund pending';
      return;
    }
    if (result.isPaidOnline || result.verificationState == 'paid') {
      phase = CheckoutPhase.successful;
      message = 'Payment successful';
      return;
    }
    if (result.verificationState == 'paid_cash') {
      phase = CheckoutPhase.alreadyPaid;
      message = 'Payment already completed';
      return;
    }
    switch (result.verificationState) {
      case 'failed':
        phase = CheckoutPhase.failed;
        message = 'Payment failed';
        return;
      case 'cancelled':
        phase = CheckoutPhase.cancelled;
        message = 'Payment cancelled';
        return;
      case 'pending':
        if (phase == CheckoutPhase.awaiting || phase == CheckoutPhase.opening) return;
        phase = CheckoutPhase.idle;
        message = 'Pay Now';
        return;
      case 'verifying':
      case 'unknown':
      default:
        phase = CheckoutPhase.unknown;
        message = paymentVerificationMessage;
    }
  }

  void fail(String text) {
    phase = CheckoutPhase.failed;
    message = text.isEmpty ? 'Payment failed' : text;
  }

  void cancelled() {
    phase = CheckoutPhase.cancelled;
    message = 'Payment cancelled';
  }

  void unknown([String? text]) {
    phase = CheckoutPhase.unknown;
    message = (text == null || text.isEmpty) ? paymentVerificationMessage : text;
  }
}

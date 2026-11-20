import 'package:flutter_test/flutter_test.dart';
import 'package:laundry_customer_app/services/checkout_session.dart';
import 'package:laundry_customer_app/services/payment_service.dart';

PayIntentResult result({
  String verificationState = 'pending',
  String paymentStatus = 'pending',
  String? paymentMethod,
  Map<String, dynamic>? intent,
  String provider = 'razorpay',
}) {
  return PayIntentResult(
    provider: provider,
    providerRef: intent?['razorpayOrderId'] as String?,
    intent: intent,
    finalAmount: '100.00',
    paymentStatus: paymentStatus,
    paymentMethod: paymentMethod,
    transactionId: paymentStatus == 'completed' ? 'pay_1' : null,
    verificationState: verificationState,
    refundStatus: verificationState == 'refund_pending'
        ? 'pending'
        : verificationState == 'refund_completed'
            ? 'processed'
            : null,
  );
}

void main() {
  test('pay-intent payload becomes Checkout options and does not invent an amount', () {
    final launch = launchFromIntent(result(intent: {
      'keyId': 'rzp_test_public',
      'razorpayOrderId': 'order_1',
      'amount': 10000,
      'currency': 'INR',
    }));
    expect(launch, isNotNull);
    expect(launch!.toOptions()['order_id'], 'order_1');
    expect(launch.toOptions()['amount'], 10000);
    expect(launch.toOptions()['key'], 'rzp_test_public');
    expect(launch.toOptions().containsKey('method'), isFalse);
  });

  test('a missing order id does not open Checkout', () {
    expect(launchFromIntent(result(intent: {'keyId': 'rzp_test_public', 'amount': 100})), isNull);
  });

  test('success is shown only after the server says the payment is captured', () {
    final session = CheckoutSession()..verifying();
    session.applyServerResult(result(
      verificationState: 'paid',
      paymentStatus: 'completed',
      paymentMethod: 'upi',
    ));
    expect(session.phase, CheckoutPhase.successful);
    expect(session.message, 'Payment successful');
  });

  test('a failed server status is a failure, not a success', () {
    final session = CheckoutSession()..begin();
    session.applyServerResult(result(verificationState: 'failed'));
    expect(session.phase, CheckoutPhase.failed);
    expect(session.message, 'Payment failed');
  });

  test('cancellation is a terminal unpaid state', () {
    final session = CheckoutSession()..awaitingExternalApp();
    session.cancelled();
    expect(session.phase, CheckoutPhase.cancelled);
    expect(session.blocksAnotherCheckout, isFalse);
  });

  test('a second tap cannot open another Checkout while one is open', () {
    final session = CheckoutSession();
    expect(session.begin(), isTrue);
    expect(session.begin(), isFalse);
    session.awaitingExternalApp();
    expect(session.begin(), isFalse);
    expect(session.phase, CheckoutPhase.awaiting);
  });

  test('leaving the app for a UPI app does not cancel the payment', () {
    final session = CheckoutSession()..awaitingExternalApp();
    session.pausedForExternalApp();
    expect(session.phase, CheckoutPhase.awaiting);
    expect(session.message, 'Awaiting payment');
  });

  test('a confirmation timeout keeps the verification message', () {
    final session = CheckoutSession()..verifying();
    session.unknown(describePaymentError(Exception('Failed to confirm payment')));
    expect(session.phase, CheckoutPhase.unknown);
    expect(session.message, paymentVerificationMessage);
    expect(session.showRefresh, isTrue);
    expect(session.blocksAnotherCheckout, isTrue);
    session.applyServerResult(result(verificationState: 'pending'));
    expect(session.phase, CheckoutPhase.idle);
    expect(session.begin(), isTrue);
  });

  test('resume after a missing callback shows paid when the server has captured it', () {
    final session = CheckoutSession()..awaitingExternalApp();
    session.pausedForExternalApp();
    session.applyServerResult(result(
      verificationState: 'paid',
      paymentStatus: 'completed',
      paymentMethod: 'card',
    ));
    expect(session.phase, CheckoutPhase.successful);
  });

  test('reopening the app on a pending attempt does not start a new charge by itself', () {
    final session = CheckoutSession();
    session.applyServerResult(result(verificationState: 'pending'));
    expect(session.phase, CheckoutPhase.idle);
    expect(session.blocksAnotherCheckout, isFalse);
  });

  test('an already completed payment is not opened in Checkout', () {
    final session = CheckoutSession()..begin();
    session.applyServerResult(result(
      verificationState: 'paid',
      paymentStatus: 'completed',
      paymentMethod: 'upi',
    ));
    expect(session.phase, CheckoutPhase.successful);
    expect(launchFromIntent(result(intent: null)), isNull);
  });

  test('refund states are distinct from a new success', () {
    final pending = CheckoutSession()
      ..applyServerResult(result(verificationState: 'refund_pending', paymentStatus: 'completed', paymentMethod: 'cash'));
    expect(pending.phase, CheckoutPhase.refundPending);
    expect(pending.message, 'Refund pending');

    final done = CheckoutSession()
      ..applyServerResult(result(verificationState: 'refund_completed', paymentStatus: 'completed', paymentMethod: 'cash'));
    expect(done.phase, CheckoutPhase.refundCompleted);
    expect(done.message, 'Refund completed');
  });
}

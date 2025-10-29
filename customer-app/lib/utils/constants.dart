class AppConstants {
  // Order Status
  static const String orderStatusPickup = 'pickup';
  static const String orderStatusInProcess = 'in_process';
  static const String orderStatusReady = 'ready';
  static const String orderStatusOutForDelivery = 'out_for_delivery';
  static const String orderStatusDelivered = 'delivered';

  // Payment Status
  static const String paymentStatusPending = 'pending';
  static const String paymentStatusCompleted = 'completed';
  static const String paymentStatusFailed = 'failed';
  static const String paymentStatusRefunded = 'refunded';

  // Payment Methods
  static const String paymentMethodCard = 'card';
  static const String paymentMethodCod = 'cod';
  static const String paymentMethodUpi = 'upi';
  static const String paymentMethodWallet = 'wallet';

  // Pricing Models
  static const String pricingModelPerPiece = 'per-unit-piece';
  static const String pricingModelPerKg = 'per-kg';
}

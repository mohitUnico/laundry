class SignupArgs {
  final String email;
  final String sessionToken;

  const SignupArgs({
    required this.email,
    required this.sessionToken,
  });
}

class OrderTrackingArgs {
  final String orderId;
  final String? pickupAddress;
  final double? pickupLat;
  final double? pickupLng;

  const OrderTrackingArgs({
    required this.orderId,
    this.pickupAddress,
    this.pickupLat,
    this.pickupLng,
  });
}



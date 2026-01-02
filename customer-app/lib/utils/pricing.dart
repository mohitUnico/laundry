class Pricing {
  /// Deterministic "random" unit price for frontend testing.
  /// Returns INR per piece (₹/pc).
  static int unitPriceInr({
    required String category,
    required String serviceName,
    required String itemName,
  }) {
    final key = '$category|$serviceName|$itemName';
    final raw = key.hashCode.abs();

    // ₹20 .. ₹90 in steps of ₹5
    final step = raw % 15; // 0..14
    return 20 + (step * 5);
  }

  /// Formats INR value as ₹X
  static String inr(int rupees) {
    return '₹$rupees';
  }

  static String inrPerPc(int rupees) {
    return '₹$rupees/pc';
  }
}



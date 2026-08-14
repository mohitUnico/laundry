class PromoCodeModel {
  final String code;
  final String headline;
  final String subhead;
  final PromoCodeType type;
  final double discountValue; // Percentage (0.20 = 20%) or flat amount

  const PromoCodeModel({
    required this.code,
    required this.headline,
    required this.subhead,
    required this.type,
    required this.discountValue,
  });

  /// Calculate discount amount based on subtotal
  int calculateDiscount(int subtotal) {
    switch (type) {
      case PromoCodeType.percentage:
        return (subtotal * discountValue).round();
      case PromoCodeType.flat:
        return discountValue.toInt();
    }
  }
}

enum PromoCodeType {
  percentage, // e.g., 20% off
  flat, // e.g., ₹50 off
}

class PromoCodeService {
  /// Get all available promo codes from home screen banners
  static List<PromoCodeModel> getAvailablePromoCodes() {
    return const [
      PromoCodeModel(
        code: 'WELCOME20',
        headline: '20% OFF',
        subhead: 'Welcome Offer',
        type: PromoCodeType.percentage,
        discountValue: 0.20, // 20%
      ),
      PromoCodeModel(
        code: 'WEEKEND15',
        headline: '15% OFF',
        subhead: 'Weekend Deal',
        type: PromoCodeType.percentage,
        discountValue: 0.15, // 15%
      ),
      PromoCodeModel(
        code: 'FIRST50',
        headline: '₹50 OFF',
        subhead: 'First Order',
        type: PromoCodeType.flat,
        discountValue: 50, // Flat ₹50
      ),
    ];
  }

  /// Validate and get promo code by code string
  static PromoCodeModel? validatePromoCode(String code) {
    final upperCode = code.trim().toUpperCase();
    final promoCodes = getAvailablePromoCodes();
    try {
      return promoCodes.firstWhere((p) => p.code == upperCode);
    } catch (e) {
      return null;
    }
  }

  /// Check if promo code exists
  static bool isValidPromoCode(String code) {
    return validatePromoCode(code) != null;
  }
}


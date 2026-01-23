class Coupon {
  final int id;
  final String code;
  final String? description;
  final String discountType;
  final num discountValue;
  final num? maxDiscount;
  final num? minOrderValue;
  final int? usageLimit;
  final int? usagePerUser;
  final DateTime? validFrom;
  final DateTime? validTill;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Coupon({
    required this.id,
    required this.code,
    required this.description,
    required this.discountType,
    required this.discountValue,
    required this.maxDiscount,
    required this.minOrderValue,
    required this.usageLimit,
    required this.usagePerUser,
    required this.validFrom,
    required this.validTill,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Coupon.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic v) {
      if (v == null) return null;
      if (v is String && v.isNotEmpty) return DateTime.tryParse(v);
      return null;
    }

    num parseNum(dynamic v, {num fallback = 0}) {
      if (v == null) return fallback;
      if (v is num) return v;
      if (v is String) return num.tryParse(v) ?? fallback;
      return fallback;
    }

    num? parseNullableNum(dynamic v) {
      if (v == null) return null;
      if (v is num) return v;
      if (v is String) return num.tryParse(v);
      return null;
    }

    return Coupon(
      id: (json['id'] as num).toInt(),
      code: (json['code'] ?? '').toString(),
      description: json['description']?.toString(),
      discountType: (json['discount_type'] ?? '').toString(),
      discountValue: parseNum(json['discount_value']),
      maxDiscount: parseNullableNum(json['max_discount']),
      minOrderValue: parseNullableNum(json['min_order_value']),
      usageLimit: (json['usage_limit'] as num?)?.toInt(),
      usagePerUser: (json['usage_per_user'] as num?)?.toInt(),
      validFrom: parseDate(json['valid_from']),
      validTill: parseDate(json['valid_till']),
      isActive: json['is_active'] == true,
      createdAt: parseDate(json['created_at']),
      updatedAt: parseDate(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'description': description,
      'discount_type': discountType,
      'discount_value': discountValue,
      'max_discount': maxDiscount,
      'min_order_value': minOrderValue,
      'usage_limit': usageLimit,
      'usage_per_user': usagePerUser,
      'valid_from': validFrom?.toIso8601String(),
      'valid_till': validTill?.toIso8601String(),
      'is_active': isActive,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}



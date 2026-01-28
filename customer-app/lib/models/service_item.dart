class ServiceItem {
  final String serviceId;
  final String categoryId;
  final String serviceName;
  final double? perKgPrice;
  final bool isActive;
  final int displayOrder;

  const ServiceItem({
    required this.serviceId,
    required this.categoryId,
    required this.serviceName,
    this.perKgPrice,
    required this.isActive,
    required this.displayOrder,
  });

  factory ServiceItem.fromJson(Map<String, dynamic> json) {
    final rawPerKg = json['per_kg_price'];
    double? perKg;
    if (rawPerKg is num) {
      perKg = rawPerKg.toDouble();
    } else if (rawPerKg is String) {
      perKg = double.tryParse(rawPerKg);
    }
    return ServiceItem(
      serviceId: (json['service_id'] ?? '') as String,
      categoryId: (json['category_id'] ?? '') as String,
      serviceName: (json['service_name'] ?? '') as String,
      perKgPrice: perKg,
      isActive: (json['is_active'] ?? true) as bool,
      displayOrder: (json['display_order'] ?? 0) as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'service_id': serviceId,
      'category_id': categoryId,
      'service_name': serviceName,
      'per_kg_price': perKgPrice,
      'is_active': isActive,
      'display_order': displayOrder,
    };
  }
}



class ServiceItem {
  final String serviceId;
  final String categoryId;
  final String serviceName;
  final bool isActive;
  final int displayOrder;

  const ServiceItem({
    required this.serviceId,
    required this.categoryId,
    required this.serviceName,
    required this.isActive,
    required this.displayOrder,
  });

  factory ServiceItem.fromJson(Map<String, dynamic> json) {
    return ServiceItem(
      serviceId: (json['service_id'] ?? '') as String,
      categoryId: (json['category_id'] ?? '') as String,
      serviceName: (json['service_name'] ?? '') as String,
      isActive: (json['is_active'] ?? true) as bool,
      displayOrder: (json['display_order'] ?? 0) as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'service_id': serviceId,
      'category_id': categoryId,
      'service_name': serviceName,
      'is_active': isActive,
      'display_order': displayOrder,
    };
  }
}



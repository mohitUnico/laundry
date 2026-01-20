class ClothesItem {
  final String clothId;
  final String serviceId;
  final String itemName;
  final double perUnitPrice;
  final bool isActive;
  final int displayOrder;
  final String? iconUrl;

  const ClothesItem({
    required this.clothId,
    required this.serviceId,
    required this.itemName,
    required this.perUnitPrice,
    required this.isActive,
    required this.displayOrder,
    this.iconUrl,
  });

  factory ClothesItem.fromJson(Map<String, dynamic> json) {
    double parsePrice(dynamic v) {
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v) ?? 0.0;
      return 0.0;
    }

    return ClothesItem(
      clothId: (json['cloth_id'] ?? '') as String,
      serviceId: (json['service_id'] ?? '') as String,
      itemName: (json['item_name'] ?? '') as String,
      perUnitPrice: parsePrice(json['per_unit_price']),
      isActive: (json['is_active'] ?? true) as bool,
      displayOrder: (json['display_order'] ?? 0) as int,
      iconUrl: json['icon_url'] as String?,
    );
  }
}



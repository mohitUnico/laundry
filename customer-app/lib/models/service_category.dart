class ServiceCategory {
  final String categoryId;
  final String categoryName;
  final bool isActive;
  final int displayOrder;

  const ServiceCategory({
    required this.categoryId,
    required this.categoryName,
    required this.isActive,
    required this.displayOrder,
  });

  factory ServiceCategory.fromJson(Map<String, dynamic> json) {
    return ServiceCategory(
      categoryId: (json['category_id'] ?? '') as String,
      categoryName: (json['category_name'] ?? '') as String,
      isActive: (json['is_active'] ?? true) as bool,
      displayOrder: (json['display_order'] ?? 0) as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'category_id': categoryId,
      'category_name': categoryName,
      'is_active': isActive,
      'display_order': displayOrder,
    };
  }
}



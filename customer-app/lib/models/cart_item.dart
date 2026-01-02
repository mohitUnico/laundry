class CartItem {
  final String id;
  final String category;
  final String serviceName;
  final String? imageAsset;
  final Map<String, int> quantities;
  // Nullable for hot-reload safety: existing in-memory objects created before this
  // field existed will have null here until app restart.
  final Map<String, int>? unitPricesInr;
  final bool isPerPiece;
  final String? note;

  const CartItem({
    required this.id,
    required this.category,
    required this.serviceName,
    required this.quantities,
    this.unitPricesInr,
    this.isPerPiece = true,
    this.imageAsset,
    this.note,
  });

  int get totalQuantity => quantities.values.fold<int>(0, (a, b) => a + b);

  int get subtotalInr {
    int sum = 0;
    if (!isPerPiece) return 0;
    final prices = unitPricesInr ?? const <String, int>{};
    for (final e in quantities.entries) {
      final unit = prices[e.key] ?? 0;
      sum += e.value * unit;
    }
    return sum;
  }

  CartItem copyWith({
    String? id,
    String? category,
    String? serviceName,
    String? imageAsset,
    Map<String, int>? quantities,
    Map<String, int>? unitPricesInr,
    bool? isPerPiece,
    String? note,
  }) {
    return CartItem(
      id: id ?? this.id,
      category: category ?? this.category,
      serviceName: serviceName ?? this.serviceName,
      imageAsset: imageAsset ?? this.imageAsset,
      quantities: quantities ?? this.quantities,
      unitPricesInr: unitPricesInr ?? this.unitPricesInr,
      isPerPiece: isPerPiece ?? this.isPerPiece,
      note: note ?? this.note,
    );
  }
}



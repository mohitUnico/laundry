import 'package:flutter/foundation.dart';

import '../models/cart_item.dart';
import '../utils/pricing.dart';

class CartProvider with ChangeNotifier {
  final List<CartItem> _items = [];

  List<CartItem> get items => List.unmodifiable(_items);

  int get totalInr =>
      _items.where((x) => x.isPerPiece).fold<int>(0, (sum, x) => sum + x.subtotalInr);

  bool get hasPricedItems => _items.any((x) => x.isPerPiece);

  void addOrMerge({
    required String category,
    required String serviceName,
    required Map<String, int> quantities,
    bool isPerPiece = true,
    String? imageAsset,
    String? note,
  }) {
    final cleaned = <String, int>{};
    for (final e in quantities.entries) {
      final v = e.value;
      if (v > 0) cleaned[e.key] = v;
    }

    final trimmedNote = note?.trim();

    // Nothing to add.
    if (cleaned.isEmpty && (trimmedNote == null || trimmedNote.isEmpty)) return;

    final newPrices = <String, int>{};
    if (isPerPiece) {
      for (final name in cleaned.keys) {
        newPrices[name] = Pricing.unitPriceInr(
          category: category,
          serviceName: serviceName,
          itemName: name,
        );
      }
    }

    final existingIndex = _items.indexWhere(
      (x) => x.category == category && x.serviceName == serviceName,
    );

    if (existingIndex >= 0) {
      final existing = _items[existingIndex];
      final mergedQty = <String, int>{...existing.quantities};
      for (final e in cleaned.entries) {
        mergedQty[e.key] = (mergedQty[e.key] ?? 0) + e.value;
      }

      final mergedPrices = <String, int>{...(existing.unitPricesInr ?? const {})};
      if (isPerPiece) {
        for (final e in newPrices.entries) {
          mergedPrices.putIfAbsent(e.key, () => e.value);
        }
      }

      _items[existingIndex] = existing.copyWith(
        quantities: mergedQty,
        unitPricesInr: isPerPiece ? mergedPrices : existing.unitPricesInr,
        isPerPiece: existing.isPerPiece || isPerPiece,
        imageAsset: imageAsset ?? existing.imageAsset,
        note: (trimmedNote != null && trimmedNote.isNotEmpty)
            ? trimmedNote
            : existing.note,
      );
    } else {
      _items.add(
        CartItem(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          category: category,
          serviceName: serviceName,
          imageAsset: imageAsset,
          quantities: cleaned,
          unitPricesInr: isPerPiece ? newPrices : null,
          isPerPiece: isPerPiece,
          note: (trimmedNote != null && trimmedNote.isNotEmpty) ? trimmedNote : null,
        ),
      );
    }

    notifyListeners();
  }

  void remove(String id) {
    _items.removeWhere((x) => x.id == id);
    notifyListeners();
  }

  void incrementFirst(String id) {
    final idx = _items.indexWhere((x) => x.id == id);
    if (idx < 0) return;

    final item = _items[idx];
    if (item.quantities.isEmpty) return;
    final firstKey = item.quantities.keys.first;
    final nextQty = <String, int>{...item.quantities};
    nextQty[firstKey] = ((nextQty[firstKey] ?? 0) + 1).clamp(0, 999);
    _items[idx] = item.copyWith(quantities: nextQty);
    notifyListeners();
  }

  void decrementFirst(String id) {
    final idx = _items.indexWhere((x) => x.id == id);
    if (idx < 0) return;

    final item = _items[idx];
    if (item.quantities.isEmpty) return;
    final firstKey = item.quantities.keys.first;
    final nextQty = <String, int>{...item.quantities};
    nextQty[firstKey] = ((nextQty[firstKey] ?? 0) - 1).clamp(0, 999);
    if ((nextQty[firstKey] ?? 0) == 0) {
      nextQty.remove(firstKey);
    }

    if (nextQty.isEmpty) {
      _items.removeAt(idx);
    } else {
      _items[idx] = item.copyWith(quantities: nextQty);
    }

    notifyListeners();
  }

  void updateItemQuantity(String id, String itemName, int delta) {
    final idx = _items.indexWhere((x) => x.id == id);
    if (idx < 0) return;

    final item = _items[idx];
    final nextQty = <String, int>{...item.quantities};
    final currentQty = nextQty[itemName] ?? 0;
    final newQty = (currentQty + delta).clamp(0, 999);

    if (newQty == 0) {
      nextQty.remove(itemName);
    } else {
      nextQty[itemName] = newQty;
    }

    if (nextQty.isEmpty) {
      _items.removeAt(idx);
    } else {
      _items[idx] = item.copyWith(quantities: nextQty);
    }

    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }
}



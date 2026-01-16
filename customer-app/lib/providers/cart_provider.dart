import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/cart_item.dart';
import '../utils/pricing.dart';
import '../repositories/cart_repository.dart';

class CartProvider with ChangeNotifier {
  final CartRepository _repo;
  final List<CartItem> _items = [];

  CartProvider({CartRepository? repo}) : _repo = repo ?? CartRepository();

  List<CartItem> get items => List.unmodifiable(_items);

  int get totalInr =>
      _items.where((x) => x.isPerPiece).fold<int>(0, (sum, x) => sum + x.subtotalInr);

  bool get hasPricedItems => _items.any((x) => x.isPerPiece);

  void addOrMerge({
    required String category,
    required String serviceName,
    required Map<String, int> quantities,
    bool isPerPiece = true,
    Map<String, int>? unitPricesInr,
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
      if (unitPricesInr != null && unitPricesInr.isNotEmpty) {
        newPrices.addAll(unitPricesInr);
      } else {
        for (final name in cleaned.keys) {
          newPrices[name] = Pricing.unitPriceInr(
            category: category,
            serviceName: serviceName,
            itemName: name,
          );
        }
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

  Future<void> addAndSave({
    required String category,
    required String serviceName,
    required String serviceId,
    required Map<String, int> quantities,
    required Map<String, String> clothIdByItemName,
    bool isPerPiece = true,
    Map<String, int>? unitPricesInr,
    double? weightKg,
    String? imageAsset,
    String? note,
  }) async {
    // First update local cart (so UI responds immediately)
    addOrMerge(
      category: category,
      serviceName: serviceName,
      quantities: isPerPiece ? quantities : const <String, int>{},
      isPerPiece: isPerPiece,
      unitPricesInr: unitPricesInr,
      imageAsset: imageAsset,
      note: note,
    );

    // Then persist to backend with exact payload keys expected by backend.
    final cleaned = <String, int>{};
    for (final e in quantities.entries) {
      if (e.value > 0) cleaned[e.key] = e.value;
    }

    final List<Map<String, dynamic>> itemsPayload;

    if (isPerPiece) {
      final selections = <Map<String, dynamic>>[];
      for (final e in cleaned.entries) {
        final clothId = clothIdByItemName[e.key];
        if (clothId == null || clothId.isEmpty) {
          throw Exception('Missing cloth_id for item: ${e.key}');
        }
        selections.add({
          'cloth_id': clothId,
          'quantity': e.value,
        });
      }

      if (selections.isEmpty) {
        // Nothing to persist for per_unit
        return;
      }

      itemsPayload = [
        {
          'service_id': serviceId,
          'pricing_type': 'per_unit',
          'selections': selections,
        }
      ];
    } else {
      final w = weightKg;
      if (w == null || w <= 0) {
        throw Exception('weight_kg is required for Kg-wise pricing');
      }

      itemsPayload = [
        {
          'service_id': serviceId,
          'pricing_type': 'per_kg',
          'weight_kg': w,
        }
      ];
    }

    // Store server cart_item_id so we can update quantities later using a single endpoint.
    // Note: backend currently returns only cart item ids (not selection ids), so we update by cloth_id.
    final addRes = await _repo.addCartItems(items: itemsPayload);

    // Attach server-required metadata locally (serviceId, clothId map, prices, weight)
    // so we can build payloads later if needed.
    final idx = _items.lastIndexWhere((x) => x.category == category && x.serviceName == serviceName);
    if (idx >= 0) {
      final existing = _items[idx];
      _items[idx] = existing.copyWith(
        serviceId: serviceId,
        clothIdByItemName: clothIdByItemName,
        unitPricesInr: unitPricesInr ?? existing.unitPricesInr,
        weightKg: weightKg ?? existing.weightKg,
        cartItemId: addRes.addedCartItemIds.isNotEmpty ? addRes.addedCartItemIds.first : existing.cartItemId,
      );
      notifyListeners();
    }
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

    // Persist remotely (single endpoint) if we have enough metadata.
    unawaited(_persistSelectionQuantity(item: item, itemName: itemName, quantity: newQty));
  }

  Future<void> _persistSelectionQuantity({
    required CartItem item,
    required String itemName,
    required int quantity,
  }) async {
    try {
      final cartItemId = item.cartItemId;
      final clothId = item.clothIdByItemName?[itemName];

      if (cartItemId == null || cartItemId.isEmpty) return;
      if (clothId == null || clothId.isEmpty) return;

      await _repo.setSelectionQuantity(
        cartItemId: cartItemId,
        clothId: clothId,
        quantity: quantity,
      );
    } catch (_) {
      // Keep UI responsive; cart will re-sync when we start reading cart from backend.
      // Intentionally swallow for now (no global snackbar handler here).
    }
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }
}



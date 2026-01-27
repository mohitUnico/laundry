import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/cart_item.dart';
import '../utils/pricing.dart';
import '../repositories/cart_repository.dart';

class CartProvider with ChangeNotifier {
  final CartRepository _repo;
  final List<CartItem> _items = [];
  String? _activeCartId;
  bool _isAddingToCart = false;

  CartProvider({CartRepository? repo}) : _repo = repo ?? CartRepository();

  String? get activeCartId => _activeCartId;
  bool get isAddingToCart => _isAddingToCart;

  List<CartItem> get items => List.unmodifiable(_items);

  int get totalInr =>
      _items.where((x) => x.isPerPiece).fold<int>(0, (sum, x) => sum + x.subtotalInr);

  bool get hasPricedItems => _items.any((x) => x.isPerPiece);
  
  bool get hasOnlyKgWiseItems => _items.isNotEmpty && _items.every((x) => !x.isPerPiece);
  
  bool get hasAnyKgWiseItems => _items.any((x) => !x.isPerPiece);
  
  bool get hasMixedItems => _items.any((x) => x.isPerPiece) && _items.any((x) => !x.isPerPiece);

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

    // Nothing to add (must have at least one item quantity).
    if (cleaned.isEmpty) return;

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
    if (_isAddingToCart) return; // Prevent multiple calls
    
    _isAddingToCart = true;
    notifyListeners();

    try {
      // Must have at least one item selected (non-zero quantity).
      // We intentionally do NOT allow adding a service with only a note and 0 qty.
      final cleaned = <String, int>{};
      for (final e in quantities.entries) {
        if (e.value > 0) cleaned[e.key] = e.value;
      }
      if (cleaned.isEmpty) {
        throw Exception('Please select at least 1 item before adding to cart.');
      }

      // First update local cart (so UI responds immediately)
      // For both per-piece and kg-wise, include quantities to show cloth items
      addOrMerge(
        category: category,
        serviceName: serviceName,
        quantities: quantities, // Include quantities for both per-piece and kg-wise
        isPerPiece: isPerPiece,
        unitPricesInr: unitPricesInr,
        imageAsset: imageAsset,
        note: note,
      );

      // Then persist to backend with exact payload keys expected by backend.
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
          _isAddingToCart = false;
          notifyListeners();
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
        // For per_kg items, we can also include selections to track cloth items
        // weight_kg is optional (will be calculated after supervision)
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

        itemsPayload = [
          {
            'service_id': serviceId,
            'pricing_type': 'per_kg',
            // Include selections to track cloth items for kg-wise services
            'selections': selections.isNotEmpty ? selections : [],
            // weight_kg is optional - can be null, will be set later
            'weight_kg': weightKg != null && weightKg > 0 ? weightKg : null,
          }
        ];
      }

      // Store server cart_item_id so we can update quantities later using a single endpoint.
      // Note: backend currently returns only cart item ids (not selection ids), so we update by cloth_id.
      final addRes = await _repo.addCartItems(items: itemsPayload);

      // Store active cart_id for order creation
      _activeCartId = addRes.cartId;

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
    } catch (e) {
      // Re-throw error after resetting loading state
      _isAddingToCart = false;
      notifyListeners();
      rethrow;
    } finally {
      _isAddingToCart = false;
      notifyListeners();
    }
  }

  Future<void> remove(String id) async {
    final item = _items.firstWhere((x) => x.id == id, orElse: () => throw Exception('Item not found'));
    final cartItemId = item.cartItemId;
    
    // Remove from local state immediately for responsive UI
    _items.removeWhere((x) => x.id == id);
    notifyListeners();

    // Delete from backend if cartItemId exists
    if (cartItemId != null && cartItemId.isNotEmpty) {
      try {
        await _repo.deleteCartItem(cartItemId: cartItemId);
      } catch (e) {
        // If delete fails, re-add item to local state
        _items.add(item);
        notifyListeners();
        debugPrint('Failed to delete cart item from backend: $e');
        rethrow;
      }
    }
  }

  Future<void> fetchFromBackend() async {
    try {
      final carts = await _repo.getCarts();
      _items.clear();

      // Find the active cart
      final activeCart = carts.firstWhere(
        (cart) => cart['is_active'] == true,
        orElse: () => <String, dynamic>{},
      );

      if (activeCart.isEmpty) {
        _activeCartId = null;
        notifyListeners();
        return;
      }

      // Store active cart_id
      _activeCartId = activeCart['cart_id'] as String?;

      final cartItems = (activeCart['cart_items'] as List?) ?? [];
      for (final cartItemData in cartItems) {
        final service = cartItemData['service'] as Map<String, dynamic>?;
        if (service == null) continue;

        final serviceName = service['service_name'] as String? ?? '';
        final pricingType = cartItemData['pricing_type'] as String? ?? 'per_unit';
        final isPerPiece = pricingType == 'per_unit';
        final cartItemId = cartItemData['cart_item_id'] as String? ?? '';

        // Get category from service (if available) or default
        const category = 'Service'; // Default, can be enhanced if category is in response

        if (isPerPiece) {
          final selections = (cartItemData['item_selections'] as List?) ?? [];
          final quantities = <String, int>{};
          final clothIdByItemName = <String, String>{};
          final unitPricesInr = <String, int>{};

          for (final selection in selections) {
            final clothItem = selection['cloth_item'] as Map<String, dynamic>?;
            if (clothItem == null) continue;

            final itemName = clothItem['item_name'] as String? ?? '';
            final quantity = selection['quantity'] as int? ?? 0;
            final clothId = clothItem['cloth_id'] as String? ?? '';
            
            // Handle per_unit_price which can be num, String (from Prisma Decimal), or null
            int perUnitPrice = 0;
            final priceValue = clothItem['per_unit_price'];
            if (priceValue != null) {
              if (priceValue is num) {
                perUnitPrice = priceValue.toInt();
              } else if (priceValue is String) {
                // Prisma Decimal is serialized as string
                perUnitPrice = (double.tryParse(priceValue) ?? 0.0).toInt();
              }
            }

            if (itemName.isNotEmpty && quantity > 0) {
              quantities[itemName] = quantity;
              clothIdByItemName[itemName] = clothId;
              unitPricesInr[itemName] = perUnitPrice;
            }
          }

          if (quantities.isNotEmpty) {
            _items.add(
              CartItem(
                id: cartItemId.isNotEmpty ? cartItemId : DateTime.now().microsecondsSinceEpoch.toString(),
                category: category,
                serviceName: serviceName,
                serviceId: service['service_id'] as String?,
                cartItemId: cartItemId,
                quantities: quantities,
                clothIdByItemName: clothIdByItemName,
                unitPricesInr: unitPricesInr,
                isPerPiece: true,
                imageAsset: service['icon_url'] as String?,
              ),
            );
          }
        } else {
          // Per kg item - parse selections if available (to show cloth items)
          final selections = (cartItemData['item_selections'] as List?) ?? [];
          final quantities = <String, int>{};
          final clothIdByItemName = <String, String>{};

          for (final selection in selections) {
            final clothItem = selection['cloth_item'] as Map<String, dynamic>?;
            if (clothItem == null) continue;

            final itemName = clothItem['item_name'] as String? ?? '';
            final quantity = selection['quantity'] as int? ?? 0;
            final clothId = clothItem['cloth_id'] as String? ?? '';

            if (itemName.isNotEmpty && quantity > 0) {
              quantities[itemName] = quantity;
              clothIdByItemName[itemName] = clothId;
            }
          }

          final weightKg = (cartItemData['weight_kg'] is num)
              ? (cartItemData['weight_kg'] as num).toDouble()
              : null;

          // Show kg-wise items even if weight is null
          _items.add(
            CartItem(
              id: cartItemId.isNotEmpty ? cartItemId : DateTime.now().microsecondsSinceEpoch.toString(),
              category: category,
              serviceName: serviceName,
              serviceId: service['service_id'] as String?,
              cartItemId: cartItemId,
              quantities: quantities, // Include selections for kg-wise items
              clothIdByItemName: clothIdByItemName,
              isPerPiece: false,
              weightKg: weightKg, // Can be null - will be calculated after supervision
              imageAsset: service['icon_url'] as String?,
            ),
          );
        }
      }

      notifyListeners();
    } catch (e) {
      // Silently fail - cart will remain in local state
      debugPrint('Failed to fetch cart from backend: $e');
    }
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
    _activeCartId = null;
    notifyListeners();
  }

  /// Clears cart locally and best-effort clears the active cart on backend.
  ///
  /// Why: Order creation should delete the cart server-side, but if anything
  /// leaves the cart active (race/deploy mismatch), the app must not show
  /// stale items after successful order placement.
  Future<void> clearAfterOrderPlaced() async {
    // Always clear local state first (fast UI feedback).
    clear();

    try {
      final carts = await _repo.getCarts();

      // Find active cart (backend returns both active+inactive).
      final activeCart = carts.cast<Map<String, dynamic>>().firstWhere(
            (c) => c['is_active'] == true,
            orElse: () => <String, dynamic>{},
          );

      if (activeCart.isEmpty) return;

      final cartItems = (activeCart['cart_items'] as List?) ?? const [];
      if (cartItems.isEmpty) return;

      // Delete all cart items best-effort. If backend already deleted the cart,
      // these calls may fail (404) — we intentionally ignore.
      for (final raw in cartItems) {
        final item = raw as Map<String, dynamic>?;
        final cartItemId = (item?['cart_item_id'] ?? '').toString().trim();
        if (cartItemId.isEmpty) continue;
        try {
          await _repo.deleteCartItem(cartItemId: cartItemId);
        } catch (_) {
          // ignore best-effort
        }
      }
    } catch (_) {
      // ignore best-effort
    } finally {
      // Ensure local is clean even if backend cleanup failed.
      clear();
    }
  }
}



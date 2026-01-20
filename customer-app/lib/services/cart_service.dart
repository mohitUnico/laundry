import 'package:dio/dio.dart';

import 'api_service.dart';

class CartAddItemsResult {
  final String cartId;
  final List<String> addedCartItemIds;

  const CartAddItemsResult({
    required this.cartId,
    required this.addedCartItemIds,
  });

  factory CartAddItemsResult.fromJson(Map<String, dynamic> json) {
    return CartAddItemsResult(
      cartId: (json['cart_id'] ?? '') as String,
      addedCartItemIds: ((json['added_cart_item_ids'] as List?) ?? const [])
          .whereType<String>()
          .toList(),
    );
  }
}

class CartService {
  final ApiService _api;

  CartService({ApiService? api}) : _api = api ?? ApiService();

  Future<CartAddItemsResult> addCartItems({
    required List<Map<String, dynamic>> items,
  }) async {
    try {
      final res = await _api.post(
        '/carts/items',
        data: {'items': items},
      );

      final data = (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
      return CartAddItemsResult.fromJson(data);
    } on DioException catch (e) {
      final msg = _extractErrorMessage(e, 'Failed to add cart items');
      throw Exception(msg);
    } catch (e) {
      throw Exception('Failed to add cart items: $e');
    }
  }

  Future<void> setSelectionQuantity({
    required String cartItemId,
    required String clothId,
    required int quantity,
  }) async {
    try {
      await _api.patch(
        '/carts/items/$cartItemId/selections/quantity',
        data: {
          'cloth_id': clothId,
          'quantity': quantity,
        },
      );
    } on DioException catch (e) {
      final msg = _extractErrorMessage(e, 'Failed to update cart quantity');
      throw Exception(msg);
    } catch (e) {
      throw Exception('Failed to update cart quantity: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getCarts() async {
    try {
      final res = await _api.get('/carts');
      final data = (res.data as Map<String, dynamic>)['data'] as List?;
      return (data ?? []).whereType<Map<String, dynamic>>().toList();
    } on DioException catch (e) {
      final msg = _extractErrorMessage(e, 'Failed to fetch cart items');
      throw Exception(msg);
    } catch (e) {
      throw Exception('Failed to fetch cart items: $e');
    }
  }

  Future<void> deleteCartItem({
    required String cartItemId,
  }) async {
    try {
      await _api.delete('/carts/items/$cartItemId');
    } on DioException catch (e) {
      final msg = _extractErrorMessage(e, 'Failed to delete cart item');
      throw Exception(msg);
    } catch (e) {
      throw Exception('Failed to delete cart item: $e');
    }
  }

  String _extractErrorMessage(DioException e, String fallback) {
    try {
      final data = e.response?.data;
      if (data is Map<String, dynamic>) {
        final message = data['message'];
        if (message is String && message.isNotEmpty) return message;
      }
    } catch (_) {
      // ignore
    }
    return fallback;
  }
}



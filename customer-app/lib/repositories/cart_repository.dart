import '../services/cart_service.dart';

class CartRepository {
  final CartService _service;

  CartRepository({CartService? service}) : _service = service ?? CartService();

  Future<CartAddItemsResult> addCartItems({
    required List<Map<String, dynamic>> items,
  }) {
    return _service.addCartItems(items: items);
  }

  Future<void> setSelectionQuantity({
    required String cartItemId,
    required String clothId,
    required int quantity,
  }) {
    return _service.setSelectionQuantity(
      cartItemId: cartItemId,
      clothId: clothId,
      quantity: quantity,
    );
  }

  Future<List<Map<String, dynamic>>> getCarts() {
    return _service.getCarts();
  }

  Future<void> deleteCartItem({
    required String cartItemId,
  }) {
    return _service.deleteCartItem(cartItemId: cartItemId);
  }
}



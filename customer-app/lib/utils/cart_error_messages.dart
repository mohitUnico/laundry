import 'package:dio/dio.dart';

/// Utility class to convert technical errors into user-friendly messages
/// for cart and order operations.
class CartErrorMessages {
  /// Converts any error to a user-friendly message for cart operations.
  static String getCartErrorMessage(dynamic error, {
    String? operation, // e.g., 'delete item', 'add to cart', 'update quantity'
  }) {
    if (error is DioException) {
      return _getDioErrorMessage(error, operation: operation);
    }
    
    if (error is Exception) {
      final message = error.toString().toLowerCase();
      
      // Handle common exception messages
      if (message.contains('missing') || message.contains('invalid')) {
        if (message.contains('cart') || message.contains('item')) {
          return 'Cart item not found. Please refresh and try again.';
        }
        if (message.contains('address')) {
          return 'Please select a delivery address before placing your order.';
        }
        return 'Some required information is missing. Please try again.';
      }
      
      if (message.contains('network') || message.contains('connection')) {
        return 'Please check your internet connection and try again.';
      }
      
      if (message.contains('timeout')) {
        return 'Request timed out. Please try again.';
      }
      
      if (message.contains('not found')) {
        if (message.contains('cart') || message.contains('item')) {
          return 'Cart item not found. It may have been removed.';
        }
        return 'Item not found. Please refresh and try again.';
      }
    }
    
    // Generic fallback
    return _getGenericErrorMessage(operation);
  }

  /// Converts any error to a user-friendly message for order operations.
  static String getOrderErrorMessage(dynamic error, {
    String? operation, // e.g., 'create order', 'update order', 'place order'
  }) {
    if (error is DioException) {
      return _getDioErrorMessage(error, operation: operation);
    }
    
    if (error is Exception) {
      final message = error.toString().toLowerCase();
      
      // Handle common exception messages
      if (message.contains('missing') || message.contains('invalid')) {
        if (message.contains('cart') || message.contains('empty')) {
          return 'Your cart is empty. Please add items before placing an order.';
        }
        if (message.contains('address')) {
          return 'Please add a delivery address before placing your order.';
        }
        if (message.contains('date') || message.contains('time')) {
          return 'Please select a pickup date and time for your order.';
        }
        return 'Some required information is missing. Please check your order details.';
      }
      
      if (message.contains('network') || message.contains('connection')) {
        return 'Please check your internet connection and try again.';
      }
      
      if (message.contains('timeout')) {
        return 'Order placement timed out. Please try again.';
      }
      
      if (message.contains('not found')) {
        if (message.contains('cart')) {
          return 'Your cart was not found. Please add items to cart again.';
        }
        return 'Order details not found. Please try again.';
      }
    }
    
    // Generic fallback
    return _getGenericErrorMessage(operation);
  }

  /// Handles DioException errors with specific status codes and messages.
  static String _getDioErrorMessage(DioException error, {String? operation}) {
    // Try to extract message from response
    try {
      final data = error.response?.data;
      if (data is Map<String, dynamic>) {
        final message = (data['message'] ?? '') as String;
        if (message.isNotEmpty) {
          // Convert backend messages to user-friendly ones
          return _convertBackendMessage(message, operation: operation);
        }
      }
    } catch (_) {
      // Ignore parsing errors
    }

    // Handle by status code
    final statusCode = error.response?.statusCode;
    switch (statusCode) {
      case 400:
        return _getBadRequestMessage(operation);
      case 401:
        return 'Your session has expired. Please login again.';
      case 403:
        return 'You don\'t have permission to perform this action.';
      case 404:
        if (operation != null && operation.toLowerCase().contains('cart')) {
          return 'Cart not found. Please add items to your cart again.';
        }
        return 'Item not found. Please refresh and try again.';
      case 409:
        return 'This item is already in your cart.';
      case 422:
        return _getValidationErrorMessage(operation);
      case 429:
        return 'Too many requests. Please wait a moment and try again.';
      case 500:
      case 502:
      case 503:
        return 'Our servers are experiencing issues. Please try again in a few moments.';
      default:
        break;
    }

    // Handle connection errors
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout) {
      return 'Connection timed out. Please check your internet and try again.';
    }

    if (error.type == DioExceptionType.connectionError) {
      return 'Unable to connect to our servers. Please check your internet connection.';
    }

    if (error.type == DioExceptionType.badResponse) {
      return _getGenericErrorMessage(operation);
    }

    // Generic fallback
    return _getGenericErrorMessage(operation);
  }

  /// Converts backend error messages to user-friendly ones.
  static String _convertBackendMessage(String backendMessage, {String? operation}) {
    final lower = backendMessage.toLowerCase();
    
    // Cart related
    if (lower.contains('cart') && (lower.contains('empty') || lower.contains('not found'))) {
      return 'Your cart is empty. Please add items before placing an order.';
    }
    if (lower.contains('cart') && lower.contains('invalid')) {
      return 'Invalid cart. Please refresh and try again.';
    }
    
    // Item related
    if (lower.contains('item') && (lower.contains('not found') || lower.contains('missing'))) {
      return 'Item not found. It may have been removed from your cart.';
    }
    if (lower.contains('item') && lower.contains('invalid')) {
      return 'Invalid item. Please refresh and try again.';
    }
    
    // Order related
    if (lower.contains('order') && lower.contains('failed')) {
      return 'Failed to place your order. Please try again.';
    }
    if (lower.contains('order') && lower.contains('invalid')) {
      return 'Invalid order details. Please check and try again.';
    }
    if (lower.contains('order') && (lower.contains('not found') || lower.contains('missing'))) {
      return 'Order not found. Please try placing your order again.';
    }
    
    // Address related
    if (lower.contains('address') && (lower.contains('required') || lower.contains('missing'))) {
      return 'Please add a delivery address before placing your order.';
    }
    if (lower.contains('address') && lower.contains('invalid')) {
      return 'Invalid address. Please select a valid delivery address.';
    }
    
    // Date/Time related
    if ((lower.contains('date') || lower.contains('time')) && (lower.contains('required') || lower.contains('missing'))) {
      return 'Please select a pickup date and time for your order.';
    }
    if ((lower.contains('date') || lower.contains('time')) && lower.contains('invalid')) {
      return 'Invalid date or time selected. Please choose a valid schedule.';
    }
    
    // Quantity related
    if (lower.contains('quantity') && (lower.contains('invalid') || lower.contains('zero'))) {
      return 'Invalid quantity. Please select at least one item.';
    }
    
    // Rate limiting
    if (lower.contains('rate limit') || lower.contains('too many')) {
      return 'Too many attempts. Please wait a moment before trying again.';
    }
    
    // Generic validation
    if (lower.contains('validation') || lower.contains('invalid input')) {
      return 'Please check your input and try again.';
    }
    
    // If we can't convert it, return a generic message
    return _getGenericErrorMessage(operation);
  }

  /// Returns user-friendly message for 400 Bad Request errors.
  static String _getBadRequestMessage(String? operation) {
    if (operation != null) {
      final lower = operation.toLowerCase();
      if (lower.contains('delete') || lower.contains('remove')) {
        return 'Unable to remove item. Please try again.';
      }
      if (lower.contains('add') || lower.contains('cart')) {
        return 'Unable to add item to cart. Please try again.';
      }
      if (lower.contains('order') || lower.contains('place')) {
        return 'Unable to place order. Please check your order details and try again.';
      }
      if (lower.contains('update') || lower.contains('quantity')) {
        return 'Unable to update item. Please try again.';
      }
    }
    return 'Invalid request. Please check your information and try again.';
  }

  /// Returns user-friendly message for 422 Validation errors.
  static String _getValidationErrorMessage(String? operation) {
    if (operation != null) {
      final lower = operation.toLowerCase();
      if (lower.contains('cart') || lower.contains('item')) {
        return 'Invalid cart item. Please refresh and try again.';
      }
      if (lower.contains('order')) {
        return 'Invalid order details. Please check your information and try again.';
      }
      if (lower.contains('address')) {
        return 'Invalid address. Please select a valid delivery address.';
      }
      if (lower.contains('date') || lower.contains('time')) {
        return 'Invalid date or time. Please select a valid schedule.';
      }
    }
    return 'Please check your information and try again.';
  }

  /// Returns a generic error message based on the operation.
  static String _getGenericErrorMessage(String? operation) {
    if (operation != null) {
      final lower = operation.toLowerCase();
      if (lower.contains('delete') || lower.contains('remove')) {
        return 'Failed to remove item from cart. Please try again.';
      }
      if (lower.contains('add') || lower.contains('cart')) {
        return 'Failed to add item to cart. Please try again.';
      }
      if (lower.contains('order') || lower.contains('place') || lower.contains('create')) {
        return 'Failed to place your order. Please try again.';
      }
      if (lower.contains('update') || lower.contains('quantity')) {
        return 'Failed to update item. Please try again.';
      }
      if (lower.contains('fetch') || lower.contains('load')) {
        return 'Failed to load cart. Please try again.';
      }
    }
    return 'Something went wrong. Please try again.';
  }
}


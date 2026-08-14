import 'package:dio/dio.dart';

/// Utility class to convert technical errors into user-friendly messages
/// for order and payment operations.
class OrderPaymentErrorMessages {
  /// Converts any error to a user-friendly message for order operations.
  static String getOrderErrorMessage(dynamic error, {
    String? operation, // e.g., 'create order', 'fetch orders', 'update order'
  }) {
    if (error is DioException) {
      return _getDioErrorMessage(error, operation: operation);
    }
    
    if (error is Exception) {
      final message = error.toString().toLowerCase();
      
      // Handle common exception messages
      if (message.contains('missing') || message.contains('invalid')) {
        if (message.contains('cart') || message.contains('item')) {
          return 'Cart items are missing. Please add items to cart and try again.';
        }
        if (message.contains('address')) {
          return 'Please select a valid address before placing an order.';
        }
        if (message.contains('order')) {
          return 'Order information is incomplete. Please try again.';
        }
      }
      
      if (message.contains('timeout') || message.contains('connection')) {
        return 'Connection timeout. Please check your internet and try again.';
      }
      
      if (message.contains('unauthorized') || message.contains('session')) {
        return 'Your session has expired. Please login again.';
      }
    }
    
    // Default fallback
    final operationText = operation != null ? ' $operation' : '';
    return 'Unable to$operationText. Please try again later.';
  }

  /// Converts any error to a user-friendly message for payment operations.
  static String getPaymentErrorMessage(dynamic error, {
    String? operation, // e.g., 'process payment', 'verify payment', 'refund'
  }) {
    if (error is DioException) {
      return _getDioErrorMessage(error, operation: operation);
    }
    
    if (error is Exception) {
      final message = error.toString().toLowerCase();
      
      // Handle common exception messages
      if (message.contains('payment') || message.contains('transaction')) {
        if (message.contains('failed') || message.contains('declined')) {
          return 'Payment failed. Please check your payment method and try again.';
        }
        if (message.contains('insufficient') || message.contains('balance')) {
          return 'Insufficient balance. Please use a different payment method.';
        }
        if (message.contains('expired') || message.contains('invalid')) {
          return 'Payment method is invalid or expired. Please use a different card.';
        }
      }
      
      if (message.contains('timeout') || message.contains('connection')) {
        return 'Payment processing timeout. Please try again.';
      }
      
      if (message.contains('unauthorized') || message.contains('session')) {
        return 'Your session has expired. Please login again.';
      }
    }
    
    // Default fallback
    final operationText = operation != null ? ' $operation' : '';
    return 'Unable to$operationText. Please try again or use a different payment method.';
  }

  /// Handles DioException errors with specific HTTP status codes.
  static String _getDioErrorMessage(DioException error, {String? operation}) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Connection timeout. Please check your internet connection and try again.';
      
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        if (statusCode != null) {
          return _getHttpErrorMessage(statusCode, operation: operation);
        }
        return 'Server error. Please try again later.';
      
      case DioExceptionType.cancel:
        return 'Request cancelled. Please try again.';
      
      case DioExceptionType.connectionError:
        return 'No internet connection. Please check your network and try again.';
      
      case DioExceptionType.badCertificate:
        return 'Security error. Please try again later.';
      
      case DioExceptionType.unknown:
        final message = error.message?.toLowerCase() ?? '';
        if (message.contains('socket') || message.contains('network')) {
          return 'Network error. Please check your internet connection.';
        }
        return 'An unexpected error occurred. Please try again.';
    }
  }

  /// Maps HTTP status codes to user-friendly messages.
  static String _getHttpErrorMessage(int statusCode, {String? operation}) {
    switch (statusCode) {
      case 400:
        if (operation?.contains('order') ?? false) {
          return 'Invalid order details. Please check and try again.';
        }
        if (operation?.contains('payment') ?? false) {
          return 'Invalid payment information. Please check your payment details.';
        }
        return 'Invalid request. Please check your information and try again.';
      
      case 401:
        return 'Your session has expired. Please login again.';
      
      case 403:
        return 'You don\'t have permission to perform this action.';
      
      case 404:
        if (operation?.contains('order') ?? false) {
          return 'Order not found. Please refresh and try again.';
        }
        return 'Resource not found. Please try again.';
      
      case 409:
        if (operation?.contains('order') ?? false) {
          return 'Order already exists. Please check your orders list.';
        }
        return 'Conflict occurred. Please try again.';
      
      case 422:
        if (operation?.contains('order') ?? false) {
          return 'Order validation failed. Please check your cart and address.';
        }
        if (operation?.contains('payment') ?? false) {
          return 'Payment validation failed. Please check your payment details.';
        }
        return 'Validation error. Please check your information.';
      
      case 429:
        return 'Too many requests. Please wait a moment and try again.';
      
      case 500:
      case 502:
      case 503:
        return 'Server is temporarily unavailable. Please try again later.';
      
      default:
        final operationText = operation != null ? ' $operation' : '';
        return 'Unable to$operationText. Please try again later.';
    }
  }
}


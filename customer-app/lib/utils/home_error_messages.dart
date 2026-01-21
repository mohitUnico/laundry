import 'package:dio/dio.dart';

/// Utility class to convert technical errors into user-friendly messages
/// for home screen and general app operations.
class HomeErrorMessages {
  /// Converts any error to a user-friendly message for general operations.
  static String getErrorMessage(dynamic error, {
    String? operation, // e.g., 'load services', 'fetch orders', 'load categories'
  }) {
    if (error is DioException) {
      return _getDioErrorMessage(error, operation: operation);
    }
    
    if (error is Exception) {
      final message = error.toString().toLowerCase();
      
      // Handle common exception messages
      if (message.contains('missing') || message.contains('invalid')) {
        if (message.contains('service') || message.contains('catalog')) {
          return 'Unable to load services. Please try again.';
        }
        if (message.contains('order')) {
          return 'Unable to load orders. Please try again.';
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
        if (message.contains('service') || message.contains('category')) {
          return 'Service not found. Please refresh and try again.';
        }
        return 'Item not found. Please refresh and try again.';
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
        if (operation != null && operation.toLowerCase().contains('service')) {
          return 'Service not found. Please refresh and try again.';
        }
        return 'Item not found. Please refresh and try again.';
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
    
    // Service/Catalog related
    if (lower.contains('service') && (lower.contains('not found') || lower.contains('missing'))) {
      return 'Service not found. Please refresh and try again.';
    }
    if (lower.contains('category') && (lower.contains('not found') || lower.contains('missing'))) {
      return 'Category not found. Please refresh and try again.';
    }
    if (lower.contains('catalog') && lower.contains('invalid')) {
      return 'Unable to load service catalog. Please try again.';
    }
    
    // Order related
    if (lower.contains('order') && (lower.contains('not found') || lower.contains('missing'))) {
      return 'Unable to load orders. Please try again.';
    }
    
    // Rate limiting
    if (lower.contains('rate limit') || lower.contains('too many')) {
      return 'Too many requests. Please wait a moment before trying again.';
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
      if (lower.contains('service') || lower.contains('catalog')) {
        return 'Unable to load services. Please try again.';
      }
      if (lower.contains('order')) {
        return 'Unable to load orders. Please try again.';
      }
    }
    return 'Invalid request. Please try again.';
  }

  /// Returns user-friendly message for 422 Validation errors.
  static String _getValidationErrorMessage(String? operation) {
    if (operation != null) {
      final lower = operation.toLowerCase();
      if (lower.contains('service') || lower.contains('catalog')) {
        return 'Invalid service information. Please refresh and try again.';
      }
      if (lower.contains('order')) {
        return 'Invalid order information. Please try again.';
      }
    }
    return 'Please check your information and try again.';
  }

  /// Returns a generic error message based on the operation.
  static String _getGenericErrorMessage(String? operation) {
    if (operation != null) {
      final lower = operation.toLowerCase();
      if (lower.contains('service') || lower.contains('catalog') || lower.contains('category')) {
        return 'Unable to load services. Please try again.';
      }
      if (lower.contains('order')) {
        return 'Unable to load orders. Please try again.';
      }
      if (lower.contains('fetch') || lower.contains('load')) {
        return 'Failed to load data. Please try again.';
      }
    }
    return 'Something went wrong. Please try again.';
  }
}


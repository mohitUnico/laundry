import 'package:dio/dio.dart';

/// Utility class to convert technical errors into user-friendly messages
/// for location and address operations.
class LocationErrorMessages {
  /// Converts any error to a user-friendly message for address operations.
  static String getAddressErrorMessage(dynamic error, {
    String? operation, // e.g., 'save address', 'update address', 'delete address', 'load addresses'
  }) {
    if (error is DioException) {
      return _getDioErrorMessage(error, operation: operation);
    }
    
    if (error is Exception) {
      final message = error.toString().toLowerCase();
      
      // Handle common exception messages
      if (message.contains('missing') || message.contains('invalid')) {
        if (message.contains('address')) {
          return 'Invalid address. Please check and try again.';
        }
        if (message.contains('location') || message.contains('latitude') || message.contains('longitude')) {
          return 'Please select a valid location on the map.';
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
        if (message.contains('address')) {
          return 'Address not found. Please refresh and try again.';
        }
        return 'Item not found. Please refresh and try again.';
      }
    }
    
    // Generic fallback
    return _getGenericErrorMessage(operation);
  }

  /// Converts any error to a user-friendly message for location/geocoding operations.
  static String getLocationErrorMessage(dynamic error) {
    if (error is DioException) {
      return _getDioErrorMessage(error, operation: 'get location');
    }
    
    if (error is Exception) {
      final message = error.toString().toLowerCase();
      
      // Handle common location-related errors
      if (message.contains('permission')) {
        return 'Location permission is required. Please allow location access.';
      }
      if (message.contains('service') || message.contains('disabled')) {
        return 'Location services are disabled. Please enable them in device settings.';
      }
      if (message.contains('timeout')) {
        return 'Location request timed out. Please try again.';
      }
      if (message.contains('network') || message.contains('connection')) {
        return 'Unable to get location. Please check your internet connection.';
      }
      if (message.contains('geocoding') || message.contains('geocode')) {
        return 'Unable to find address for this location. Please try selecting a different location.';
      }
    }
    
    return 'Unable to get your location. Please try again.';
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
        if (operation != null && operation.toLowerCase().contains('address')) {
          return 'Address not found. Please refresh and try again.';
        }
        return 'Item not found. Please refresh and try again.';
      case 409:
        return 'This address already exists. Please use a different label.';
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
    
    // Address related
    if (lower.contains('address') && (lower.contains('not found') || lower.contains('missing'))) {
      return 'Address not found. Please refresh and try again.';
    }
    if (lower.contains('address') && lower.contains('invalid')) {
      return 'Invalid address. Please check and try again.';
    }
    if (lower.contains('address') && lower.contains('required')) {
      return 'Please provide a complete address.';
    }
    if (lower.contains('address') && lower.contains('already') && lower.contains('exist')) {
      return 'This address already exists. Please use a different label.';
    }
    
    // Location related
    if (lower.contains('location') && (lower.contains('invalid') || lower.contains('missing'))) {
      return 'Invalid location. Please select a location on the map.';
    }
    if (lower.contains('latitude') || lower.contains('longitude')) {
      return 'Invalid location coordinates. Please select a location on the map.';
    }
    
    // Label related
    if (lower.contains('label') && (lower.contains('required') || lower.contains('missing'))) {
      return 'Please provide an address label (e.g., Home, Work).';
    }
    if (lower.contains('label') && lower.contains('invalid')) {
      return 'Invalid address label. Please use a different label.';
    }
    
    // Rate limiting
    if (lower.contains('rate limit') || lower.contains('too many')) {
      return 'Too many requests. Please wait a moment before trying again.';
    }
    
    // Generic validation
    if (lower.contains('validation') || lower.contains('invalid input')) {
      return 'Please check your address information and try again.';
    }
    
    // If we can't convert it, return a generic message
    return _getGenericErrorMessage(operation);
  }

  /// Returns user-friendly message for 400 Bad Request errors.
  static String _getBadRequestMessage(String? operation) {
    if (operation != null) {
      final lower = operation.toLowerCase();
      if (lower.contains('save') || lower.contains('create')) {
        return 'Unable to save address. Please check your information and try again.';
      }
      if (lower.contains('update')) {
        return 'Unable to update address. Please check your information and try again.';
      }
      if (lower.contains('delete') || lower.contains('remove')) {
        return 'Unable to delete address. Please try again.';
      }
      if (lower.contains('load') || lower.contains('fetch')) {
        return 'Unable to load addresses. Please try again.';
      }
    }
    return 'Invalid request. Please check your information and try again.';
  }

  /// Returns user-friendly message for 422 Validation errors.
  static String _getValidationErrorMessage(String? operation) {
    if (operation != null) {
      final lower = operation.toLowerCase();
      if (lower.contains('address')) {
        return 'Invalid address information. Please check and try again.';
      }
      if (lower.contains('location')) {
        return 'Invalid location. Please select a valid location on the map.';
      }
    }
    return 'Please check your address information and try again.';
  }

  /// Returns a generic error message based on the operation.
  static String _getGenericErrorMessage(String? operation) {
    if (operation != null) {
      final lower = operation.toLowerCase();
      if (lower.contains('save') || lower.contains('create')) {
        return 'Failed to save address. Please try again.';
      }
      if (lower.contains('update')) {
        return 'Failed to update address. Please try again.';
      }
      if (lower.contains('delete') || lower.contains('remove')) {
        return 'Failed to delete address. Please try again.';
      }
      if (lower.contains('load') || lower.contains('fetch')) {
        return 'Failed to load addresses. Please try again.';
      }
      if (lower.contains('get') && lower.contains('location')) {
        return 'Unable to get your location. Please try again.';
      }
    }
    return 'Something went wrong. Please try again.';
  }
}


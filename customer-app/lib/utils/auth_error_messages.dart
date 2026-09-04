import 'package:dio/dio.dart';

/// Utility class to convert technical errors into user-friendly messages
/// for authentication flows.
class AuthErrorMessages {
  /// Converts any error to a user-friendly message for authentication operations.
  static String getAuthErrorMessage(dynamic error, {
    String? operation, // e.g., 'send OTP', 'verify OTP', 'register'
  }) {
    if (error is DioException) {
      return _getDioErrorMessage(error, operation: operation);
    }
    
    if (error is Exception) {
      final message = error.toString().toLowerCase();
      
      // Handle common exception messages
      if (message.contains('missing') || message.contains('invalid')) {
        if (message.contains('token') || message.contains('session')) {
          return 'Your session has expired. Please login again.';
        }
        if (message.contains('email')) {
          return 'Please enter a valid email address.';
        }
        if (message.contains('otp')) {
          return 'Please enter a valid OTP code.';
        }
        return 'Some required information is missing. Please try again.';
      }
      
      if (message.contains('network') || message.contains('connection')) {
        return 'Please check your internet connection and try again.';
      }
      
      if (message.contains('timeout')) {
        return 'Request timed out. Please try again.';
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
        return 'Service not found. Please try again later.';
      case 409:
        return _getConflictMessage(operation);
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
    
    // OTP related
    if (lower.contains('otp') && lower.contains('already used')) {
      return 'This OTP was already used. Please request a new one.';
    }
    if (lower.contains('otp') && lower.contains('invalid')) {
      return 'The OTP code you entered is incorrect. Please check and try again.';
    }
    if (lower.contains('otp') && lower.contains('expired')) {
      return 'The OTP code has expired. Please request a new one.';
    }
    if (lower.contains('otp') && (lower.contains('not found') || lower.contains('missing'))) {
      return 'No OTP found. Please request a new OTP code.';
    }
    
    // Email related
    if (lower.contains('email') && (lower.contains('invalid') || lower.contains('format'))) {
      return 'Please enter a valid email address.';
    }
    if (lower.contains('email') && lower.contains('already') && lower.contains('exist')) {
      return 'This email is already registered. Please login instead.';
    }
    if (lower.contains('email') && (lower.contains('not found') || lower.contains('does not exist'))) {
      return 'No account found with this email. Please sign up first.';
    }
    
    // Phone related
    if (lower.contains('phone') && (lower.contains('invalid') || lower.contains('format'))) {
      return 'Please enter a valid phone number.';
    }
    if (lower.contains('phone') && lower.contains('already')) {
      return 'This phone number is already registered.';
    }
    
    // Name related
    if (lower.contains('name') && (lower.contains('required') || lower.contains('missing'))) {
      return 'Please enter your full name.';
    }
    if (lower.contains('name') && lower.contains('invalid')) {
      return 'Please enter a valid name.';
    }
    
    // Session/Token related
    if (lower.contains('session') || lower.contains('token')) {
      if (lower.contains('expired') || lower.contains('invalid')) {
        return 'Your session has expired. Please login again.';
      }
      if (lower.contains('missing') || lower.contains('not found')) {
        return 'Session not found. Please login again.';
      }
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
      if (operation.toLowerCase().contains('otp')) {
        return 'Invalid request. Please check your OTP code and try again.';
      }
      if (operation.toLowerCase().contains('register') || operation.toLowerCase().contains('signup')) {
        return 'Invalid information provided. Please check your details and try again.';
      }
    }
    return 'Invalid request. Please check your information and try again.';
  }

  /// Returns user-friendly message for 409 Conflict errors.
  static String _getConflictMessage(String? operation) {
    if (operation != null && operation.toLowerCase().contains('register')) {
      return 'An account with this email already exists. Please login instead.';
    }
    return 'This information is already in use. Please use different details.';
  }

  /// Returns user-friendly message for 422 Validation errors.
  static String _getValidationErrorMessage(String? operation) {
    if (operation != null) {
      if (operation.toLowerCase().contains('otp')) {
        return 'Please enter a valid 6-digit OTP code.';
      }
      if (operation.toLowerCase().contains('email')) {
        return 'Please enter a valid email address.';
      }
      if (operation.toLowerCase().contains('phone')) {
        return 'Please enter a valid phone number.';
      }
      if (operation.toLowerCase().contains('name')) {
        return 'Please enter a valid name.';
      }
    }
    return 'Please check your information and try again.';
  }

  /// Returns a generic error message based on the operation.
  static String _getGenericErrorMessage(String? operation) {
    if (operation != null) {
      final lower = operation.toLowerCase();
      if (lower.contains('send') && lower.contains('otp')) {
        return 'Failed to send OTP. Please try again.';
      }
      if (lower.contains('resend') && lower.contains('otp')) {
        return 'Failed to resend OTP. Please try again.';
      }
      if (lower.contains('verify') && lower.contains('otp')) {
        return 'Failed to verify OTP. Please check your code and try again.';
      }
      if (lower.contains('register') || lower.contains('signup')) {
        return 'Registration failed. Please try again.';
      }
      if (lower.contains('upload') && lower.contains('photo')) {
        return 'Failed to upload photo. Please try again.';
      }
    }
    return 'Something went wrong. Please try again.';
  }

  /// Gets user-friendly error message for image picker errors.
  static String getImagePickerErrorMessage(dynamic error) {
    final message = error.toString().toLowerCase();
    
    if (message.contains('permission')) {
      return 'Permission denied. Please allow camera/gallery access in settings.';
    }
    if (message.contains('camera')) {
      return 'Camera error. Please try again or select from gallery.';
    }
    if (message.contains('gallery') || message.contains('photo')) {
      return 'Unable to access photos. Please try again.';
    }
    if (message.contains('cancel')) {
      return 'Photo selection cancelled.';
    }
    
    return 'Failed to pick image. Please try again.';
  }

  /// Gets user-friendly error message for location permission errors.
  static String getLocationErrorMessage(dynamic error) {
    final message = error.toString().toLowerCase();
    
    if (message.contains('permission')) {
      return 'Location permission is required. Please allow location access.';
    }
    if (message.contains('service') || message.contains('disabled')) {
      return 'Location services are disabled. Please enable them in device settings.';
    }
    if (message.contains('timeout')) {
      return 'Location request timed out. Please try again.';
    }
    
    return 'Unable to get your location. Please try again.';
  }
}


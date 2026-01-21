import 'package:dio/dio.dart';

/// Utility class to convert technical errors into user-friendly messages
/// for profile and service operations.
class ProfileServiceErrorMessages {
  /// Converts any error to a user-friendly message for profile operations.
  static String getProfileErrorMessage(dynamic error, {
    String? operation, // e.g., 'update profile', 'upload photo', 'fetch profile'
  }) {
    if (error is DioException) {
      return _getDioErrorMessage(error, operation: operation);
    }
    
    if (error is Exception) {
      final message = error.toString().toLowerCase();
      
      // Handle common exception messages
      if (message.contains('missing') || message.contains('invalid')) {
        if (message.contains('name') || message.contains('phone')) {
          return 'Please check your name and phone number and try again.';
        }
        if (message.contains('image') || message.contains('photo')) {
          return 'Invalid image. Please select a different photo.';
        }
        if (message.contains('profile')) {
          return 'Profile information is incomplete. Please check and try again.';
        }
      }
      
      if (message.contains('permission') || message.contains('denied')) {
        return 'Permission denied. Please enable camera or photo access in settings.';
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

  /// Converts any error to a user-friendly message for service operations.
  static String getServiceErrorMessage(dynamic error, {
    String? operation, // e.g., 'add to cart', 'load service', 'fetch services'
  }) {
    if (error is DioException) {
      return _getDioErrorMessage(error, operation: operation);
    }
    
    if (error is Exception) {
      final message = error.toString().toLowerCase();
      
      // Handle common exception messages
      if (message.contains('missing') || message.contains('invalid')) {
        if (message.contains('service') || message.contains('item')) {
          return 'Service information is missing. Please try again.';
        }
        if (message.contains('cart')) {
          return 'Unable to add to cart. Please try again.';
        }
      }
      
      if (message.contains('not found') || message.contains('category')) {
        return 'Service not found. Please browse available services.';
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

  /// Converts any error to a user-friendly message for external app operations.
  static String getExternalAppErrorMessage(dynamic error, {
    String? appName, // e.g., 'WhatsApp', 'Email', 'Phone'
  }) {
    if (error is Exception) {
      final message = error.toString().toLowerCase();
      
      if (message.contains('not installed') || message.contains('no app')) {
        final app = appName ?? 'app';
        return '$app is not installed on your device.';
      }
      
      if (message.contains('permission') || message.contains('denied')) {
        return 'Permission denied. Please enable access in settings.';
      }
      
      if (message.contains('timeout') || message.contains('connection')) {
        return 'Connection timeout. Please try again.';
      }
    }
    
    // Default fallback
    final app = appName ?? 'app';
    return 'Unable to open $app. Please try again.';
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
        if (operation?.contains('profile') ?? false) {
          return 'Invalid profile information. Please check and try again.';
        }
        if (operation?.contains('service') ?? false) {
          return 'Invalid service information. Please try again.';
        }
        return 'Invalid request. Please check your information and try again.';
      
      case 401:
        return 'Your session has expired. Please login again.';
      
      case 403:
        return 'You don\'t have permission to perform this action.';
      
      case 404:
        if (operation?.contains('service') ?? false) {
          return 'Service not found. Please browse available services.';
        }
        if (operation?.contains('profile') ?? false) {
          return 'Profile not found. Please try again.';
        }
        return 'Resource not found. Please try again.';
      
      case 409:
        return 'Conflict occurred. Please try again.';
      
      case 422:
        if (operation?.contains('profile') ?? false) {
          return 'Profile validation failed. Please check your information.';
        }
        if (operation?.contains('service') ?? false) {
          return 'Service validation failed. Please try again.';
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


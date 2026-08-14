class Validators {
  /// Validates email format
  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Please enter a valid email address';
    }
    
    return null;
  }

  /// Validates required field
  static String? required(String? value, {String fieldName = 'This field'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  /// Validates first name
  static String? firstName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'First name is required';
    }
    
    if (value.trim().length < 2) {
      return 'First name must be at least 2 characters';
    }
    
    if (value.trim().length > 50) {
      return 'First name must be less than 50 characters';
    }
    
    // Allow letters, spaces, hyphens, and apostrophes
    final nameRegex = RegExp(r"^[a-zA-Z\s'-]+$");
    if (!nameRegex.hasMatch(value.trim())) {
      return 'First name can only contain letters, spaces, hyphens, and apostrophes';
    }
    
    return null;
  }

  /// Validates last name
  static String? lastName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Last name is required';
    }
    
    if (value.trim().length < 2) {
      return 'Last name must be at least 2 characters';
    }
    
    if (value.trim().length > 50) {
      return 'Last name must be less than 50 characters';
    }
    
    // Allow letters, spaces, hyphens, and apostrophes
    final nameRegex = RegExp(r"^[a-zA-Z\s'-]+$");
    if (!nameRegex.hasMatch(value.trim())) {
      return 'Last name can only contain letters, spaces, hyphens, and apostrophes';
    }
    
    return null;
  }

  /// Validates OTP (6 digits)
  static String? otp(String? value) {
    if (value == null || value.isEmpty) {
      return 'OTP is required';
    }
    
    if (value.length != 6) {
      return 'OTP must be 6 digits';
    }
    
    final digitRegex = RegExp(r'^\d+$');
    if (!digitRegex.hasMatch(value)) {
      return 'OTP must contain only numbers';
    }
    
    return null;
  }

  /// Validates phone number
  static String? phoneNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }
    
    // Remove spaces, dashes, and parentheses
    final cleaned = value.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    
    // Check if it contains only digits
    final digitRegex = RegExp(r'^\d+$');
    if (!digitRegex.hasMatch(cleaned)) {
      return 'Phone number must contain only numbers';
    }
    
    // Check length (typically 10 digits for most countries, but allow 8-15 for international)
    if (cleaned.length < 8 || cleaned.length > 15) {
      return 'Phone number must be between 8 and 15 digits';
    }
    
    // For Indian numbers, check if it starts with valid prefix
    if (cleaned.length == 10) {
      if (!cleaned.startsWith(RegExp(r'[6-9]'))) {
        return 'Please enter a valid phone number';
      }
    }
    
    return null;
  }
}


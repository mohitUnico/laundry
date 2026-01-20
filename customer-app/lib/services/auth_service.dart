import 'package:dio/dio.dart';

import 'api_service.dart';

class CustomerSendOtpResult {
  final String email;
  final int expiresIn;

  const CustomerSendOtpResult({
    required this.email,
    required this.expiresIn,
  });

  factory CustomerSendOtpResult.fromJson(Map<String, dynamic> json) {
    return CustomerSendOtpResult(
      email: (json['email'] ?? '') as String,
      expiresIn: (json['expiresIn'] ?? 0) as int,
    );
  }
}

class CustomerVerifyOtpResult {
  final bool isNewUser;
  final String? token;
  final String? refreshToken;
  final Map<String, dynamic>? user;
  final String? sessionToken;
  final int? expiresIn;

  const CustomerVerifyOtpResult({
    required this.isNewUser,
    this.token,
    this.refreshToken,
    this.user,
    this.sessionToken,
    this.expiresIn,
  });

  factory CustomerVerifyOtpResult.fromJson(Map<String, dynamic> json) {
    return CustomerVerifyOtpResult(
      isNewUser: (json['isNewUser'] ?? false) as bool,
      token: json['token'] as String?,
      refreshToken: json['refreshToken'] as String?,
      user: json['user'] as Map<String, dynamic>?,
      sessionToken: json['sessionToken'] as String?,
      expiresIn: json['expiresIn'] as int?,
    );
  }
}

class CustomerCompleteRegistrationResult {
  final String token;
  final String refreshToken;
  final Map<String, dynamic> customer;

  const CustomerCompleteRegistrationResult({
    required this.token,
    required this.refreshToken,
    required this.customer,
  });

  factory CustomerCompleteRegistrationResult.fromJson(Map<String, dynamic> json) {
    return CustomerCompleteRegistrationResult(
      token: (json['token'] ?? '') as String,
      refreshToken: (json['refreshToken'] ?? '') as String,
      customer: (json['customer'] ?? <String, dynamic>{}) as Map<String, dynamic>,
    );
  }
}

class RefreshTokenResult {
  final String token;
  final String refreshToken;
  final Map<String, dynamic>? user;

  const RefreshTokenResult({
    required this.token,
    required this.refreshToken,
    this.user,
  });

  factory RefreshTokenResult.fromJson(Map<String, dynamic> json) {
    return RefreshTokenResult(
      token: (json['token'] ?? '') as String,
      refreshToken: (json['refreshToken'] ?? '') as String,
      user: json['user'] as Map<String, dynamic>?,
    );
  }
}

class AuthService {
  final ApiService _api;

  AuthService({ApiService? api}) : _api = api ?? ApiService();

  Future<CustomerSendOtpResult> sendCustomerOtp({required String email}) async {
    final Response response = await _api.post(
      '/auth/customer/send-otp',
      data: {'email': email},
    );

    final data = (response.data as Map?)?['data'] as Map<String, dynamic>?;
    if (data == null) {
      throw Exception('Invalid response from send-otp');
    }
    return CustomerSendOtpResult.fromJson(data);
  }

  Future<CustomerSendOtpResult> resendCustomerOtp({required String email}) async {
    final Response response = await _api.post(
      '/auth/resend-otp',
      data: {
        'email': email,
        'userType': 'customer',
      },
    );

    final data = (response.data as Map?)?['data'] as Map<String, dynamic>?;
    if (data == null) {
      throw Exception('Invalid response from resend-otp');
    }
    return CustomerSendOtpResult.fromJson(data);
  }

  Future<CustomerVerifyOtpResult> verifyCustomerOtp({
    required String email,
    required String otp,
  }) async {
    final Response response = await _api.post(
      '/auth/customer/verify-otp',
      data: {'email': email, 'otp': otp},
    );

    final data = (response.data as Map?)?['data'] as Map<String, dynamic>?;
    if (data == null) {
      throw Exception('Invalid response from verify-otp');
    }
    return CustomerVerifyOtpResult.fromJson(data);
  }

  Future<CustomerCompleteRegistrationResult> completeCustomerRegistration({
    required String sessionToken,
    required String fullName,
    String? phone,
    Map<String, dynamic>? address,
  }) async {
    final Response response = await _api.post(
      '/auth/customer/complete-registration',
      data: {
        'sessionToken': sessionToken,
        'customerData': {
          'fullName': fullName,
          if (phone != null && phone.isNotEmpty) 'phone': phone,
          if (address != null) 'address': address,
        },
      },
    );

    final data = (response.data as Map?)?['data'] as Map<String, dynamic>?;
    if (data == null) {
      throw Exception('Invalid response from complete-registration');
    }
    return CustomerCompleteRegistrationResult.fromJson(data);
  }

  Future<RefreshTokenResult> refreshSession({required String refreshToken}) async {
    final Response response = await _api.post(
      '/auth/refresh',
      data: {'refreshToken': refreshToken},
    );

    final data = (response.data as Map?)?['data'] as Map<String, dynamic>?;
    if (data == null) {
      throw Exception('Invalid response from refresh');
    }
    return RefreshTokenResult.fromJson(data);
  }
}



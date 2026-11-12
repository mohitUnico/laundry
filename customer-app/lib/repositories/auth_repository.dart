import '../services/auth_service.dart';
import '../utils/auth_storage.dart';
import '../utils/jwt_utils.dart';

export '../services/auth_service.dart'
    show CustomerVerifyOtpResult, CustomerSendOtpResult, RefreshTokenResult;

class AuthRepository {
  final AuthService _service;

  AuthRepository({AuthService? service}) : _service = service ?? AuthService();

  Future<CustomerSendOtpResult> sendCustomerOtp({required String email}) {
    return _service.sendCustomerOtp(email: email);
  }

  Future<CustomerSendOtpResult> resendCustomerOtp({required String email}) {
    return _service.resendCustomerOtp(email: email);
  }

  /// Verifies OTP with the backend. An existing customer receives a JWT.
  Future<CustomerVerifyOtpResult> verifyCustomerOtp({
    required String email,
    required String otp,
  }) async {
    final result = await _service.verifyCustomerOtp(email: email, otp: otp);

    if (!result.isNewUser) {
      final token = result.token;
      final refresh = result.refreshToken;
      if (token == null || token.isEmpty) {
        throw Exception('Missing token in verify-otp response');
      }
      await AuthStorage.setAuthToken(token);
      if (refresh != null && refresh.isNotEmpty) {
        await AuthStorage.setRefreshToken(refresh);
      }
    }

    return result;
  }

  /// Completes registration and stores the JWT the backend returns.
  Future<CustomerCompleteRegistrationResult> completeCustomerRegistration({
    required String sessionToken,
    required String fullName,
    String? phone,
    Map<String, dynamic>? address,
  }) async {
    final result = await _service.completeCustomerRegistration(
      sessionToken: sessionToken,
      fullName: fullName,
      phone: phone,
      address: address,
    );

    await AuthStorage.setAuthToken(result.token);
    await AuthStorage.setRefreshToken(result.refreshToken);
    return result;
  }

  Future<String?> getStoredToken() async {
    return AuthStorage.getAuthToken();
  }

  Future<bool> hasValidStoredSession() async {
    final token = await getStoredToken();
    if (token == null || token.isEmpty) return false;
    return !JwtUtils.isExpired(token);
  }

  Future<void> clearSession() async {
    await AuthStorage.clearSession();
  }

  Future<RefreshTokenResult> refreshSession() async {
    final refresh = await AuthStorage.getRefreshToken();
    if (refresh == null || refresh.isEmpty) {
      throw Exception('Missing refresh token');
    }
    final result = await _service.refreshSession(refreshToken: refresh);
    if (result.token.isEmpty || result.refreshToken.isEmpty) {
      throw Exception('Invalid refresh response');
    }
    await AuthStorage.setAuthToken(result.token);
    await AuthStorage.setRefreshToken(result.refreshToken);
    return result;
  }
}

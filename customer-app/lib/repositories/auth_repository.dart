import '../services/auth_service.dart';
import '../services/local_auth_store.dart';
import '../utils/auth_storage.dart';
import '../utils/jwt_utils.dart';

export '../services/auth_service.dart'
    show CustomerVerifyOtpResult, CustomerSendOtpResult, RefreshTokenResult;

class AuthRepository {
  final LocalAuthStore _localAuth;

  AuthRepository({LocalAuthStore? localAuth})
      : _localAuth = localAuth ?? LocalAuthStore();

  Future<CustomerSendOtpResult> sendCustomerOtp({required String email}) {
    return _localAuth.sendOtp(email);
  }

  Future<CustomerSendOtpResult> resendCustomerOtp({required String email}) {
    return _localAuth.sendOtp(email);
  }

  /// Verifies OTP. If user exists, this also persists the returned JWT.
  Future<CustomerVerifyOtpResult> verifyCustomerOtp({
    required String email,
    required String otp,
  }) async {
    final result = await _localAuth.verifyOtp(email: email, otp: otp);

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

  /// Completes registration and persists the returned JWT.
  Future<CustomerCompleteRegistrationResult> completeCustomerRegistration({
    required String sessionToken,
    required String fullName,
    String? phone,
    Map<String, dynamic>? address,
  }) async {
    final result = await _localAuth.completeRegistration(
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
    final result = await _localAuth.refresh();
    if (result.token.isEmpty || result.refreshToken.isEmpty) {
      throw Exception('Invalid refresh response');
    }
    await AuthStorage.setAuthToken(result.token);
    await AuthStorage.setRefreshToken(result.refreshToken);
    return result;
  }
}



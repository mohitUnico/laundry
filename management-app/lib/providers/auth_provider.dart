import 'dart:io';

import 'package:flutter/foundation.dart';

import '../models/delivery_registration_draft.dart';
import '../services/delivery_auth_service.dart';
import '../services/staff_auth_service.dart';
import '../utils/auth_storage.dart';
import '../utils/role_manager.dart';
import '../utils/role_constants.dart';

class AuthProvider with ChangeNotifier {
  String? _token;
  Map<String, dynamic>? _partner;
  Map<String, dynamic>? _currentUser;
  bool _isAuthenticated = false;
  bool _isVerified = false;
  bool _isLoading = false;
  String? _error;

  DeliveryRegistrationDraft? _deliveryDraft;

  final DeliveryAuthService _deliveryAuthService = DeliveryAuthService();
  final StaffAuthService _staffAuthService = StaffAuthService();

  AuthProvider() {
    _hydrateFromStorage();
  }

  String? get token => _token;
  Map<String, dynamic>? get partner => _partner;
  Map<String, dynamic>? get currentUser => _currentUser;
  bool get isAuthenticated => _isAuthenticated;
  bool get isVerified => _isVerified;
  bool get isLoading => _isLoading;
  String? get error => _error;
  DeliveryRegistrationDraft? get deliveryDraft => _deliveryDraft;

  Future<void> _hydrateFromStorage() async {
    try {
      final token = await AuthStorage.getToken();
      if (token == null || token.isEmpty) return;

      _token = token;
      _currentUser = await AuthStorage.getCurrentUser();
      _partner = await AuthStorage.getDeliveryStaff();
      _isAuthenticated = true;
      _isVerified = true;
      notifyListeners();
    } catch (_) {
      // ignore: app can still proceed with manual login
    }
  }

  Future<void> login(String phone, String password) async {
    // TODO: Implement login logic
    _isAuthenticated = true;
    _isVerified = true;
    notifyListeners();
  }

  Future<void> sendDeliveryOtp({required String email}) async {
    _setLoading(true);
    _error = null;
    notifyListeners();

    try {
      await _deliveryAuthService.sendOtp(email: email);
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> sendOtpForRole({
    required String role,
    required String email,
    String? serviceId,
  }) async {
    if (role == RoleConstants.deliveryPartner) {
      return sendDeliveryOtp(email: email);
    }

    _setLoading(true);
    _error = null;
    notifyListeners();

    try {
      if (role == RoleConstants.collectionManager) {
        await _staffAuthService.sendCollectionManagerOtp(email: email);
      } else if (role == RoleConstants.distributionManager) {
        await _staffAuthService.sendDistributionManagerOtp(email: email);
      } else if (role == RoleConstants.serviceMan) {
        final sid = (serviceId ?? '').trim();
        if (sid.isEmpty) {
          throw Exception('Service ID is required');
        }
        await _staffAuthService.sendServiceManOtp(email: email, serviceId: sid);
      } else {
        throw Exception('Unsupported role for OTP login');
      }
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Returns:
  /// - `isNewUser == true`: starts registration by setting `deliveryDraft`
  /// - `isNewUser == false`: stores token + user in storage
  Future<bool> verifyDeliveryOtp({
    required String email,
    required String otp,
  }) async {
    _setLoading(true);
    _error = null;
    notifyListeners();

    try {
      final body = await _deliveryAuthService.verifyOtp(email: email, otp: otp);
      final data = body['data'];
      if (data is! Map<String, dynamic>) {
        throw Exception('Invalid response: missing data');
      }

      final isNewUser = data['isNewUser'];
      if (isNewUser is! bool) {
        throw Exception('Invalid response: missing isNewUser');
      }

      if (isNewUser) {
        final sessionToken = data['sessionToken'];
        if (sessionToken is! String || sessionToken.isEmpty) {
          throw Exception('Invalid response: missing sessionToken');
        }
        _deliveryDraft = DeliveryRegistrationDraft(
          email: email,
          sessionToken: sessionToken,
        );
        notifyListeners();
        return true;
      }

      final token = data['token'];
      if (token is! String || token.isEmpty) {
        throw Exception('Invalid response: missing token');
      }

      final user = data['user'];
      if (user is Map<String, dynamic>) {
        _partner = user;
        await AuthStorage.saveDeliveryStaff(user);
        _currentUser = user;
        await AuthStorage.saveCurrentUser(user);
      }

      _token = token;
      await AuthStorage.saveToken(token);

      _isAuthenticated = true;
      _isVerified = true;
      _deliveryDraft = null;
      notifyListeners();
      return false;
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Returns:
  /// - `isNewUser == true`: user exists in OTP system but profile is not created/approved yet (no JWT token returned)
  /// - `isNewUser == false`: stores JWT token
  Future<bool> verifyOtpForRole({
    required String role,
    required String email,
    required String otp,
    String? serviceId,
  }) async {
    if (role == RoleConstants.deliveryPartner) {
      return verifyDeliveryOtp(email: email, otp: otp);
    }

    _setLoading(true);
    _error = null;
    notifyListeners();

    try {
      Map<String, dynamic> body;
      if (role == RoleConstants.collectionManager) {
        body = await _staffAuthService.verifyCollectionManagerOtp(email: email, otp: otp);
      } else if (role == RoleConstants.distributionManager) {
        body = await _staffAuthService.verifyDistributionManagerOtp(email: email, otp: otp);
      } else if (role == RoleConstants.serviceMan) {
        final sid = (serviceId ?? '').trim();
        if (sid.isEmpty) {
          throw Exception('Service ID is required');
        }
        body = await _staffAuthService.verifyServiceManOtp(email: email, otp: otp, serviceId: sid);
      } else {
        throw Exception('Unsupported role for OTP login');
      }

      final data = body['data'];
      if (data is! Map<String, dynamic>) {
        throw Exception('Invalid response: missing data');
      }

      final isNewUser = data['isNewUser'];
      if (isNewUser is! bool) {
        throw Exception('Invalid response: missing isNewUser');
      }

      if (isNewUser) {
        // Backend returns sessionToken/expiresIn for new user flows, but we don't allow self profile creation here.
        return true;
      }

      final token = data['token'];
      if (token is! String || token.isEmpty) {
        throw Exception('Invalid response: missing token');
      }

      final user = data['user'];
      if (user is Map<String, dynamic>) {
        _currentUser = user;
        await AuthStorage.saveCurrentUser(user);
      }

      _token = token;
      await AuthStorage.saveToken(token);

      _isAuthenticated = true;
      _isVerified = true;
      notifyListeners();
      return false;
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  void updateDeliveryUserDetails({
    required String fullName,
    String? phone,
  }) {
    final draft = _deliveryDraft;
    if (draft == null) return;
    _deliveryDraft = draft.copyWith(
      fullName: fullName.trim(),
      phone: phone?.trim(),
    );
    notifyListeners();
  }

  void updateDeliveryAddressAndId({
    required String address,
    required File idProofDocumentFile,
    String? idProofType,
  }) {
    final draft = _deliveryDraft;
    if (draft == null) return;
    _deliveryDraft = draft.copyWith(
      address: address.trim(),
      idProofType: idProofType?.trim(),
      idProofDocumentFile: idProofDocumentFile,
    );
    notifyListeners();
  }

  void updateDeliveryVehicleDetails({
    required String vehicleType,
    required String vehicleNumber,
  }) {
    final draft = _deliveryDraft;
    if (draft == null) return;
    _deliveryDraft = draft.copyWith(
      vehicleType: vehicleType.trim(),
      vehicleNumber: vehicleNumber.trim(),
    );
    notifyListeners();
  }

  void updateDeliveryDrivingLicenseFile({required File drivingLicenseFile}) {
    final draft = _deliveryDraft;
    if (draft == null) return;
    _deliveryDraft = draft.copyWith(drivingLicenseFile: drivingLicenseFile);
    notifyListeners();
  }

  void updateDeliveryProfileAndLocation({
    required File profileImageFile,
    required double latitude,
    required double longitude,
  }) {
    final draft = _deliveryDraft;
    if (draft == null) return;
    _deliveryDraft = draft.copyWith(
      profileImageFile: profileImageFile,
      latitude: latitude,
      longitude: longitude,
    );
    notifyListeners();
  }

  Future<void> completeDeliveryRegistration() async {
    final draft = _deliveryDraft;
    if (draft == null) {
      throw Exception('No registration in progress');
    }

    final fullName = draft.fullName;
    final vehicleType = draft.vehicleType;
    final vehicleNumber = draft.vehicleNumber;
    final address = draft.address;
    final latitude = draft.latitude;
    final longitude = draft.longitude;
    final profileImage = draft.profileImageFile;
    final idProof = draft.idProofDocumentFile;
    final drivingLicense = draft.drivingLicenseFile;

    if (fullName == null || fullName.trim().isEmpty) {
      throw Exception('Full name is required');
    }
    if (vehicleType == null || vehicleType.trim().isEmpty) {
      throw Exception('Vehicle type is required');
    }
    if (vehicleNumber == null || vehicleNumber.trim().isEmpty) {
      throw Exception('Vehicle number is required');
    }
    if (address == null || address.trim().isEmpty) {
      throw Exception('Address is required');
    }
    if (latitude == null || longitude == null) {
      throw Exception('Location is required');
    }
    if (profileImage == null || idProof == null || drivingLicense == null) {
      throw Exception('All documents are required');
    }

    _setLoading(true);
    _error = null;
    notifyListeners();

    try {
      final body = await _deliveryAuthService.completeRegistration(
        sessionToken: draft.sessionToken,
        fullName: fullName,
        phone: draft.phone,
        vehicleType: vehicleType,
        vehicleNumber: vehicleNumber,
        address: address,
        latitude: latitude,
        longitude: longitude,
        idProofType: draft.idProofType,
        profileImage: profileImage,
        idProofDocument: idProof,
        drivingLicenseFile: drivingLicense,
      );

      final data = body['data'];
      if (data is! Map<String, dynamic>) {
        throw Exception('Invalid response: missing data');
      }

      final token = data['token'];
      if (token is! String || token.isEmpty) {
        throw Exception('Invalid response: missing token');
      }

      final deliveryStaff = data['deliveryStaff'];
      if (deliveryStaff is Map<String, dynamic>) {
        _partner = deliveryStaff;
        await AuthStorage.saveDeliveryStaff(deliveryStaff);
        // Keep Account/Profile screen consistent: it reads from `current_user_json`.
        _currentUser = deliveryStaff;
        await AuthStorage.saveCurrentUser(deliveryStaff);
      }

      _token = token;
      await AuthStorage.saveToken(token);

      _isAuthenticated = true;
      _isVerified = true;
      _deliveryDraft = null;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  void logout() {
    _token = null;
    _partner = null;
    _currentUser = null;
    _isAuthenticated = false;
    _isVerified = false;
    _deliveryDraft = null;
    _error = null;
    _isLoading = false;
    AuthStorage.clearAll();
    RoleManager.clearRole();
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}

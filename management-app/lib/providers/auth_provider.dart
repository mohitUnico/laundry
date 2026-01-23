import 'dart:io';

import 'package:flutter/foundation.dart';

import '../models/delivery_registration_draft.dart';
import '../services/delivery_auth_service.dart';
import '../utils/auth_storage.dart';

class AuthProvider with ChangeNotifier {
  String? _token;
  Map<String, dynamic>? _partner;
  bool _isAuthenticated = false;
  bool _isVerified = false;
  bool _isLoading = false;
  String? _error;

  DeliveryRegistrationDraft? _deliveryDraft;

  final DeliveryAuthService _deliveryAuthService = DeliveryAuthService();

  String? get token => _token;
  Map<String, dynamic>? get partner => _partner;
  bool get isAuthenticated => _isAuthenticated;
  bool get isVerified => _isVerified;
  bool get isLoading => _isLoading;
  String? get error => _error;
  DeliveryRegistrationDraft? get deliveryDraft => _deliveryDraft;

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
    _isAuthenticated = false;
    _isVerified = false;
    _deliveryDraft = null;
    _error = null;
    _isLoading = false;
    AuthStorage.clearAll();
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}

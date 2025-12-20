import 'package:flutter/foundation.dart';

import '../models/staff_role.dart';

class AuthProvider with ChangeNotifier {
  String? _token;
  Map<String, dynamic>? _user;
  StaffRole? _role;
  bool _isAuthenticated = false;
  bool _isVerified = false;

  String? get token => _token;
  Map<String, dynamic>? get user => _user;
  StaffRole? get role => _role;
  bool get isAuthenticated => _isAuthenticated;
  bool get isVerified => _isVerified;

  Future<void> login({
    required String identifier,
    required String password,
    required StaffRole role,
  }) async {
    // TODO: Replace this stub with backend login + role from API response
    _role = role;
    _isAuthenticated = true;
    _isVerified = role != StaffRole.deliveryPartner ? true : true;
    notifyListeners();
  }

  void logout() {
    _token = null;
    _user = null;
    _role = null;
    _isAuthenticated = false;
    _isVerified = false;
    notifyListeners();
  }
}

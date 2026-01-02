import 'package:flutter/foundation.dart';

class AuthProvider with ChangeNotifier {
  String? _token;
  Map<String, dynamic>? _partner;
  bool _isAuthenticated = false;
  bool _isVerified = false;

  String? get token => _token;
  Map<String, dynamic>? get partner => _partner;
  bool get isAuthenticated => _isAuthenticated;
  bool get isVerified => _isVerified;

  Future<void> login(String phone, String password) async {
    // TODO: Implement login logic
    _isAuthenticated = true;
    _isVerified = true;
    notifyListeners();
  }

  void logout() {
    _token = null;
    _partner = null;
    _isAuthenticated = false;
    _isVerified = false;
    notifyListeners();
  }
}

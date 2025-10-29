import 'package:flutter/foundation.dart';

class AuthProvider with ChangeNotifier {
  String? _token;
  Map<String, dynamic>? _user;
  bool _isAuthenticated = false;

  String? get token => _token;
  Map<String, dynamic>? get user => _user;
  bool get isAuthenticated => _isAuthenticated;

  Future<void> login(String phone, String otp) async {
    // TODO: Implement login logic
    _isAuthenticated = true;
    notifyListeners();
  }

  void logout() {
    _token = null;
    _user = null;
    _isAuthenticated = false;
    notifyListeners();
  }
}

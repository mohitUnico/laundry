import 'package:flutter/material.dart';

import '../../routes/app_routes.dart';
import '../../utils/auth_storage.dart';
import '../../utils/role_constants.dart';
import '../../utils/role_manager.dart';

/// App entry gate that restores the last session (token + role) if available.
class BootstrapScreen extends StatefulWidget {
  const BootstrapScreen({super.key});

  @override
  State<BootstrapScreen> createState() => _BootstrapScreenState();
}

class _BootstrapScreenState extends State<BootstrapScreen> {
  bool _navigated = false;

  Future<void> _bootstrap() async {
    final token = await AuthStorage.getToken();
    final role = await RoleManager.getRole();

    Map<String, dynamic>? user;
    if (role == RoleConstants.deliveryPartner) {
      user = await AuthStorage.getDeliveryStaff() ?? await AuthStorage.getCurrentUser();
    }

    if (!mounted || _navigated) return;
    _navigated = true;

    if (token != null && token.isNotEmpty && role != null && role.isNotEmpty) {
      final isAdminVerified = _isAdminVerified(user);
      final targetRoute = (role == RoleConstants.deliveryPartner && !isAdminVerified)
          ? AppRoutes.verificationPending
          : AppRoutes.home;

      Navigator.of(context).pushNamedAndRemoveUntil(targetRoute, (_) => false);
      return;
    }

    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRoutes.roleSelection,
      (_) => false,
    );
  }

  @override
  void initState() {
    super.initState();
    // Defer navigation until after first frame.
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  bool _isAdminVerified(Map<String, dynamic>? user) {
    if (user == null) return false;
    final raw = user['is_verified_by_admin'] ??
        user['isVerifiedByAdmin'] ??
        user['is_admin_verified'];

    if (raw is bool) return raw;
    if (raw is num) return raw != 0;
    if (raw is String) {
      final v = raw.toLowerCase().trim();
      return v == 'true' || v == '1' || v == 'yes' || v == 'verified';
    }
    return false;
  }
}



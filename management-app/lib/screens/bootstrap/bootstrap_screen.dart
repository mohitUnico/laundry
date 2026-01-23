import 'package:flutter/material.dart';

import '../../routes/app_routes.dart';
import '../../utils/auth_storage.dart';
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

    if (!mounted || _navigated) return;
    _navigated = true;

    if (token != null && token.isNotEmpty && role != null && role.isNotEmpty) {
      Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.home, (_) => false);
      return;
    }

    Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.roleSelection, (_) => false);
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
}



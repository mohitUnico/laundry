import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../providers/auth_provider.dart';
import '../../routes/app_routes.dart';
import '../../utils/prefs_keys.dart';

class BootstrapScreen extends StatefulWidget {
  const BootstrapScreen({super.key});

  @override
  State<BootstrapScreen> createState() => _BootstrapScreenState();
}

class _BootstrapScreenState extends State<BootstrapScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _navigateNext();
    });
  }

  Future<void> _navigateNext() async {
    if (!mounted) return;

    // 1) Onboarding gate
    final prefs = await SharedPreferences.getInstance();
    final onboardingSeen = prefs.getBool(PrefsKeys.onboardingSeen) ?? false;
    if (!onboardingSeen) {
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(AppRoutes.onboarding);
      return;
    }

    // 2) Auth session restore
    final auth = context.read<AuthProvider>();
    await auth.hydrateFromStorage();

    if (!mounted) return;
    if (auth.hasValidSession) {
      Navigator.of(context).pushReplacementNamed(AppRoutes.shell);
    } else {
      Navigator.of(context).pushReplacementNamed(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(
        child: Center(
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }
}



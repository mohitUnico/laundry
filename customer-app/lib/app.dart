import 'package:flutter/material.dart';
import 'routes/app_routes.dart';
import 'theme/app_theme.dart';
import 'utils/no_scrollbar_behavior.dart';
import 'services/location_permission_service.dart';

class LaundryCustomerApp extends StatefulWidget {
  const LaundryCustomerApp({super.key});

  @override
  State<LaundryCustomerApp> createState() => _LaundryCustomerAppState();
}

class _LaundryCustomerAppState extends State<LaundryCustomerApp> with WidgetsBindingObserver {
  final LocationPermissionService _locationService = LocationPermissionService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Check location permission when app starts
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkLocationPermission();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Check location permission when app comes to foreground
    if (state == AppLifecycleState.resumed) {
      _checkLocationPermission();
    }
  }

  Future<void> _checkLocationPermission() async {
    await _locationService.checkAndNotifyLocationPermission();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Laundry App',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      scrollBehavior: const NoScrollbarBehavior(),
      // TEMP (testing): start directly on Home screen.
      initialRoute: AppRoutes.shell,
      routes: AppRoutes.routes,
    );
  }
}

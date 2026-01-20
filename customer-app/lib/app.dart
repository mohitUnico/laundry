import 'package:flutter/material.dart';
import 'routes/app_routes.dart';
import 'theme/app_theme.dart';
import 'utils/no_scrollbar_behavior.dart';

class LaundryCustomerApp extends StatefulWidget {
  const LaundryCustomerApp({super.key});

  @override
  State<LaundryCustomerApp> createState() => _LaundryCustomerAppState();
}

class _LaundryCustomerAppState extends State<LaundryCustomerApp> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Laundry App',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      scrollBehavior: const NoScrollbarBehavior(),
      // Start via Bootstrap so we can restore auth + onboarding state.
      initialRoute: AppRoutes.bootstrap,
      routes: AppRoutes.routes,
    );
  }
}

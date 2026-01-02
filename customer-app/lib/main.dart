import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'providers/auth_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/order_provider.dart';

import 'services/location_permission_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize location permission service
  await LocationPermissionService().initialize();

  // TODO: Initialize Firebase
  // await Firebase.initializeApp();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
        // Add more providers as needed
      ],
      child: const LaundryCustomerApp(),
    ),
  );
}

 import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';

import 'app.dart';
import 'providers/auth_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/coupons_provider.dart';
import 'providers/order_provider.dart';
import 'repositories/auth_repository.dart';
import 'repositories/cart_repository.dart';
import 'repositories/coupons_repository.dart';
import 'repositories/customer_info_repository.dart';
import 'repositories/service_catalog_repository.dart';
import 'providers/service_catalog_provider.dart';
import 'services/notification_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        Provider<AuthRepository>(create: (_) => AuthRepository()),
        Provider<CustomerInfoRepository>(create: (_) => CustomerInfoRepository()),
        Provider<ServiceCatalogRepository>(create: (_) => ServiceCatalogRepository()),
        Provider<CouponsRepository>(create: (_) => CouponsRepository()),
        Provider<CartRepository>(
          lazy: false,
          create: (_) => CartRepository(),
        ),
        ChangeNotifierProvider(
          create: (context) => AuthProvider(
            authRepository: context.read<AuthRepository>(),
            customerInfoRepository: context.read<CustomerInfoRepository>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => ServiceCatalogProvider(
            repo: context.read<ServiceCatalogRepository>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => CouponsProvider(
            repo: context.read<CouponsRepository>(),
          ),
        ),
        ChangeNotifierProvider(
          lazy: false,
          create: (context) => CartProvider(
            repo: context.read<CartRepository>(),
          ),
        ),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
      ],
      child: const LaundryCustomerApp(),
    ),
  );
  unawaited(_startServices());
}

Future<void> _startServices() async {
  try {
    await Firebase.initializeApp().timeout(const Duration(seconds: 4));
  } catch (e) {
    debugPrint('Firebase initialization skipped: $e');
    return;
  }

  try {
    await NotificationService().initialize().timeout(const Duration(seconds: 4));
  } catch (e) {
    debugPrint('Notification service skipped: $e');
  }
}

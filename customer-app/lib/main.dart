import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'providers/auth_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/order_provider.dart';
import 'repositories/auth_repository.dart';
import 'repositories/cart_repository.dart';
import 'repositories/customer_info_repository.dart';
import 'repositories/service_catalog_repository.dart';
import 'providers/service_catalog_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // TODO: Initialize Firebase
  // await Firebase.initializeApp();

  runApp(
    MultiProvider(
      providers: [
        Provider<AuthRepository>(create: (_) => AuthRepository()),
        Provider<CustomerInfoRepository>(create: (_) => CustomerInfoRepository()),
        Provider<ServiceCatalogRepository>(create: (_) => ServiceCatalogRepository()),
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
          lazy: false,
          create: (context) => CartProvider(
            repo: context.read<CartRepository>(),
          ),
        ),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
        // Add more providers as needed
      ],
      child: const LaundryCustomerApp(),
    ),
  );
}

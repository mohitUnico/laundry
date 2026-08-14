import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'routes/app_routes.dart';
import 'routes/route_args.dart';
import 'theme/app_theme.dart';
import 'utils/no_scrollbar_behavior.dart';
import 'services/notification_service.dart';
import 'providers/order_provider.dart';

class LaundryCustomerApp extends StatefulWidget {
  const LaundryCustomerApp({super.key});

  @override
  State<LaundryCustomerApp> createState() => _LaundryCustomerAppState();
}

class _LaundryCustomerAppState extends State<LaundryCustomerApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    _setupNotificationHandlers();
  }

  void _setupNotificationHandlers() {
    // Set up notification handler to navigate to order tracking
    NotificationService().onOrderStatusChanged = (String orderId) {
      // Use a post-frame callback to ensure context is available
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final navigator = _navigatorKey.currentState;
        if (navigator != null) {
          // Navigate to order tracking screen with order ID
          navigator.pushNamed(
            AppRoutes.orderTracking,
            arguments: OrderTrackingArgs(orderId: orderId),
          );
          
          // Refresh orders in the provider
          final orderProvider = Provider.of<OrderProvider>(
            navigator.context,
            listen: false,
          );
          orderProvider.fetchOrders();
        }
      });
    };
  }

  @override
  void dispose() {
    NotificationService().onOrderStatusChanged = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Laundry App',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      scrollBehavior: const NoScrollbarBehavior(),
      navigatorKey: _navigatorKey,
      // Start via Bootstrap so we can restore auth + onboarding state.
      initialRoute: AppRoutes.bootstrap,
      routes: AppRoutes.routes,
    );
  }
}

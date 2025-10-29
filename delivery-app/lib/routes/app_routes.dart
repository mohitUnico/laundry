import 'package:flutter/material.dart';
import '../screens/auth/login_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/delivery/active_delivery_screen.dart';
import '../screens/earnings/earnings_screen.dart';
import '../screens/profile/profile_screen.dart';

class AppRoutes {
  static const String login = '/login';
  static const String home = '/home';
  static const String activeDelivery = '/active-delivery';
  static const String earnings = '/earnings';
  static const String profile = '/profile';

  static Map<String, WidgetBuilder> get routes {
    return {
      login: (context) => const LoginScreen(),
      home: (context) => const HomeScreen(),
      activeDelivery: (context) => const ActiveDeliveryScreen(),
      earnings: (context) => const EarningsScreen(),
      profile: (context) => const ProfileScreen(),
    };
  }
}

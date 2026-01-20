import 'package:flutter/material.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/signup_screen.dart';
import '../screens/auth/profile_photo_screen.dart';
import '../screens/auth/location_permission_screen.dart';
import '../screens/bootstrap/bootstrap_screen.dart';
import '../screens/location/select_location_screen.dart';
import '../screens/shell/main_shell_screen.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../screens/services/home_linens_screen.dart';
import '../screens/services/luxury_care_screen.dart';
import '../screens/services/pro_clean_screen.dart';
import '../screens/services/pro_clean/dry_cleaning_screen.dart';
import '../screens/services/pro_clean/delicate_fabrics_screen.dart';
import '../screens/services/pro_clean/shoe_cleaning_screen.dart';
import '../screens/services/pro_clean/stain_treatment_screen.dart';
import '../screens/services/pro_clean/winter_wear_screen.dart';
import '../screens/services/regular_wash/regular_wash_service_screen.dart';
import '../screens/orders/order_tracking_screen.dart';
import '../screens/cart/delivery_options_screen.dart';
import '../screens/cart/schedule_date_time_screen.dart';
import '../screens/cart/order_confirmation_screen.dart';
import '../screens/payment/payment_screen.dart';
import '../screens/payment/payment_successful_screen.dart';
import '../screens/orders/order_successful_screen.dart';
import '../screens/home/widgets/regular_wash_bottom_sheet.dart';
import '../screens/notifications/notifications_screen.dart';
import '../screens/profile/payment_methods_screen.dart';
import '../screens/profile/favorites_screen.dart';
import '../screens/profile/help_center_screen.dart';
import '../screens/profile/terms_conditions_screen.dart';
import '../screens/profile/privacy_policy_screen.dart';

class AppRoutes {
  static const String bootstrap = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String profilePhoto = '/profile-photo';
  static const String locationPermission = '/location-permission';
  static const String selectLocation = '/select-location';
  static const String shell = '/app';
  static const String home = '/home';
  static const String orders = '/orders';
  static const String cart = '/cart';
  static const String profile = '/profile';
  static const String washAndFold = '/services/wash-and-fold';
  static const String washAndIron = '/services/regular-wash/wash-and-iron';
  static const String ironOnly = '/services/regular-wash/iron-only';
  static const String handWash = '/services/regular-wash/hand-wash';
  static const String proClean = '/services/pro-clean';
  static const String dryCleaning = '/services/pro-clean/dry-cleaning';
  static const String delicateFabrics = '/services/pro-clean/delicate-fabrics';
  static const String shoeCleaning = '/services/pro-clean/shoe-cleaning';
  static const String stainTreatment = '/services/pro-clean/stain-treatment';
  static const String winterWear = '/services/pro-clean/winter-wear';
  static const String homeLinens = '/services/home-linens';
  static const String luxuryCare = '/services/luxury-care';
  static const String orderTracking = '/orders/tracking';
  static const String deliveryOptions = '/cart/delivery-options';
  static const String scheduleDateTime = '/cart/schedule-date-time';
  static const String orderConfirmation = '/cart/order-confirmation';
  static const String payment = '/payment';
  static const String paymentSuccessful = '/payment-successful';
  static const String orderSuccessful = '/order-successful';
  static const String notifications = '/notifications';
  static const String paymentMethods = '/profile/payment-methods';
  static const String favorites = '/profile/favorites';
  static const String helpCenter = '/profile/help-center';
  static const String termsConditions = '/profile/terms-conditions';
  static const String privacyPolicy = '/profile/privacy-policy';

  static Map<String, WidgetBuilder> get routes {
    return {
      bootstrap: (context) => const BootstrapScreen(),
      onboarding: (context) => const OnboardingScreen(),
      login: (context) => const LoginScreen(),
      signup: (context) => const SignupScreen(),
      profilePhoto: (context) => const ProfilePhotoScreen(),
      locationPermission: (context) => const LocationPermissionScreen(),
      selectLocation: (context) => const SelectLocationScreen(),
      shell: (context) => const MainShellScreen(),
      // Keep these legacy routes, but always land in the Shell so bottom nav
      // is persistent everywhere.
      home: (context) => const MainShellScreen(initialIndex: 0),
      orders: (context) => const MainShellScreen(initialIndex: 1),
      cart: (context) => const MainShellScreen(initialIndex: 2),
      profile: (context) => const MainShellScreen(initialIndex: 3),
      washAndFold: (context) =>
          RegularWashServiceScreen(
            serviceTitle: 'Wash & Fold',
            serviceId: (() {
              final sel =
                  ModalRoute.of(context)?.settings.arguments as RegularWashSelection?;
              return sel?.serviceId;
            })(),
            showPrices: (() {
              final sel =
                  ModalRoute.of(context)?.settings.arguments as RegularWashSelection?;
              return sel == null ? true : sel.pricingType == RegularWashPricingType.perPiece;
            })(),
          ),
      washAndIron: (context) =>
          RegularWashServiceScreen(
            serviceTitle: 'Wash & Iron',
            serviceId: (() {
              final sel =
                  ModalRoute.of(context)?.settings.arguments as RegularWashSelection?;
              return sel?.serviceId;
            })(),
            showPrices: (() {
              final sel =
                  ModalRoute.of(context)?.settings.arguments as RegularWashSelection?;
              return sel == null ? true : sel.pricingType == RegularWashPricingType.perPiece;
            })(),
          ),
      ironOnly: (context) =>
          RegularWashServiceScreen(
            serviceTitle: 'Iron only',
            serviceId: (() {
              final sel =
                  ModalRoute.of(context)?.settings.arguments as RegularWashSelection?;
              return sel?.serviceId;
            })(),
            showPrices: (() {
              final sel =
                  ModalRoute.of(context)?.settings.arguments as RegularWashSelection?;
              return sel == null ? true : sel.pricingType == RegularWashPricingType.perPiece;
            })(),
          ),
      handWash: (context) =>
          RegularWashServiceScreen(
            serviceTitle: 'Hand Wash',
            serviceId: (() {
              final sel =
                  ModalRoute.of(context)?.settings.arguments as RegularWashSelection?;
              return sel?.serviceId;
            })(),
            showPrices: (() {
              final sel =
                  ModalRoute.of(context)?.settings.arguments as RegularWashSelection?;
              return sel == null ? true : sel.pricingType == RegularWashPricingType.perPiece;
            })(),
          ),
      proClean: (context) => const ProCleanScreen(),
      dryCleaning: (context) => const DryCleaningScreen(),
      delicateFabrics: (context) => const DelicateFabricsScreen(),
      shoeCleaning: (context) => const ShoeCleaningScreen(),
      stainTreatment: (context) => const StainTreatmentScreen(),
      winterWear: (context) => const WinterWearScreen(),
      homeLinens: (context) => const HomeLinensScreen(),
      luxuryCare: (context) => const LuxuryCareScreen(),
      orderTracking: (context) => const OrderTrackingScreen(),
      deliveryOptions: (context) => const DeliveryOptionsScreen(),
      scheduleDateTime: (context) => const ScheduleDateTimeScreen(),
      orderConfirmation: (context) => const OrderConfirmationScreen(),
      payment: (context) => const PaymentScreen(),
      paymentSuccessful: (context) => const PaymentSuccessfulScreen(),
      orderSuccessful: (context) => const OrderSuccessfulScreen(),
      notifications: (context) => const NotificationsScreen(),
      paymentMethods: (context) => const PaymentMethodsScreen(),
      favorites: (context) => const FavoritesScreen(),
      helpCenter: (context) => const HelpCenterScreen(),
      termsConditions: (context) => const TermsConditionsScreen(),
      privacyPolicy: (context) => const PrivacyPolicyScreen(),
    };
  }
}

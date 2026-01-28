import 'package:flutter/material.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/role_selection_screen.dart';
import '../screens/auth/user_details_screen.dart';
import '../screens/auth/address_and_id_screen.dart';
import '../screens/auth/delivery/vehicle_details_screen.dart';
import '../screens/auth/delivery/driving_license_screen.dart';
import '../screens/auth/profile_location_screen.dart';
import '../screens/auth/register_success_screen.dart';
import '../screens/bootstrap/bootstrap_screen.dart';
// Role-specific screens
import '../screens/roles/delivery_partner/pages/home_screen.dart';
import '../screens/roles/delivery_partner/pages/main_shell_screen.dart';
import '../screens/roles/delivery_partner/pages/active_delivery_screen.dart';
import '../screens/roles/delivery_partner/pages/orders_screen.dart';
import '../screens/roles/delivery_partner/pages/profile_screen.dart';
import '../screens/roles/delivery_partner/pages/help_screen.dart';
import '../screens/roles/service_man/pages/pending_orders_screen.dart';
import '../screens/roles/collection_manager/pages/home_screen.dart';
import '../screens/roles/distribution_manager/pages/home_screen.dart';
// Common screens
import '../screens/common/earnings_screen.dart';
import '../utils/role_manager.dart';
import '../utils/role_constants.dart';

class AppRoutes {
  static const String bootstrap = '/';
  static const String roleSelection = '/role-selection';
  static const String login = '/login';
  static const String userDetails = '/user-details';
  static const String address = '/address';
  static const String vehicleDetails = '/vehicle-details';
  static const String drivingLicense = '/driving-license';
  static const String profileLocation = '/profile-location';
  static const String registerSuccess = '/register-success';
  static const String home = '/home';
  static const String orders = '/orders';
  static const String pendingOrdersServicemen = '/pending-orders-servicemen';
  static const String activeDelivery = '/active-delivery';
  static const String earnings = '/earnings';
  static const String profile = '/profile';
  static const String help = '/help';

  static Map<String, WidgetBuilder> get routes {
    return {
      bootstrap: (context) => const BootstrapScreen(),
      roleSelection: (context) => const RoleSelectionScreen(),
      login: (context) => const LoginScreen(),
      userDetails: (context) => const UserDetailsScreen(),
      address: (context) => const AddressAndIdScreen(),
      vehicleDetails: (context) => const VehicleDetailsScreen(),
      drivingLicense: (context) => const DrivingLicenseScreen(),
      profileLocation: (context) => const ProfileLocationScreen(),
      registerSuccess: (context) => const RegisterSuccessScreen(),
      home: (context) => _buildRoleBasedHome(context),
      orders: (context) => const OrdersScreen(),
      pendingOrdersServicemen: (context) => const PendingOrdersServicemenScreen(),
      activeDelivery: (context) => const ActiveDeliveryScreen(),
      earnings: (context) => const EarningsScreen(),
      profile: (context) => const ProfileScreen(),
      help: (context) => const HelpScreen(),
    };
  }

  static Widget _buildRoleBasedHome(BuildContext context) {
    // Return role-specific home screen based on stored role
    return FutureBuilder<String?>(
      future: RoleManager.getRole(),
      builder: (context, snapshot) {
        final role = snapshot.data;
        // Navigate to role-specific home screens
        if (role == RoleConstants.serviceMan) {
          return const PendingOrdersServicemenScreen();
        } else if (role == RoleConstants.deliveryPartner) {
          // Wrap delivery partner experience in a shell with persistent bottom nav.
          return const DeliveryPartnerMainShellScreen();
        } else if (role == RoleConstants.collectionManager) {
          return const CollectionManagerHomeScreen();
        } else if (role == RoleConstants.distributionManager) {
          return const DistributionManagerHomeScreen();
        }
        // Default home screen for other roles (can be customized per role)
        return const HomeScreen();
      },
    );
  }
}

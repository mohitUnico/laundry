import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/staff_role.dart';
import '../../providers/auth_provider.dart';
import 'collection_manager_home_screen.dart';
import 'distribution_manager_home_screen.dart';
import 'home_screen.dart';
import 'service_man_home_screen.dart';

class RoleHomeScreen extends StatelessWidget {
  const RoleHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    switch (auth.role) {
      case StaffRole.collectionManager:
        return const CollectionManagerHomeScreen();
      case StaffRole.serviceMan:
        return const ServiceManHomeScreen();
      case StaffRole.distributionManager:
        return const DistributionManagerHomeScreen();
      case StaffRole.deliveryPartner:
        return const HomeScreen();
      case null:
        return const Scaffold(
          body: Center(
            child: Text('No role assigned. Please login again.'),
          ),
        );
    }
  }
}

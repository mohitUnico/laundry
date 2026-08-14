import 'package:flutter/material.dart';

import '../../../../theme/app_colors.dart';
import '../../../common/widgets/bottom_nav_bar.dart';
import 'home_screen.dart';
import 'orders_screen.dart';
import 'help_screen.dart';
import 'profile_screen.dart';

/// Shell screen for delivery partner role that keeps a single persistent
/// bottom navigation bar and only swaps the tab content. This avoids
/// reloading the entire screen (and nav bar) on every tab change.
class DeliveryPartnerMainShellScreen extends StatefulWidget {
  final int initialIndex;

  const DeliveryPartnerMainShellScreen({
    super.key,
    this.initialIndex = 0,
  });

  @override
  State<DeliveryPartnerMainShellScreen> createState() =>
      _DeliveryPartnerMainShellScreenState();
}

class _DeliveryPartnerMainShellScreenState
    extends State<DeliveryPartnerMainShellScreen> {
  late int _currentIndex;

  late final List<Widget> _tabs;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, 3);
    _tabs = const [
      HomeScreen(showBottomNav: false),
      OrdersScreen(showBottomNav: false),
      HelpScreen(showBottomNav: false),
      ProfileScreen(showBottomNav: false),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: IndexedStack(
          index: _currentIndex,
          children: _tabs,
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          if (index == _currentIndex) {
            // Home tab special-case: trigger its own refresh logic via
            // lifecycle (it already refreshes on resume) – no nav needed.
            return;
          }
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}



import 'package:flutter/material.dart';

import '../cart/cart_screen.dart';
import '../home/home_screen.dart';
import '../orders/orders_list_screen.dart';
import '../profile/profile_screen.dart';
import '../home/widgets/home_bottom_nav.dart';
import '../home/widgets/home_colors.dart';

class MainShellScreen extends StatefulWidget {
  final int initialIndex;

  const MainShellScreen({
    super.key,
    this.initialIndex = 0,
  });

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen> {
  late int _index;

  static const _tabs = <Widget>[
    HomeScreen(),
    OrdersListScreen(showBack: false),
    CartScreen(showBack: false),
    ProfileScreen(showBack: false),
  ];

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex.clamp(0, _tabs.length - 1);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _index == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _index != 0) setState(() => _index = 0);
      },
      child: Scaffold(
        backgroundColor: HomeColors.background,
        body: IndexedStack(
          index: _index,
          children: _tabs,
        ),
        bottomNavigationBar: HomeBottomNav(
          currentIndex: _index,
          onTap: (i) => setState(() => _index = i),
        ),
      ),
    );
  }
}



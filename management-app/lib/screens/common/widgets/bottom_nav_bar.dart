import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';

/// Bottom navigation bar styled similar to the customer app's HomeBottomNav.
/// Tabs: Home, Orders, Help (instead of Cart), Account.
class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    const barHeight = 82.0;
    const topRadius = Radius.circular(36);
    const topOnlyRadius = BorderRadius.only(
      topLeft: topRadius,
      topRight: topRadius,
    );

    return SizedBox(
      height: barHeight + bottomInset,
      child: Material(
        color: AppColors.surface,
        elevation: 14,
        borderRadius: topOnlyRadius,
        shadowColor: const Color(0x26000000),
        child: ClipRRect(
          borderRadius: topOnlyRadius,
          child: Stack(
            children: [
              // Bottom inset filler so bar sits flush with screen bottom.
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: bottomInset,
                child: const ColoredBox(color: Colors.white),
              ),
              // Main bar content.
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                height: barHeight,
                child: Stack(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 10, 18, 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          _NavItem(
                            iconAsset:
                                'assets/icons/bottom_navbar/home_icon.png',
                            label: 'Home',
                            isActive: currentIndex == 0,
                            onTap: () => onTap(0),
                          ),
                          _NavItem(
                            iconAsset:
                                'assets/icons/bottom_navbar/orders_icon.png',
                            label: 'Orders',
                            isActive: currentIndex == 1,
                            onTap: () => onTap(1),
                          ),
                          _NavItem(
                            iconAsset:
                                'assets/icons/bottom_navbar/orders_icon.png',
                            label: 'Help',
                            isActive: currentIndex == 2,
                            onTap: () => onTap(2),
                          ),
                          _NavItem(
                            iconAsset:
                                'assets/icons/bottom_navbar/account_icon.png',
                            label: 'Account',
                            isActive: currentIndex == 3,
                            onTap: () => onTap(3),
                          ),
                        ],
                      ),
                    ),
                    // Top accent line (inset from both ends) - rendered on top
                    Positioned(
                      left: 10,
                      right: 10,
                      top: 1,
                      child: IgnorePointer(
                        child: Container(
                          height: 2,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [
                                Color(0x002C3CA5), // transparent
                                Color(0xFF2C3CA5), // sharp in center
                                Color(0x002C3CA5), // transparent
                              ],
                              stops: [0.0, 0.5, 1.0],
                            ),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final String iconAsset;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.iconAsset,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive ? AppColors.primary : const Color(0xFF98A0B5);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: SizedBox(
        height: 56,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                iconAsset,
                width: 22,
                height: 22,
                color: color,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  height: 1.0,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


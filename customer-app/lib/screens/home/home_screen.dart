import 'package:flutter/material.dart';

import '../../routes/app_routes.dart';
import 'widgets/home_colors.dart';
import 'widgets/home_header.dart';
import 'widgets/offer_carousel.dart';
import 'widgets/active_order_card.dart';
import 'widgets/luxury_care_bottom_sheet.dart';
import 'widgets/pro_clean_bottom_sheet.dart';
import 'widgets/regular_wash_bottom_sheet.dart';
import 'widgets/service_tile.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: HomeColors.background,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 18),
          child: Column(
            children: [
              SizedBox(height: 8),
              HomeHeader(
                userName: 'Zendaya',
                location: 'E-City, Uniworld, neeladri road...',
                notificationCount: 12,
              ),
              SizedBox(height: 14),
              Expanded(child: _HomeContent()),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeContent extends StatelessWidget {
  const _HomeContent();

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final gridHeight = (w * 0.78).clamp(280.0, 330.0);
    final rightTileHeight = (gridHeight - 12) / 2;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          const OfferCarousel(
            banners: [
              OfferBannerData(
                headline: '20% OFF',
                subhead: 'Welcome Offer',
                code: 'WELCOME20',
              ),
              OfferBannerData(
                headline: '15% OFF',
                subhead: 'Weekend Deal',
                code: 'WEEKEND15',
              ),
              OfferBannerData(
                headline: '₹50 OFF',
                subhead: 'First Order',
                code: 'FIRST50',
              ),
            ],
          ),
          const SizedBox(height: 12),
          ActiveOrderCard(
            orderId: '#LD12345',
            activeStepIndex: 1,
            etaText: 'Estimated Delivery: Tomorrow, 4 PM',
            onTrackNow: () => Navigator.of(context).pushNamed(
              AppRoutes.orderTracking,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: SizedBox(
                  height: gridHeight,
                  child: ServiceTile(
                    isPrimary: true,
                    fullWidthImage: true,
                    title: 'Regular Wash',
                    subtitle: 'Fast & Fresh Laundry',
                    imageAsset: 'assets/images/home/regular_wash.png',
                    onTap: () async {
                      final sel = await RegularWashBottomSheet.show(context);
                      if (!context.mounted || sel == null) return;
                      final route = switch (sel.serviceName) {
                        'Wash & Fold' => AppRoutes.washAndFold,
                        'Wash & Iron' => AppRoutes.washAndIron,
                        'Iron only' => AppRoutes.ironOnly,
                        'Hand Wash' => AppRoutes.handWash,
                        _ => null,
                      };
                      if (route != null) {
                        Navigator.of(context).pushNamed(route, arguments: sel);
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  children: [
                    SizedBox(
                      height: rightTileHeight,
                      child: ServiceTile(
                        title: 'Pro Clean',
                        subtitle: 'Expert dry cleaning',
                        imageAsset: 'assets/images/home/pro_clean.png',
                        imageSize: 132,
                        onTap: () async {
                          final sel = await ProCleanBottomSheet.show(context);
                          if (!context.mounted || sel == null) return;
                          final route = switch (sel.categoryName) {
                            'Dry Cleaning' => AppRoutes.dryCleaning,
                            'Stain Treatment' => AppRoutes.stainTreatment,
                            'Shoe Cleaning' => AppRoutes.shoeCleaning,
                            'Winter Wear' => AppRoutes.winterWear,
                            'Delicate Fabrics' => AppRoutes.delicateFabrics,
                            _ => AppRoutes.proClean,
                          };
                          Navigator.of(context).pushNamed(route, arguments: sel);
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: rightTileHeight,
                      child: ServiceTile(
                        title: 'Home Linens',
                        subtitle: 'Household items',
                        imageAsset: 'assets/images/home/home_linen.png',
                        imageSize: 132,
                        onTap: () => Navigator.of(context)
                            .pushNamed(AppRoutes.homeLinens),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: (w * 0.34).clamp(124.0, 150.0),
            child: ServiceTile(
              isPrimary: true,
              title: 'Luxury Care',
              subtitle: 'Delicate fabric treatment',
              imageAsset: 'assets/images/home/luxury_care.png',
              onTap: () async {
                final sel = await LuxuryCareBottomSheet.show(context);
                if (!context.mounted || sel == null) return;
                Navigator.of(context)
                    .pushNamed(AppRoutes.luxuryCare, arguments: sel);
              },
            ),
          ),
          const SizedBox(height: 18),
        ],
      ),
    );
  }
}

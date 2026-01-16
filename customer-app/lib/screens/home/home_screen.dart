import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../routes/app_routes.dart';
import '../../providers/auth_provider.dart';
import '../../providers/service_catalog_provider.dart';
import 'widgets/home_colors.dart';
import 'widgets/home_header.dart';
import 'widgets/offer_carousel.dart';
import 'widgets/active_order_card.dart';
import 'widgets/luxury_care_bottom_sheet.dart';
import 'widgets/pro_clean_bottom_sheet.dart';
import 'widgets/regular_wash_bottom_sheet.dart';
import 'widgets/service_tile.dart';
import '../../models/service_item.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Force refresh so newly added categories in Supabase show up even if we have cached data.
      context.read<ServiceCatalogProvider>().fetchServiceCategories(isActive: true, force: true);
    });
  }

  String _pickCategoryName(
    List<String> defaults,
    List<String> candidates,
    String fallback,
  ) {
    final normalizedCandidates =
        candidates.map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    if (normalizedCandidates.isEmpty) return fallback;

    // Try to match by contains for stability.
    final fallbackKey = fallback.toLowerCase();
    for (final c in normalizedCandidates) {
      if (c.toLowerCase().contains(fallbackKey)) return c;
    }

    // Otherwise, try to pick by the fallback's index in the default list.
    final idx = defaults.indexOf(fallback);
    if (idx >= 0 && idx < normalizedCandidates.length) return normalizedCandidates[idx];

    return normalizedCandidates.first;
  }

  String? _findCategoryIdForTitle({
    required List<String> availableNames,
    required List<String> availableIds,
    required String title,
  }) {
    final lowerTitle = title.trim().toLowerCase();
    for (var i = 0; i < availableNames.length; i++) {
      if (availableNames[i].trim().toLowerCase() == lowerTitle) return availableIds[i];
    }
    for (var i = 0; i < availableNames.length; i++) {
      if (availableNames[i].trim().toLowerCase().contains(lowerTitle)) return availableIds[i];
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final catalog = context.watch<ServiceCatalogProvider>();
    final categories = [...catalog.categories]..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
    final names = categories.map((c) => c.categoryName).toList();
    final ids = categories.map((c) => c.categoryId).toList();

    const defaultNames = <String>[
      'Regular Wash',
      'Pro Clean',
      'Home Linens',
      'Luxury Care',
    ];

    final regularWashTitle = _pickCategoryName(defaultNames, names, defaultNames[0]);
    final proCleanTitle = _pickCategoryName(defaultNames, names, defaultNames[1]);
    final homeLinensTitle = _pickCategoryName(defaultNames, names, defaultNames[2]);
    final luxuryCareTitle = _pickCategoryName(defaultNames, names, defaultNames[3]);

    final regularWashCategoryId = _findCategoryIdForTitle(
      availableNames: names,
      availableIds: ids,
      title: regularWashTitle,
    );
    final proCleanCategoryId = _findCategoryIdForTitle(
      availableNames: names,
      availableIds: ids,
      title: proCleanTitle,
    );
    final homeLinensCategoryId = _findCategoryIdForTitle(
      availableNames: names,
      availableIds: ids,
      title: homeLinensTitle,
    );
    final luxuryCareCategoryId = _findCategoryIdForTitle(
      availableNames: names,
      availableIds: ids,
      title: luxuryCareTitle,
    );

    return Scaffold(
      backgroundColor: HomeColors.background,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 18),
          child: Column(
            children: [
              const SizedBox(height: 8),
              HomeHeader(
                userName: auth.displayFirstName,
                location: 'E-City, Uniworld, neeladri road...',
                notificationCount: 12,
                profileImageUrl: auth.profileImageUrl,
              ),
              const SizedBox(height: 14),
              Expanded(
                child: _HomeContent(
                  regularWashTitle: regularWashTitle,
                  proCleanTitle: proCleanTitle,
                  homeLinensTitle: homeLinensTitle,
                  luxuryCareTitle: luxuryCareTitle,
                  regularWashCategoryId: regularWashCategoryId,
                  proCleanCategoryId: proCleanCategoryId,
                  homeLinensCategoryId: homeLinensCategoryId,
                  luxuryCareCategoryId: luxuryCareCategoryId,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeContent extends StatelessWidget {
  final String regularWashTitle;
  final String proCleanTitle;
  final String homeLinensTitle;
  final String luxuryCareTitle;
  final String? regularWashCategoryId;
  final String? proCleanCategoryId;
  final String? homeLinensCategoryId;
  final String? luxuryCareCategoryId;

  const _HomeContent({
    required this.regularWashTitle,
    required this.proCleanTitle,
    required this.homeLinensTitle,
    required this.luxuryCareTitle,
    required this.regularWashCategoryId,
    required this.proCleanCategoryId,
    required this.homeLinensCategoryId,
    required this.luxuryCareCategoryId,
  });

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
                    title: regularWashTitle,
                    subtitle: 'Fast & Fresh Laundry',
                    imageAsset: 'assets/images/home/regular_wash.png',
                    onTap: () async {
                      if (regularWashCategoryId != null) {
                        await context.read<ServiceCatalogProvider>().fetchServicesForCategory(
                              categoryId: regularWashCategoryId!,
                              isActive: true,
                              force: true,
                            );
                      }
                      final categoryId = regularWashCategoryId;
                      final provider = context.read<ServiceCatalogProvider>();
                      final services = categoryId == null ? const <ServiceItem>[] : provider.servicesForCategory(categoryId).toList();
                      final sel = await RegularWashBottomSheet.show(
                        context,
                        services: services,
                        isLoading: categoryId != null && provider.isLoadingServices(categoryId),
                      );
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
                        title: proCleanTitle,
                        subtitle: 'Expert dry cleaning',
                        imageAsset: 'assets/images/home/pro_clean.png',
                        imageSize: 132,
                        onTap: () async {
                          if (proCleanCategoryId != null) {
                            await context.read<ServiceCatalogProvider>().fetchServicesForCategory(
                                  categoryId: proCleanCategoryId!,
                                  isActive: true,
                                  force: true,
                                );
                          }
                          final categoryId = proCleanCategoryId;
                          final provider = context.read<ServiceCatalogProvider>();
                          final services = categoryId == null ? const <ServiceItem>[] : provider.servicesForCategory(categoryId).toList();
                          final sel = await ProCleanBottomSheet.show(
                            context,
                            services: services,
                            isLoading: categoryId != null && provider.isLoadingServices(categoryId),
                          );
                          if (!context.mounted || sel == null) return;
                          // IMPORTANT:
                          // Backend service names can vary (e.g. "Stain removal", "Winter wear cleaning", "Delicate wash").
                          // Route using tolerant matching, and fall back to the generic ProCleanScreen which
                          // will still fetch clothes items using serviceId.
                          final n = sel.categoryName.trim().toLowerCase();
                          String route;
                          if (n.contains('dry')) {
                            route = AppRoutes.dryCleaning;
                          } else if (n.contains('stain')) {
                            route = AppRoutes.stainTreatment;
                          } else if (n.contains('shoe')) {
                            route = AppRoutes.shoeCleaning;
                          } else if (n.contains('winter')) {
                            route = AppRoutes.winterWear;
                          } else if (n.contains('delicate')) {
                            route = AppRoutes.delicateFabrics;
                          } else {
                            route = AppRoutes.proClean;
                          }
                          Navigator.of(context).pushNamed(route, arguments: sel);
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: rightTileHeight,
                      child: ServiceTile(
                        title: homeLinensTitle,
                        subtitle: 'Household items',
                        imageAsset: 'assets/images/home/home_linen.png',
                        imageSize: 132,
                        onTap: () async {
                          if (homeLinensCategoryId != null) {
                            await context
                                .read<ServiceCatalogProvider>()
                                .fetchServicesForCategory(
                                  categoryId: homeLinensCategoryId!,
                                  isActive: true,
                                  force: true,
                                );
                          }

                          final categoryId = homeLinensCategoryId;
                          final provider = context.read<ServiceCatalogProvider>();
                          final services = categoryId == null ? const <ServiceItem>[] : provider.servicesForCategory(categoryId).toList();

                          final sel = await RegularWashBottomSheet.show(
                            context,
                            services: services,
                            isLoading: categoryId != null && provider.isLoadingServices(categoryId),
                          );
                          if (!context.mounted || sel == null) return;
                          Navigator.of(context).pushNamed(
                            AppRoutes.homeLinens,
                            arguments: sel,
                          );
                        },
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
              title: luxuryCareTitle,
              subtitle: 'Delicate fabric treatment',
              imageAsset: 'assets/images/home/luxury_care.png',
              onTap: () async {
                if (luxuryCareCategoryId != null) {
                  await context.read<ServiceCatalogProvider>().fetchServicesForCategory(
                        categoryId: luxuryCareCategoryId!,
                        isActive: true,
                        force: true,
                      );
                }
                final categoryId = luxuryCareCategoryId;
                final provider = context.read<ServiceCatalogProvider>();
                final services = categoryId == null ? const <ServiceItem>[] : provider.servicesForCategory(categoryId).toList();
                final sel = await LuxuryCareBottomSheet.show(
                  context,
                  services: services,
                  isLoading: categoryId != null && provider.isLoadingServices(categoryId),
                );
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

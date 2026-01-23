import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../routes/app_routes.dart';
import '../../providers/auth_provider.dart';
import '../../providers/coupons_provider.dart';
import '../../providers/service_catalog_provider.dart';
import '../../providers/order_provider.dart';
import '../../models/order_record.dart';
import 'widgets/home_colors.dart';
import 'widgets/home_header.dart';
import 'widgets/offer_carousel.dart';
import 'widgets/active_orders_carousel.dart';
import 'widgets/luxury_care_bottom_sheet.dart';
import 'widgets/pro_clean_bottom_sheet.dart';
import 'widgets/regular_wash_bottom_sheet.dart';
import 'widgets/service_tile.dart';
import '../../models/service_item.dart';
import '../../utils/supabase_config.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  RealtimeChannel? _ordersChannel;
  RealtimeChannel? _couponsChannel;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Force refresh so newly added categories in Supabase show up even if we have cached data.
      context.read<ServiceCatalogProvider>().fetchServiceCategories(isActive: true, force: true);
      // Fetch coupons for home screen offers
      context.read<CouponsProvider>().fetchApplicableCoupons(force: true);
      // Fetch active orders for the home screen
      _refreshActiveOrders();
      _subscribeToOrdersRealtime();
      _subscribeToCouponsRealtime();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ordersChannel?.unsubscribe();
    _couponsChannel?.unsubscribe();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Refresh active orders when app comes back to foreground
    // This ensures delivered orders are removed from the active orders section
    if (state == AppLifecycleState.resumed && mounted) {
      _refreshActiveOrders();
      // Refresh coupons so expired offers disappear without needing a restart.
      context.read<CouponsProvider>().fetchApplicableCoupons(force: true);
    }
  }

  void _refreshActiveOrders() {
    if (!mounted) return;
    // Fetch active orders (excludes delivered/closed orders)
    context.read<OrderProvider>().fetchOrders(status: 'active', limit: 10);
  }

  void _subscribeToOrdersRealtime() {
    if (!SupabaseConfig.isEnabled) return;

    try {
      final client = Supabase.instance.client;
      _ordersChannel = client
          .channel('public:orders')
          .onPostgresChanges(
            event: PostgresChangeEvent.update,
            schema: 'public',
            table: 'orders',
            callback: (payload) {
              // Whenever any order row updates, refresh active orders.
              if (!mounted) return;
              _refreshActiveOrders();
            },
          )
          .subscribe();
    } catch (_) {
      // If Supabase isn't initialized or channel fails, ignore and rely on manual refresh.
    }
  }

  void _subscribeToCouponsRealtime() {
    if (!SupabaseConfig.isEnabled) return;

    try {
      final client = Supabase.instance.client;
      _couponsChannel = client
          .channel('public:coupons')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'coupons',
            callback: (payload) {
              if (!mounted) return;
              final eventType = payload.eventType.name;
              final newRow = (payload.newRecord as Map?)?.cast<String, dynamic>();
              final oldRow = (payload.oldRecord as Map?)?.cast<String, dynamic>();
              context.read<CouponsProvider>().applyRealtimeChange(
                    eventType: eventType,
                    newRow: newRow,
                    oldRow: oldRow,
                  );
            },
          )
          .subscribe();
    } catch (_) {
      // ignore
    }
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
          Consumer<CouponsProvider>(
            builder: (context, couponsProvider, _) {
              final coupons = couponsProvider.coupons;
              if (couponsProvider.isLoading && coupons.isEmpty) {
                return Container(
                  height: 200,
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: HomeColors.borderSoft),
                  ),
                  child: const Center(child: CircularProgressIndicator()),
                );
              }
              if (coupons.isEmpty) return const SizedBox(height: 6);

              String headlineFor(String discountType, num discountValue) {
                final t = discountType.toLowerCase();
                if (t.contains('percent')) {
                  final pct = discountValue <= 1 ? (discountValue * 100) : discountValue;
                  return '${pct.round()}% OFF';
                }
                final amount = discountValue.round();
                return '₹$amount OFF';
              }

              final banners = coupons
                  .take(8)
                  .map(
                    (c) => OfferBannerData(
                      headline: headlineFor(c.discountType, c.discountValue),
                      subhead: (c.description == null || c.description!.trim().isEmpty)
                          ? 'Limited time offer'
                          : c.description!.trim(),
                      code: c.code,
                    ),
                  )
                  .toList();

              return OfferCarousel(banners: banners);
            },
          ),
          Consumer<OrderProvider>(
            builder: (context, orderProvider, _) {
              final activeOrders = orderProvider.orders
                  .where((order) => order.status == OrderStatus.inProgress)
                  .toList();

              if (activeOrders.isEmpty) {
                // No active orders – still keep some space after coupons
                return const SizedBox(height: 20);
              }

              return Column(
                children: [
                  const SizedBox(height: 16),
                  ActiveOrdersCarousel(orders: activeOrders),
                  // Tighter gap below active order card
                  const SizedBox(height: 8),
                ],
              );
            },
          ),
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

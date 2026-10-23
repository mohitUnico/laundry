import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';

import '../../routes/app_routes.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/coupons_provider.dart';
import '../../providers/order_provider.dart';
import 'widgets/home_colors.dart';
import 'widgets/home_header.dart';
import 'widgets/how_laundry_card.dart';
import 'widgets/offer_carousel.dart';
import 'widgets/pickup_cards.dart';
import 'widgets/home_linen_bottom_sheet.dart';
import 'widgets/luxury_care_bottom_sheet.dart';
import 'widgets/pro_clean_bottom_sheet.dart';
import 'widgets/regular_wash_bottom_sheet.dart';
import 'widgets/service_tile.dart';
import '../../utils/polling_config.dart';
import '../../repositories/customer_info_repository.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  Timer? _ordersPollTimer;
  Timer? _couponsPollTimer;
  String _locationText = 'Select location';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Fetch coupons for home screen offers
      context.read<CouponsProvider>().fetchApplicableCoupons(force: true);
      // Fetch active orders for the home screen
      _refreshActiveOrders();
      _refreshDefaultAddress();
      _startPolling();
    });
  }

  void _startPolling() {
    _ordersPollTimer?.cancel();
    _couponsPollTimer?.cancel();
    _ordersPollTimer = Timer.periodic(PollingConfig.orders, (_) {
      if (mounted) _refreshActiveOrders();
    });
    _couponsPollTimer = Timer.periodic(PollingConfig.coupons, (_) {
      if (!mounted) return;
      context.read<CouponsProvider>().fetchApplicableCoupons(force: true);
    });
  }

  void _stopPolling() {
    _ordersPollTimer?.cancel();
    _couponsPollTimer?.cancel();
    _ordersPollTimer = null;
    _couponsPollTimer = null;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopPolling();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Refresh active orders when app comes back to foreground
    // This ensures delivered orders are removed from the active orders section
    if (state == AppLifecycleState.resumed && mounted) {
      _refreshActiveOrders();
      context.read<CouponsProvider>().fetchApplicableCoupons(force: true);
      _refreshDefaultAddress();
      _startPolling();
    } else if (state == AppLifecycleState.paused) {
      _stopPolling();
    }
  }

  void _refreshActiveOrders() {
    if (!mounted) return;
    // Fetch active orders (excludes delivered/closed orders)
    context.read<OrderProvider>().fetchOrders(status: 'active', limit: 10);
  }

  Future<void> _refreshDefaultAddress() async {
    try {
      final repo = CustomerInfoRepository();
      final addresses = await repo.getAddresses();
      if (!mounted) return;

      if (addresses.isEmpty) {
        setState(() => _locationText = 'Select location');
        return;
      }

      final defaultAddr = addresses.firstWhere(
        (a) => a.isDefault,
        orElse: () => addresses.first,
      );

      final text = defaultAddr.fullAddress.trim().isNotEmpty
          ? defaultAddr.fullAddress.trim()
          : defaultAddr.addressLabel.trim();

      setState(() => _locationText = text.isEmpty ? 'Select location' : text);
    } catch (_) {
      // Keep UI stable even if address fetch fails (e.g. not logged in yet).
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

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
                location: _locationText,
                notificationCount: 12,
                profileImageUrl: auth.profileImageUrl,
                onLocationTap: () async {
                  await Navigator.of(context)
                      .pushNamed(AppRoutes.selectLocation);
                  await _refreshDefaultAddress();
                },
              ),
              const SizedBox(height: 14),
              Expanded(
                child: _HomeContent(
                  regularWashTitle: 'Regular Wash',
                  proCleanTitle: 'Pro Clean',
                  homeLinensTitle: 'Home Linens',
                  luxuryCareTitle: 'Luxury Care',
                  regularWashImageAsset: 'assets/images/home/regular_wash.png',
                  proCleanImageAsset: 'assets/images/home/pro_clean.png',
                  homeLinensImageAsset: 'assets/images/home/home_linen.png',
                  luxuryCareImageAsset: 'assets/images/home/luxury_care.png',
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
  final String regularWashImageAsset;
  final String proCleanImageAsset;
  final String homeLinensImageAsset;
  final String luxuryCareImageAsset;

  const _HomeContent({
    required this.regularWashTitle,
    required this.proCleanTitle,
    required this.homeLinensTitle,
    required this.luxuryCareTitle,
    required this.regularWashImageAsset,
    required this.proCleanImageAsset,
    required this.homeLinensImageAsset,
    required this.luxuryCareImageAsset,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final gridHeight = (w * 0.78).clamp(280.0, 330.0);
    final rightTileHeight = (gridHeight - 12) / 2;
    final bannerHeight = (w * 0.34).clamp(124.0, 150.0);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          Consumer<CouponsProvider>(
            builder: (context, couponsProvider, _) {
              final coupons = couponsProvider.coupons;
              if (kDebugMode) {
                debugPrint(
                  '[HomeScreen] coupons state: loading=${couponsProvider.isLoading} '
                  'count=${coupons.length} error=${couponsProvider.error}',
                );
              }
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
                  final pct = discountValue <= 1
                      ? (discountValue * 100)
                      : discountValue;
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
                      subhead: (c.description == null ||
                              c.description!.trim().isEmpty)
                          ? 'Limited time offer'
                          : c.description!.trim(),
                      code: c.code,
                    ),
                  )
                  .toList();

              return OfferCarousel(banners: banners);
            },
          ),
          const SizedBox(height: 16),
          const PickupCards(),
          const SizedBox(height: 16),
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
                    imageAsset: regularWashImageAsset,
                    onTap: () async {
                      final sel = await RegularWashBottomSheet.show(context);
                      if (!context.mounted || sel == null) return;
                      _addServiceToCart(
                        context,
                        category: 'Regular Wash',
                        serviceName: sel.serviceName,
                        isPerPiece:
                            sel.pricingType == RegularWashPricingType.perPiece,
                        imageAsset: regularWashImageAsset,
                      );
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
                        imageAsset: proCleanImageAsset,
                        imageSize: 132,
                        onTap: () async {
                          final sel = await ProCleanBottomSheet.show(context);
                          if (!context.mounted || sel == null) return;
                          _addServiceToCart(
                            context,
                            category: 'Pro Clean',
                            serviceName: sel.categoryName,
                            isPerPiece:
                                sel.pricingType == ProCleanPricingType.perPiece,
                            imageAsset: proCleanImageAsset,
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: rightTileHeight,
                      child: ServiceTile(
                        title: homeLinensTitle,
                        subtitle: 'Household items',
                        imageAsset: homeLinensImageAsset,
                        imageSize: 132,
                        onTap: () async {
                          final sel = await HomeLinenBottomSheet.show(context);
                          if (!context.mounted || sel == null) return;
                          _addServiceToCart(
                            context,
                            category: 'Home Linens',
                            serviceName: sel.serviceName,
                            isPerPiece:
                                sel.pricingType == HomeLinenPricingType.perPiece,
                            imageAsset: homeLinensImageAsset,
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
            height: bannerHeight,
            child: ServiceTile(
              isPrimary: true,
              title: luxuryCareTitle,
              subtitle: 'Delicate fabric treatment',
              imageAsset: luxuryCareImageAsset,
              onTap: () async {
                final sel = await LuxuryCareBottomSheet.show(context);
                if (!context.mounted || sel == null) return;
                _addServiceToCart(
                  context,
                  category: 'Luxury Care',
                  serviceName: sel.serviceName,
                  isPerPiece: sel.pricingType == LuxuryCarePricingType.perPiece,
                  imageAsset: luxuryCareImageAsset,
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: bannerHeight,
            child: const HowLaundryCard(),
          ),
          const SizedBox(height: 18),
        ],
      ),
    );
  }
}

void _addServiceToCart(
  BuildContext context, {
  required String category,
  required String serviceName,
  required bool isPerPiece,
  String? imageAsset,
}) {
  final added = context.read<CartProvider>().addService(
        category: category,
        serviceName: serviceName,
        isPerPiece: isPerPiece,
        imageAsset: imageAsset,
      );
  ScaffoldMessenger.of(context).hideCurrentSnackBar();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(added ? 'Added to cart' : 'Already in your cart'),
      duration: const Duration(seconds: 2),
    ),
  );
}

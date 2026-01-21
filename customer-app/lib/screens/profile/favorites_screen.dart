import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../home/widgets/home_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../routes/app_routes.dart';
import '../../providers/service_catalog_provider.dart';
import '../../utils/profile_service_error_messages.dart';
import '../home/widgets/pro_clean_bottom_sheet.dart';
import '../home/widgets/regular_wash_bottom_sheet.dart';
import '../../models/service_item.dart';

enum FavoritePricingType { perPiece, perKg }

class FavoriteService {
  final String id;
  final String serviceId;
  final String categoryId;
  final String name;
  final String category;
  final IconData icon;
  final Color iconColor;
  final FavoritePricingType pricingType;

  const FavoriteService({
    required this.id,
    required this.serviceId,
    required this.categoryId,
    required this.name,
    required this.category,
    required this.icon,
    required this.iconColor,
    required this.pricingType,
  });
}

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  bool _isPreloading = false;
  List<FavoriteService> _favorites = [
    const FavoriteService(
      id: '1',
      serviceId: 'wash-fold-service-id',
      categoryId: 'regular-wash-category-id',
      name: 'Wash & Fold',
      category: 'Regular Wash',
      icon: Icons.local_laundry_service_rounded,
      iconColor: HomeColors.primary,
      pricingType: FavoritePricingType.perKg,
    ),
    const FavoriteService(
      id: '2',
      serviceId: 'dry-cleaning-service-id',
      categoryId: 'pro-clean-category-id',
      name: 'Dry Cleaning',
      category: 'Pro Clean',
      icon: Icons.dry_cleaning_rounded,
      iconColor: const Color(0xFF10B981),
      pricingType: FavoritePricingType.perKg,
    ),
    const FavoriteService(
      id: '3',
      serviceId: 'iron-only-service-id',
      categoryId: 'regular-wash-category-id',
      name: 'Iron only',
      category: 'Regular Wash',
      icon: Icons.iron_rounded,
      iconColor: const Color(0xFFFF9800),
      pricingType: FavoritePricingType.perPiece,
    ),
    const FavoriteService(
      id: '4',
      serviceId: 'shoe-cleaning-service-id',
      categoryId: 'pro-clean-category-id',
      name: 'Shoe Cleaning',
      category: 'Pro Clean',
      icon: Icons.shopping_bag_rounded,
      iconColor: const Color(0xFFFF6B35),
      pricingType: FavoritePricingType.perKg,
    ),
  ];

  @override
  void initState() {
    super.initState();
    // Pre-load categories and services for all favorites to cache them
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _preloadCategoriesAndServices();
    });
  }

  Future<void> _preloadCategoriesAndServices() async {
    if (_isPreloading) return;
    setState(() => _isPreloading = true);

    try {
      final provider = context.read<ServiceCatalogProvider>();
      
      // Fetch categories first (uses cache if available)
      await provider.fetchServiceCategories(isActive: true, force: false);
      
      // Get unique category names from favorites
      final uniqueCategories = _favorites.map((f) => f.category).toSet().toList();
      final categories = provider.categories.toList();
      
      // Pre-fetch services for all unique categories
      for (final categoryName in uniqueCategories) {
        try {
          final category = categories.firstWhere(
            (c) => c.categoryName.toLowerCase().contains(categoryName.toLowerCase()) ||
                   categoryName.toLowerCase().contains(c.categoryName.toLowerCase()),
          );
          
          // Fetch services (uses cache if available, won't re-fetch if already cached)
          await provider.fetchServicesForCategory(
            categoryId: category.categoryId,
            isActive: true,
            force: false,
          );
        } catch (e) {
          // Skip if category not found - will be handled during navigation
          debugPrint('Preload: Category not found: $categoryName');
        }
      }
    } catch (e) {
      // Silently fail - navigation will handle it
      debugPrint('Preload error: $e');
    } finally {
      if (mounted) {
        setState(() => _isPreloading = false);
      }
    }
  }

  void _removeFavorite(String id, BuildContext context) {
    setState(() {
      _favorites.removeWhere((fav) => fav.id == id);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Removed from favorites'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _navigateToService(FavoriteService favorite, BuildContext context) async {
    final provider = context.read<ServiceCatalogProvider>();
    
    try {
      // Ensure categories are loaded (should be cached from preload)
      if (provider.categories.isEmpty) {
        await provider.fetchServiceCategories(isActive: true, force: false);
      }
      
      // Find the category ID by matching category name
      final categories = provider.categories.toList();
      final category = categories.firstWhere(
        (c) => c.categoryName.toLowerCase().contains(favorite.category.toLowerCase()) ||
               favorite.category.toLowerCase().contains(c.categoryName.toLowerCase()),
        orElse: () => throw Exception('Category not found: ${favorite.category}'),
      );
      
      // Fetch services (should be cached from preload, so this is fast)
      final services = provider.servicesForCategory(category.categoryId);
      if (services.isEmpty) {
        await provider.fetchServicesForCategory(
          categoryId: category.categoryId,
          isActive: true,
          force: false,
        );
      }
      
      // Find the service by name
      final allServices = provider.servicesForCategory(category.categoryId).toList();
      final service = allServices.firstWhere(
        (s) => s.serviceName.toLowerCase() == favorite.name.toLowerCase() ||
               s.serviceName.toLowerCase().contains(favorite.name.toLowerCase()),
        orElse: () => allServices.isNotEmpty ? allServices.first : throw Exception('Service not found: ${favorite.name}'),
      );

      String route;
      dynamic arguments;

      // Map service to route based on category and name
      if (favorite.category == 'Regular Wash') {
        route = switch (favorite.name) {
          'Wash & Fold' => AppRoutes.washAndFold,
          'Wash & Iron' => AppRoutes.washAndIron,
          'Iron only' => AppRoutes.ironOnly,
          'Hand Wash' => AppRoutes.handWash,
          _ => AppRoutes.washAndFold,
        };
        
        // Use the favorite's pricing type preference
        final pricingType = favorite.pricingType == FavoritePricingType.perPiece
            ? RegularWashPricingType.perPiece
            : RegularWashPricingType.kgWise;
        
        // Create RegularWashSelection argument
        arguments = RegularWashSelection(
          serviceId: service.serviceId,
          serviceName: service.serviceName,
          pricingType: pricingType,
        );
      } else if (favorite.category == 'Pro Clean') {
        // Map Pro Clean service to route
        final serviceNameLower = favorite.name.toLowerCase();
        if (serviceNameLower.contains('dry')) {
          route = AppRoutes.dryCleaning;
        } else if (serviceNameLower.contains('stain')) {
          route = AppRoutes.stainTreatment;
        } else if (serviceNameLower.contains('shoe')) {
          route = AppRoutes.shoeCleaning;
        } else if (serviceNameLower.contains('winter')) {
          route = AppRoutes.winterWear;
        } else if (serviceNameLower.contains('delicate')) {
          route = AppRoutes.delicateFabrics;
        } else {
          route = AppRoutes.proClean;
        }
        
        // Use the favorite's pricing type preference
        final pricingType = favorite.pricingType == FavoritePricingType.perPiece
            ? ProCleanPricingType.perPiece
            : ProCleanPricingType.kgWise;
        
        // Create ProCleanSelection argument
        arguments = ProCleanSelection(
          serviceId: service.serviceId,
          categoryName: service.serviceName,
          pricingType: pricingType,
        );
      } else {
        // Default navigation for other categories
        route = AppRoutes.proClean;
        final pricingType = favorite.pricingType == FavoritePricingType.perPiece
            ? ProCleanPricingType.perPiece
            : ProCleanPricingType.kgWise;
        arguments = ProCleanSelection(
          serviceId: service.serviceId,
          categoryName: service.serviceName,
          pricingType: pricingType,
        );
      }

      if (context.mounted) {
        Navigator.of(context).pushNamed(route, arguments: arguments);
      }
    } catch (e) {
      if (context.mounted) {
        final message = ProfileServiceErrorMessages.getServiceErrorMessage(
          e,
          operation: 'load service',
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HomeColors.background,
      appBar: AppBar(
        backgroundColor: HomeColors.background,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: InkWell(
            onTap: () => Navigator.of(context).maybePop(),
            borderRadius: BorderRadius.circular(18),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: HomeColors.borderSoft),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 18,
                color: HomeColors.text,
              ),
            ),
          ),
        ),
        title: Text(
          'Favorites',
          style: AppTextStyles.header(color: HomeColors.text),
        ),
      ),
      body: SafeArea(
        child: _favorites.isEmpty
            ? _EmptyState()
            : SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(
                      'Your Preferred Services',
                      style: AppTextStyles.header(color: HomeColors.text),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${_favorites.length} ${_favorites.length == 1 ? 'service' : 'services'} saved',
                      style: AppTextStyles.body(color: HomeColors.muted).copyWith(fontSize: 13),
                    ),
                    const SizedBox(height: 20),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.85,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      itemCount: _favorites.length,
                      itemBuilder: (context, index) {
                        final favorite = _favorites[index];
                        return _FavoriteServiceCard(
                          service: favorite,
                          onTap: () => _navigateToService(favorite, context),
                          onRemove: () => _removeFavorite(favorite.id, context),
                        );
                      },
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _FavoriteServiceCard extends StatelessWidget {
  final FavoriteService service;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _FavoriteServiceCard({
    required this.service,
    required this.onTap,
    required this.onRemove,
  });

  String _getPricingTypeText() {
    return service.pricingType == FavoritePricingType.perPiece ? 'Per Piece' : 'Per Kg';
  }

  Color _getPricingTypeColor() {
    return service.pricingType == FavoritePricingType.perPiece
        ? const Color(0xFF10B981)
        : const Color(0xFFFF9800);
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: HomeColors.borderSoft, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: HomeColors.primary.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: service.iconColor.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      service.icon,
                      size: 28,
                      color: service.iconColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Service Name
                  Text(
                    service.name,
                    style: AppTextStyles.listItemTitle(color: HomeColors.text).copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  // Category
                  Text(
                    service.category,
                    style: AppTextStyles.body(color: HomeColors.muted).copyWith(
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  // Pricing Type Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getPricingTypeColor().withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _getPricingTypeColor().withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          service.pricingType == FavoritePricingType.perPiece
                              ? Icons.check_circle_outline_rounded
                              : Icons.scale_rounded,
                          size: 12,
                          color: _getPricingTypeColor(),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _getPricingTypeText(),
                          style: AppTextStyles.body(color: _getPricingTypeColor()).copyWith(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Remove button
            Positioned(
              top: 10,
              right: 10,
              child: InkWell(
                onTap: () {
                  onRemove();
                },
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF04438).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: Color(0xFFF04438),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: HomeColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.favorite_border_rounded,
              size: 50,
              color: HomeColors.primary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No favorites yet',
            style: AppTextStyles.header(color: HomeColors.text),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              'Start adding your preferred services to see them here',
              textAlign: TextAlign.center,
              style: AppTextStyles.body(color: HomeColors.muted).copyWith(fontSize: 12),
            ),
          ),
          const SizedBox(height: 32),
          InkWell(
            onTap: () {
              Navigator.of(context).maybePop();
              // TODO: Navigate to services/home screen
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: HomeColors.primary,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.add_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Browse Services',
                    style: AppTextStyles.button(color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

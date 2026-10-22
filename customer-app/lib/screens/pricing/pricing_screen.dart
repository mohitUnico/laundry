import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../providers/cart_provider.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/pricing.dart';
import '../home/widgets/home_colors.dart';

class PricingScreen extends StatefulWidget {
  const PricingScreen({super.key});

  @override
  State<PricingScreen> createState() => _PricingScreenState();
}

class _PricingScreenState extends State<PricingScreen> {
  int _categoryIndex = 0;
  int _serviceIndex = 0;

  static const _categories = <_Category>[
    _Category(
      label: 'Regular wash',
      imageAsset: 'assets/images/home/regular_wash.png',
      priceCategory: 'Regular Wash',
      includes: [
        'Washing with fabric-appropriate detergents',
        'Gentle cleaning based on fabric type and color',
        'Thorough rinsing and drying',
        'Neatly folded and packed clothes',
      ],
      excludes: [
        'Steam ironing or pressing',
        'Dry cleaning or delicate garment care',
        'Specialized stain removal',
        'Repairing damaged garments or missing buttons',
      ],
      services: [
        _Service(
          name: 'Wash & Fold',
          route: AppRoutes.washAndFold,
          items: ['Top Wear', 'Bottom Wear', 'Saree', 'Kurta'],
        ),
        _Service(
          name: 'Wash & Iron',
          route: AppRoutes.washAndIron,
          items: ['Top Wear', 'Bottom Wear', 'Saree', 'Kurta'],
        ),
        _Service(
          name: 'Iron only',
          route: AppRoutes.ironOnly,
          items: ['Top Wear', 'Bottom Wear', 'Saree', 'Kurta'],
        ),
        _Service(
          name: 'Hand Wash',
          route: AppRoutes.handWash,
          items: ['Top Wear', 'Bottom Wear', 'Saree', 'Kurta'],
        ),
      ],
    ),
    _Category(
      label: 'Pro Clean',
      imageAsset: 'assets/images/home/pro_clean.png',
      priceCategory: 'Pro Clean',
      includes: [
        'Professional dry cleaning for suitable garments',
        'Targeted stain treatment',
        'Shoe cleaning and care',
        'Specialized cleaning for winter wear',
      ],
      excludes: [
        'Standard wash & fold for everyday laundry',
        'Major repairs or alterations',
        'Guaranteed removal of all stains',
        'Restoration of damaged or discoloured fabrics',
      ],
      services: [
        _Service(
          name: 'Dry Cleaning',
          route: AppRoutes.dryCleaning,
          items: ['Top Wear', 'Bottom Wear', 'Saree', 'Lingerie', 'Kurta'],
        ),
        _Service(
          name: 'Stain Treatment',
          route: AppRoutes.stainTreatment,
          items: ['Heavy Stain', 'Light Stain'],
        ),
        _Service(
          name: 'Shoe Cleaning',
          route: AppRoutes.shoeCleaning,
          items: ['Sports Shoes', 'Formal Shoes', 'Sneakers', 'Loafers'],
        ),
        _Service(
          name: 'Winter Wear',
          route: AppRoutes.winterWear,
          items: ['Woolen', 'Jackets', 'Blazers', 'Accessories', 'Cashmere Sweaters'],
        ),
        _Service(
          name: 'Delicate Fabrics',
          route: AppRoutes.delicateFabrics,
          items: ['Top Wear', 'Bottom Wear', 'Saree', 'Kurta'],
        ),
      ],
    ),
    _Category(
      label: 'Home Linens',
      imageAsset: 'assets/images/home/home_linen.png',
      priceCategory: 'Home Linens',
      includes: [
        'Cleaning for bed sheets, blankets and quilts',
        'Carpet and curtain cleaning',
        'Tablecloth and napkin washing',
        'Fabric-appropriate cleaning and fresh finishing',
      ],
      excludes: [
        'Repairing tears or damaged fabrics',
        'Specialized stain removal for stubborn stains',
        'Dry cleaning of delicate or specialty items unless specified',
        'Removal of permanent stains or discoloration',
      ],
      services: [
        _Service(
          name: 'Home Linen',
          route: AppRoutes.homeLinens,
          items: [
            'Bed Sheets',
            'Carpets',
            'Blankets & Quilts',
            'Curtains',
            'Tablecloths & Napkins',
          ],
        ),
      ],
    ),
    _Category(
      label: 'Luxury Care',
      imageAsset: 'assets/images/home/luxury_care.png',
      priceCategory: 'Luxury Care',
      includes: [
        'Professional steam pressing for a premium finish',
        'Specialized care for designer wear',
        'Gentle handling of delicate embellishments and fabrics',
        'Shape and finish preservation',
      ],
      excludes: [
        'Regular washing or drying',
        'Stain removal unless specified',
        'Repairs or alterations',
        'Guaranteed treatment of damaged garments',
      ],
      services: [
        _Service(
          name: 'Steam Press',
          route: AppRoutes.luxuryCare,
          items: ['Top Wear', 'Bottom Wear', 'Saree', 'Kurta'],
        ),
        _Service(
          name: 'Designer Wear',
          route: AppRoutes.luxuryCare,
          items: ['Top Wear', 'Bottom Wear', 'Saree', 'Kurta'],
        ),
      ],
    ),
  ];

  _Category get _category => _categories[_categoryIndex];
  _Service get _service => _category.services[_serviceIndex];

  void _selectCategory(int index) {
    if (index == _categoryIndex) return;
    setState(() {
      _categoryIndex = index;
      _serviceIndex = 0;
    });
  }

  int _itemPrice(String item) {
    return Pricing.unitPriceInr(
      category: _category.priceCategory,
      serviceName: _service.name,
      itemName: item,
    );
  }

  void _openService() {
    final added = context.read<CartProvider>().addService(
          category: _category.priceCategory,
          serviceName: _service.name,
          isPerPiece: true,
          imageAsset: _category.imageAsset,
        );
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(added ? 'Added to cart' : 'Already in your cart'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final service = _service;
    final prices = [for (final item in service.items) _itemPrice(item)];
    final startsFrom = prices.reduce((a, b) => a < b ? a : b);

    return Scaffold(
      backgroundColor: HomeColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const _PricingHeader(),
            const SizedBox(height: 6),
            _CategoryRow(
              selectedIndex: _categoryIndex,
              onSelected: _selectCategory,
            ),
            const SizedBox(height: 14),
            _ServiceChips(
              services: _category.services,
              selectedIndex: _serviceIndex,
              onSelected: (index) => setState(() => _serviceIndex = index),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                children: [
                  _PriceCard(
                    items: service.items,
                    prices: prices,
                    startsFrom: startsFrom,
                  ),
                  const SizedBox(height: 12),
                  _IncludesCard(
                    serviceName: service.name,
                    includes: _category.includes,
                    excludes: _category.excludes,
                  ),
                  const SizedBox(height: 16),
                  _SelectButton(
                    label: 'Add to cart',
                    onTap: _openService,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PricingHeader extends StatelessWidget {
  const _PricingHeader();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(left: 16),
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
                    size: 16,
                    color: HomeColors.text,
                  ),
                ),
              ),
            ),
          ),
          Text(
            'Pricing',
            style: AppTextStyles.header(color: HomeColors.text).copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const _CategoryRow({
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          for (var i = 0; i < _PricingScreenState._categories.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            Expanded(
              child: _CategoryTile(
                category: _PricingScreenState._categories[i],
                selected: i == selectedIndex,
                onTap: () => onSelected(i),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final _Category category;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryTile({
    required this.category,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            height: 64,
            decoration: BoxDecoration(
              color: selected ? const Color(0xFFE4E9FF) : const Color(0xFFF3F5FB),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected ? const Color(0xFFC9D2FF) : Colors.transparent,
              ),
            ),
            padding: const EdgeInsets.all(6),
            child: Image.asset(
              category.imageAsset,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            category.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              height: 1.1,
              color: selected ? HomeColors.primary : HomeColors.muted,
            ),
          ),
        ],
      ),
    );
  }
}

class _ServiceChips extends StatelessWidget {
  final List<_Service> services;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const _ServiceChips({
    required this.services,
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: services.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final selected = index == selectedIndex;
          return InkWell(
            onTap: () => onSelected(index),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: selected ? HomeColors.primary : const Color(0xFFE4E7F2),
                  width: selected ? 1.4 : 1,
                ),
              ),
              child: Text(
                services[index].name,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  height: 1,
                  color: selected ? HomeColors.primary : HomeColors.text,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PriceCard extends StatelessWidget {
  final List<String> items;
  final List<int> prices;
  final int startsFrom;

  const _PriceCard({
    required this.items,
    required this.prices,
    required this.startsFrom,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: _cardDecoration,
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++)
            _PriceRow(
              label: items[i],
              value: Pricing.inr(prices[i]),
              showDivider: true,
            ),
          _PriceRow(
            label: 'Other',
            value: 'Starts from ${Pricing.inr(startsFrom)}',
            mutedLabel: true,
            showDivider: false,
          ),
        ],
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  final String label;
  final String value;
  final bool mutedLabel;
  final bool showDivider;

  const _PriceRow({
    required this.label,
    required this.value,
    required this.showDivider,
    this.mutedLabel = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    height: 1.2,
                    color: mutedLabel ? const Color(0xFF98A2B3) : HomeColors.text,
                  ),
                ),
              ),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                  color: HomeColors.primary,
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          const Divider(height: 1, thickness: 1, color: Color(0xFFF0F2F8)),
      ],
    );
  }
}

class _IncludesCard extends StatelessWidget {
  final String serviceName;
  final List<String> includes;
  final List<String> excludes;

  const _IncludesCard({
    required this.serviceName,
    required this.includes,
    required this.excludes,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: _cardDecoration,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your $serviceName order includes',
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              height: 1.3,
              color: HomeColors.text,
            ),
          ),
          const SizedBox(height: 12),
          for (final line in includes)
            _Bullet(
              text: line,
              color: const Color(0xFF17B26A),
              icon: Icons.check_rounded,
            ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Divider(height: 1, thickness: 1, color: Color(0xFFF0F2F8)),
          ),
          Text(
            'Not included',
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              height: 1.3,
              color: HomeColors.text,
            ),
          ),
          const SizedBox(height: 12),
          for (final line in excludes)
            _Bullet(
              text: line,
              color: const Color(0xFFF04438),
              icon: Icons.close_rounded,
            ),
        ],
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  final String text;
  final Color color;
  final IconData icon;

  const _Bullet({
    required this.text,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 20,
            margin: const EdgeInsets.only(top: 1),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 1.4),
            ),
            child: Icon(icon, size: 13, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 13.5,
                fontWeight: FontWeight.w400,
                height: 1.35,
                color: const Color(0xFF475467),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _SelectButton({
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: HomeColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
        ),
        child: Row(
          children: [
            const SizedBox(width: 36),
            Expanded(
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_forward_rounded,
                size: 16,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

const _cardDecoration = BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.all(Radius.circular(18)),
  boxShadow: [
    BoxShadow(
      color: Color(0x10101828),
      blurRadius: 18,
      offset: Offset(0, 8),
    ),
  ],
);

class _Category {
  final String label;
  final String imageAsset;
  final String priceCategory;
  final List<String> includes;
  final List<String> excludes;
  final List<_Service> services;

  const _Category({
    required this.label,
    required this.imageAsset,
    required this.priceCategory,
    required this.includes,
    required this.excludes,
    required this.services,
  });
}

class _Service {
  final String name;
  final String route;
  final List<String> items;

  const _Service({
    required this.name,
    required this.route,
    required this.items,
  });
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../routes/app_routes.dart';
import '../../../providers/cart_provider.dart';
import '../../../theme/app_text_styles.dart';
import '../../../utils/pricing.dart';
import '../../home/widgets/home_bottom_nav.dart';
import '../../home/widgets/home_colors.dart';
import 'widgets/others_field.dart';
import '../../home/widgets/pro_clean_bottom_sheet.dart';

class WinterWearScreen extends StatefulWidget {
  const WinterWearScreen({super.key});

  @override
  State<WinterWearScreen> createState() => _WinterWearScreenState();
}

class _WinterWearScreenState extends State<WinterWearScreen> {
  final _othersController = TextEditingController();

  final Map<_WinterItem, int> _qty = {
    _WinterItem.woolen: 0,
    _WinterItem.jackets: 0,
    _WinterItem.blazers: 0,
    _WinterItem.accessories: 0,
    _WinterItem.cashmereSweaters: 0,
  };

  @override
  void dispose() {
    _othersController.dispose();
    super.dispose();
  }

  int get _total => _qty.values.fold(0, (a, b) => a + b);

  List<MapEntry<String, int>> get _nonZeroSummaryRows {
    final rows = <MapEntry<String, int>>[];
    void addRow(String label, _WinterItem type) {
      final v = _qty[type] ?? 0;
      if (v > 0) rows.add(MapEntry(label, v));
    }

    addRow('Woolen', _WinterItem.woolen);
    addRow('Jackets', _WinterItem.jackets);
    addRow('Blazers', _WinterItem.blazers);
    addRow('Accessories', _WinterItem.accessories);
    addRow('Cashmere Sweaters', _WinterItem.cashmereSweaters);
    return rows;
  }

  @override
  Widget build(BuildContext context) {
    final selection =
        ModalRoute.of(context)?.settings.arguments as ProCleanSelection?;
    final showPrices = selection?.pricingType == ProCleanPricingType.perPiece;
    return Scaffold(
      backgroundColor: HomeColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 8),
            _TopBar(
              title: 'Winter Wear',
              onBack: () => Navigator.of(context).maybePop(),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  children: [
                    _ItemCard(
                      title: 'Woolen',
                      imageAsset: 'assets/images/winter_wear/woolen_wear.png',
                      priceText: showPrices
                          ? Pricing.inrPerPc(
                              Pricing.unitPriceInr(
                                category: 'Pro Clean',
                                serviceName: 'Winter Wear',
                                itemName: 'Woolen',
                              ),
                            )
                          : null,
                      value: _qty[_WinterItem.woolen]!,
                      onMinus: () => setState(() {
                        _qty[_WinterItem.woolen] =
                            (_qty[_WinterItem.woolen]! - 1).clamp(0, 999);
                      }),
                      onPlus: () => setState(() {
                        _qty[_WinterItem.woolen] =
                            (_qty[_WinterItem.woolen]! + 1).clamp(0, 999);
                      }),
                    ),
                    const SizedBox(height: 10),
                    _ItemCard(
                      title: 'Jackets',
                      imageAsset: 'assets/images/winter_wear/jackets.png',
                      priceText: showPrices
                          ? Pricing.inrPerPc(
                              Pricing.unitPriceInr(
                                category: 'Pro Clean',
                                serviceName: 'Winter Wear',
                                itemName: 'Jackets',
                              ),
                            )
                          : null,
                      value: _qty[_WinterItem.jackets]!,
                      onMinus: () => setState(() {
                        _qty[_WinterItem.jackets] =
                            (_qty[_WinterItem.jackets]! - 1).clamp(0, 999);
                      }),
                      onPlus: () => setState(() {
                        _qty[_WinterItem.jackets] =
                            (_qty[_WinterItem.jackets]! + 1).clamp(0, 999);
                      }),
                    ),
                    const SizedBox(height: 10),
                    _ItemCard(
                      title: 'Blazers',
                      imageAsset: 'assets/images/winter_wear/blazers.png',
                      priceText: showPrices
                          ? Pricing.inrPerPc(
                              Pricing.unitPriceInr(
                                category: 'Pro Clean',
                                serviceName: 'Winter Wear',
                                itemName: 'Blazers',
                              ),
                            )
                          : null,
                      value: _qty[_WinterItem.blazers]!,
                      onMinus: () => setState(() {
                        _qty[_WinterItem.blazers] =
                            (_qty[_WinterItem.blazers]! - 1).clamp(0, 999);
                      }),
                      onPlus: () => setState(() {
                        _qty[_WinterItem.blazers] =
                            (_qty[_WinterItem.blazers]! + 1).clamp(0, 999);
                      }),
                    ),
                    const SizedBox(height: 10),
                    _ItemCard(
                      title: 'Accessories',
                      imageAsset: 'assets/images/winter_wear/accessories.png',
                      priceText: showPrices
                          ? Pricing.inrPerPc(
                              Pricing.unitPriceInr(
                                category: 'Pro Clean',
                                serviceName: 'Winter Wear',
                                itemName: 'Accessories',
                              ),
                            )
                          : null,
                      value: _qty[_WinterItem.accessories]!,
                      onMinus: () => setState(() {
                        _qty[_WinterItem.accessories] =
                            (_qty[_WinterItem.accessories]! - 1).clamp(0, 999);
                      }),
                      onPlus: () => setState(() {
                        _qty[_WinterItem.accessories] =
                            (_qty[_WinterItem.accessories]! + 1).clamp(0, 999);
                      }),
                    ),
                    const SizedBox(height: 10),
                    _ItemCard(
                      title: 'Cashmere Sweaters',
                      imageAsset: 'assets/images/winter_wear/cashmere.png',
                      priceText: showPrices
                          ? Pricing.inrPerPc(
                              Pricing.unitPriceInr(
                                category: 'Pro Clean',
                                serviceName: 'Winter Wear',
                                itemName: 'Cashmere Sweaters',
                              ),
                            )
                          : null,
                      value: _qty[_WinterItem.cashmereSweaters]!,
                      onMinus: () => setState(() {
                        _qty[_WinterItem.cashmereSweaters] =
                            (_qty[_WinterItem.cashmereSweaters]! - 1).clamp(0, 999);
                      }),
                      onPlus: () => setState(() {
                        _qty[_WinterItem.cashmereSweaters] =
                            (_qty[_WinterItem.cashmereSweaters]! + 1).clamp(0, 999);
                      }),
                    ),
                    const SizedBox(height: 12),
                    OthersField(controller: _othersController),
                    const SizedBox(height: 12),
                    _OrderSummaryCard(
                      rows: _nonZeroSummaryRows,
                      total: _total,
                    ),
                    const SizedBox(height: 16),
                    _PrimaryGradientButton(
                      label: 'Add to Cart',
                      onTap: () {
                        context.read<CartProvider>().addOrMerge(
                              category: 'Pro Clean',
                              serviceName: 'Winter Wear',
                              imageAsset: 'assets/images/winter_wear/jackets.png',
                              isPerPiece: showPrices,
                              quantities: {
                                'Woolen': _qty[_WinterItem.woolen] ?? 0,
                                'Jackets': _qty[_WinterItem.jackets] ?? 0,
                                'Blazers': _qty[_WinterItem.blazers] ?? 0,
                                'Accessories': _qty[_WinterItem.accessories] ?? 0,
                                'Cashmere Sweaters':
                                    _qty[_WinterItem.cashmereSweaters] ?? 0,
                              },
                              note: _othersController.text,
                            );

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Added to cart')),
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: HomeBottomNav(
        currentIndex: 0,
        onTap: (i) {
          final route = switch (i) {
            0 => AppRoutes.home,
            1 => AppRoutes.orders,
            2 => AppRoutes.cart,
            _ => AppRoutes.profile,
          };
          Navigator.of(context).pushNamedAndRemoveUntil(route, (r) => false);
        },
      ),
    );
  }
}

enum _WinterItem { woolen, jackets, blazers, accessories, cashmereSweaters }

class _TopBar extends StatelessWidget {
  final String title;
  final VoidCallback onBack;

  const _TopBar({
    required this.title,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: SizedBox(
        height: 44,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: InkWell(
                onTap: onBack,
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(999),
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
            Text(
              title,
              style: AppTextStyles.header(color: HomeColors.text),
            ),
          ],
        ),
      ),
    );
  }
}

class _ItemCard extends StatelessWidget {
  final String title;
  final String imageAsset;
  final String? priceText;
  final int value;
  final VoidCallback onMinus;
  final VoidCallback onPlus;

  const _ItemCard({
    required this.title,
    required this.imageAsset,
    required this.priceText,
    required this.value,
    required this.onMinus,
    required this.onPlus,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: HomeColors.borderSoft),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: 56,
              height: 56,
              color: const Color(0xFFF0F2FF),
              child: Image.asset(imageAsset, fit: BoxFit.cover),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.header(color: HomeColors.text)
                      .copyWith(fontSize: 13),
                ),
                if (priceText != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    priceText!,
                    style: AppTextStyles.body(color: HomeColors.primary).copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          _QtyButton(
            icon: Icons.remove_rounded,
            variant: _QtyButtonVariant.outline,
            onTap: onMinus,
          ),
          const SizedBox(width: 10),
          Text(
            '$value',
            style:
                AppTextStyles.header(color: HomeColors.text).copyWith(fontSize: 13),
          ),
          const SizedBox(width: 10),
          _QtyButton(
            icon: Icons.add_rounded,
            variant: _QtyButtonVariant.filled,
            onTap: onPlus,
          ),
        ],
      ),
    );
  }
}

enum _QtyButtonVariant { outline, filled }

class _QtyButton extends StatelessWidget {
  final IconData icon;
  final _QtyButtonVariant variant;
  final VoidCallback onTap;

  const _QtyButton({
    required this.icon,
    required this.variant,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isFilled = variant == _QtyButtonVariant.filled;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isFilled ? HomeColors.primary : Colors.transparent,
          border: Border.all(color: HomeColors.primary),
        ),
        child: Icon(
          icon,
          size: 16,
          color: isFilled ? Colors.white : HomeColors.primary,
        ),
      ),
    );
  }
}

class _OrderSummaryCard extends StatelessWidget {
  final List<MapEntry<String, int>> rows;
  final int total;

  const _OrderSummaryCard({
    required this.rows,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: HomeColors.borderSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Order Summary',
            style:
                AppTextStyles.header(color: HomeColors.text).copyWith(fontSize: 12),
          ),
          const SizedBox(height: 10),
          for (final r in rows) _SummaryRow(label: r.key, value: '${r.value}'),
          const SizedBox(height: 8),
          const Divider(height: 1, thickness: 1, color: HomeColors.borderSoft),
          const SizedBox(height: 8),
          _SummaryRow(
            label: 'Total',
            value: '$total',
            isTotal: true,
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isTotal;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.isTotal = false,
  });

  @override
  Widget build(BuildContext context) {
    final style = isTotal
        ? AppTextStyles.header(color: HomeColors.primary).copyWith(fontSize: 12)
        : AppTextStyles.body(color: HomeColors.text).copyWith(fontSize: 12);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          Text(value, style: style),
        ],
      ),
    );
  }
}

class _PrimaryGradientButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _PrimaryGradientButton({
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(26),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(26),
              gradient: const LinearGradient(
                colors: [Color(0xFF2437B6), Color(0xFF2C3CA5)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            ),
            child: Center(
              child: Text(
                label,
                style: AppTextStyles.header(color: Colors.white)
                    .copyWith(fontSize: 14),
              ),
            ),
          ),
        ),
      ),
    );
  }
}



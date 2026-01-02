import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../routes/app_routes.dart';
import '../../providers/cart_provider.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/pricing.dart';
import '../home/widgets/home_bottom_nav.dart';
import '../home/widgets/home_colors.dart';
import 'pro_clean/widgets/others_field.dart';

class HomeLinensScreen extends StatefulWidget {
  const HomeLinensScreen({super.key});

  @override
  State<HomeLinensScreen> createState() => _HomeLinensScreenState();
}

class _HomeLinensScreenState extends State<HomeLinensScreen> {
  final _othersController = TextEditingController();

  final Map<_HomeLinenItem, int> _qty = {
    _HomeLinenItem.bedSheets: 0,
    _HomeLinenItem.carpets: 0,
    _HomeLinenItem.blanketsAndQuilts: 0,
    _HomeLinenItem.curtains: 0,
    _HomeLinenItem.tableclothsAndNapkins: 0,
  };

  @override
  void dispose() {
    _othersController.dispose();
    super.dispose();
  }

  int get _total => _qty.values.fold(0, (a, b) => a + b);

  List<MapEntry<String, int>> get _nonZeroSummaryRows {
    final rows = <MapEntry<String, int>>[];
    void addRow(String label, _HomeLinenItem type) {
      final v = _qty[type] ?? 0;
      if (v > 0) rows.add(MapEntry(label, v));
    }

    addRow('Bed Sheets', _HomeLinenItem.bedSheets);
    addRow('Carpets', _HomeLinenItem.carpets);
    addRow('Blankets & Quilts', _HomeLinenItem.blanketsAndQuilts);
    addRow('Curtains', _HomeLinenItem.curtains);
    addRow('Tablecloths & Napkins', _HomeLinenItem.tableclothsAndNapkins);
    return rows;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HomeColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 8),
            _TopBar(
              title: 'Home Linens',
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
                      title: 'Bed Sheets',
                      imageAsset: 'assets/images/home_linen/bedsheets.png',
                      priceText: Pricing.inrPerPc(
                        Pricing.unitPriceInr(
                          category: 'Home Linens',
                          serviceName: 'Home Linens',
                          itemName: 'Bed Sheets',
                        ),
                      ),
                      value: _qty[_HomeLinenItem.bedSheets]!,
                      onMinus: () => setState(() {
                        _qty[_HomeLinenItem.bedSheets] =
                            (_qty[_HomeLinenItem.bedSheets]! - 1).clamp(0, 999);
                      }),
                      onPlus: () => setState(() {
                        _qty[_HomeLinenItem.bedSheets] =
                            (_qty[_HomeLinenItem.bedSheets]! + 1).clamp(0, 999);
                      }),
                    ),
                    const SizedBox(height: 10),
                    _ItemCard(
                      title: 'Carpets',
                      imageAsset: 'assets/images/home_linen/carpets.png',
                      priceText: Pricing.inrPerPc(
                        Pricing.unitPriceInr(
                          category: 'Home Linens',
                          serviceName: 'Home Linens',
                          itemName: 'Carpets',
                        ),
                      ),
                      value: _qty[_HomeLinenItem.carpets]!,
                      onMinus: () => setState(() {
                        _qty[_HomeLinenItem.carpets] =
                            (_qty[_HomeLinenItem.carpets]! - 1).clamp(0, 999);
                      }),
                      onPlus: () => setState(() {
                        _qty[_HomeLinenItem.carpets] =
                            (_qty[_HomeLinenItem.carpets]! + 1).clamp(0, 999);
                      }),
                    ),
                    const SizedBox(height: 10),
                    _ItemCard(
                      title: 'Blankets & Quilts',
                      imageAsset: 'assets/images/home_linen/blankets.png',
                      priceText: Pricing.inrPerPc(
                        Pricing.unitPriceInr(
                          category: 'Home Linens',
                          serviceName: 'Home Linens',
                          itemName: 'Blankets & Quilts',
                        ),
                      ),
                      value: _qty[_HomeLinenItem.blanketsAndQuilts]!,
                      onMinus: () => setState(() {
                        _qty[_HomeLinenItem.blanketsAndQuilts] =
                            (_qty[_HomeLinenItem.blanketsAndQuilts]! - 1)
                                .clamp(0, 999);
                      }),
                      onPlus: () => setState(() {
                        _qty[_HomeLinenItem.blanketsAndQuilts] =
                            (_qty[_HomeLinenItem.blanketsAndQuilts]! + 1)
                                .clamp(0, 999);
                      }),
                    ),
                    const SizedBox(height: 10),
                    _ItemCard(
                      title: 'Curtains',
                      imageAsset: 'assets/images/home_linen/curtains.png',
                      priceText: Pricing.inrPerPc(
                        Pricing.unitPriceInr(
                          category: 'Home Linens',
                          serviceName: 'Home Linens',
                          itemName: 'Curtains',
                        ),
                      ),
                      value: _qty[_HomeLinenItem.curtains]!,
                      onMinus: () => setState(() {
                        _qty[_HomeLinenItem.curtains] =
                            (_qty[_HomeLinenItem.curtains]! - 1).clamp(0, 999);
                      }),
                      onPlus: () => setState(() {
                        _qty[_HomeLinenItem.curtains] =
                            (_qty[_HomeLinenItem.curtains]! + 1).clamp(0, 999);
                      }),
                    ),
                    const SizedBox(height: 10),
                    _ItemCard(
                      title: 'Tablecloths & Napkins',
                      imageAsset: 'assets/images/home_linen/tablecloths.png',
                      priceText: Pricing.inrPerPc(
                        Pricing.unitPriceInr(
                          category: 'Home Linens',
                          serviceName: 'Home Linens',
                          itemName: 'Tablecloths & Napkins',
                        ),
                      ),
                      value: _qty[_HomeLinenItem.tableclothsAndNapkins]!,
                      onMinus: () => setState(() {
                        _qty[_HomeLinenItem.tableclothsAndNapkins] =
                            (_qty[_HomeLinenItem.tableclothsAndNapkins]! - 1)
                                .clamp(0, 999);
                      }),
                      onPlus: () => setState(() {
                        _qty[_HomeLinenItem.tableclothsAndNapkins] =
                            (_qty[_HomeLinenItem.tableclothsAndNapkins]! + 1)
                                .clamp(0, 999);
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
                              category: 'Home Linens',
                              serviceName: 'Home Linens',
                              imageAsset: 'assets/images/home_linen/bedsheets.png',
                              quantities: {
                                'Bed Sheets': _qty[_HomeLinenItem.bedSheets] ?? 0,
                                'Carpets': _qty[_HomeLinenItem.carpets] ?? 0,
                                'Blankets & Quilts':
                                    _qty[_HomeLinenItem.blanketsAndQuilts] ?? 0,
                                'Curtains': _qty[_HomeLinenItem.curtains] ?? 0,
                                'Tablecloths & Napkins':
                                    _qty[_HomeLinenItem.tableclothsAndNapkins] ?? 0,
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

enum _HomeLinenItem {
  bedSheets,
  carpets,
  blanketsAndQuilts,
  curtains,
  tableclothsAndNapkins
}

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
  final String priceText;
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
                const SizedBox(height: 2),
                Text(
                  priceText,
                  style: AppTextStyles.body(color: HomeColors.primary).copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
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



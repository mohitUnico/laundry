import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../routes/app_routes.dart';
import '../../../providers/cart_provider.dart';
import '../../../theme/app_text_styles.dart';
import '../../../utils/pricing.dart';
import '../../home/widgets/home_bottom_nav.dart';
import '../../home/widgets/home_colors.dart';

class RegularWashServiceScreen extends StatefulWidget {
  final String serviceTitle;
  final bool showPrices;

  const RegularWashServiceScreen({
    super.key,
    required this.serviceTitle,
    this.showPrices = true,
  });

  @override
  State<RegularWashServiceScreen> createState() => _RegularWashServiceScreenState();
}

class _RegularWashServiceScreenState extends State<RegularWashServiceScreen> {
  final _othersController = TextEditingController();

  final Map<_ItemType, int> _qty = {
    _ItemType.topWear: 0,
    _ItemType.bottomWear: 0,
    _ItemType.saree: 0,
    _ItemType.kurta: 0,
  };

  @override
  void dispose() {
    _othersController.dispose();
    super.dispose();
  }

  int get _total => _qty.values.fold(0, (a, b) => a + b);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HomeColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 8),
            _TopBar(
              title: widget.serviceTitle,
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
                      title: 'Top Wear',
                      imageAsset: 'assets/images/regular_wash/top_wear.png',
                      priceText: widget.showPrices
                          ? Pricing.inrPerPc(
                              Pricing.unitPriceInr(
                                category: 'Regular Wash',
                                serviceName: widget.serviceTitle,
                                itemName: 'Top Wear',
                              ),
                            )
                          : null,
                      value: _qty[_ItemType.topWear]!,
                      onMinus: () => setState(() {
                        _qty[_ItemType.topWear] =
                            (_qty[_ItemType.topWear]! - 1).clamp(0, 999);
                      }),
                      onPlus: () => setState(() {
                        _qty[_ItemType.topWear] =
                            (_qty[_ItemType.topWear]! + 1).clamp(0, 999);
                      }),
                    ),
                    const SizedBox(height: 10),
                    _ItemCard(
                      title: 'Bottom Wear',
                      imageAsset: 'assets/images/regular_wash/bottom_wear.png',
                      priceText: widget.showPrices
                          ? Pricing.inrPerPc(
                              Pricing.unitPriceInr(
                                category: 'Regular Wash',
                                serviceName: widget.serviceTitle,
                                itemName: 'Bottom Wear',
                              ),
                            )
                          : null,
                      value: _qty[_ItemType.bottomWear]!,
                      onMinus: () => setState(() {
                        _qty[_ItemType.bottomWear] =
                            (_qty[_ItemType.bottomWear]! - 1).clamp(0, 999);
                      }),
                      onPlus: () => setState(() {
                        _qty[_ItemType.bottomWear] =
                            (_qty[_ItemType.bottomWear]! + 1).clamp(0, 999);
                      }),
                    ),
                    const SizedBox(height: 10),
                    _ItemCard(
                      title: 'Saree',
                      imageAsset: 'assets/images/regular_wash/saree.png',
                      priceText: widget.showPrices
                          ? Pricing.inrPerPc(
                              Pricing.unitPriceInr(
                                category: 'Regular Wash',
                                serviceName: widget.serviceTitle,
                                itemName: 'Saree',
                              ),
                            )
                          : null,
                      value: _qty[_ItemType.saree]!,
                      onMinus: () => setState(() {
                        _qty[_ItemType.saree] =
                            (_qty[_ItemType.saree]! - 1).clamp(0, 999);
                      }),
                      onPlus: () => setState(() {
                        _qty[_ItemType.saree] =
                            (_qty[_ItemType.saree]! + 1).clamp(0, 999);
                      }),
                    ),
                    const SizedBox(height: 10),
                    _ItemCard(
                      title: 'Kurta',
                      imageAsset: 'assets/images/regular_wash/kurta.png',
                      priceText: widget.showPrices
                          ? Pricing.inrPerPc(
                              Pricing.unitPriceInr(
                                category: 'Regular Wash',
                                serviceName: widget.serviceTitle,
                                itemName: 'Kurta',
                              ),
                            )
                          : null,
                      value: _qty[_ItemType.kurta]!,
                      onMinus: () => setState(() {
                        _qty[_ItemType.kurta] =
                            (_qty[_ItemType.kurta]! - 1).clamp(0, 999);
                      }),
                      onPlus: () => setState(() {
                        _qty[_ItemType.kurta] =
                            (_qty[_ItemType.kurta]! + 1).clamp(0, 999);
                      }),
                    ),
                    const SizedBox(height: 12),
                    _OthersField(controller: _othersController),
                    const SizedBox(height: 12),
                    _OrderSummaryCard(
                      topWear: _qty[_ItemType.topWear]!,
                      bottomWear: _qty[_ItemType.bottomWear]!,
                      saree: _qty[_ItemType.saree]!,
                      kurta: _qty[_ItemType.kurta]!,
                      total: _total,
                    ),
                    const SizedBox(height: 14),
                    _PrimaryButton(
                      label: 'Add to Cart',
                      onTap: () {
                        context.read<CartProvider>().addOrMerge(
                              category: 'Regular Wash',
                              serviceName: widget.serviceTitle,
                              imageAsset: 'assets/images/regular_wash/top_wear.png',
                              isPerPiece: widget.showPrices,
                              quantities: {
                                'Top Wear': _qty[_ItemType.topWear] ?? 0,
                                'Bottom Wear': _qty[_ItemType.bottomWear] ?? 0,
                                'Saree': _qty[_ItemType.saree] ?? 0,
                                'Kurta': _qty[_ItemType.kurta] ?? 0,
                              },
                              note: _othersController.text,
                            );

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Added to cart')),
                        );
                      },
                    ),
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

enum _ItemType { topWear, bottomWear, saree, kurta }

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
      height: 76,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: HomeColors.borderSoft),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: const Color(0xFFF0F2FF),
              borderRadius: BorderRadius.circular(14),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.asset(
                imageAsset,
                fit: BoxFit.cover,
              ),
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
                      .copyWith(fontSize: 14),
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
            onTap: onMinus,
          ),
          const SizedBox(width: 10),
          Text(
            '$value',
            style:
                AppTextStyles.header(color: HomeColors.text).copyWith(fontSize: 14),
          ),
          const SizedBox(width: 10),
          _QtyButton(
            icon: Icons.add_rounded,
            onTap: onPlus,
          ),
        ],
      ),
    );
  }
}

class _QtyButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _QtyButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: HomeColors.primary),
        ),
        child: Icon(icon, size: 16, color: HomeColors.primary),
      ),
    );
  }
}

class _OthersField extends StatelessWidget {
  final TextEditingController controller;

  const _OthersField({required this.controller});

  @override
  Widget build(BuildContext context) {
    final inputStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: HomeColors.text,
        ) ??
        const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: HomeColors.text,
        );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: HomeColors.borderSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Others',
            style:
                AppTextStyles.header(color: HomeColors.text).copyWith(fontSize: 12),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 34,
            child: TextField(
              controller: controller,
              textAlignVertical: TextAlignVertical.center,
              decoration: const InputDecoration(
                contentPadding: EdgeInsets.symmetric(vertical: 8),
                border: UnderlineInputBorder(
                  borderSide: BorderSide(color: HomeColors.borderSoft),
                ),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: HomeColors.borderSoft),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: HomeColors.primary, width: 1.6),
                ),
              ),
              style: inputStyle,
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderSummaryCard extends StatelessWidget {
  final int topWear;
  final int bottomWear;
  final int saree;
  final int kurta;
  final int total;

  const _OrderSummaryCard({
    required this.topWear,
    required this.bottomWear,
    required this.saree,
    required this.kurta,
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
          _SummaryRow(label: 'Top Wear', value: '$topWear'),
          _SummaryRow(label: 'Bottom Wear', value: '$bottomWear'),
          _SummaryRow(label: 'Saree', value: '$saree'),
          _SummaryRow(label: 'Kurta', value: '$kurta'),
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
        ? AppTextStyles.header(color: HomeColors.text).copyWith(fontSize: 12)
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

class _PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _PrimaryButton({
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: double.infinity,
        height: 50,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: HomeColors.primary,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          label,
          style: AppTextStyles.header(color: Colors.white).copyWith(fontSize: 14),
        ),
      ),
    );
  }
}



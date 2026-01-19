import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../routes/app_routes.dart';
import '../../../providers/cart_provider.dart';
import '../../../providers/service_catalog_provider.dart';
import '../../../theme/app_text_styles.dart';
import '../../../widgets/cart_success_dialog.dart';
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
  final TextEditingController _weightController = TextEditingController();

  final Map<String, int> _qtyByItemName = {};
  bool _didInit = false;
  String? _serviceId;

  @override
  void dispose() {
    _othersController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<double?> _askWeightKg() async {
    _weightController.text = '';
    return showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Enter weight (kg)'),
        content: TextField(
          controller: _weightController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(hintText: 'e.g. 3.5'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final v = double.tryParse(_weightController.text.trim());
              Navigator.of(ctx).pop(v);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  int get _total => _qtyByItemName.values.fold(0, (a, b) => a + b);

  List<MapEntry<String, int>> get _nonZeroSummaryRows {
    return _qtyByItemName.entries
        .where((e) => e.value > 0)
        .map((e) => MapEntry(e.key, e.value))
        .toList();
  }

  String _priceText(double perUnitPrice) => '₹${perUnitPrice.toStringAsFixed(0)}/pc';

  String _assetForItemName(String itemName) {
    final n = itemName.toLowerCase();
    if (n.contains('wool')) return 'assets/images/winter_wear/woolen_wear.png';
    if (n.contains('jacket')) return 'assets/images/winter_wear/jackets.png';
    if (n.contains('blazer')) return 'assets/images/winter_wear/blazers.png';
    if (n.contains('access')) return 'assets/images/winter_wear/accessories.png';
    if (n.contains('cashmere')) return 'assets/images/winter_wear/cashmere.png';
    return 'assets/images/winter_wear/jackets.png';
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInit) return;
    _didInit = true;

    final selection =
        ModalRoute.of(context)?.settings.arguments as ProCleanSelection?;
    _serviceId = selection?.serviceId;

    final sid = _serviceId;
    if (sid == null || sid.isEmpty) return;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await context
          .read<ServiceCatalogProvider>()
          .fetchClothesItemsForService(serviceId: sid, isActive: true);
      if (!mounted) return;
      final items =
          context.read<ServiceCatalogProvider>().clothesItemsForService(sid);
      setState(() {
        for (final it in items) {
          _qtyByItemName.putIfAbsent(it.itemName, () => 0);
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final selection =
        ModalRoute.of(context)?.settings.arguments as ProCleanSelection?;
    final showPrices = selection?.pricingType == ProCleanPricingType.perPiece;
    final serviceName = selection?.categoryName ?? 'Winter Wear';
    final sid = selection?.serviceId;
    final catalog = context.watch<ServiceCatalogProvider>();
    final items =
        (sid == null || sid.isEmpty) ? const [] : catalog.clothesItemsForService(sid);
    final isLoading =
        (sid == null || sid.isEmpty) ? false : catalog.isLoadingClothesItems(sid);
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
                    if (sid != null && sid.isNotEmpty && isLoading)
                      const Padding(
                        padding: EdgeInsets.only(top: 24, bottom: 24),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    for (final it in items) ...[
                      _ItemCard(
                        title: it.itemName,
                        imageAsset: _assetForItemName(it.itemName),
                        priceText: showPrices ? _priceText(it.perUnitPrice) : null,
                        value: _qtyByItemName[it.itemName] ?? 0,
                        onMinus: () => setState(() {
                          _qtyByItemName[it.itemName] =
                              ((_qtyByItemName[it.itemName] ?? 0) - 1).clamp(0, 999);
                        }),
                        onPlus: () => setState(() {
                          _qtyByItemName[it.itemName] =
                              ((_qtyByItemName[it.itemName] ?? 0) + 1).clamp(0, 999);
                        }),
                      ),
                      const SizedBox(height: 10),
                    ],
                    const SizedBox(height: 12),
                    OthersField(controller: _othersController),
                    const SizedBox(height: 12),
                    _OrderSummaryCard(
                      rows: _nonZeroSummaryRows,
                      total: _total,
                    ),
                    const SizedBox(height: 16),
                    Consumer<CartProvider>(
                      builder: (context, cart, _) {
                        return _PrimaryGradientButton(
                          label: 'Add to Cart',
                          isLoading: cart.isAddingToCart,
                          onTap: cart.isAddingToCart ? () {} : () async {
                        final serviceId = sid;
                        if (serviceId == null || serviceId.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Missing service id')),
                          );
                          return;
                        }

                        final clothIdByName = <String, String>{
                          for (final it in items) it.itemName: it.clothId,
                        };
                        final unitPrices = <String, int>{
                          for (final it in items) it.itemName: it.perUnitPrice.round(),
                        };

                            // For kg-wise items, weight will be calculated after supervision
                            // No need to ask user for weight
                            try {
                              await context.read<CartProvider>().addAndSave(
                                    category: 'Pro Clean',
                                    serviceName: serviceName,
                                    serviceId: serviceId,
                                    imageAsset: 'assets/images/winter_wear/jackets.png',
                                    isPerPiece: showPrices,
                                    quantities: Map<String, int>.from(_qtyByItemName),
                                    clothIdByItemName: clothIdByName,
                                    unitPricesInr: unitPrices,
                                    weightKg: null, // Weight will be calculated after supervision
                                    note: _othersController.text,
                              );

                              if (!mounted) return;
                              showCartSuccessDialog(context);
                            } catch (e) {
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(e.toString())),
                              );
                            }
                          },
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
  final bool isLoading;

  const _PrimaryGradientButton({
    required this.label,
    required this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onTap,
          borderRadius: BorderRadius.circular(26),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(26),
              gradient: isLoading
                  ? null
                  : const LinearGradient(
                      colors: [Color(0xFF2437B6), Color(0xFF2C3CA5)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
              color: isLoading ? Colors.grey : null,
            ),
            child: Center(
              child: isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
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



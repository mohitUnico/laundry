import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../routes/app_routes.dart';
import '../../../providers/cart_provider.dart';
import '../../../providers/service_catalog_provider.dart';
import '../../../theme/app_text_styles.dart';
import '../../home/widgets/home_bottom_nav.dart';
import '../../home/widgets/home_colors.dart';

class RegularWashServiceScreen extends StatefulWidget {
  final String serviceTitle;
  final bool showPrices;
  final String? serviceId;

  const RegularWashServiceScreen({
    super.key,
    required this.serviceTitle,
    this.showPrices = true,
    this.serviceId,
  });

  @override
  State<RegularWashServiceScreen> createState() => _RegularWashServiceScreenState();
}

class _RegularWashServiceScreenState extends State<RegularWashServiceScreen> {
  final _othersController = TextEditingController();

  final Map<String, int> _qtyByItemName = {};
  final TextEditingController _weightController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final serviceId = widget.serviceId;
      if (!mounted || serviceId == null || serviceId.isEmpty) return;
      await context
          .read<ServiceCatalogProvider>()
          .fetchClothesItemsForService(serviceId: serviceId, isActive: true);
      if (!mounted) return;
      final items = context.read<ServiceCatalogProvider>().clothesItemsForService(serviceId);
      setState(() {
        for (final it in items) {
          _qtyByItemName.putIfAbsent(it.itemName, () => 0);
        }
      });
    });
  }

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

  String _priceText(double perUnitPrice) => '₹${perUnitPrice.toStringAsFixed(0)}/pc';

  String _assetForItemName(String itemName) {
    final n = itemName.toLowerCase();
    if (n.contains('top')) return 'assets/images/regular_wash/top_wear.png';
    if (n.contains('bottom')) return 'assets/images/regular_wash/bottom_wear.png';
    if (n.contains('saree')) return 'assets/images/regular_wash/saree.png';
    if (n.contains('kurta')) return 'assets/images/regular_wash/kurta.png';
    return 'assets/images/regular_wash/top_wear.png';
  }

  @override
  Widget build(BuildContext context) {
    final serviceId = widget.serviceId;
    final catalog = context.watch<ServiceCatalogProvider>();
    final items = (serviceId == null || serviceId.isEmpty)
        ? const []
        : catalog.clothesItemsForService(serviceId);
    final isLoading = (serviceId == null || serviceId.isEmpty)
        ? false
        : catalog.isLoadingClothesItems(serviceId);

    // If we don't have a serviceId (legacy route entry), fall back to the old hardcoded UI.
    final effectiveItems = items.isNotEmpty
        ? items
        : const [];

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
                    if (serviceId != null && serviceId.isNotEmpty && isLoading)
                      const Padding(
                        padding: EdgeInsets.only(top: 24, bottom: 24),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    for (final it in effectiveItems) ...[
                      _ItemCard(
                        title: it.itemName,
                        imageAsset: _assetForItemName(it.itemName),
                        priceText: widget.showPrices ? _priceText(it.perUnitPrice) : null,
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
                    _OthersField(controller: _othersController),
                    const SizedBox(height: 12),
                    _OrderSummaryCard(
                      rows: _qtyByItemName.entries
                          .where((e) => e.value > 0)
                          .map((e) => MapEntry(e.key, e.value))
                          .toList(),
                      total: _total,
                    ),
                    const SizedBox(height: 14),
                    _PrimaryButton(
                      label: 'Add to Cart',
                      onTap: () async {
                        final sid = widget.serviceId;
                        if (sid == null || sid.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Missing service id')),
                          );
                          return;
                        }

                        final clothIdByName = <String, String>{
                          for (final it in effectiveItems) it.itemName: it.clothId,
                        };
                        final unitPrices = <String, int>{
                          for (final it in effectiveItems) it.itemName: it.perUnitPrice.round(),
                        };

                        double? weightKg;
                        if (!widget.showPrices) {
                          weightKg = await _askWeightKg();
                          if (weightKg == null || weightKg <= 0) return;
                        }

                        try {
                          await context.read<CartProvider>().addAndSave(
                                category: 'Regular Wash',
                                serviceName: widget.serviceTitle,
                                serviceId: sid,
                                imageAsset: 'assets/images/regular_wash/top_wear.png',
                                isPerPiece: widget.showPrices,
                                quantities: Map<String, int>.from(_qtyByItemName),
                                clothIdByItemName: clothIdByName,
                                unitPricesInr: unitPrices,
                                weightKg: weightKg,
                                note: _othersController.text,
                              );

                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Added to cart')),
                          );
                        } catch (e) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(e.toString())),
                          );
                        }
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



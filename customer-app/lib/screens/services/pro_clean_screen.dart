import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/cart_provider.dart';
import '../../providers/service_catalog_provider.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/profile_service_error_messages.dart';
import '../../widgets/cart_success_dialog.dart';
import '../home/widgets/home_bottom_nav.dart';
import '../home/widgets/home_colors.dart';
import '../home/widgets/pro_clean_bottom_sheet.dart';
import '../../widgets/per_kg_price_banner.dart';

/// Generic Pro Clean service screen.
///
/// This is used as a fallback when backend service names don't match our
/// hardcoded Pro Clean routes (e.g. "Stain removal", "Winter wear cleaning",
/// "Delicate wash"). It still fetches clothes items correctly using `serviceId`.
class ProCleanScreen extends StatefulWidget {
  const ProCleanScreen({super.key});

  @override
  State<ProCleanScreen> createState() => _ProCleanScreenState();
}

class _ProCleanScreenState extends State<ProCleanScreen> {
  final TextEditingController _weightController = TextEditingController();
  final Map<String, int> _qtyByItemName = {};
  bool _didInit = false;
  String? _serviceId;

  @override
  void dispose() {
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
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInit) return;
    _didInit = true;

    final selection = ModalRoute.of(context)?.settings.arguments as ProCleanSelection?;
    _serviceId = selection?.serviceId;

    final sid = _serviceId;
    if (sid == null || sid.isEmpty) return;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await context.read<ServiceCatalogProvider>().fetchClothesItemsForService(
            serviceId: sid,
            isActive: true,
          );
      if (!mounted) return;
      final items = context.read<ServiceCatalogProvider>().clothesItemsForService(sid);
      setState(() {
        for (final it in items) {
          _qtyByItemName.putIfAbsent(it.itemName, () => 0);
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final selection = ModalRoute.of(context)?.settings.arguments as ProCleanSelection?;
    final showPrices = selection?.pricingType == ProCleanPricingType.perPiece;
    final perKgPrice = selection?.perKgPrice;
    final serviceName = selection?.categoryName ?? 'Pro Clean';
    final sid = selection?.serviceId;

    final catalog = context.watch<ServiceCatalogProvider>();
    final items = (sid == null || sid.isEmpty) ? const [] : catalog.clothesItemsForService(sid);
    final isLoading = (sid == null || sid.isEmpty) ? false : catalog.isLoadingClothesItems(sid);

    return Scaffold(
      backgroundColor: HomeColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 8),
            _TopBar(
              title: serviceName,
              onBack: () => Navigator.of(context).maybePop(),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  children: [
                    if (!showPrices)
                      PerKgPriceBanner(
                        perKgPrice: perKgPrice,
                        label: '₹/kg for $serviceName',
                      ),
                    if (!showPrices) const SizedBox(height: 12),
                    if (sid != null && sid.isNotEmpty && isLoading)
                      const Padding(
                        padding: EdgeInsets.only(top: 24, bottom: 24),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    if (sid == null || sid.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 12, bottom: 12),
                        child: Text(
                          'Missing service id',
                          style: AppTextStyles.body(color: HomeColors.muted).copyWith(fontSize: 12),
                        ),
                      )
                    else if (!isLoading && items.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 12, bottom: 12),
                        child: Text(
                          'No cloth items found for this service.',
                          style: AppTextStyles.body(color: HomeColors.muted).copyWith(fontSize: 12),
                        ),
                      )
                    else
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
                                    imageAsset: 'assets/images/home/pro_clean.png',
                                    isPerPiece: showPrices,
                                    quantities: Map<String, int>.from(_qtyByItemName),
                                    clothIdByItemName: clothIdByName,
                                    unitPricesInr: unitPrices,
                                    weightKg: null, // Weight will be calculated after supervision
                              );

                              if (!mounted) return;
                              showCartSuccessDialog(context);
                            } catch (e) {
                              if (!mounted) return;
                              final message = ProfileServiceErrorMessages.getServiceErrorMessage(
                                e,
                                operation: 'add to cart',
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(message)),
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
                child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
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
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 44,
            height: 44,
            child: Image.asset(imageAsset, fit: BoxFit.contain),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.listItemTitle(color: HomeColors.text),
                ),
                if (priceText != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    priceText!,
                    style: AppTextStyles.body(color: HomeColors.muted).copyWith(fontSize: 11),
                  ),
                ],
              ],
            ),
          ),
          Row(
            children: [
              _QtyButton(icon: Icons.remove, onTap: onMinus),
              const SizedBox(width: 10),
              Text(
                '$value',
                style: AppTextStyles.listItemTitle(color: HomeColors.text),
              ),
              const SizedBox(width: 10),
              _QtyButton(icon: Icons.add, onTap: onPlus),
            ],
          ),
        ],
      ),
    );
  }
}

class _QtyButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _QtyButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Icon(icon, size: 16, color: HomeColors.text),
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
    return InkWell(
      onTap: isLoading ? null : onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 52,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: isLoading
              ? null
              : const LinearGradient(
                  colors: [
                    HomeColors.primary,
                    Color(0xFF1F2F8E), // slightly darker shade for depth
                  ],
                ),
          color: isLoading ? Colors.grey : null,
        ),
        alignment: Alignment.center,
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
                style: AppTextStyles.button(color: Colors.white),
              ),
      ),
    );
  }
}



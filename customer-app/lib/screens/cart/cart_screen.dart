import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../home/widgets/home_colors.dart';
import '../../providers/cart_provider.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/pricing.dart';
import '../../utils/cart_error_messages.dart';
import '../../models/cart_item.dart';
import '../../services/customer_info_service.dart';

class CartScreen extends StatefulWidget {
  final bool showBack;

  const CartScreen({
    super.key,
    this.showBack = false,
  });

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final Map<String, bool> _expandedCategories = {};
  final Map<String, bool> _expandedServices = {};
  final _customerInfoService = CustomerInfoService();
  
  CustomerAddress? _pickupAddress;
  CustomerAddress? _deliveryAddress;
  bool _isLoadingAddresses = false;

  String _formatInr(int value) => Pricing.inr(value);

  @override
  void initState() {
    super.initState();
    // Fetch cart items from backend when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CartProvider>().fetchFromBackend();
      _loadDefaultAddresses();
    });
  }

  Future<void> _loadDefaultAddresses() async {
    setState(() {
      _isLoadingAddresses = true;
    });

    try {
      final addresses = await _customerInfoService.getAddresses();
      if (addresses.isNotEmpty && mounted) {
        // Use default address or first address for both pickup and delivery
        final defaultAddress = addresses.firstWhere(
          (a) => a.isDefault,
          orElse: () => addresses.first,
        );
        setState(() {
          _pickupAddress = defaultAddress;
          _deliveryAddress = defaultAddress;
          _isLoadingAddresses = false;
        });
      } else if (mounted) {
        setState(() {
          _isLoadingAddresses = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingAddresses = false;
        });
      }
    }
  }

  Future<void> _handleChangePickupAddress() async {
    final result = await Navigator.of(context).pushNamed(AppRoutes.selectLocation);
    if (result != null && mounted) {
      final address = result as CustomerAddress;
      setState(() {
        _pickupAddress = address;
      });
    }
  }

  Future<void> _handleChangeDeliveryAddress() async {
    final result = await Navigator.of(context).pushNamed(AppRoutes.selectLocation);
    if (result != null && mounted) {
      final address = result as CustomerAddress;
      setState(() {
        _deliveryAddress = address;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HomeColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              Stack(
                alignment: Alignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      widget.showBack
                          ? _IconButtonSquare(
                              icon: Icons.arrow_back_ios_new_rounded,
                              onTap: () => Navigator.of(context).maybePop(),
                            )
                          : const SizedBox(width: 44, height: 44),
                      _IconButtonSquare(
                        icon: Icons.tune_rounded,
                        onTap: () {},
                      ),
                    ],
                  ),
                  Center(
                    child: Text(
                      'Cart',
                      style: AppTextStyles.header(color: HomeColors.text),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Consumer<CartProvider>(
                  builder: (context, cart, _) {
                    final items = cart.items;
                    if (items.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                color: HomeColors.primary.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.shopping_cart_outlined,
                                size: 60,
                                color: HomeColors.primary.withOpacity(0.5),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'No items added',
                              style: AppTextStyles.header(color: HomeColors.text)
                                  .copyWith(fontSize: 20, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Add items to your cart to continue',
                              style: AppTextStyles.body(color: HomeColors.muted)
                                  .copyWith(fontSize: 14),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    }

                    // Separate items by pricing type
                    final perPieceItems = items.where((x) => x.isPerPiece).toList();
                    final kgWiseItems = items.where((x) => !x.isPerPiece).toList();

                    // Group per-piece items by category
                    final perPieceByCategory = <String, List<CartItem>>{};
                    for (final item in perPieceItems) {
                      perPieceByCategory.putIfAbsent(item.category, () => []).add(item);
                    }

                    // Group kg-wise items by category and service
                    // Count how many times each service appears
                    final kgWiseByCategory = <String, List<CartItem>>{};
                    final kgWiseServiceCounts = <String, int>{}; // Track count per service
                    for (final item in kgWiseItems) {
                      final serviceKey = '${item.category}_${item.serviceName}';
                      kgWiseServiceCounts[serviceKey] = (kgWiseServiceCounts[serviceKey] ?? 0) + 1;
                      kgWiseByCategory.putIfAbsent(item.category, () => []).add(item);
                    }

                    return ListView(
                      padding: const EdgeInsets.only(bottom: 16),
                      children: [
                        // Per-Piece Items Section
                        if (perPieceItems.isNotEmpty) ...[
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.check_circle_outline,
                                  size: 18,
                                  color: HomeColors.primary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Per-Piece Items',
                                  style: AppTextStyles.header(color: HomeColors.text)
                                      .copyWith(fontSize: 16, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                          for (final categoryEntry in perPieceByCategory.entries) ...[
                            _CategorySection(
                              category: categoryEntry.key,
                              services: categoryEntry.value,
                              isExpanded: _expandedCategories[categoryEntry.key] ?? true,
                              onToggle: () => setState(() {
                                _expandedCategories[categoryEntry.key] =
                                    !(_expandedCategories[categoryEntry.key] ?? true);
                              }),
                              onServiceToggle: (serviceId) => setState(() {
                                _expandedServices[serviceId] =
                                    !(_expandedServices[serviceId] ?? true);
                              }),
                              expandedServices: _expandedServices,
                              onItemQuantityChange: (itemId, itemName, delta) {
                                context.read<CartProvider>().updateItemQuantity(
                                      itemId,
                                      itemName,
                                      delta,
                                    );
                              },
                            onDeleteService: (itemId) async {
                              try {
                                await context.read<CartProvider>().remove(itemId);
                              } catch (e) {
                                if (mounted) {
                                  final message = CartErrorMessages.getCartErrorMessage(
                                    e,
                                    operation: 'delete item',
                                  );
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(message)),
                                  );
                                }
                              }
                            },
                              formatInr: _formatInr,
                            ),
                            const SizedBox(height: 12),
                          ],
                        ],
                        // Kg-Wise Items Section
                        if (kgWiseItems.isNotEmpty) ...[
                          if (perPieceItems.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            const Divider(height: 24, thickness: 1),
                            const SizedBox(height: 8),
                          ],
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.scale_outlined,
                                  size: 18,
                                  color: HomeColors.primary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Kg-Wise Items',
                                  style: AppTextStyles.header(color: HomeColors.text)
                                      .copyWith(fontSize: 16, fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFEF3C7),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: const Color(0xFFFCD34D)),
                                  ),
                                  child: Text(
                                    'Price after supervision',
                                    style: AppTextStyles.body(color: const Color(0xFF92400E))
                                        .copyWith(fontSize: 10),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          for (final categoryEntry in kgWiseByCategory.entries) ...[
                            _CategorySection(
                              category: categoryEntry.key,
                              services: categoryEntry.value,
                              isExpanded: _expandedCategories[categoryEntry.key] ?? true,
                              onToggle: () => setState(() {
                                _expandedCategories[categoryEntry.key] =
                                    !(_expandedCategories[categoryEntry.key] ?? true);
                              }),
                              onServiceToggle: (serviceId) => setState(() {
                                _expandedServices[serviceId] =
                                    !(_expandedServices[serviceId] ?? true);
                              }),
                              expandedServices: _expandedServices,
                              onItemQuantityChange: (itemId, itemName, delta) {
                                // Kg-wise items don't have quantity changes
                              },
                            onDeleteService: (itemId) async {
                              try {
                                await context.read<CartProvider>().remove(itemId);
                              } catch (e) {
                                if (mounted) {
                                  final message = CartErrorMessages.getCartErrorMessage(
                                    e,
                                    operation: 'delete item',
                                  );
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(message)),
                                  );
                                }
                              }
                            },
                              formatInr: _formatInr,
                            ),
                            const SizedBox(height: 12),
                          ],
                        ],
                        const SizedBox(height: 14),
                        Consumer<CartProvider>(
                          builder: (context, cart, _) {
                            if (cart.items.isEmpty || !cart.hasPricedItems) {
                              return const SizedBox.shrink();
                            }
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: HomeColors.borderSoft),
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    'Total',
                                    style: AppTextStyles.header(color: HomeColors.text),
                                  ),
                                  const Spacer(),
                                  Text(
                                    _formatInr(cart.totalInr),
                                    style: AppTextStyles.header(color: HomeColors.primary),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 18),
                        Text(
                          'Address',
                          style: AppTextStyles.header(color: HomeColors.text),
                        ),
                        const SizedBox(height: 10),
                        _AddressCard(
                          pickupAddress: _pickupAddress,
                          deliveryAddress: _deliveryAddress,
                          isLoading: _isLoadingAddresses,
                          onChangePickup: _handleChangePickupAddress,
                          onChangeDelivery: _handleChangeDeliveryAddress,
                        ),
                      ],
                    );
                  },
                ),
              ),
              Consumer<CartProvider>(
                builder: (context, cart, _) {
                  // Show for both per-piece and kg-wise carts.
                  if (cart.items.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _PrimaryBottomButton(
                      label: 'Choose Delivery',
                      onTap: () => Navigator.of(context).pushNamed(AppRoutes.deliveryOptions),
                    ),
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

class _CategorySection extends StatelessWidget {
  final String category;
  final List<CartItem> services;
  final bool isExpanded;
  final VoidCallback onToggle;
  final Function(String) onServiceToggle;
  final Map<String, bool> expandedServices;
  final Function(String, String, int) onItemQuantityChange;
  final Function(String) onDeleteService;
  final String Function(int) formatInr;

  const _CategorySection({
    required this.category,
    required this.services,
    required this.isExpanded,
    required this.onToggle,
    required this.onServiceToggle,
    required this.expandedServices,
    required this.onItemQuantityChange,
    required this.onDeleteService,
    required this.formatInr,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: HomeColors.borderSoft),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onToggle,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Text(
                    category,
                    style: AppTextStyles.header(color: HomeColors.text),
                  ),
                  const Spacer(),
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: HomeColors.text,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded) ...[
            const Divider(height: 1, thickness: 1),
            // Group services by serviceName to show individual entries
            Builder(
              builder: (context) {
                // Group services by serviceName
                final servicesByServiceName = <String, List<CartItem>>{};
                for (final service in services) {
                  servicesByServiceName.putIfAbsent(service.serviceName, () => []).add(service);
                }
                
                return Column(
                  children: [
                    for (final serviceGroup in servicesByServiceName.entries) ...[
                      // Show service group header if multiple items
                      if (serviceGroup.value.length > 1) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          child: Row(
                            children: [
                              Text(
                                serviceGroup.key,
                                style: AppTextStyles.header(color: HomeColors.text)
                                    .copyWith(fontSize: 14),
                              ),
                              const Spacer(),
                              Text(
                                '${serviceGroup.value.length} items',
                                style: AppTextStyles.body(color: HomeColors.muted)
                                    .copyWith(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        const Divider(height: 1, thickness: 1),
                      ],
                      // Show each service entry
                      for (int i = 0; i < serviceGroup.value.length; i++) ...[
                        _ServiceSection(
                          service: serviceGroup.value[i],
                          isExpanded: expandedServices[serviceGroup.value[i].id] ?? true,
                          onToggle: () => onServiceToggle(serviceGroup.value[i].id),
                          onItemQuantityChange: (itemName, delta) =>
                              onItemQuantityChange(serviceGroup.value[i].id, itemName, delta),
                          onDelete: () => onDeleteService(serviceGroup.value[i].id),
                          formatInr: formatInr,
                          showServiceName: serviceGroup.value.length == 1, // Only show service name if single item
                        ),
                        if (i < serviceGroup.value.length - 1)
                          const Divider(height: 1, thickness: 1),
                      ],
                    ],
                  ],
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}

class _ServiceSection extends StatelessWidget {
  final CartItem service;
  final bool isExpanded;
  final VoidCallback onToggle;
  final Function(String, int) onItemQuantityChange;
  final VoidCallback onDelete;
  final String Function(int) formatInr;

  final bool showServiceName; // Whether to show service name in header

  const _ServiceSection({
    required this.service,
    required this.isExpanded,
    required this.onToggle,
    required this.onItemQuantityChange,
    required this.onDelete,
    required this.formatInr,
    this.showServiceName = true, // Default to showing service name
  });

  @override
  Widget build(BuildContext context) {
    final showPrices = service.isPerPiece;
    final prices = showPrices
        ? (service.unitPricesInr ?? const <String, int>{})
        : const <String, int>{};
    final subtotal = service.subtotalInr;
    final weightLabel = (!showPrices && service.weightKg != null && service.weightKg! > 0)
        ? '${service.weightKg!.toStringAsFixed(service.weightKg! % 1 == 0 ? 0 : 1)} kg'
        : null;

    return Column(
      children: [
        InkWell(
          onTap: onToggle,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                if (service.imageAsset != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 48,
                      height: 48,
                      color: const Color(0xFFF0F2FF),
                      child: Image.asset(
                        service.imageAsset!,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (showServiceName) ...[
                        Text(
                          service.serviceName,
                          style: AppTextStyles.header(color: HomeColors.text),
                        ),
                      ] else ...[
                        // For grouped items, show a generic label
                        Text(
                          'Item',
                          style: AppTextStyles.header(color: HomeColors.text),
                        ),
                      ],
                      const SizedBox(height: 4),
                      Builder(
                        builder: (context) {
                          // For kg-wise items, count how many kg-wise items exist in the cart
                          if (!showPrices) {
                            // Get all kg-wise items from the cart provider
                            final cart = context.read<CartProvider>();
                            final allKgWiseItems = cart.items.where((x) => !x.isPerPiece).toList();
                            final count = allKgWiseItems.length;
                            return Text(
                              count == 1 ? '1 item' : '$count items',
                              style: AppTextStyles.body(color: HomeColors.muted)
                                  .copyWith(fontSize: 12),
                            );
                          }
                          // For per-piece items
                          return Text(
                            service.quantities.length == 1
                                ? '${service.totalQuantity} ${service.quantities.keys.first}${service.totalQuantity > 1 ? 's' : ''}'
                                : '${service.quantities.length} items (${service.totalQuantity} total)',
                            style: AppTextStyles.body(color: HomeColors.muted)
                                .copyWith(fontSize: 12),
                          );
                        },
                      ),
                      if (showPrices && subtotal > 0) ...[
                        const SizedBox(height: 4),
                        Text(
                          formatInr(subtotal),
                          style: AppTextStyles.header(color: HomeColors.primary),
                        ),
                      ],
                    ],
                  ),
                ),
                InkWell(
                  onTap: onDelete,
                  borderRadius: BorderRadius.circular(999),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(
                      Icons.delete_outline_rounded,
                      size: 20,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  isExpanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: HomeColors.text,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
        if (isExpanded) ...[
          const Divider(height: 1, thickness: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
            child: Column(
              children: [
                // Show individual cloth items for both per-piece and kg-wise items
                if (service.quantities.isNotEmpty) ...[
                  for (final itemEntry in service.quantities.entries) ...[
                    _ItemRow(
                      itemName: itemEntry.key,
                      quantity: itemEntry.value,
                      unitPrice: showPrices ? (prices[itemEntry.key] ?? 0) : null,
                      onIncrement: () => onItemQuantityChange(itemEntry.key, 1),
                      onDecrement: () => onItemQuantityChange(itemEntry.key, -1),
                      formatInr: formatInr,
                    ),
                    if (itemEntry != service.quantities.entries.last)
                      const SizedBox(height: 8),
                  ],
                ] else ...[
                  // Fallback: if no quantities, show service name (shouldn't happen normally)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      service.serviceName,
                      style: AppTextStyles.body(color: HomeColors.text),
                    ),
                  ),
                ],
                if (service.note != null && service.note!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F2FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.note_outlined,
                          size: 16,
                          color: HomeColors.muted,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            service.note!,
                            style: AppTextStyles.body(color: HomeColors.muted)
                                .copyWith(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _ItemRow extends StatelessWidget {
  final String itemName;
  final int quantity;
  final int? unitPrice;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final String Function(int) formatInr;

  const _ItemRow({
    required this.itemName,
    required this.quantity,
    this.unitPrice,
    required this.onIncrement,
    required this.onDecrement,
    required this.formatInr,
  });

  @override
  Widget build(BuildContext context) {
    final itemTotal = unitPrice != null ? unitPrice! * quantity : null;

    return Row(
      children: [
        Expanded(
          child: Text(
            itemName,
            style: AppTextStyles.body(color: HomeColors.text),
          ),
        ),
        if (unitPrice != null) ...[
          Text(
            formatInr(unitPrice!),
            style: AppTextStyles.body(color: HomeColors.muted).copyWith(fontSize: 12),
          ),
          const SizedBox(width: 8),
        ],
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _QtyButton(
              icon: Icons.remove_rounded,
              variant: _QtyButtonVariant.outline,
              onTap: onDecrement,
            ),
            const SizedBox(width: 10),
            Text(
              '$quantity',
              style: AppTextStyles.header(color: HomeColors.text),
            ),
            const SizedBox(width: 10),
            _QtyButton(
              icon: Icons.add_rounded,
              variant: _QtyButtonVariant.filled,
              onTap: onIncrement,
            ),
          ],
        ),
        if (itemTotal != null) ...[
          const SizedBox(width: 12),
          SizedBox(
            width: 60,
            child: Text(
              formatInr(itemTotal),
              textAlign: TextAlign.right,
              style: AppTextStyles.header(color: HomeColors.primary).copyWith(fontSize: 14),
            ),
          ),
        ],
      ],
    );
  }
}

class _KgWiseItemRow extends StatelessWidget {
  final String serviceName;
  final double? weightKg;
  final String Function(int) formatInr;

  const _KgWiseItemRow({
    required this.serviceName,
    this.weightKg,
    required this.formatInr,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            serviceName,
            style: AppTextStyles.body(color: HomeColors.text),
          ),
        ),
        if (weightKg != null && weightKg! > 0) ...[
          Text(
            '${weightKg!.toStringAsFixed(weightKg! % 1 == 0 ? 0 : 1)} kg',
            style: AppTextStyles.body(color: HomeColors.muted).copyWith(fontSize: 12),
          ),
        ] else ...[
          Text(
            'Weight to be calculated',
            style: AppTextStyles.body(color: HomeColors.muted).copyWith(fontSize: 12),
          ),
        ],
      ],
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
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isFilled ? HomeColors.primary : Colors.transparent,
          border: Border.all(
            color: isFilled ? HomeColors.primary : const Color(0xFFD1D5DB),
          ),
        ),
        child: Icon(
          icon,
          size: 18,
          color: isFilled ? Colors.white : const Color(0xFF6B7280),
        ),
      ),
    );
  }
}

class _IconButtonSquare extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _IconButtonSquare({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: HomeColors.borderSoft),
        ),
        child: Center(
          child: Icon(
            icon,
            size: 18,
            color: HomeColors.text,
          ),
        ),
      ),
    );
  }
}

class _AddressCard extends StatelessWidget {
  final CustomerAddress? pickupAddress;
  final CustomerAddress? deliveryAddress;
  final bool isLoading;
  final VoidCallback onChangePickup;
  final VoidCallback onChangeDelivery;

  const _AddressCard({
    required this.pickupAddress,
    required this.deliveryAddress,
    required this.isLoading,
    required this.onChangePickup,
    required this.onChangeDelivery,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: HomeColors.borderSoft),
      ),
      child: Stack(
        children: [
          Positioned(
            left: 16,
            top: 40,
            bottom: 40,
            child: Container(
              width: 3,
              decoration: BoxDecoration(
                color: const Color(0xFF35C66B),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          Positioned(
            left: 9,
            top: 28,
            child: Container(
              width: 18,
              height: 18,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(
                  Icons.radio_button_checked_rounded,
                  size: 16,
                  color: Colors.black87,
                ),
              ),
            ),
          ),
          Positioned(
            left: 10,
            top: 118,
            child: Container(
              width: 18,
              height: 18,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(
                  Icons.location_on_outlined,
                  size: 18,
                  color: Colors.black87,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 38),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Pick-up Address',
                        style: AppTextStyles.header(color: HomeColors.text),
                      ),
                    ),
                    InkWell(
                      onTap: onChangePickup,
                      borderRadius: BorderRadius.circular(999),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 4,
                        ),
                        child: Text(
                          'Change',
                          style: AppTextStyles.header(color: HomeColors.primary),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                if (isLoading)
                  const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else if (pickupAddress != null)
                  Text(
                    pickupAddress!.fullAddress,
                    style: AppTextStyles.body(color: HomeColors.muted).copyWith(
                      height: 1.25,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  )
                else
                  Text(
                    'No address selected',
                    style: AppTextStyles.body(color: HomeColors.muted).copyWith(
                      height: 1.25,
                    ),
                  ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Delivery Address',
                        style: AppTextStyles.header(color: HomeColors.text),
                      ),
                    ),
                    InkWell(
                      onTap: onChangeDelivery,
                      borderRadius: BorderRadius.circular(999),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 4,
                        ),
                        child: Text(
                          'Change',
                          style: AppTextStyles.header(color: HomeColors.primary),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                if (isLoading)
                  const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else if (deliveryAddress != null)
                  Text(
                    deliveryAddress!.fullAddress,
                    style: AppTextStyles.body(color: HomeColors.muted).copyWith(
                      height: 1.25,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  )
                else
                  Text(
                    'No address selected',
                    style: AppTextStyles.body(color: HomeColors.muted).copyWith(
                      height: 1.25,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PrimaryBottomButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _PrimaryBottomButton({
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
          borderRadius: BorderRadius.circular(18),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: const LinearGradient(
                colors: [Color(0xFF2437B6), Color(0xFF2C3CA5)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            ),
            child: Center(
              child: Text(
                label,
                style: AppTextStyles.header(color: Colors.white),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

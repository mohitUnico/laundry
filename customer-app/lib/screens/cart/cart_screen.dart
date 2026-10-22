import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../models/cart_item.dart';
import '../../providers/cart_provider.dart';
import '../../routes/app_routes.dart';
import '../../services/customer_info_service.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/cart_error_messages.dart';
import '../../widgets/catalog_image.dart';
import '../home/widgets/home_colors.dart';

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
  final _customerInfoService = CustomerInfoService();

  CustomerAddress? _pickupAddress;
  CustomerAddress? _deliveryAddress;
  bool _isLoadingAddresses = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDefaultAddress();
    });
  }

  Future<void> _loadDefaultAddress() async {
    setState(() => _isLoadingAddresses = true);
    try {
      final addresses = await _customerInfoService.getAddresses();
      if (!mounted) return;
      if (addresses.isEmpty) {
        setState(() => _isLoadingAddresses = false);
        return;
      }
      final defaultAddress = addresses.firstWhere(
        (a) => a.isDefault,
        orElse: () => addresses.first,
      );
      setState(() {
        _pickupAddress = defaultAddress;
        _deliveryAddress = defaultAddress;
        _isLoadingAddresses = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoadingAddresses = false);
    }
  }

  Future<void> _handleChangePickupAddress() async {
    final result = await Navigator.of(context).pushNamed(AppRoutes.selectLocation);
    if (!mounted || result is! CustomerAddress) return;
    setState(() => _pickupAddress = result);
  }

  Future<void> _handleChangeDeliveryAddress() async {
    final result = await Navigator.of(context).pushNamed(AppRoutes.selectLocation);
    if (!mounted || result is! CustomerAddress) return;
    setState(() => _deliveryAddress = result);
  }

  String _addressLine(CustomerAddress? address) {
    if (address == null) return 'No address selected';
    final line = address.fullAddress.trim();
    if (line.isNotEmpty) return line;
    final label = address.addressLabel.trim();
    return label.isEmpty ? 'No address selected' : label;
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
              const SizedBox(height: 8),
              Row(
                children: [
                  if (widget.showBack) ...[
                    _BackButton(onTap: () => Navigator.of(context).maybePop()),
                    const SizedBox(width: 10),
                  ],
                  Text(
                    'Cart',
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: HomeColors.text,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Expanded(
                child: Consumer<CartProvider>(
                  builder: (context, cart, _) {
                    final items = cart.items;
                    if (items.isEmpty) {
                      return const _EmptyCart();
                    }
                    return ListView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.only(bottom: 12),
                      children: [
                        for (final item in items) ...[
                          _CartServiceRow(
                            item: item,
                            onDelete: () => _deleteItem(item.id),
                          ),
                          const SizedBox(height: 10),
                        ],
                        const SizedBox(height: 8),
                        Text(
                          'Address',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: HomeColors.text,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _AddressCard(
                          pickupLine: _addressLine(_pickupAddress),
                          deliveryLine: _addressLine(_deliveryAddress),
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
                  if (cart.items.isEmpty) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12, top: 8),
                    child: SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context)
                            .pushNamed(AppRoutes.deliveryOptions),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: HomeColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(26),
                          ),
                        ),
                        child: Text(
                          'Choose Delivery',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
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

  Future<void> _deleteItem(String id) async {
    try {
      await context.read<CartProvider>().remove(id);
    } catch (e) {
      if (!mounted) return;
      final message = CartErrorMessages.getCartErrorMessage(
        e,
        operation: 'delete item',
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }
}

class _EmptyCart extends StatelessWidget {
  const _EmptyCart();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'No services added',
        style: AppTextStyles.header(color: HomeColors.muted),
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  final VoidCallback onTap;

  const _BackButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
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
    );
  }
}

class _CartServiceRow extends StatelessWidget {
  final CartItem item;
  final VoidCallback onDelete;

  const _CartServiceRow({
    required this.item,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: HomeColors.borderSoft),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: 52,
              height: 52,
              color: const Color(0xFFF3F6FF),
              child: item.imageAsset == null
                  ? const Icon(
                      Icons.local_laundry_service_outlined,
                      color: HomeColors.primary,
                    )
                  : CatalogImage(
                      url: item.imageAsset,
                      fit: BoxFit.cover,
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.serviceName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                    color: HomeColors.text,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.isPerPiece ? '/pc' : '/kg',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF98A2B3),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onDelete,
            icon: const Icon(
              Icons.delete_outline_rounded,
              color: Color(0xFF98A2B3),
              size: 22,
            ),
          ),
        ],
      ),
    );
  }
}

class _AddressCard extends StatelessWidget {
  final String pickupLine;
  final String deliveryLine;
  final bool isLoading;
  final VoidCallback onChangePickup;
  final VoidCallback onChangeDelivery;

  const _AddressCard({
    required this.pickupLine,
    required this.deliveryLine,
    required this.isLoading,
    required this.onChangePickup,
    required this.onChangeDelivery,
  });

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF22C55E);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: HomeColors.borderSoft),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Column(
              children: [
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: green, width: 4),
                  ),
                ),
                Container(
                  width: 2,
                  height: 46,
                  color: green,
                ),
                const Icon(
                  Icons.location_on_outlined,
                  size: 18,
                  color: Color(0xFF111827),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Pick-up Address',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: HomeColors.text,
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: onChangePickup,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        child: Text(
                          'Change',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: HomeColors.primary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                if (isLoading)
                  const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  Text(
                    pickupLine,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      height: 1.35,
                      color: const Color(0xFF667085),
                    ),
                  ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Delivery Address',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: HomeColors.text,
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: onChangeDelivery,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        child: Text(
                          'Change',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: HomeColors.primary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  deliveryLine,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    height: 1.35,
                    color: const Color(0xFF667085),
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

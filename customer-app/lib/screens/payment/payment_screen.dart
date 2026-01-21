import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../home/widgets/home_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../providers/cart_provider.dart';
import '../../providers/order_provider.dart';
import '../../models/order_record.dart';
import '../../models/cart_item.dart';
import '../../routes/app_routes.dart';
import '../../utils/pricing.dart';
import '../../utils/order_payment_error_messages.dart';
import '../../models/promo_code_model.dart';
import '../../repositories/order_repository.dart';
import '../../repositories/customer_info_repository.dart';
import '../../repositories/payment_repository.dart';
import '../cart/delivery_options_screen.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  PaymentMethod _selectedMethod = PaymentMethod.visa;
  final TextEditingController _promoCodeController = TextEditingController();
  String? _appliedPromoCode;
  int _promoDiscount = 0;

  @override
  void dispose() {
    _promoCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Get delivery option from route arguments
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final deliveryOptionStr = args?['deliveryOption'] as String? ?? 'pickupOnly';
    final deliveryOption = DeliveryOptionType.values.firstWhere(
      (e) => e.name == deliveryOptionStr,
      orElse: () => DeliveryOptionType.pickupOnly,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F7),
      body: SafeArea(
        child: Consumer<CartProvider>(
          builder: (context, cart, _) {
            final perPieceItems = cart.items.where((x) => x.isPerPiece).toList();
            final kgWiseItems = cart.items.where((x) => !x.isPerPiece).toList();
            final hasMixed = perPieceItems.isNotEmpty && kgWiseItems.isNotEmpty;

            // Calculate fees for per-piece items only
            final itemTotal = perPieceItems.fold<int>(0, (sum, x) => sum + x.subtotalInr);
            final handlingFee = (itemTotal * 0.114).round(); // ~11.4% handling fee
            
            // All delivery options are FREE - no charges
            final pickupFeeOriginal = 0; // FREE
            final deliveryFeeAmount = 0; // FREE
            
            int pickupFee = 0; // FREE
            int deliveryFee = 0; // FREE

            final subtotal = itemTotal + handlingFee + pickupFee + deliveryFee;
            // Calculate original total based on delivery option
            final originalPickupFee = (deliveryOption == DeliveryOptionType.pickupOnly ||
                    deliveryOption == DeliveryOptionType.pickupAndDelivery)
                ? pickupFeeOriginal
                : 0;
            final originalDeliveryFee = (deliveryOption == DeliveryOptionType.deliveryOnly ||
                    deliveryOption == DeliveryOptionType.pickupAndDelivery)
                ? deliveryFee
                : 0;
            final originalTotal = itemTotal + handlingFee + originalPickupFee + originalDeliveryFee;
            // Apply promo discount to subtotal
            final finalTotal = (subtotal - _promoDiscount).clamp(0, double.infinity).toInt();
            final savings = originalTotal - finalTotal;

            return Column(
              children: [
                const SizedBox(height: 10),
                _TopBar(
                  onBack: () => Navigator.of(context).maybePop(),
                ),
                const Divider(height: 1, thickness: 1, color: Color(0xFFE5E7EB)),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),
                        _BillSummaryCard(
                          perPieceItems: perPieceItems,
                          itemTotal: itemTotal,
                          handlingFee: handlingFee,
                          pickupFeeOriginal: pickupFeeOriginal,
                          pickupFee: pickupFee,
                          deliveryFee: deliveryFee,
                          subtotal: subtotal,
                          originalTotal: originalTotal,
                          finalTotal: finalTotal,
                          hasKgWise: kgWiseItems.isNotEmpty,
                          deliveryOption: deliveryOption,
                          promoCodeController: _promoCodeController,
                          appliedPromoCode: _appliedPromoCode,
                          promoDiscount: _promoDiscount,
                          onApplyPromo: (code, discount) {
                            setState(() {
                              _appliedPromoCode = code.isEmpty ? null : code;
                              _promoDiscount = discount;
                              if (code.isEmpty) {
                                _promoCodeController.clear();
                              }
                            });
                          },
                        ),
                        const SizedBox(height: 20),
                        _ToPaySection(
                          originalTotal: originalTotal,
                          finalTotal: finalTotal,
                          savings: savings,
                        ),
                        const SizedBox(height: 20),
                        const Divider(height: 1, thickness: 1, color: Color(0xFFE5E7EB)),
                        const SizedBox(height: 20),
                        Text(
                          'Choose Payment Mode',
                          style: AppTextStyles.header(color: const Color(0xFF1B1F2A))
                              .copyWith(fontSize: 18),
                        ),
                        const SizedBox(height: 16),
                        _PaymentMethodCard(
                          method: PaymentMethod.visa,
                          title: 'Visa ending in 2361',
                          subtitle: 'Expiry 03/2028',
                          icon: Icons.credit_card_rounded,
                          isSelected: _selectedMethod == PaymentMethod.visa,
                          onTap: () => setState(() => _selectedMethod = PaymentMethod.visa),
                        ),
                        const SizedBox(height: 12),
                        _PaymentMethodCard(
                          method: PaymentMethod.mastercard,
                          title: 'Master ending in 4227',
                          subtitle: 'Expiry 11/2027',
                          icon: Icons.credit_card_rounded,
                          isSelected: _selectedMethod == PaymentMethod.mastercard,
                          onTap: () => setState(() => _selectedMethod = PaymentMethod.mastercard),
                        ),
                        const SizedBox(height: 12),
                        _PaymentMethodCard(
                          method: PaymentMethod.cod,
                          title: 'COD',
                          subtitle: 'Pay later',
                          icon: Icons.money_rounded,
                          isSelected: _selectedMethod == PaymentMethod.cod,
                          onTap: () => setState(() => _selectedMethod = PaymentMethod.cod),
                        ),
                        const SizedBox(height: 100), // Space for bottom button
                      ],
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 20),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x0A000000),
                        blurRadius: 10,
                        offset: Offset(0, -2),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    top: false,
                    child: _PayButton(
                      amount: finalTotal,
                      onTap: () async {
                        // Create order via backend, then process payment
                        final cart = context.read<CartProvider>();
                        final items = cart.items;
                        if (items.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Cart is empty')),
                          );
                          return;
                        }

                        final cartId = cart.activeCartId;
                        if (cartId == null || cartId.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('No active cart found. Please add items to cart.')),
                          );
                          return;
                        }

                        // Get delivery option from route arguments
                        final paymentArgs = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
                        final deliveryOptionStr = paymentArgs?['deliveryOption'] as String? ?? 'pickupOnly';
                        final deliveryOption = DeliveryOptionType.values.firstWhere(
                          (e) => e.name == deliveryOptionStr,
                          orElse: () => DeliveryOptionType.pickupOnly,
                        );

                        // Get schedule from route arguments
                        final dateLabel = paymentArgs?['dateLabel'] as String? ?? 'Dec 20';
                        final timeLabel = paymentArgs?['timeLabel'] as String? ?? '2:30 PM';

                        // Show loading
                        if (!mounted) return;
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (context) => const Center(
                            child: CircularProgressIndicator(),
                          ),
                        );

                        try {
                          // Fetch addresses
                          final addressRepo = CustomerInfoRepository();
                          final addresses = await addressRepo.getAddresses();

                          if (addresses.isEmpty) {
                            if (mounted) {
                              Navigator.of(context).pop(); // Close loading
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Please add an address before placing an order'),
                                ),
                              );
                            }
                            return;
                          }

                          // Use default address or first address
                          final defaultAddress = addresses.firstWhere(
                            (a) => a.isDefault,
                            orElse: () => addresses.first,
                          );

                          // Determine pickup and delivery addresses based on order type
                          final orderType = deliveryOption.toBackendOrderType();
                          String pickupAddressId;
                          String deliveryAddressId;

                          switch (deliveryOption) {
                            case DeliveryOptionType.pickupOnly:
                              pickupAddressId = defaultAddress.addressId;
                              deliveryAddressId = defaultAddress.addressId; // Not used but required
                              break;
                            case DeliveryOptionType.deliveryOnly:
                              pickupAddressId = defaultAddress.addressId; // Not used but required
                              deliveryAddressId = defaultAddress.addressId;
                              break;
                            case DeliveryOptionType.pickupAndDelivery:
                              pickupAddressId = defaultAddress.addressId;
                              deliveryAddressId = defaultAddress.addressId;
                              break;
                          }

                          // Parse date/time from arguments or use current time + 1 day as default
                          DateTime pickupDateTime;
                          try {
                            // Try to parse from dateLabel and timeLabel
                            // For simplicity, use current time + 1 day as default
                            pickupDateTime = DateTime.now().add(const Duration(days: 1));
                          } catch (_) {
                            pickupDateTime = DateTime.now().add(const Duration(days: 1));
                          }
                          final pickupDateIso = pickupDateTime.toIso8601String();

                          // Create order via backend
                          final orderRepo = OrderRepository();
                          final orderResult = await orderRepo.createOrder(
                            cartId: cartId,
                            pickupAddressId: pickupAddressId,
                            deliveryAddressId: deliveryAddressId,
                            orderType: orderType,
                            pickupDate: pickupDateIso,
                            deliveryDate: null,
                            specialInstructions: null,
                          );

                          if (!mounted) return;
                          Navigator.of(context).pop(); // Close loading

                          // Calculate fees for passing to success screen
                          final totalItems = items.fold<int>(0, (a, x) => a + x.totalQuantity);
                          final totalInr = cart.totalInr;
                          final perPieceItems = items.where((x) => x.isPerPiece).toList();
                          final itemTotal = perPieceItems.fold<int>(0, (sum, x) => sum + x.subtotalInr);
                          final handlingFee = (itemTotal * 0.114).round(); // ~11.4% handling fee
                          final pickupFeeOriginal = 0; // FREE
                          final deliveryFeeAmount = 0; // FREE
                          
                          int pickupFee = 0; // FREE
                          int deliveryFee = 0; // FREE
                          
                          final subtotal = itemTotal + handlingFee + pickupFee + deliveryFee;
                          // Calculate original total based on delivery option
                          final originalPickupFee = (deliveryOption == DeliveryOptionType.pickupOnly ||
                                  deliveryOption == DeliveryOptionType.pickupAndDelivery)
                              ? pickupFeeOriginal
                              : 0;
                          final originalDeliveryFee = (deliveryOption == DeliveryOptionType.deliveryOnly ||
                                  deliveryOption == DeliveryOptionType.pickupAndDelivery)
                              ? deliveryFee
                              : 0;
                          final originalTotal = itemTotal + handlingFee + originalPickupFee + originalDeliveryFee;
                          final finalTotal = subtotal - _promoDiscount;

                          // Process payment via backend
                          final paymentRepo = PaymentRepository();
                          String transactionId;
                          String paymentMethodBackend;
                          String paymentStatus;
                          
                          // Map PaymentMethod enum to backend payment_method string
                          switch (_selectedMethod) {
                            case PaymentMethod.visa:
                            case PaymentMethod.mastercard:
                              paymentMethodBackend = 'card';
                              paymentStatus = 'completed';
                              break;
                            case PaymentMethod.cod:
                              paymentMethodBackend = 'cod';
                              paymentStatus = 'pending'; // COD is paid on delivery
                              break;
                            default:
                              paymentMethodBackend = 'card';
                              paymentStatus = 'completed';
                          }

                          // Generate transaction ID (for card payments, this would come from payment gateway)
                          // For COD, transaction ID is generated when payment is confirmed on delivery
                          final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
                          transactionId = 'QUCVG${timestamp.length > 7 ? timestamp.substring(timestamp.length - 7) : timestamp.padLeft(7, '0')}';

                          // Process payment and update bill
                          final paymentResult = await paymentRepo.processPayment(
                            orderId: orderResult.orderId,
                            paymentMethod: paymentMethodBackend,
                            transactionId: paymentStatus == 'completed' ? transactionId : null, // Only set transaction ID for completed payments
                            paymentStatus: paymentStatus,
                          );

                          // Use transaction ID from payment result if available
                          if (paymentResult.transactionId != null && paymentResult.transactionId!.isNotEmpty) {
                            transactionId = paymentResult.transactionId!;
                          } else if (paymentStatus == 'pending') {
                            // For pending payments (COD), use a placeholder or empty
                            transactionId = 'Pending';
                          }

                          // Create local order record for UI
                          final title = items.length == 1 ? items.first.category : 'Mixed';
                          final placedAt = DateTime.now();
                          final placedDateLabel = _formatDateLabel(placedAt);
                          final placedTimeLabel = _formatTime12h(
                            placedAt.hour > 12 ? placedAt.hour - 12 : (placedAt.hour == 0 ? 12 : placedAt.hour),
                            placedAt.minute,
                            placedAt.hour >= 12 ? 1 : 0,
                          );

                          context.read<OrderProvider>().addOrder(
                                OrderRecord(
                                  id: orderResult.orderId,
                                  title: title,
                                  items: items,
                                  totalItems: totalItems,
                                  totalInr: totalInr,
                                  dateLabel: dateLabel,
                                  timeLabel: timeLabel,
                                  placedAt: placedAt,
                                  placedDateLabel: placedDateLabel,
                                  placedTimeLabel: placedTimeLabel,
                                  status: OrderStatus.inProgress,
                                  backendStatus: 'placed', // Newly created order
                                  paymentMethod: _selectedMethod,
                                ),
                              );

                          cart.clear();

                          if (!mounted) return;
                          
                          // Navigate based on payment method
                          if (_selectedMethod == PaymentMethod.cod) {
                            // For COD, navigate to order successful screen
                            Navigator.of(context).pushNamedAndRemoveUntil(
                              AppRoutes.orderSuccessful,
                              (r) => false,
                              arguments: orderResult.orderId,
                            );
                          } else {
                            // For card payments, navigate to payment successful screen
                            Navigator.of(context).pushNamedAndRemoveUntil(
                              AppRoutes.paymentSuccessful,
                              (r) => false,
                              arguments: {
                                'transactionId': transactionId,
                                'itemTotal': itemTotal,
                                'handlingFee': handlingFee,
                                'pickupFeeOriginal': pickupFeeOriginal,
                                'pickupFee': pickupFee,
                                'deliveryFee': deliveryFee,
                                'originalTotal': originalTotal,
                                'finalTotal': finalTotal,
                                'deliveryOption': deliveryOption.name,
                                'promoCode': _appliedPromoCode,
                                'promoDiscount': _promoDiscount,
                              },
                            );
                          }
                        } catch (e) {
                          if (!mounted) return;
                          Navigator.of(context).pop(); // Close loading
                          final message = OrderPaymentErrorMessages.getOrderErrorMessage(
                            e,
                            operation: 'create order',
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(message),
                              duration: const Duration(seconds: 4),
                            ),
                          );
                        }
                      },
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final VoidCallback onBack;

  const _TopBar({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      child: Row(
        children: [
          InkWell(
            onTap: onBack,
            borderRadius: BorderRadius.circular(999),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 16,
                color: Color(0xFF1B1F2A),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Text(
            'Payment',
            style: AppTextStyles.header(color: const Color(0xFF1B1F2A))
                .copyWith(fontSize: 20),
          ),
        ],
      ),
    );
  }
}

class _BillSummaryCard extends StatelessWidget {
  final List<CartItem> perPieceItems;
  final int itemTotal;
  final int handlingFee;
  final int pickupFeeOriginal;
  final int pickupFee;
  final int deliveryFee;
  final int subtotal;
  final int originalTotal;
  final int finalTotal;
  final bool hasKgWise;
  final DeliveryOptionType deliveryOption;
  final TextEditingController promoCodeController;
  final String? appliedPromoCode;
  final int promoDiscount;
  final Function(String code, int discount) onApplyPromo;

  const _BillSummaryCard({
    required this.perPieceItems,
    required this.itemTotal,
    required this.handlingFee,
    required this.pickupFeeOriginal,
    required this.pickupFee,
    required this.deliveryFee,
    required this.subtotal,
    required this.originalTotal,
    required this.finalTotal,
    required this.hasKgWise,
    required this.deliveryOption,
    required this.promoCodeController,
    required this.appliedPromoCode,
    required this.promoDiscount,
    required this.onApplyPromo,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: HomeColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.receipt_long_rounded,
                  color: HomeColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bill Summary',
                      style: AppTextStyles.header(color: const Color(0xFF1B1F2A))
                          .copyWith(fontSize: 16),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Incl. all taxes & charges',
                      style: AppTextStyles.body(color: const Color(0xFF98A0B5))
                          .copyWith(fontSize: 12),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    Pricing.inr(finalTotal),
                    style: AppTextStyles.header(color: HomeColors.primary)
                        .copyWith(fontSize: 18),
                  ),
                  if (originalTotal > finalTotal) ...[
                    const SizedBox(height: 2),
                    Text(
                      Pricing.inr(originalTotal),
                      style: AppTextStyles.body(color: const Color(0xFF98A0B5))
                          .copyWith(
                        fontSize: 12,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Per-piece item wise pricing (like in cart screen)
          if (perPieceItems.isNotEmpty) ...[
            Text(
              'Per-Piece Items',
              style: AppTextStyles.body(color: const Color(0xFF6B7280))
                  .copyWith(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            for (final item in perPieceItems) ...[
              for (final entry in item.quantities.entries) ...[
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      // e.g. "Saree - 2"
                      Expanded(
                        child: Text(
                          '${entry.key} - ${entry.value}',
                          style: AppTextStyles.body(color: HomeColors.text)
                              .copyWith(fontSize: 12),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        Pricing.inr(
                          (item.unitPricesInr?[entry.key] ?? 0) * entry.value,
                        ),
                        style: AppTextStyles.body(color: HomeColors.text)
                            .copyWith(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ],
            ],
            const SizedBox(height: 12),
          ],
          // Per-Piece Items Total
          if (itemTotal > 0) ...[
            _FeeRow(
              label: 'Per-Piece Items Total',
              amount: itemTotal,
            ),
            const SizedBox(height: 8),
          ],
          // Kg-Wise Items Note
          if (hasKgWise) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.scale_outlined,
                    size: 18,
                    color: HomeColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Kg-Wise Items',
                          style: AppTextStyles.header(color: HomeColors.text)
                              .copyWith(fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Amount will be calculated after supervision',
                          style: AppTextStyles.body(color: HomeColors.muted)
                              .copyWith(fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
          _FeeRow(
            label: 'Handling Fee',
            amount: handlingFee,
          ),
          if (deliveryOption == DeliveryOptionType.pickupOnly ||
              deliveryOption == DeliveryOptionType.pickupAndDelivery) ...[
            const SizedBox(height: 8),
            _FeeRow(
              label: 'Pickup Fee',
              amount: pickupFee,
            ),
          ],
          if (deliveryOption == DeliveryOptionType.deliveryOnly ||
              deliveryOption == DeliveryOptionType.pickupAndDelivery) ...[
            const SizedBox(height: 8),
            _FeeRow(
              label: 'Delivery Fee',
              amount: deliveryFee,
            ),
          ],
          const SizedBox(height: 12),
          // Promo Code Field
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: appliedPromoCode != null && appliedPromoCode!.isNotEmpty
                    ? const Color(0xFF16A34A)
                    : HomeColors.primary,
                width: appliedPromoCode != null && appliedPromoCode!.isNotEmpty ? 2.0 : 1.6,
              ),
              boxShadow: [
                BoxShadow(
                  color: HomeColors.primary.withOpacity(0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Icon
                Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: Icon(
                    Icons.local_offer_outlined,
                    size: 20,
                    color: appliedPromoCode != null && appliedPromoCode!.isNotEmpty
                        ? const Color(0xFF16A34A)
                        : HomeColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                // Text Field
                Expanded(
                  child: TextField(
                    controller: promoCodeController,
                    enabled: appliedPromoCode == null || appliedPromoCode!.isEmpty,
                    readOnly: appliedPromoCode != null && appliedPromoCode!.isNotEmpty,
                    decoration: InputDecoration(
                      hintText: 'Enter promo code here',
                      hintStyle: AppTextStyles.body(color: HomeColors.muted)
                          .copyWith(fontSize: 14),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
                      filled: false,
                      isDense: true,
                    ),
                    style: AppTextStyles.body(color: const Color(0xFF1B1F2A))
                        .copyWith(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                ),
                // Apply Button or Applied Code
                if (appliedPromoCode == null)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Container(
                      decoration: BoxDecoration(
                        color: HomeColors.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            final code = promoCodeController.text.trim();
                            if (code.isEmpty) return;
                            
                            // Validate promo code against available codes from home screen
                            final promoCode = PromoCodeService.validatePromoCode(code);
                            
                            if (promoCode != null) {
                              // Calculate discount based on promo code type
                              final discount = promoCode.calculateDiscount(subtotal);
                              onApplyPromo(promoCode.code, discount);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Invalid promo code. Please check the codes from home screen.'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            child: Text(
                              'Apply',
                              style: AppTextStyles.button(color: Colors.white)
                                  .copyWith(fontSize: 14, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                      ),
                    ),
                  )
                else
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF16A34A).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.check_circle_rounded,
                          size: 16,
                          color: Color(0xFF16A34A),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          appliedPromoCode!,
                          style: AppTextStyles.body(color: const Color(0xFF16A34A))
                              .copyWith(fontSize: 13, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: () {
                            promoCodeController.clear();
                            onApplyPromo('', 0);
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF16A34A).withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close_rounded,
                              size: 14,
                              color: Color(0xFF16A34A),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          if (promoDiscount > 0) ...[
            const SizedBox(height: 8),
            _FeeRow(
              label: 'Promo Discount',
              amount: -promoDiscount,
              isDiscount: true,
            ),
          ],
          if (hasKgWise) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFCD34D)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    size: 18,
                    color: Color(0xFFD97706),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'For kg-wise items, price details will be updated after supervisor checks items',
                      style: AppTextStyles.body(color: const Color(0xFF92400E))
                          .copyWith(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _FeeRow extends StatelessWidget {
  final String label;
  final int amount;
  final int? originalAmount;
  final bool isDiscount;

  const _FeeRow({
    required this.label,
    required this.amount,
    this.originalAmount,
    this.isDiscount = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: AppTextStyles.body(color: const Color(0xFF1B1F2A))
                .copyWith(fontSize: 14),
          ),
        ),
        if (originalAmount != null && originalAmount! > amount) ...[
          Text(
            Pricing.inr(originalAmount!),
            style: AppTextStyles.body(color: const Color(0xFF98A0B5))
                .copyWith(
              fontSize: 12,
              decoration: TextDecoration.lineThrough,
            ),
          ),
          const SizedBox(width: 8),
        ],
        Text(
          isDiscount ? '-${Pricing.inr(amount.abs())}' : Pricing.inr(amount),
          style: AppTextStyles.body(
                  color: isDiscount ? const Color(0xFF16A34A) : HomeColors.primary)
              .copyWith(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _ToPaySection extends StatelessWidget {
  final int originalTotal;
  final int finalTotal;
  final int savings;

  const _ToPaySection({
    required this.originalTotal,
    required this.finalTotal,
    required this.savings,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          'To Pay',
          style: AppTextStyles.header(color: const Color(0xFF1B1F2A))
              .copyWith(fontSize: 18),
        ),
        const Spacer(),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (originalTotal > finalTotal) ...[
              Text(
                Pricing.inr(originalTotal),
                style: AppTextStyles.body(color: const Color(0xFF98A0B5))
                    .copyWith(
                  fontSize: 14,
                  decoration: TextDecoration.lineThrough,
                ),
              ),
              const SizedBox(height: 4),
            ],
            Text(
              Pricing.inr(finalTotal),
              style: AppTextStyles.header(color: HomeColors.primary)
                  .copyWith(fontSize: 20),
            ),
            if (savings > 0) ...[
              const SizedBox(height: 4),
              Text(
                'You saved ${Pricing.inr(savings)}',
                style: AppTextStyles.body(color: const Color(0xFF16A34A))
                    .copyWith(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _PaymentMethodCard extends StatelessWidget {
  final PaymentMethod method;
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _PaymentMethodCard({
    required this.method,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? HomeColors.primary
                : const Color(0xFFE5E7EB),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            if (method == PaymentMethod.visa) ...[
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1F71),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Text(
                    'VISA',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ] else if (method == PaymentMethod.mastercard) ...[
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      left: 0,
                      child: Container(
                        width: 20,
                        height: 40,
                        decoration: const BoxDecoration(
                          color: Color(0xFFEB001B),
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(8),
                            bottomLeft: Radius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 0,
                      child: Container(
                        width: 20,
                        height: 40,
                        decoration: const BoxDecoration(
                          color: Color(0xFFF79E1B),
                          borderRadius: BorderRadius.only(
                            topRight: Radius.circular(8),
                            bottomRight: Radius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F2FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: HomeColors.primary,
                  size: 24,
                ),
              ),
            ],
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.header(color: const Color(0xFF1B1F2A))
                        .copyWith(fontSize: 16),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTextStyles.body(color: const Color(0xFF98A0B5))
                        .copyWith(fontSize: 12),
                  ),
                ],
              ),
            ),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected
                    ? HomeColors.primary
                    : Colors.transparent,
                border: Border.all(
                  color: isSelected
                      ? HomeColors.primary
                      : const Color(0xFFD1D5DB),
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(
                      Icons.check_rounded,
                      size: 16,
                      color: Colors.white,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

String _formatDateLabel(DateTime date) {
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return '${months[date.month - 1]} ${date.day}, ${date.year}';
}

String _formatTime12h(int hour, int minute, int amPm) {
  final h = hour.toString();
  final mm = minute.toString().padLeft(2, '0');
  final suffix = amPm == 0 ? 'AM' : 'PM';
  return '$h:$mm $suffix';
}

class _PayButton extends StatelessWidget {
  final int amount;
  final VoidCallback onTap;

  const _PayButton({
    required this.amount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
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
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Pay ${Pricing.inr(amount)}',
                  style: AppTextStyles.header(color: Colors.white)
                      .copyWith(fontSize: 16),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.arrow_forward_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


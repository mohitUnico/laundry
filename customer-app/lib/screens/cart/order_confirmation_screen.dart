import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../home/widgets/home_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../routes/app_routes.dart';
import '../../providers/cart_provider.dart';
import '../../providers/order_provider.dart';
import '../../models/order_record.dart';
import '../../models/cart_item.dart';
import '../../repositories/order_repository.dart';
import '../../repositories/customer_info_repository.dart';
import '../../utils/cart_error_messages.dart';
import 'delivery_options_screen.dart';
import 'schedule_date_time_screen.dart';

class OrderConfirmationArgs {
  final DeliveryOptionType deliveryOption;
  final String dateLabel;
  final String timeLabel;

  const OrderConfirmationArgs({
    required this.deliveryOption,
    required this.dateLabel,
    required this.timeLabel,
  });
}

class OrderConfirmationScreen extends StatefulWidget {
  const OrderConfirmationScreen({super.key});

  @override
  State<OrderConfirmationScreen> createState() => _OrderConfirmationScreenState();
}

class _OrderConfirmationScreenState extends State<OrderConfirmationScreen> {
  bool _isCreatingOrder = false;

  String _formatDeliveryOption(DeliveryOptionType option) {
    switch (option) {
      case DeliveryOptionType.pickupOnly:
        return 'Pickup Only';
      case DeliveryOptionType.deliveryOnly:
        return 'Delivery Only';
      case DeliveryOptionType.pickupAndDelivery:
        return 'Pickup & Delivery';
    }
  }

  Future<void> _confirmOrder() async {
    final args = ModalRoute.of(context)?.settings.arguments as OrderConfirmationArgs?;
    if (args == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Missing order details')),
      );
      return;
    }

    setState(() => _isCreatingOrder = true);

    try {
      final cart = context.read<CartProvider>();
      final items = cart.items;
      if (items.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cart is empty')),
        );
        setState(() => _isCreatingOrder = false);
        return;
      }

      final cartId = cart.activeCartId;
      if (cartId == null || cartId.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No active cart found. Please add items to cart.')),
        );
        setState(() => _isCreatingOrder = false);
        return;
      }

      // Fetch addresses
      final addressRepo = CustomerInfoRepository();
      final addresses = await addressRepo.getAddresses();

      if (addresses.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please add an address before placing an order'),
          ),
        );
        setState(() => _isCreatingOrder = false);
        return;
      }

      // Use default address or first address
      final defaultAddress = addresses.firstWhere(
        (a) => a.isDefault,
        orElse: () => addresses.first,
      );

      // Determine pickup and delivery addresses based on order type
      final orderType = args.deliveryOption.toBackendOrderType();
      String pickupAddressId;
      String deliveryAddressId;

      switch (args.deliveryOption) {
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

      // Parse date and time from labels
      // The dateLabel is in format "Jan 21" and timeLabel is in format "11:35 AM"
      // We need to reconstruct the full DateTime
      // For simplicity, we'll use the current date and parse the time
      final now = DateTime.now();
      final timeParts = args.timeLabel.split(' ');
      final timeValue = timeParts[0].split(':');
      final hour = int.parse(timeValue[0]);
      final minute = int.parse(timeValue[1]);
      final isPM = timeParts.length > 1 && timeParts[1].toUpperCase() == 'PM';
      
      int hour24;
      if (isPM) {
        hour24 = hour == 12 ? 12 : hour + 12;
      } else {
        hour24 = hour == 12 ? 0 : hour;
      }
      
      // Parse date from "Jan 21" format
      final dateParts = args.dateLabel.split(' ');
      final monthName = dateParts[0];
      final day = int.parse(dateParts[1]);
      
      final monthMap = {
        'Jan': 1, 'Feb': 2, 'Mar': 3, 'Apr': 4, 'May': 5, 'Jun': 6,
        'Jul': 7, 'Aug': 8, 'Sep': 9, 'Oct': 10, 'Nov': 11, 'Dec': 12,
      };
      final month = monthMap[monthName] ?? now.month;
      
      // Use current year, or next year if the date has passed
      int year = now.year;
      final pickupDate = DateTime(year, month, day);
      if (pickupDate.isBefore(DateTime(now.year, now.month, now.day))) {
        year = now.year + 1;
      }
      
      final pickupDateTime = DateTime(year, month, day, hour24, minute);
      final pickupDateIso = pickupDateTime.toUtc().toIso8601String();

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

      // Create local order record for UI
      final totalItems = items.fold<int>(0, (a, x) => a + x.totalQuantity);
      final title = items.length == 1 ? items.first.category : 'Mixed';
      final placedAt = DateTime.now();
      final placedDateLabel =
          '${_monthShort(placedAt.month)} ${placedAt.day}, ${placedAt.year}';
      final placedTimeLabel = _formatTime12h(
        placedAt.hour > 12
            ? placedAt.hour - 12
            : (placedAt.hour == 0 ? 12 : placedAt.hour),
        placedAt.minute,
        placedAt.hour >= 12 ? 1 : 0,
      );

      context.read<OrderProvider>().addOrder(
            OrderRecord(
              id: orderResult.orderId,
              title: title,
              items: items,
              totalItems: totalItems,
              totalInr: 0, // Kg-wise items have no upfront price
              orderType: orderType,
              dateLabel: args.dateLabel,
              timeLabel: args.timeLabel,
              placedAt: placedAt,
              placedDateLabel: placedDateLabel,
              placedTimeLabel: placedTimeLabel,
              status: OrderStatus.inProgress,
              backendStatus: 'placed',
            ),
          );

      await cart.clearAfterOrderPlaced();

      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.orderSuccessful,
        (r) => false,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isCreatingOrder = false);
      final message = CartErrorMessages.getOrderErrorMessage(
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
  }

  String _monthShort(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return months[month - 1];
  }

  String _formatTime12h(int hour, int minute, int amPm) {
    final h = hour.toString().padLeft(2, '0');
    final m = minute.toString().padLeft(2, '0');
    final period = amPm == 0 ? 'AM' : 'PM';
    return '$h:$m $period';
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as OrderConfirmationArgs?;
    final cart = context.watch<CartProvider>();
    final items = cart.items;

    if (args == null) {
      return Scaffold(
        backgroundColor: HomeColors.background,
        appBar: AppBar(
          backgroundColor: HomeColors.background,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: HomeColors.text),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: const Center(
          child: Text('Missing order details'),
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

    // Group kg-wise items by category
    final kgWiseByCategory = <String, List<CartItem>>{};
    for (final item in kgWiseItems) {
      kgWiseByCategory.putIfAbsent(item.category, () => []).add(item);
    }

    return Scaffold(
      backgroundColor: HomeColors.background,
      appBar: AppBar(
        backgroundColor: HomeColors.background,
        elevation: 0,
        centerTitle: true,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
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
                size: 18,
                color: HomeColors.text,
              ),
            ),
          ),
        ),
        title: Text(
          'Order Confirmation',
          style: AppTextStyles.header(color: HomeColors.text),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    // Delivery Option Section
                    _EditableSection(
                      title: 'Delivery Option',
                      value: _formatDeliveryOption(args.deliveryOption),
                      onEdit: () {
                        Navigator.of(context).pushReplacementNamed(
                          AppRoutes.deliveryOptions,
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    // Date & Time Section
                    _EditableSection(
                      title: 'Schedule Date & Time',
                      value: '${args.dateLabel} at ${args.timeLabel}',
                      onEdit: () {
                        Navigator.of(context).pushReplacementNamed(
                          AppRoutes.scheduleDateTime,
                          arguments: ScheduleDateTimeArgs(
                            option: args.deliveryOption,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    // Items Section
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: HomeColors.borderSoft),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Items (${items.length})',
                                  style: AppTextStyles.header(color: HomeColors.text)
                                      .copyWith(fontSize: 16, fontWeight: FontWeight.w600),
                                ),
                              ),
                              InkWell(
                                onTap: () {
                                  Navigator.of(context).pushNamedAndRemoveUntil(
                                    AppRoutes.cart,
                                    (route) => route.settings.name == AppRoutes.shell,
                                  );
                                },
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: HomeColors.primary.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.edit_outlined,
                                        size: 16,
                                        color: HomeColors.primary,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Edit',
                                        style: AppTextStyles.body(color: HomeColors.primary)
                                            .copyWith(fontSize: 12, fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
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
                                        .copyWith(fontSize: 14, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            if (perPieceByCategory.isNotEmpty) ...[
                              for (final categoryEntry in perPieceByCategory.entries) ...[
                                // Category Header
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: HomeColors.primary.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.category_outlined,
                                        size: 16,
                                        color: HomeColors.primary,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        categoryEntry.key,
                                        style: AppTextStyles.header(color: HomeColors.text)
                                            .copyWith(fontSize: 13, fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 10),
                                // Service Items
                                for (final item in categoryEntry.value) ...[
                                  Container(
                                    margin: const EdgeInsets.only(bottom: 10),
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: HomeColors.borderSoft,
                                        width: 1,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: HomeColors.primary.withValues(alpha: 0.03),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Service Name
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(6),
                                              decoration: BoxDecoration(
                                                color: HomeColors.primary.withValues(alpha: 0.1),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Icon(
                                                Icons.local_laundry_service_rounded,
                                                size: 16,
                                                color: HomeColors.primary,
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Text(
                                                item.serviceName.isNotEmpty
                                                    ? item.serviceName
                                                    : 'Service',
                                                style: AppTextStyles.body(color: HomeColors.text)
                                                    .copyWith(
                                                      fontSize: 14,
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        // Cloth Items List
                                        if (item.quantities.isNotEmpty) ...[
                                          Container(
                                            padding: const EdgeInsets.all(10),
                                            decoration: BoxDecoration(
                                              color: HomeColors.background,
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                for (final qtyEntry in item.quantities.entries) ...[
                                                  Padding(
                                                    padding: const EdgeInsets.symmetric(vertical: 4),
                                                    child: Row(
                                                      children: [
                                                        Container(
                                                          width: 6,
                                                          height: 6,
                                                          decoration: BoxDecoration(
                                                            color: HomeColors.primary,
                                                            shape: BoxShape.circle,
                                                          ),
                                                        ),
                                                        const SizedBox(width: 10),
                                                        Expanded(
                                                          child: Text(
                                                            qtyEntry.key,
                                                            style: AppTextStyles.body(
                                                              color: HomeColors.text,
                                                            ).copyWith(fontSize: 13),
                                                          ),
                                                        ),
                                                        Container(
                                                          padding: const EdgeInsets.symmetric(
                                                            horizontal: 8,
                                                            vertical: 4,
                                                          ),
                                                          decoration: BoxDecoration(
                                                            color: HomeColors.primary.withValues(alpha: 0.1),
                                                            borderRadius: BorderRadius.circular(6),
                                                          ),
                                                          child: Text(
                                                            'Qty: ${qtyEntry.value}',
                                                            style: AppTextStyles.body(
                                                              color: HomeColors.primary,
                                                            ).copyWith(
                                                              fontSize: 11,
                                                              fontWeight: FontWeight.w600,
                                                            ),
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
                                    ),
                                  ),
                                ],
                                if (categoryEntry != perPieceByCategory.entries.last ||
                                    kgWiseItems.isNotEmpty)
                                  const SizedBox(height: 16),
                              ],
                            ],
                          ],
                          // Kg-Wise Items Section
                          if (kgWiseItems.isNotEmpty) ...[
                            if (perPieceItems.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              const Divider(height: 1, thickness: 1, color: HomeColors.borderSoft),
                              const SizedBox(height: 12),
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
                                        .copyWith(fontSize: 14, fontWeight: FontWeight.w600),
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
                            const SizedBox(height: 12),
                            if (kgWiseByCategory.isNotEmpty) ...[
                              for (final categoryEntry in kgWiseByCategory.entries) ...[
                                // Category Header
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFEDD5),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.category_outlined,
                                        size: 16,
                                        color: const Color(0xFFF97316),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        categoryEntry.key,
                                        style: AppTextStyles.header(color: HomeColors.text)
                                            .copyWith(fontSize: 13, fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 10),
                                // Service Items
                                for (final item in categoryEntry.value) ...[
                                  Container(
                                    margin: const EdgeInsets.only(bottom: 10),
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: const Color(0xFFFFEDD5),
                                        width: 1.5,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFFFFEDD5).withValues(alpha: 0.3),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Service Name
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(6),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFFFEDD5),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: const Icon(
                                                Icons.scale_outlined,
                                                size: 16,
                                                color: Color(0xFFF97316),
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Text(
                                                item.serviceName.isNotEmpty
                                                    ? item.serviceName
                                                    : 'Service',
                                                style: AppTextStyles.body(color: HomeColors.text)
                                                    .copyWith(
                                                      fontSize: 14,
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        // Cloth Items List
                                        if (item.quantities.isNotEmpty) ...[
                                          Container(
                                            padding: const EdgeInsets.all(10),
                                            decoration: BoxDecoration(
                                              color: HomeColors.background,
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                for (final qtyEntry in item.quantities.entries) ...[
                                                  Padding(
                                                    padding: const EdgeInsets.symmetric(vertical: 4),
                                                    child: Row(
                                                      children: [
                                                        Container(
                                                          width: 6,
                                                          height: 6,
                                                          decoration: const BoxDecoration(
                                                            color: Color(0xFFF97316),
                                                            shape: BoxShape.circle,
                                                          ),
                                                        ),
                                                        const SizedBox(width: 10),
                                                        Expanded(
                                                          child: Text(
                                                            qtyEntry.key,
                                                            style: AppTextStyles.body(
                                                              color: HomeColors.text,
                                                            ).copyWith(fontSize: 13),
                                                          ),
                                                        ),
                                                        Container(
                                                          padding: const EdgeInsets.symmetric(
                                                            horizontal: 8,
                                                            vertical: 4,
                                                          ),
                                                          decoration: BoxDecoration(
                                                            color: const Color(0xFFFFEDD5),
                                                            borderRadius: BorderRadius.circular(6),
                                                          ),
                                                          child: Text(
                                                            'Qty: ${qtyEntry.value}',
                                                            style: AppTextStyles.body(
                                                              color: const Color(0xFFF97316),
                                                            ).copyWith(
                                                              fontSize: 11,
                                                              fontWeight: FontWeight.w600,
                                                            ),
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
                                    ),
                                  ),
                                ],
                                if (categoryEntry != kgWiseByCategory.entries.last)
                                  const SizedBox(height: 16),
                              ],
                            ],
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Info Banner
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFFCD34D)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            size: 20,
                            color: const Color(0xFF92400E),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Total bill will be generated after weighing and updated later',
                              style: AppTextStyles.body(color: const Color(0xFF92400E))
                                  .copyWith(fontSize: 12, height: 1.4),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
            // Confirm Button
            Container(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _isCreatingOrder ? null : _confirmOrder,
                      borderRadius: BorderRadius.circular(18),
                      child: Ink(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          gradient: _isCreatingOrder
                              ? null
                              : const LinearGradient(
                                  colors: [Color(0xFF2437B6), Color(0xFF2C3CA5)],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                          color: _isCreatingOrder ? HomeColors.borderSoft : null,
                        ),
                        child: Center(
                          child: _isCreatingOrder
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : Text(
                                  'Confirm Order',
                                  style: AppTextStyles.header(color: Colors.white)
                                      .copyWith(fontSize: 16, fontWeight: FontWeight.w600),
                                ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditableSection extends StatelessWidget {
  final String title;
  final String value;
  final VoidCallback onEdit;

  const _EditableSection({
    required this.title,
    required this.value,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: HomeColors.borderSoft),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.body(color: HomeColors.muted)
                      .copyWith(fontSize: 12),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: AppTextStyles.header(color: HomeColors.text)
                      .copyWith(fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          InkWell(
            onTap: onEdit,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: HomeColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.edit_outlined,
                    size: 16,
                    color: HomeColors.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Edit',
                    style: AppTextStyles.body(color: HomeColors.primary)
                        .copyWith(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}


import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/cart_item.dart';
import '../../models/order_record.dart';
import '../../routes/route_args.dart';
import '../../utils/pricing.dart';
import '../cart/schedule_bottom_sheet.dart';
import '../home/widgets/home_colors.dart';
import 'order_payment_screen.dart';

class OrderDetailsScreen extends StatefulWidget {
  final OrderRecord order;

  const OrderDetailsScreen({
    super.key,
    required this.order,
  });

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  late String _pickupAddress;
  late String _deliveryAddress;

  static const _defaultInstructions =
      'Handle with care, cold wash only for dark items. Avoid high heat on woollen pieces. Return on hangers if possible.';

  @override
  void initState() {
    super.initState();
    final address = (widget.order.pickupAddress ?? '').trim();
    final line = address.isEmpty ? '123 Main St, Apartment 4B' : address;
    _pickupAddress = line;
    _deliveryAddress = line;
  }

  bool get _cancelled => widget.order.backendStatus.toLowerCase() == 'cancelled';

  /// Door count / bill exist from picked_up onward.
  bool get _pickupDone {
    final s = widget.order.backendStatus.toLowerCase();
    return s != 'placed' && s != 'pickup_assigned' && s != 'cancelled';
  }

  bool get _canPay =>
      widget.order.backendStatus.toLowerCase() == 'out_for_delivery' && !_cancelled;

  bool get _showInvoice =>
      widget.order.status == OrderStatus.delivered && !_cancelled;

  OrderTrackingArgs _trackingArgs() {
    final order = widget.order;
    final instant = order.orderType == 'instant_pickup';
    final scheduled = order.orderType == 'schedule_pickup';
    final at = order.scheduledPickupAt;
    return OrderTrackingArgs(
      orderId: order.id,
      pickupAddress: order.pickupAddress,
      pickupLat: order.pickupLat,
      pickupLng: order.pickupLng,
      backendStatus: order.backendStatus,
      orderType: instant || scheduled ? order.orderType : 'both',
      slotLabel: instant
          ? 'Within 20 mins'
          : (scheduled && at != null && order.timeLabel.isNotEmpty
              ? schedulePickupHeadline(at, order.timeLabel)
              : null),
    );
  }

  void _payBill(_Bill bill) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => OrderPaymentScreen(
          orderId: widget.order.id,
          itemTotal: bill.items,
          handling: bill.handling,
          pickup: bill.pickup,
          delivery: bill.delivery,
          toPay: bill.toPay,
          original: bill.original,
          tracking: _trackingArgs(),
        ),
      ),
    );
  }

  void _openDetailedBill(_Bill bill, List<_CategoryGroup> categories) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _DetailedBillSheet(
        order: widget.order,
        bill: bill,
        categories: categories,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final categories = _pickupDone ? _categoryGroups(order) : const <_CategoryGroup>[];
    final itemCount = categories.fold<int>(
      0,
      (sum, cat) => sum + cat.services.fold<int>(0, (s, svc) => s + svc.count),
    );
    final bill = _pickupDone ? _bill(order, itemCount) : null;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: SizedBox(
                height: 44,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Material(
                        color: Colors.white,
                        shape: const CircleBorder(),
                        elevation: 1,
                        shadowColor: const Color(0x14000000),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: () => Navigator.of(context).maybePop(),
                          child: const SizedBox(
                            width: 36,
                            height: 36,
                            child: Icon(
                              Icons.chevron_left_rounded,
                              color: Color(0xFF1F2430),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Text(
                      'View Details',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1F2430),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                children: [
                  if (!_pickupDone)
                    const _PendingCard(
                      title: 'Items Summary',
                      message: 'Order items will be updated after pickup',
                      icon: Icons.inventory_2_outlined,
                    )
                  else
                    _Card(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Items Summary',
                                  style: _titleStyle(15),
                                ),
                              ),
                              Text(
                                itemCount == 1 ? '1 item' : '$itemCount items',
                                style: _mutedStyle(13),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          for (var i = 0; i < categories.length; i++) ...[
                            if (i > 0) ...[
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 12),
                                child: Divider(
                                  height: 1,
                                  color: Color(0xFFE8ECF4),
                                ),
                              ),
                            ],
                            _CategoryBlock(group: categories[i]),
                          ],
                        ],
                      ),
                    ),
                  const SizedBox(height: 12),
                  _Card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Special washing or care instructions',
                          style: _titleStyle(14),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _instructions(order),
                          style: _mutedStyle(13).copyWith(height: 1.45),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _Card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Pickup & Delivery', style: _titleStyle(15)),
                        const SizedBox(height: 14),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Column(
                                children: [
                                  Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: const Color(0xFF22C55E),
                                        width: 3,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    width: 2,
                                    height: 46,
                                    color: const Color(0xFF22C55E),
                                  ),
                                  const Icon(
                                    Icons.location_on_outlined,
                                    size: 16,
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
                                  Text(
                                    'Pick-up Address',
                                    style: _titleStyle(14),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(_pickupAddress, style: _mutedStyle(12)),
                                  const SizedBox(height: 16),
                                  Text('Delivery Address', style: _titleStyle(14)),
                                  const SizedBox(height: 2),
                                  Text(_deliveryAddress, style: _mutedStyle(12)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (!_pickupDone || bill == null)
                    const _PendingCard(
                      title: 'Bill Summary',
                      message: 'Bill will be generated after pickup is done',
                      icon: Icons.receipt_long_outlined,
                    )
                  else
                    _BriefBillCard(
                      bill: bill,
                      itemCount: itemCount,
                      onTap: () => _openDetailedBill(bill, categories),
                    ),
                  if (_canPay && bill != null) ...[
                    const SizedBox(height: 12),
                    _PrimaryButton(
                      label: 'Pay your bill',
                      onPressed: () => _payBill(bill),
                    ),
                  ],
                ],
              ),
            ),
            if (_showInvoice && bill != null)
              Container(
                color: const Color(0xFFF4F6FB),
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => _InvoiceScreen(
                            order: order,
                            bill: bill,
                            itemCount: itemCount,
                          ),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: HomeColors.primary,
                      side: const BorderSide(color: Color(0xFFE4E7EC)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: const Icon(Icons.file_download_outlined, size: 18),
                    label: Text(
                      'Invoice',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
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

  String _instructions(OrderRecord order) {
    for (final item in order.items) {
      final note = (item.note ?? '').trim();
      if (note.isNotEmpty) return note;
    }
    return _defaultInstructions;
  }
}

class _PendingCard extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;

  const _PendingCard({
    required this.title,
    required this.message,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: _titleStyle(15)),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F9FC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE8ECF4)),
            ),
            child: Column(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFE8ECF4)),
                  ),
                  child: Icon(icon, size: 22, color: HomeColors.primary),
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF667085),
                    height: 1.4,
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

class _BriefBillCard extends StatelessWidget {
  final _Bill bill;
  final int itemCount;
  final VoidCallback onTap;

  const _BriefBillCard({
    required this.bill,
    required this.itemCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: _Card(
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text('Bill Summary', style: _titleStyle(15)),
                            const SizedBox(width: 6),
                            const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              size: 20,
                              color: Color(0xFF98A2B3),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Incl. all taxes & charges · tap for details',
                          style: _mutedStyle(11),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        Pricing.inr(bill.toPay),
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: HomeColors.primary,
                        ),
                      ),
                      Text(
                        Pricing.inr(bill.original),
                        style: _mutedStyle(11).copyWith(
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _BillRow(label: 'Item Total', value: '$itemCount'),
              const SizedBox(height: 10),
              _BillRow(
                label: 'Handling Fee',
                value: Pricing.inr(bill.handling),
              ),
              const SizedBox(height: 10),
              _BillRow(
                label: 'Pickup Fee',
                value: Pricing.inr(bill.pickup),
                trailing: 'Free',
              ),
              const SizedBox(height: 10),
              _BillRow(
                label: 'Delivery Fee',
                value: Pricing.inr(bill.delivery),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Divider(height: 1, color: Color(0xFFE8ECF4)),
              ),
              Row(
                children: [
                  Text('To Pay', style: _titleStyle(15)),
                  const Spacer(),
                  Text(
                    Pricing.inr(bill.toPay),
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: HomeColors.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    Pricing.inr(bill.original),
                    style: _mutedStyle(12).copyWith(
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'You saved ${Pricing.inr(bill.pickup)} 🎉',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF16A34A),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailedBillSheet extends StatelessWidget {
  final OrderRecord order;
  final _Bill bill;
  final List<_CategoryGroup> categories;

  const _DetailedBillSheet({
    required this.order,
    required this.bill,
    required this.categories,
  });

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewPadding.bottom;
    return DraggableScrollableSheet(
      initialChildSize: 0.78,
      minChildSize: 0.45,
      maxChildSize: 0.94,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFFF4F6FB),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFD0D5DD),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 8, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text('Detailed bill', style: _titleStyle(17)),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                      color: const Color(0xFF667085),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + bottom),
                  children: [
                    _Card(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            order.id.startsWith('#') ? order.id : '#${order.id}',
                            style: _titleStyle(14),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Placed ${order.placedDateLabel} · ${order.placedTimeLabel}',
                            style: _mutedStyle(12),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _Card(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Items by category', style: _titleStyle(15)),
                          const SizedBox(height: 14),
                          for (var i = 0; i < categories.length; i++) ...[
                            if (i > 0)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 12),
                                child: Divider(
                                  height: 1,
                                  color: Color(0xFFE8ECF4),
                                ),
                              ),
                            _DetailedCategoryBlock(group: categories[i]),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _Card(
                      child: Column(
                        children: [
                          _BillRow(
                            label: 'Item total',
                            value: Pricing.inr(bill.items),
                          ),
                          const SizedBox(height: 10),
                          _BillRow(
                            label: 'Handling fee',
                            value: Pricing.inr(bill.handling),
                          ),
                          const SizedBox(height: 10),
                          _BillRow(
                            label: 'Pickup fee',
                            value: Pricing.inr(bill.pickup),
                            trailing: 'Free',
                          ),
                          const SizedBox(height: 10),
                          _BillRow(
                            label: 'Delivery fee',
                            value: Pricing.inr(bill.delivery),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Divider(height: 1, color: Color(0xFFE8ECF4)),
                          ),
                          Row(
                            children: [
                              Text('To pay', style: _titleStyle(15)),
                              const Spacer(),
                              Text(
                                Pricing.inr(bill.toPay),
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: HomeColors.primary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Pickup fee waived · you saved ${Pricing.inr(bill.pickup)}',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF16A34A),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _PrimaryButton({
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: HomeColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class _InvoiceScreen extends StatelessWidget {
  final OrderRecord order;
  final _Bill bill;
  final int itemCount;

  const _InvoiceScreen({
    required this.order,
    required this.bill,
    required this.itemCount,
  });

  @override
  Widget build(BuildContext context) {
    final displayId = order.id.startsWith('#') ? order.id : '#${order.id}';
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: SizedBox(
                height: 44,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Material(
                        color: Colors.white,
                        shape: const CircleBorder(),
                        elevation: 1,
                        shadowColor: const Color(0x14000000),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: () => Navigator.of(context).maybePop(),
                          child: const SizedBox(
                            width: 36,
                            height: 36,
                            child: Icon(
                              Icons.chevron_left_rounded,
                              color: Color(0xFF1F2430),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Text(
                      'Invoice',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1F2430),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                children: [
                  _Card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(displayId, style: _titleStyle(16)),
                        const SizedBox(height: 4),
                        Text(
                          'Placed ${order.placedDateLabel} · ${order.placedTimeLabel}',
                          style: _mutedStyle(12),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _Card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Items', style: _titleStyle(15)),
                        const SizedBox(height: 12),
                        if (order.items.isEmpty)
                          Text(
                            '${order.title} · $itemCount items',
                            style: _mutedStyle(13),
                          )
                        else
                          for (var i = 0; i < order.items.length; i++) ...[
                            if (i > 0) const SizedBox(height: 14),
                            _InvoiceService(item: order.items[i]),
                          ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _Card(
                    child: Column(
                      children: [
                        _BillRow(
                          label: 'Item total',
                          value: Pricing.inr(bill.items),
                        ),
                        const SizedBox(height: 10),
                        _BillRow(
                          label: 'Handling fee',
                          value: Pricing.inr(bill.handling),
                        ),
                        const SizedBox(height: 10),
                        _BillRow(
                          label: 'Pickup fee',
                          value: Pricing.inr(bill.pickup),
                          trailing: 'Free',
                        ),
                        const SizedBox(height: 10),
                        _BillRow(
                          label: 'Delivery fee',
                          value: Pricing.inr(bill.delivery),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Divider(height: 1, color: Color(0xFFE8ECF4)),
                        ),
                        Row(
                          children: [
                            Text('To pay', style: _titleStyle(15)),
                            const Spacer(),
                            Text(
                              Pricing.inr(bill.toPay),
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: HomeColors.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Pickup fee waived · you saved ${Pricing.inr(bill.pickup)}',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF16A34A),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InvoiceService extends StatelessWidget {
  final CartItem item;

  const _InvoiceService({required this.item});

  @override
  Widget build(BuildContext context) {
    final name =
        item.serviceName.trim().isEmpty ? item.category : item.serviceName;
    final lines =
        item.quantities.entries.where((entry) => entry.value > 0).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(name, style: _titleStyle(14))),
            Text(
              Pricing.inr(item.subtotalInr),
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1F2430),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        if (lines.isEmpty)
          Text('1 item', style: _mutedStyle(12))
        else
          for (final line in lines)
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(
                _lineText(item, line.key, line.value),
                style: _mutedStyle(12),
              ),
            ),
      ],
    );
  }

  String _lineText(CartItem item, String name, int qty) {
    final price = item.unitPricesInr?[name] ?? 0;
    if (price <= 0) return '$name × $qty';
    final unit = item.isPerPiece
        ? '${Pricing.inr(price)}/Pc'
        : '${Pricing.inr(price)}/kg';
    return '$name × $qty · $unit · ${Pricing.inr(price * qty)}';
  }
}

class _ClothLine {
  final String name;
  final int quantity;
  final int unitPrice;
  final bool isPerPiece;

  const _ClothLine({
    required this.name,
    required this.quantity,
    required this.unitPrice,
    required this.isPerPiece,
  });

  int get lineTotal => unitPrice * quantity;
}

class _ServiceGroup {
  final String name;
  final int count;
  final bool isPerPiece;
  final double? weightKg;
  final int subtotal;
  final List<_ClothLine> lines;

  const _ServiceGroup({
    required this.name,
    required this.count,
    required this.isPerPiece,
    required this.weightKg,
    required this.subtotal,
    required this.lines,
  });
}

class _CategoryGroup {
  final String name;
  final List<_ServiceGroup> services;

  const _CategoryGroup({
    required this.name,
    required this.services,
  });

  int get count =>
      services.fold<int>(0, (sum, service) => sum + service.count);

  int get subtotal =>
      services.fold<int>(0, (sum, service) => sum + service.subtotal);
}

class _Bill {
  final int items;
  final int handling;
  final int pickup;
  final int delivery;
  final int toPay;
  final int original;

  const _Bill({
    required this.items,
    required this.handling,
    required this.pickup,
    required this.delivery,
    required this.toPay,
    required this.original,
  });
}

List<_CategoryGroup> _categoryGroups(OrderRecord order) {
  if (order.items.isEmpty) return const [];

  final byCategory = <String, List<CartItem>>{};
  for (final item in order.items) {
    final key = item.category.trim().isEmpty ? 'Services' : item.category.trim();
    byCategory.putIfAbsent(key, () => []).add(item);
  }

  return [
    for (final entry in byCategory.entries)
      _CategoryGroup(
        name: entry.key,
        services: [
          for (final item in entry.value) _serviceGroupFromItem(item),
        ],
      ),
  ];
}

_ServiceGroup _serviceGroupFromItem(CartItem item) {
  final lines = <_ClothLine>[
    for (final entry in item.quantities.entries)
      if (entry.value > 0)
        _ClothLine(
          name: entry.key,
          quantity: entry.value,
          unitPrice: item.unitPricesInr?[entry.key] ?? 0,
          isPerPiece: item.isPerPiece,
        ),
  ];
  final count = item.isPerPiece
      ? lines.fold<int>(0, (sum, line) => sum + line.quantity)
      : (item.weightKg != null && item.weightKg! > 0 ? 1 : lines.length);
  final name =
      item.serviceName.trim().isEmpty ? item.category : item.serviceName;
  var subtotal = item.subtotalInr;
  if (!item.isPerPiece) {
    final prices = item.unitPricesInr?.values.toList() ?? const <int>[];
    final perKg = prices.isEmpty ? 0 : prices.first;
    final weight = item.weightKg ?? 0;
    subtotal = (perKg * weight).round();
  }
  return _ServiceGroup(
    name: name,
    count: count == 0 ? 1 : count,
    isPerPiece: item.isPerPiece,
    weightKg: item.weightKg,
    subtotal: subtotal,
    lines: lines,
  );
}

_Bill _bill(OrderRecord order, int itemCount) {
  var itemsTotal = order.totalInr;
  if (itemsTotal <= 0) {
    itemsTotal = 0;
    for (final item in order.items) {
      if (item.isPerPiece) {
        itemsTotal += item.subtotalInr;
      } else {
        final prices = item.unitPricesInr?.values.toList() ?? const <int>[];
        final perKg = prices.isEmpty ? 0 : prices.first;
        itemsTotal += (perKg * (item.weightKg ?? 0)).round();
      }
    }
  }
  if (itemsTotal <= 0) itemsTotal = itemCount * 40;
  final handling = (itemsTotal * 8 / 100).round().clamp(10, 9999);
  final pickup = (itemsTotal * 12 / 100).round().clamp(20, 9999);
  final delivery = (itemsTotal * 6 / 100).round().clamp(15, 9999);
  final toPay = itemsTotal + handling + delivery;
  return _Bill(
    items: itemsTotal,
    handling: handling,
    pickup: pickup,
    delivery: delivery,
    toPay: toPay,
    original: toPay + pickup,
  );
}

class _CategoryBlock extends StatelessWidget {
  final _CategoryGroup group;

  const _CategoryBlock({required this.group});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: HomeColors.primary,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                group.name,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: HomeColors.primary,
                  letterSpacing: 0.2,
                ),
              ),
            ),
            Text(
              group.count == 1 ? '1 item' : '${group.count} items',
              style: _mutedStyle(12),
            ),
          ],
        ),
        const SizedBox(height: 12),
        for (var i = 0; i < group.services.length; i++) ...[
          if (i > 0) const SizedBox(height: 14),
          _ServiceBlock(group: group.services[i]),
        ],
      ],
    );
  }
}

class _ServiceBlock extends StatelessWidget {
  final _ServiceGroup group;

  const _ServiceBlock({required this.group});

  @override
  Widget build(BuildContext context) {
    final meta = group.isPerPiece
        ? (group.count == 1 ? '1 item' : '${group.count} items')
        : (group.weightKg != null && group.weightKg! > 0
            ? '${group.weightKg} kg'
            : 'Per kg');
    return Padding(
      padding: const EdgeInsets.only(left: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(group.name, style: _titleStyle(14))),
              if (group.subtotal > 0)
                Text(
                  Pricing.inr(group.subtotal),
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1F2430),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 2),
          Text(meta, style: _mutedStyle(12)),
          if (group.lines.isNotEmpty) ...[
            const SizedBox(height: 8),
            for (final line in group.lines)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${line.name} × ${line.quantity}',
                        style: _mutedStyle(12),
                      ),
                    ),
                    if (line.unitPrice > 0)
                      Text(
                        line.isPerPiece
                            ? '${Pricing.inr(line.unitPrice)}/Pc'
                            : '${Pricing.inr(line.unitPrice)}/kg',
                        style: _mutedStyle(12),
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

class _DetailedCategoryBlock extends StatelessWidget {
  final _CategoryGroup group;

  const _DetailedCategoryBlock({required this.group});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                group.name,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: HomeColors.primary,
                ),
              ),
            ),
            if (group.subtotal > 0)
              Text(
                Pricing.inr(group.subtotal),
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1F2430),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        for (var i = 0; i < group.services.length; i++) ...[
          if (i > 0) const SizedBox(height: 12),
          _DetailedServiceBlock(group: group.services[i]),
        ],
      ],
    );
  }
}

class _DetailedServiceBlock extends StatelessWidget {
  final _ServiceGroup group;

  const _DetailedServiceBlock({required this.group});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(group.name, style: _titleStyle(13))),
              if (group.subtotal > 0)
                Text(
                  Pricing.inr(group.subtotal),
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1F2430),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          if (group.lines.isEmpty)
            Text(
              group.isPerPiece
                  ? '${group.count} item${group.count == 1 ? '' : 's'}'
                  : '${group.weightKg ?? 0} kg',
              style: _mutedStyle(12),
            )
          else
            for (final line in group.lines)
              Padding(
                padding: const EdgeInsets.only(bottom: 4, left: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${line.name} × ${line.quantity}',
                        style: _mutedStyle(12),
                      ),
                    ),
                    Text(
                      line.unitPrice > 0
                          ? '${Pricing.inr(line.unitPrice)} × ${line.quantity} = ${Pricing.inr(line.lineTotal)}'
                          : '× ${line.quantity}',
                      style: _mutedStyle(12),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}

class _BillRow extends StatelessWidget {
  final String label;
  final String value;
  final String? trailing;

  const _BillRow({
    required this.label,
    required this.value,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(label, style: _mutedStyle(13))),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF1F2430),
            decoration: trailing == null ? null : TextDecoration.lineThrough,
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 6),
          Text(
            trailing!,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF16A34A),
            ),
          ),
        ],
      ],
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;

  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8ECF4)),
      ),
      child: child,
    );
  }
}

TextStyle _titleStyle(double size) {
  return GoogleFonts.poppins(
    fontSize: size,
    fontWeight: FontWeight.w700,
    color: const Color(0xFF1F2430),
  );
}

TextStyle _mutedStyle(double size) {
  return GoogleFonts.poppins(
    fontSize: size,
    fontWeight: FontWeight.w400,
    color: const Color(0xFF98A2B3),
  );
}

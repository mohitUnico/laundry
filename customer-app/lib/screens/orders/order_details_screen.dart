import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/cart_item.dart';
import '../../models/order_record.dart';
import '../../routes/app_routes.dart';
import '../../routes/route_args.dart';
import '../../utils/pricing.dart';
import '../home/widgets/home_colors.dart';
import 'order_invoice_screen.dart';
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

  void _trackOrder() {
    final order = widget.order;
    Navigator.of(context).pushNamed(
      AppRoutes.orderTracking,
      arguments: OrderTrackingArgs(
        orderId: order.id,
        pickupAddress: order.pickupAddress,
        pickupLat: order.pickupLat,
        pickupLng: order.pickupLng,
        backendStatus: order.backendStatus,
        orderType: order.orderTypeOrBoth,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final groups = _serviceGroups(order);
    final itemCount = groups.fold<int>(0, (sum, group) => sum + group.count);
    final bill = _bill(order, itemCount);

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
                              '$itemCount items',
                              style: _mutedStyle(13),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        for (var i = 0; i < groups.length; i++) ...[
                          if (i > 0) const SizedBox(height: 16),
                          _ServiceBlock(group: groups[i]),
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
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _trackOrder,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: HomeColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        'Track your order',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _Card(
                    child: Column(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Bill Summary', style: _titleStyle(15)),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Incl. all taxes & charges',
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
                        Text(
                          'You saved ${Pricing.inr(bill.pickup)} 🎉',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF16A34A),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => OrderPaymentScreen(
                              itemTotal: bill.items,
                              handling: bill.handling,
                              pickup: bill.pickup,
                              delivery: bill.delivery,
                              toPay: bill.toPay,
                              original: bill.original,
                              tracking: OrderTrackingArgs(
                                orderId: order.id,
                                pickupAddress: order.pickupAddress,
                                pickupLat: order.pickupLat,
                                pickupLng: order.pickupLng,
                                backendStatus: order.backendStatus,
                                orderType: order.orderTypeOrBoth,
                              ),
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: HomeColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        'Pay Bill',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
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
                        builder: (_) => OrderInvoiceScreen(orderId: order.id),
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

class _ServiceGroup {
  final String name;
  final int count;
  final String rate;
  final List<MapEntry<String, int>> lines;

  const _ServiceGroup({
    required this.name,
    required this.count,
    required this.rate,
    required this.lines,
  });
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

List<_ServiceGroup> _serviceGroups(OrderRecord order) {
  final groups = <_ServiceGroup>[];
  for (final item in order.items) {
    final lines = item.quantities.entries
        .where((entry) => entry.value > 0)
        .toList();
    final count = lines.fold<int>(0, (sum, entry) => sum + entry.value);
    groups.add(
      _ServiceGroup(
        name: item.serviceName.trim().isEmpty ? item.category : item.serviceName,
        count: count == 0 ? 1 : count,
        rate: _rateLabel(item),
        lines: lines,
      ),
    );
  }
  if (groups.isEmpty) {
    groups.add(
      _ServiceGroup(
        name: order.title,
        count: order.totalItems == 0 ? 1 : order.totalItems,
        rate: order.items.any((item) => !item.isPerPiece)
            ? '${Pricing.inr(order.totalInr)}/kg'
            : '${Pricing.inr(order.totalInr)}/Pc',
        lines: const [],
      ),
    );
  }
  return groups;
}

String _rateLabel(CartItem item) {
  final prices = item.unitPricesInr?.values.where((price) => price > 0).toList() ?? [];
  final rate = prices.isEmpty ? 0 : prices.first;
  return item.isPerPiece ? '${Pricing.inr(rate)}/Pc' : '${Pricing.inr(rate)}/kg';
}

_Bill _bill(OrderRecord order, int itemCount) {
  var itemsTotal = order.totalInr;
  if (itemsTotal <= 0) {
    itemsTotal = 0;
    for (final item in order.items) {
      final prices = item.unitPricesInr ?? const <String, int>{};
      for (final entry in item.quantities.entries) {
        itemsTotal += (prices[entry.key] ?? 0) * entry.value;
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

class _ServiceBlock extends StatelessWidget {
  final _ServiceGroup group;

  const _ServiceBlock({required this.group});

  @override
  Widget build(BuildContext context) {
    final countLabel = group.count == 1 ? '1 item' : '${group.count} items';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(group.name, style: _titleStyle(14))),
            Text(
              group.rate,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1F2430),
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(countLabel, style: _mutedStyle(12)),
        const SizedBox(height: 6),
        for (final line in group.lines)
          Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Text(
              '${line.key} * ${line.value}',
              style: _mutedStyle(12),
            ),
          ),
      ],
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

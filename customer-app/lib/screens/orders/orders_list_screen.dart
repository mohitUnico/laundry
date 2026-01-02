import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../home/widgets/home_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../providers/order_provider.dart';
import '../../models/order_record.dart';
import '../../models/cart_item.dart';
import '../../utils/pricing.dart';
import '../../routes/app_routes.dart';
import '../cart/delivery_options_screen.dart';
import '../cart/schedule_date_time_screen.dart';

enum _OrdersFilter { all, active, completed }

class OrdersListScreen extends StatefulWidget {
  final bool showBack;

  const OrdersListScreen({
    super.key,
    this.showBack = false,
  });

  @override
  State<OrdersListScreen> createState() => _OrdersListScreenState();
}

class _OrdersListScreenState extends State<OrdersListScreen> {
  _OrdersFilter _filter = _OrdersFilter.all;

  List<OrderRecord> _filteredOrders(List<OrderRecord> orders) {
    switch (_filter) {
      case _OrdersFilter.all:
        return orders;
      case _OrdersFilter.active:
        return orders
            .where((o) => o.status == OrderStatus.inProgress)
            .toList(growable: false);
      case _OrdersFilter.completed:
        return orders
            .where((o) => o.status == OrderStatus.delivered)
            .toList(growable: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F7),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              _TopBar(
                title: 'Select Location',
                onBack: widget.showBack ? () => Navigator.of(context).maybePop() : null,
              ),
              const SizedBox(height: 14),
              _OrdersFilterRow(
                value: _filter,
                onChanged: (next) => setState(() => _filter = next),
              ),
              const SizedBox(height: 14),
              Consumer<OrderProvider>(
                builder: (context, orders, _) {
                  final active = orders.orders
                      .where((o) => o.status == OrderStatus.inProgress)
                      .toList(growable: false);
                  if (active.isEmpty) return const SizedBox.shrink();
                  final first = active.first;
                  return Column(
                    children: [
                      _UpcomingPickupCard(
                        order: first,
                        timeLabel: '${first.dateLabel} at ${first.timeLabel}',
                      ),
              const SizedBox(height: 12),
                    ],
                  );
                },
              ),
              Expanded(
                child: Consumer<OrderProvider>(
                  builder: (context, orders, _) {
                    final list = _filteredOrders(orders.orders);
                    if (list.isEmpty) {
                      return Center(
                        child: Text(
                          'No orders yet',
                          style: AppTextStyles.body(color: const Color(0xFF98A0B5))
                              .copyWith(fontSize: 13),
                        ),
                      );
                    }

                    return ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 16),
                      itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                        final order = list[index];
                    return _OrderCard(
                      data: order,
                          onViewDetails: () => _showOrderDetailsDialog(context, order),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final String title;
  final VoidCallback? onBack;

  const _TopBar({
    required this.title,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: onBack == null
                ? const SizedBox(width: 38, height: 38)
                : InkWell(
                    onTap: onBack,
                    borderRadius: BorderRadius.circular(999),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(999),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x14000000),
                            blurRadius: 12,
                            offset: Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 16,
                        color: Color(0xFF1B1F2A),
                      ),
                    ),
                  ),
          ),
          Text(
            title,
            style: AppTextStyles.header(color: const Color(0xFF1B1F2A)),
          ),
        ],
      ),
    );
  }
}

class _OrdersFilterRow extends StatelessWidget {
  final _OrdersFilter value;
  final ValueChanged<_OrdersFilter> onChanged;

  const _OrdersFilterRow({
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _FilterPill(
          label: 'All',
          isSelected: value == _OrdersFilter.all,
          onTap: () => onChanged(_OrdersFilter.all),
        ),
        const SizedBox(width: 10),
        _FilterPill(
          label: 'Active',
          isSelected: value == _OrdersFilter.active,
          onTap: () => onChanged(_OrdersFilter.active),
        ),
        const SizedBox(width: 10),
        _FilterPill(
          label: 'Completed',
          isSelected: value == _OrdersFilter.completed,
          onTap: () => onChanged(_OrdersFilter.completed),
        ),
      ],
    );
  }
}

class _FilterPill extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterPill({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isSelected ? const Color(0xFF1F2A5A) : Colors.white;
    final fg = isSelected ? Colors.white : const Color(0xFF98A0B5);
    final border = isSelected ? Colors.transparent : const Color(0xFFE9ECF3);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: border),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: AppTextStyles.header(color: fg),
        ),
      ),
    );
  }
}

class _UpcomingPickupCard extends StatelessWidget {
  final OrderRecord order;
  final String timeLabel;

  const _UpcomingPickupCard({
    required this.order,
    required this.timeLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFEFF1F5)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 26,
            offset: Offset(0, 14),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 22,
                color: Color(0xFF1B1F2A),
              ),
              const SizedBox(width: 8),
              Text(
                'Upcoming Pickup',
                style: AppTextStyles.header(color: const Color(0xFF1B1F2A))
                    .copyWith(fontSize: 18),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 32),
          Text(
            timeLabel,
            style: AppTextStyles.header(color: const Color(0xFF1B1F2A))
                .copyWith(fontSize: 16),
          ),
          const SizedBox(height: 6),
          Text(
            'Pickup scheduled',
            style: AppTextStyles.body(color: const Color(0xFF9AA3B2))
                .copyWith(fontSize: 12),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _PrimaryActionButton(
                  label: 'Change Schedule',
                  onTap: () {
                    Navigator.of(context).pushNamed(
                      AppRoutes.scheduleDateTime,
                      arguments: ScheduleDateTimeArgs(
                        option: DeliveryOptionType.pickupOnly,
                        orderId: order.id,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _SecondaryActionButton(
                  label: 'Cancel',
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        title: Text(
                          'Cancel Order',
                          style: AppTextStyles.header(color: const Color(0xFF1B1F2A)),
                        ),
                        content: Text(
                          'Contact supervisor for further help',
                          style: AppTextStyles.body(color: const Color(0xFF1B1F2A)),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: Text(
                              'OK',
                              style: AppTextStyles.header(color: HomeColors.primary),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PrimaryActionButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _PrimaryActionButton({
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        height: 56,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: HomeColors.primary,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          label,
          style: AppTextStyles.button(color: Colors.white),
        ),
      ),
    );
  }
}

class _SecondaryActionButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _SecondaryActionButton({
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        height: 56,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFFF4F6FA),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFF4F6FA)),
        ),
        child: Text(
          label,
          style: AppTextStyles.button(color: HomeColors.primary),
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final OrderRecord data;
  final VoidCallback onViewDetails;

  const _OrderCard({
    required this.data,
    required this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (data.status) {
      OrderStatus.inProgress => const Color(0xFFF97316),
      OrderStatus.delivered => const Color(0xFF16A34A),
    };

    final statusText = switch (data.status) {
      OrderStatus.inProgress => 'In progress',
      OrderStatus.delivered => 'Delivered',
    };

    final statusIcon = switch (data.status) {
      OrderStatus.inProgress => Icons.access_time_rounded,
      OrderStatus.delivered => Icons.check_circle_rounded,
    };

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE9ECF3)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                data.id,
                style: AppTextStyles.body(color: const Color(0xFF98A0B5))
                    .copyWith(fontSize: 12),
              ),
              const Spacer(),
              Text(
                statusText,
                style: AppTextStyles.header(color: statusColor)
                    .copyWith(fontSize: 14),
              ),
              const SizedBox(width: 6),
              Icon(statusIcon, size: 18, color: statusColor),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.title,
                      style:
                          AppTextStyles.header(color: const Color(0xFF1B1F2A)),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${data.totalItems} items',
                      style: AppTextStyles.body(color: const Color(0xFF98A0B5)),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (data.dateLabel.isNotEmpty && data.timeLabel.isNotEmpty) ...[
                    Text(
                      'Schedule date & time',
                      style: AppTextStyles.body(color: const Color(0xFF98A0B5))
                          .copyWith(fontSize: 10),
                    ),
                    const SizedBox(height: 2),
                  ],
                  Text(
                    data.dateLabel,
                    style: AppTextStyles.body(color: const Color(0xFF1B1F2A)),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    data.timeLabel,
                    style: AppTextStyles.body(color: const Color(0xFF98A0B5)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(
            height: 1,
            thickness: 1,
            color: Color(0xFFE9ECF3),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                Pricing.inr(data.totalInr),
                style: AppTextStyles.header(color: HomeColors.primary)
                    .copyWith(fontSize: 22),
              ),
              const Spacer(),
              InkWell(
                onTap: onViewDetails,
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  height: 54,
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  decoration: BoxDecoration(
                    color: HomeColors.primary,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'View Details',
                    style: AppTextStyles.button(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

void _showOrderDetailsDialog(BuildContext context, OrderRecord order) {
  showDialog(
    context: context,
    builder: (context) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 18),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: HomeColors.borderSoft),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 12, 16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Order Details',
                      style: AppTextStyles.header(color: HomeColors.text)
                          .copyWith(fontSize: 18),
                    ),
                  ),
                  InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    borderRadius: BorderRadius.circular(999),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: HomeColors.background,
                        shape: BoxShape.circle,
                        border: Border.all(color: HomeColors.borderSoft),
                      ),
                      child: Icon(
                        Icons.close_rounded,
                        size: 18,
                        color: HomeColors.text,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: HomeColors.background,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: HomeColors.borderSoft),
                ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Order ID: ${order.id}',
                    style: AppTextStyles.header(color: HomeColors.text)
                        .copyWith(fontSize: 14),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Placed on',
                              style: AppTextStyles.body(color: HomeColors.muted)
                                  .copyWith(fontSize: 10),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              order.placedDateLabel,
                              style: AppTextStyles.body(color: HomeColors.text)
                                  .copyWith(fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Time',
                            style: AppTextStyles.body(color: HomeColors.muted)
                                .copyWith(fontSize: 10),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            order.placedTimeLabel,
                            style: AppTextStyles.body(color: HomeColors.text)
                                .copyWith(fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (order.dateLabel.isNotEmpty && order.timeLabel.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Divider(height: 1, thickness: 1, color: HomeColors.borderSoft),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Schedule date & time',
                                style: AppTextStyles.body(color: HomeColors.muted)
                                    .copyWith(fontSize: 10),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${order.dateLabel} at ${order.timeLabel}',
                                style: AppTextStyles.body(color: HomeColors.text)
                                    .copyWith(fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Text(
                'Items (${order.totalItems})',
                style: AppTextStyles.header(color: HomeColors.text)
                    .copyWith(fontSize: 16),
              ),
            ),
            const SizedBox(height: 12),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: _buildItemsList(order),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Divider(height: 1, thickness: 1, color: HomeColors.borderSoft),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 20),
              child: Row(
                children: [
                  Text(
                    'Total',
                    style: AppTextStyles.header(color: HomeColors.text)
                        .copyWith(fontSize: 18),
                  ),
                  const Spacer(),
                  Text(
                    Pricing.inr(order.totalInr),
                    style: AppTextStyles.header(color: HomeColors.primary)
                        .copyWith(fontSize: 18),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Widget _buildItemsList(OrderRecord order) {
  final byCategory = <String, Map<String, List<CartItem>>>{};
  for (final item in order.items) {
    byCategory.putIfAbsent(item.category, () => {})
        .putIfAbsent(item.serviceName, () => [])
        .add(item);
  }

  final perPieceItems = order.items.where((x) => x.isPerPiece).toList();
  final kgWiseItems = order.items.where((x) => !x.isPerPiece).toList();
  final isCod = order.paymentMethod == PaymentMethod.cod;

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      for (final categoryEntry in byCategory.entries) ...[
        Text(
          categoryEntry.key,
          style: AppTextStyles.header(color: HomeColors.text)
              .copyWith(fontSize: 14),
        ),
        const SizedBox(height: 8),
        for (final serviceEntry in categoryEntry.value.entries) ...[
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Text(
              serviceEntry.key,
              style: AppTextStyles.body(color: HomeColors.muted)
                  .copyWith(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 6),
          // Check if this service has per-piece or kg-wise items
          Builder(
            builder: (context) {
              final hasPerPieceInService = serviceEntry.value.any((item) => item.isPerPiece);
              final hasKgWiseInService = serviceEntry.value.any((item) => !item.isPerPiece);
              
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final item in serviceEntry.value) ...[
                    for (final qtyEntry in item.quantities.entries) ...[
                      Padding(
                        padding: const EdgeInsets.only(left: 24),
                        child: Row(
                          children: [
                            Expanded(
                      child: Text(
                        qtyEntry.key,
                        style: AppTextStyles.body(color: HomeColors.text)
                            .copyWith(fontSize: 12),
                      ),
                    ),
                    Text(
                      'Qty: ${qtyEntry.value}',
                      style: AppTextStyles.body(color: HomeColors.muted)
                          .copyWith(fontSize: 10),
                    ),
                    if (item.isPerPiece && item.unitPricesInr != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        Pricing.inr((item.unitPricesInr![qtyEntry.key] ?? 0) * qtyEntry.value),
                        style: AppTextStyles.body(color: HomeColors.text)
                            .copyWith(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                    ],
                    if (item.note != null && item.note!.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.only(left: 24, top: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                    Icon(
                      Icons.note_outlined,
                      size: 14,
                      color: HomeColors.muted,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        item.note!,
                        style: AppTextStyles.body(color: HomeColors.muted)
                            .copyWith(fontSize: 10),
                      ),
                    ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                    ],
                  ],
                  // Show payment status for this service
                  if (hasPerPieceInService || hasKgWiseInService) ...[
                    const SizedBox(height: 6),
                    Padding(
                      padding: const EdgeInsets.only(left: 24),
                      child: _ItemSetPaymentStatus(
                        isPerPiece: hasPerPieceInService,
                        isKgWise: hasKgWiseInService,
                        isCod: isCod,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ],
              );
            },
          ),
        ],
        const SizedBox(height: 12),
      ],
    ],
  );
}

class _PaymentStatusSection extends StatelessWidget {
  final OrderRecord order;

  const _PaymentStatusSection({required this.order});

  @override
  Widget build(BuildContext context) {
    final perPieceItems = order.items.where((x) => x.isPerPiece).toList();
    final kgWiseItems = order.items.where((x) => !x.isPerPiece).toList();
    final hasPerPiece = perPieceItems.isNotEmpty;
    final hasKgWise = kgWiseItems.isNotEmpty;
    final isCod = order.paymentMethod == PaymentMethod.cod;
    final hasPayment = order.paymentMethod != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Payment Status',
          style: AppTextStyles.header(color: const Color(0xFF1B1F2A))
              .copyWith(fontSize: 14),
        ),
        const SizedBox(height: 8),
        if (hasPerPiece) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isCod
                  ? const Color(0xFFFEF3C7)
                  : const Color(0xFFD1FAE5),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isCod
                    ? const Color(0xFFFCD34D)
                    : const Color(0xFF86EFAC),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isCod ? Icons.pending_outlined : Icons.check_circle_outline,
                  size: 16,
                  color: isCod
                      ? const Color(0xFFD97706)
                      : const Color(0xFF16A34A),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isCod
                        ? 'Bill pending (COD)'
                        : 'Bill paid',
                    style: AppTextStyles.body(
                      color: isCod
                          ? const Color(0xFF92400E)
                          : const Color(0xFF166534),
                    ).copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        if (hasKgWise) ...[
          if (hasPerPiece) const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color(0xFFFCD34D),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.pending_outlined,
                  size: 16,
                  color: Color(0xFFD97706),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Bill pending (kg-wise items)',
                    style: AppTextStyles.body(
                      color: const Color(0xFF92400E),
                    ).copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        if (!hasPayment && !hasKgWise) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color(0xFFFCD34D),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.pending_outlined,
                  size: 16,
                  color: Color(0xFFD97706),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Bill pending',
                    style: AppTextStyles.body(
                      color: const Color(0xFF92400E),
                    ).copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _ItemSetPaymentStatus extends StatelessWidget {
  final bool isPerPiece;
  final bool isKgWise;
  final bool isCod;

  const _ItemSetPaymentStatus({
    required this.isPerPiece,
    required this.isKgWise,
    required this.isCod,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isPerPiece) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isCod
                  ? const Color(0xFFFEF3C7)
                  : const Color(0xFFD1FAE5),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: isCod
                    ? const Color(0xFFFCD34D)
                    : const Color(0xFF86EFAC),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isCod ? Icons.pending_outlined : Icons.check_circle_outline,
                  size: 14,
                  color: isCod
                      ? const Color(0xFFD97706)
                      : const Color(0xFF16A34A),
                ),
                const SizedBox(width: 6),
                Text(
                  isCod ? 'Bill pending (COD)' : 'Bill paid',
                  style: AppTextStyles.body(
                    color: isCod
                        ? const Color(0xFF92400E)
                        : const Color(0xFF166534),
                  ).copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
        if (isKgWise) ...[
          if (isPerPiece) const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: const Color(0xFFFCD34D),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.pending_outlined,
                  size: 14,
                  color: Color(0xFFD97706),
                ),
                const SizedBox(width: 6),
                Text(
                  'Bill pending (kg-wise)',
                  style: AppTextStyles.body(
                    color: const Color(0xFF92400E),
                  ).copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

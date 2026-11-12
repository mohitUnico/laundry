import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../home/widgets/home_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../providers/order_provider.dart';
import '../../services/order_service.dart';
import '../../models/order_record.dart';
import '../../utils/pricing.dart';
import 'order_details_screen.dart';
import 'cancel_order_dialog.dart';
import '../../utils/polling_config.dart';
import '../../routes/app_routes.dart';
import '../../routes/route_args.dart';
import '../cart/schedule_bottom_sheet.dart';

enum _OrdersFilter { all, active, completed }

/// Which card an order gets (orders contract, `card_type`). Cancelled orders
/// are not listed.
enum _CardKind { upcomingPickup, inProgress, delivered, hidden }

_CardKind _cardKindOf(OrderRecord order) {
  switch (order.backendStatus.toLowerCase()) {
    case 'cancelled':
      return _CardKind.hidden;
    case 'placed':
    case 'pickup_assigned':
      return _CardKind.upcomingPickup;
    case 'delivered':
    case 'closed':
      return _CardKind.delivered;
    default:
      return _CardKind.inProgress;
  }
}

bool _isInstantPickup(OrderRecord order) => order.orderType == 'instant_pickup';

/// Soonest pickup first; an instant pickup counts as now.
int _compareUpcoming(OrderRecord a, OrderRecord b) {
  final atA = _isInstantPickup(a) ? DateTime(0) : a.scheduledPickupAt;
  final atB = _isInstantPickup(b) ? DateTime(0) : b.scheduledPickupAt;
  if (atA == null && atB == null) return 0;
  if (atA == null) return 1;
  if (atB == null) return -1;
  return atA.compareTo(atB);
}

List<OrderRecord> _newestFirst(List<OrderRecord> orders, _CardKind kind) {
  return orders.where((o) => _cardKindOf(o) == kind).toList()
    ..sort((a, b) => b.placedAt.compareTo(a.placedAt));
}

class OrdersListScreen extends StatefulWidget {
  final bool showBack;

  const OrdersListScreen({
    super.key,
    this.showBack = false,
  });

  @override
  State<OrdersListScreen> createState() => _OrdersListScreenState();
}

class _OrdersListScreenState extends State<OrdersListScreen>
    with WidgetsBindingObserver {
  _OrdersFilter _filter = _OrdersFilter.all;
  Timer? _ordersPollTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Fetch orders from backend when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchOrders();
      _startPolling();
    });
  }

  void _startPolling() {
    _ordersPollTimer?.cancel();
    _ordersPollTimer = Timer.periodic(PollingConfig.orders, (_) {
      if (mounted) _fetchOrders();
    });
  }

  void _stopPolling() {
    _ordersPollTimer?.cancel();
    _ordersPollTimer = null;
  }

  @override
  void dispose() {
    _stopPolling();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed && mounted) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          _fetchOrders();
          _startPolling();
        }
      });
    } else if (state == AppLifecycleState.paused) {
      _stopPolling();
    }
  }

  Future<void> _fetchOrders() async {
    if (!mounted) return;

    final orderProvider = context.read<OrderProvider>();

    // Prevent rapid successive fetches
    if (orderProvider.isLoading) {
      debugPrint('Order fetch already in progress, skipping...');
      return;
    }

    try {
      // Always fetch the full list once; filtering for Active/Completed is done
      // purely on the frontend using the mapped OrderStatus field.
      await orderProvider.fetchOrders(page: 1, limit: 50, status: 'all');
    } catch (e) {
      // Error is already handled in OrderProvider
      // Orders will be preserved if fetch fails
      debugPrint('Failed to fetch orders: $e');
    }
  }

  void _openScheduleTrack(BuildContext context, OrderRecord order) {
    final instant = order.orderType == 'instant_pickup';
    final scheduled = order.orderType == 'schedule_pickup';
    final at = order.scheduledPickupAt;
    Navigator.of(context).pushNamed(
      AppRoutes.orderTracking,
      arguments: OrderTrackingArgs(
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
      ),
    );
  }

  void _openDetails(BuildContext context, OrderRecord order) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => OrderDetailsScreen(order: order),
      ),
    );
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
                onBack: widget.showBack
                    ? () => Navigator.of(context).maybePop()
                    : null,
              ),
              const SizedBox(height: 14),
              _OrdersFilterRow(
                value: _filter,
                onChanged: (next) {
                  setState(() => _filter = next);
                },
              ),
              const SizedBox(height: 14),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    await _fetchOrders();
                  },
                  child: Consumer<OrderProvider>(
                    builder: (context, orders, _) {
                      // Loading state with full-screen loader
                      if (orders.isLoading && orders.orders.isEmpty) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }

                      // Error state when nothing is cached
                      if (orders.error != null && orders.orders.isEmpty) {
                        return ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.3,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Failed to load orders',
                                    style: AppTextStyles.body(
                                      color: const Color(0xFF98A0B5),
                                    ).copyWith(fontSize: 13),
                                  ),
                                  const SizedBox(height: 8),
                                  TextButton(
                                    onPressed: _fetchOrders,
                                    child: const Text('Retry'),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      }

                      final visible = orders.orders
                          .where((o) => _cardKindOf(o) != _CardKind.hidden)
                          .toList(growable: false);
                      final children = <Widget>[];
                      void addCard(Widget card) {
                        children
                          ..add(card)
                          ..add(const SizedBox(height: 12));
                      }

                      // One card per order, in the order the orders contract fixes:
                      // upcoming pickups, then in progress, then delivered.
                      if (_filter != _OrdersFilter.completed) {
                        final upcoming = [
                          for (final o in visible)
                            if (_cardKindOf(o) == _CardKind.upcomingPickup) o,
                        ]..sort(_compareUpcoming);
                        for (final order in upcoming) {
                          addCard(
                            _UpcomingPickupCard(
                              order: order,
                              onOpen: () => _openDetails(context, order),
                            ),
                          );
                        }
                        for (final order
                            in _newestFirst(visible, _CardKind.inProgress)) {
                          addCard(
                            _OrderCard(
                              data: order,
                              onTrack: () => _openScheduleTrack(context, order),
                              onViewDetails: () => _openDetails(context, order),
                            ),
                          );
                        }
                      }
                      if (_filter != _OrdersFilter.active) {
                        for (final order
                            in _newestFirst(visible, _CardKind.delivered)) {
                          addCard(
                            _OrderCard(
                              data: order,
                              onViewDetails: () => _openDetails(context, order),
                            ),
                          );
                        }
                      }

                      if (children.isEmpty) {
                        // Return scrollable widget for RefreshIndicator to work
                        return ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.only(bottom: 16),
                          children: [
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.3,
                              child: Center(
                                child: Text(
                                  'No orders yet',
                                  style: AppTextStyles.body(
                                    color: const Color(0xFF98A0B5),
                                  ).copyWith(fontSize: 13),
                                ),
                              ),
                            ),
                          ],
                        );
                      }
                      return ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.only(bottom: 16),
                        children: children,
                      );
                    },
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
  final VoidCallback? onOpen;

  const _UpcomingPickupCard({
    required this.order,
    this.onOpen,
  });

  /// pickup_assigned: Change Schedule / Cancel still show, but tapping them
  /// opens a popup instead of the schedule sheet or cancel dialog.
  bool get _pickupStarted =>
      order.backendStatus.toLowerCase() == 'pickup_assigned';

  Future<void> _showPickupStartedPopup(
    BuildContext context, {
    required String title,
    required String message,
  }) {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          title,
          style: AppTextStyles.header(color: const Color(0xFF1B1F2A)),
        ),
        content: Text(
          message,
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
  }

  Future<void> _changeSchedule(BuildContext context) async {
    if (_pickupStarted) {
      await _showPickupStartedPopup(
        context,
        title: 'Schedule cannot be changed',
        message: 'Pickup partner has already started.',
      );
      return;
    }
    final provider = context.read<OrderProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final picked = await showScheduleBottomSheet(
      context,
      forDelivery: false,
      changing: true,
      // An instant pickup has no current schedule to preselect.
      current: _isInstantPickup(order)
          ? null
          : schedulePickFromTime(order.scheduledPickupAt),
    );
    if (picked == null || !context.mounted) return;
    final start = scheduleSlotStart(picked.date, picked.slot);
    final end = scheduleSlotEnd(picked.date, picked.slot);
    final bufferDays = order.isExpress ? 1 : 2;
    final earliest = DateTime(start.year, start.month, start.day)
        .add(Duration(days: bufferDays));
    var deliveryStart = order.scheduledDeliveryAt;
    var moved = false;
    if (deliveryStart != null) {
      final day = DateTime(deliveryStart.year, deliveryStart.month, deliveryStart.day);
      if (day.isBefore(earliest)) {
        deliveryStart = DateTime(
          earliest.year,
          earliest.month,
          earliest.day,
          deliveryStart.hour,
          deliveryStart.minute,
        );
        moved = true;
      }
    }
    final deliveryEnd = deliveryStart?.add(const Duration(minutes: 90));
    try {
      await OrderService().rescheduleOrder(
        orderId: order.id,
        pickupFrom: start.toUtc().toIso8601String(),
        pickupTo: end.toUtc().toIso8601String(),
        deliveryFrom: deliveryStart?.toUtc().toIso8601String(),
        deliveryTo: deliveryEnd?.toUtc().toIso8601String(),
      );
      await provider.fetchOrders(page: 1, limit: 50, status: 'all');
      if (!context.mounted) return;
      if (moved) {
        final updated = provider.orders.where((o) => o.id == order.id).firstOrNull;
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              'Delivery moved to ${updated?.deliveryDateLabel ?? 'a later date'}',
            ),
          ),
        );
      }
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text('$error')));
    }
  }

  Future<void> _cancel(BuildContext context) async {
    if (_pickupStarted) {
      await _showPickupStartedPopup(
        context,
        title: 'Order cannot be cancelled',
        message: 'Pickup partner has already started.',
      );
      return;
    }
    final provider = context.read<OrderProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final id = order.id.trim();
    final code = id.toUpperCase().startsWith('LD') ? '#$id' : '#${order.shortId}';
    final reason = await showCancelOrderDialog(context, orderCode: code);
    if (reason == null || !context.mounted) return;
    try {
      await OrderService().cancelOrder(orderId: order.id, reason: reason);
      await provider.fetchOrders(page: 1, limit: 50, status: 'all');
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text('$error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final instant = _isInstantPickup(order);
    final timeLabel = instant
        ? 'Instant pickup'
        : '${order.dateLabel} at ${order.timeLabel}';
    final subtitle = (order.pickupAddress ?? '').trim().isNotEmpty
        ? order.pickupAddress!.trim()
        : 'Pickup scheduled';
    final displayId =
        order.id.startsWith('LD') ? '#${order.id}' : order.shortId;
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
          if (order.isExpress)
            const Padding(
              padding: EdgeInsets.only(bottom: 10),
              child: Image(
                image: AssetImage('assets/images/express_order_type.png'),
                height: 22,
                fit: BoxFit.contain,
                alignment: Alignment.centerLeft,
              ),
            ),
          InkWell(
            onTap: onOpen,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        displayId,
                        style: AppTextStyles.body(color: HomeColors.primary)
                            .copyWith(
                                fontSize: 13, fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Upcoming Pickup',
                          style: AppTextStyles.header(
                                  color: const Color(0xFF1B1F2A))
                              .copyWith(fontSize: 14),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.location_on_outlined,
                          size: 18,
                          color: Color(0xFF1B1F2A),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  timeLabel,
                  style: AppTextStyles.header(color: const Color(0xFF1B1F2A))
                      .copyWith(fontSize: 16),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: AppTextStyles.body(color: const Color(0xFF9AA3B2))
                      .copyWith(fontSize: 12),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
          Row(
            children: [
              Expanded(
                child: _PrimaryActionButton(
                  label: 'Change Schedule',
                  onTap: () => _changeSchedule(context),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _SecondaryActionButton(
                  label: 'Cancel',
                  onTap: () => _cancel(context),
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
  final VoidCallback? onTrack;

  const _OrderCard({
    required this.data,
    required this.onViewDetails,
    this.onTrack,
  });

  @override
  Widget build(BuildContext context) {
    final cancelled = data.backendStatus.toLowerCase() == 'cancelled';
    final statusColor = cancelled
        ? HomeColors.muted
        : switch (data.status) {
            OrderStatus.inProgress => const Color(0xFFF97316),
            OrderStatus.delivered => const Color(0xFF16A34A),
          };

    final statusText = cancelled
        ? 'Cancelled'
        : switch (data.status) {
            OrderStatus.inProgress => 'In progress',
            OrderStatus.delivered => 'Delivered',
          };

    final statusIcon = cancelled
        ? Icons.cancel_outlined
        : switch (data.status) {
            OrderStatus.inProgress => Icons.access_time_rounded,
            OrderStatus.delivered => Icons.check_circle_rounded,
          };

    final hasKgWiseItems = data.items.any((item) => !item.isPerPiece);
    final hasOnlyPerPiece =
        data.items.isNotEmpty && !hasKgWiseItems;

    final displayId = data.id.startsWith('LD') ? '#${data.id}' : data.shortId;
    final itemLabel = data.itemSummary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onViewDetails,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: double.infinity,
          clipBehavior: Clip.antiAlias,
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (data.isExpress)
                const Padding(
                  padding: EdgeInsets.only(left: 14, top: 10),
                  child: Image(
                    image: AssetImage('assets/images/express_order_type.png'),
                    height: 22,
                    fit: BoxFit.contain,
                    alignment: Alignment.centerLeft,
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            displayId,
                            style: AppTextStyles.body(color: HomeColors.primary)
                                .copyWith(
                                    fontSize: 13, fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              statusText,
                              style: AppTextStyles.header(color: statusColor)
                                  .copyWith(fontSize: 14),
                            ),
                            const SizedBox(width: 6),
                            Icon(statusIcon, size: 18, color: statusColor),
                          ],
                        ),
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
                                style: AppTextStyles.header(
                                    color: const Color(0xFF1B1F2A)),
                              ),
                              if (itemLabel.isNotEmpty) ...[
                                const SizedBox(height: 3),
                                Text(
                                  itemLabel,
                                  style: AppTextStyles.body(
                                      color: const Color(0xFF98A0B5)),
                                ),
                              ],
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (data.dateLabel.isNotEmpty &&
                                data.timeLabel.isNotEmpty) ...[
                              Text(
                                data.dateLabel,
                                style: AppTextStyles.body(
                                        color: const Color(0xFF98A0B5))
                                    .copyWith(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                data.timeLabel,
                                style: AppTextStyles.body(
                                        color: const Color(0xFF98A0B5))
                                    .copyWith(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500),
                              ),
                            ],
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
                        if (hasOnlyPerPiece) ...[
                          Text(
                            Pricing.inr(data.totalInr),
                            style:
                                AppTextStyles.header(color: HomeColors.primary)
                                    .copyWith(fontSize: 22),
                          ),
                        ],
                        const Spacer(),
                        InkWell(
                          onTap: onViewDetails,
                          borderRadius: BorderRadius.circular(18),
                          child: Container(
                            height: 44,
                            padding: const EdgeInsets.symmetric(horizontal: 22),
                            decoration: BoxDecoration(
                              color: HomeColors.primary,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'View Details',
                              style: AppTextStyles.button(color: Colors.white)
                                  .copyWith(fontSize: 13),
                            ),
                          ),
                        ),
                        if (onTrack != null) ...[
                          const SizedBox(width: 10),
                          InkWell(
                            onTap: onTrack,
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: HomeColors.primary, width: 1.4),
                              ),
                              child: const Icon(
                                Icons.location_on_outlined,
                                color: HomeColors.primary,
                                size: 22,
                              ),
                            ),
                          ),
                        ],
                      ],
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
}

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../home/widgets/home_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../providers/order_provider.dart';
import '../../models/order_record.dart';
import '../../utils/pricing.dart';
import 'order_details_screen.dart';
import 'cancel_pickup_screen.dart';
import '../../utils/polling_config.dart';
import '../../routes/app_routes.dart';
import '../../routes/route_args.dart';
import '../cart/schedule_bottom_sheet.dart';

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
      await orderProvider.fetchOrders(page: 1, limit: 10);
    } catch (e) {
      // Error is already handled in OrderProvider
      // Orders will be preserved if fetch fails
      debugPrint('Failed to fetch orders: $e');
    }
  }

  void _openScheduleTrack(BuildContext context, OrderRecord order) {
    final at = order.scheduledPickupAt;
    final slot = order.timeLabel;
    Navigator.of(context).pushNamed(
      AppRoutes.orderTracking,
      arguments: OrderTrackingArgs(
        orderId: order.id,
        pickupAddress: order.pickupAddress,
        pickupLat: order.pickupLat,
        pickupLng: order.pickupLng,
        backendStatus: order.backendStatus,
        orderType: 'schedule_pickup',
        scheduleOnly: true,
        slotLabel: at != null && slot.isNotEmpty
            ? schedulePickupHeadline(at, slot)
            : slot,
      ),
    );
  }

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

                      final children = <Widget>[];

                      // Upcoming pickup/delivery cards are only shown on All/Active tabs
                      if (_filter != _OrdersFilter.completed) {
                        final active = orders.orders
                            .where((o) => o.status == OrderStatus.inProgress)
                            .toList(growable: false);

                        if (active.isNotEmpty) {
                          // Collect all upcoming pickups and deliveries; show all, sorted by schedule.
                          final now = DateTime.now();
                          final List<
                              ({
                                OrderRecord order,
                                String title,
                                String subtitle,
                              })> pickupCards = [];
                          final List<
                              ({
                                OrderRecord order,
                                String title,
                                String subtitle,
                              })> deliveryCards = [];

                          for (final o in active) {
                            final backend = o.backendStatus.toLowerCase();
                            final type = o.orderTypeOrBoth;

                            if (backend != 'placed' &&
                                backend != 'services_completed') {
                              continue;
                            }

                            if (type == 'pickup_only') {
                              if (backend == 'placed') {
                                final at = o.scheduledPickupAt;
                                if (at == null || at.isAfter(now)) {
                                  pickupCards.add((
                                    order: o,
                                    title: 'Upcoming Pickup',
                                    subtitle: (o.pickupAddress ?? '').trim().isNotEmpty
                                    ? o.pickupAddress!.trim()
                                    : 'Pickup scheduled',
                                  ));
                                }
                              }
                            } else if (type == 'drop_only') {
                              if (backend == 'services_completed') {
                                final at =
                                    o.scheduledDeliveryAt ?? o.scheduledPickupAt;
                                if (at == null || at.isAfter(now)) {
                                  deliveryCards.add((
                                    order: o,
                                    title: 'Upcoming Delivery',
                                    subtitle: (o.pickupAddress ?? '').trim().isNotEmpty
                                    ? o.pickupAddress!.trim()
                                    : 'Delivery scheduled',
                                  ));
                                }
                              }
                            } else {
                              // both
                              if (backend == 'placed') {
                                final at = o.scheduledPickupAt;
                                if (at == null || at.isAfter(now)) {
                                  pickupCards.add((
                                    order: o,
                                    title: 'Upcoming Pickup',
                                    subtitle: (o.pickupAddress ?? '').trim().isNotEmpty
                                    ? o.pickupAddress!.trim()
                                    : 'Pickup scheduled',
                                  ));
                                }
                              } else if (backend == 'services_completed') {
                                final at =
                                    o.scheduledDeliveryAt ?? o.scheduledPickupAt;
                                if (at == null || at.isAfter(now)) {
                                  deliveryCards.add((
                                    order: o,
                                    title: 'Upcoming Delivery',
                                    subtitle: (o.pickupAddress ?? '').trim().isNotEmpty
                                    ? o.pickupAddress!.trim()
                                    : 'Delivery scheduled',
                                  ));
                                }
                              }
                            }
                          }

                          // Sort by scheduled time (soonest first; nulls last)
                          pickupCards.sort((a, b) {
                            final atA = a.order.scheduledPickupAt;
                            final atB = b.order.scheduledPickupAt;
                            if (atA == null && atB == null) return 0;
                            if (atA == null) return 1;
                            if (atB == null) return -1;
                            return atA.compareTo(atB);
                          });
                          deliveryCards.sort((a, b) {
                            final atA = a.order.scheduledDeliveryAt ??
                                a.order.scheduledPickupAt;
                            final atB = b.order.scheduledDeliveryAt ??
                                b.order.scheduledPickupAt;
                            if (atA == null && atB == null) return 0;
                            if (atA == null) return 1;
                            if (atB == null) return -1;
                            return atA.compareTo(atB);
                          });

                          for (final entry in pickupCards) {
                            children.add(
                              _UpcomingPickupCard(
                                order: entry.order,
                                timeLabel:
                                    '${entry.order.dateLabel} at ${entry.order.timeLabel}',
                                title: entry.title,
                                subtitle: entry.subtitle,
                                forDelivery: false,
                                onOpen: entry.order.orderType == 'schedule_pickup'
                                    ? () => _openScheduleTrack(context, entry.order)
                                    : null,
                              ),
                            );
                            children.add(const SizedBox(height: 12));
                          }
                          for (final entry in deliveryCards) {
                            children.add(
                              _UpcomingPickupCard(
                                order: entry.order,
                                timeLabel: entry.order.deliveryDateLabel !=
                                            null &&
                                        entry.order.deliveryTimeLabel != null
                                    ? '${entry.order.deliveryDateLabel} at ${entry.order.deliveryTimeLabel}'
                                    : '${entry.order.dateLabel} at ${entry.order.timeLabel}',
                                title: entry.title,
                                subtitle: entry.subtitle,
                                forDelivery: true,
                              ),
                            );
                            children.add(const SizedBox(height: 12));
                          }
                        }
                      }

                      final list = _filteredOrders(orders.orders);

                      if (list.isEmpty && children.isEmpty) {
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

                      // Append the main orders list below the upcoming cards (if any)
                      if (list.isNotEmpty) {
                        if (children.isNotEmpty) {
                          children.add(const SizedBox(height: 8));
                        }

                        for (final order in list) {
                          final schedule = order.orderType == 'schedule_pickup';
                          children.add(
                            _OrderCard(
                              data: order,
                              onOpen: schedule
                                  ? () => _openScheduleTrack(context, order)
                                  : null,
                              onViewDetails: () {
                                if (schedule) {
                                  _openScheduleTrack(context, order);
                                  return;
                                }
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => OrderDetailsScreen(order: order),
                                  ),
                                );
                              },
                            ),
                          );
                          children.add(const SizedBox(height: 12));
                        }
                      }

                      // Fallback to avoid returning an empty list (should not normally happen)
                      if (children.isEmpty) {
                        children.add(
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

DateTime _slotStart(DateTime date, String slot) {
  final start = slot.split('-').first.trim();
  final parts = start.split(':');
  var hour = int.tryParse(parts.first) ?? 17;
  final minute = int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0;
  final period = slot.toUpperCase().contains('PM');
  if (period && hour != 12) hour += 12;
  if (!period && hour == 12) hour = 0;
  return DateTime(date.year, date.month, date.day, hour, minute);
}

class _UpcomingPickupCard extends StatelessWidget {
  final OrderRecord order;
  final String timeLabel;
  final String title;
  final String subtitle;
  final bool forDelivery;
  final VoidCallback? onOpen;

  const _UpcomingPickupCard({
    required this.order,
    required this.timeLabel,
    required this.title,
    required this.subtitle,
    required this.forDelivery,
    this.onOpen,
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
          InkWell(
            onTap: onOpen,
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
                title,
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
                  onTap: () async {
                    final picked = await showScheduleBottomSheet(context);
                    if (picked == null || !context.mounted) return;
                    const months = [
                      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
                    ];
                    context.read<OrderProvider>().updateOrderSchedule(
                          order.id,
                          '${months[picked.date.month - 1]} ${picked.date.day}',
                          picked.slot,
                          forDelivery: forDelivery,
                          at: _slotStart(picked.date, picked.slot),
                        );
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _SecondaryActionButton(
                  label: 'Cancel',
                  onTap: () {
                    if (order.orderType == 'schedule_pickup' &&
                        order.backendStatus.toLowerCase() == 'placed') {
                      final id = order.id.trim();
                      final code = id.toUpperCase().startsWith('LD') ? '#$id' : '#${order.shortId}';
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => CancelPickupScreen(
                            orderId: order.id,
                            orderCode: code,
                          ),
                        ),
                      );
                      return;
                    }
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        title: Text(
                          'Cancel Order',
                          style: AppTextStyles.header(
                              color: const Color(0xFF1B1F2A)),
                        ),
                        content: Text(
                          'Contact supervisor for further help',
                          style: AppTextStyles.body(
                              color: const Color(0xFF1B1F2A)),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: Text(
                              'OK',
                              style: AppTextStyles.header(
                                  color: HomeColors.primary),
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
  final VoidCallback? onOpen;

  const _OrderCard({
    required this.data,
    required this.onViewDetails,
    this.onOpen,
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
    final itemLabel = data.totalItems == 1 ? '1 Item' : '${data.totalItems} Items';

    final card = Container(
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
                      .copyWith(fontSize: 13, fontWeight: FontWeight.w600),
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
                      style:
                          AppTextStyles.header(color: const Color(0xFF1B1F2A)),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      itemLabel,
                      style: AppTextStyles.body(color: const Color(0xFF98A0B5)),
                    ),
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
                      style: AppTextStyles.body(color: const Color(0xFF98A0B5))
                          .copyWith(fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      data.timeLabel,
                      style: AppTextStyles.body(color: const Color(0xFF98A0B5))
                          .copyWith(fontSize: 12, fontWeight: FontWeight.w500),
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
                  style: AppTextStyles.header(color: HomeColors.primary)
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
            ],
          ),
        ],
            ),
          ),
        ],
      ),
    );
    if (onOpen == null) return card;
    return GestureDetector(onTap: onOpen, child: card);
  }
}

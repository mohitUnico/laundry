import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/order_record.dart';
import '../../providers/order_provider.dart';
import '../../routes/app_routes.dart';
import '../../services/customer_info_service.dart';
import '../../theme/app_text_styles.dart';
import '../home/widgets/home_colors.dart';
import '../orders/order_placed_screen.dart';
import 'schedule_bottom_sheet.dart';

class ScheduleConfirmScreen extends StatefulWidget {
  const ScheduleConfirmScreen({super.key});

  @override
  State<ScheduleConfirmScreen> createState() => _ScheduleConfirmScreenState();
}

class _ScheduleConfirmScreenState extends State<ScheduleConfirmScreen> {
  SchedulePick? _pick;
  CustomerAddress? _address;
  bool _loadingAddress = true;
  bool _placing = false;
  bool _instant = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is SchedulePick) {
      _pick ??= args;
    } else if (args == 'instant') {
      _instant = true;
    }
  }

  @override
  void initState() {
    super.initState();
    _loadAddress();
  }

  Future<void> _loadAddress() async {
    try {
      final addresses = await CustomerInfoService().getAddresses();
      if (!mounted) return;
      CustomerAddress? address;
      if (addresses.isNotEmpty) {
        address = addresses.firstWhere(
          (item) => item.isDefault,
          orElse: () => addresses.first,
        );
      }
      setState(() {
        _address = address;
        _loadingAddress = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingAddress = false);
    }
  }

  Future<void> _changeSlot() async {
    final picked = await showScheduleBottomSheet(context);
    if (picked == null || !mounted) return;
    setState(() => _pick = picked);
  }

  Future<void> _editAddress() async {
    await Navigator.of(context).pushNamed(AppRoutes.selectLocation);
    if (!mounted) return;
    setState(() => _loadingAddress = true);
    await _loadAddress();
  }

  Future<void> _place() async {
    if (_placing) return;
    if (!_instant && _pick == null) return;
    final line = (_address?.fullAddress ?? '').trim();
    if (line.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add a pickup address first')),
      );
      return;
    }

    setState(() => _placing = true);
    final now = DateTime.now();
    final orderNumber = (now.millisecondsSinceEpoch % 90000) + 10000;
    final id = 'LD$orderNumber';
    final pick = _pick;
    if (_instant) {
      context.read<OrderProvider>().addOrder(
            OrderRecord(
              id: id,
              title: 'Instant pickup',
              items: const [],
              totalItems: 0,
              totalInr: 0,
              orderType: 'instant_pickup',
              dateLabel: '${_month(now.month)} ${now.day}',
              timeLabel: 'Within 20 mins',
              placedAt: now,
              placedDateLabel: '${_month(now.month)} ${now.day}',
              placedTimeLabel: _clock(now),
              status: OrderStatus.inProgress,
              backendStatus: 'placed',
              pickupAddress: line,
              pickupLat: _address?.latitude,
              pickupLng: _address?.longitude,
              isExpress: true,
            ),
          );
    } else {
      context.read<OrderProvider>().addOrder(
            OrderRecord(
              id: id,
              title: 'Scheduled pickup',
              items: const [],
              totalItems: 0,
              totalInr: 0,
              orderType: 'schedule_pickup',
              dateLabel: '${_month(pick!.date.month)} ${pick.date.day}',
              timeLabel: pick.slot,
              scheduledPickupAt: scheduleSlotStart(pick.date, pick.slot),
              placedAt: now,
              placedDateLabel: '${_month(now.month)} ${now.day}',
              placedTimeLabel: _clock(now),
              status: OrderStatus.inProgress,
              backendStatus: 'placed',
              pickupAddress: line,
              pickupLat: _address?.latitude,
              pickupLng: _address?.longitude,
            ),
          );
    }
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => OrderPlacedScreen(
          slotText: _instant ? 'Within 20 mins' : schedulePickupHeadline(pick!.date, pick.slot),
          orderId: id,
          scheduleOnly: !_instant,
          instant: _instant,
        ),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final pick = _pick;
    final address = _address;
    final addressLine = (address?.fullAddress ?? '').trim();
    return Scaffold(
      backgroundColor: HomeColors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: HomeColors.background,
        foregroundColor: HomeColors.text,
        centerTitle: false,
        title: Text(
          'Review your pickup',
          style: AppTextStyles.header(color: HomeColors.text).copyWith(
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: pick == null && !_instant
          ? Center(
              child: Text(
                'Choose a pickup slot first',
                style: AppTextStyles.body(color: HomeColors.muted).copyWith(fontSize: 14),
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                    children: [
                      _InfoCard(
                        icon: _instant ? Icons.bolt_rounded : Icons.calendar_today_outlined,
                        label: 'PICKUP',
                        title: _instant
                            ? 'Instant pickup'
                            : schedulePickupHeadline(pick!.date, pick.slot),
                        subtitle: _instant ? 'Within 20 mins' : 'Scheduled',
                        action: _instant ? null : 'Change',
                        onAction: _instant ? null : _changeSlot,
                      ),
                      const SizedBox(height: 14),
                      _InfoCard(
                        icon: Icons.location_on_outlined,
                        label: 'ADDRESS',
                        title: _loadingAddress
                            ? 'Loading address'
                            : (addressLine.isEmpty ? 'Add a pickup address' : addressLine),
                        subtitle: address?.addressLabel.trim().isNotEmpty == true
                            ? address!.addressLabel.trim()
                            : null,
                        action: 'Edit',
                        onAction: _editAddress,
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(20, 8, 20, 16 + MediaQuery.paddingOf(context).bottom),
                  child: SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: TextButton(
                      onPressed: _placing ? null : _place,
                      style: TextButton.styleFrom(
                        backgroundColor: HomeColors.primary,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: HomeColors.primary.withValues(alpha: 0.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                      ),
                      child: Text(
                        _placing ? 'Placing order' : 'Confirm',
                        style: AppTextStyles.button(color: Colors.white).copyWith(fontSize: 16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String title;
  final String? subtitle;
  final String? action;
  final VoidCallback? onAction;

  const _InfoCard({
    required this.icon,
    required this.label,
    required this.title,
    required this.subtitle,
    required this.action,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 8, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: HomeColors.borderSoft),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: HomeColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: HomeColors.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.body(color: HomeColors.primary).copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  title,
                  style: AppTextStyles.header(color: HomeColors.text).copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    height: 1.25,
                  ),
                ),
                if (subtitle != null && subtitle!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    style: AppTextStyles.body(color: HomeColors.muted).copyWith(fontSize: 13),
                  ),
                ],
              ],
            ),
          ),
          if (action != null)
            TextButton(
              onPressed: onAction,
              child: Text(
                action!,
                style: AppTextStyles.button(color: HomeColors.primary).copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

String _month(int month) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return months[month - 1];
}

String _clock(DateTime time) {
  final hour12 = time.hour % 12 == 0 ? 12 : time.hour % 12;
  final minute = time.minute.toString().padLeft(2, '0');
  final period = time.hour >= 12 ? 'PM' : 'AM';
  return '$hour12:$minute $period';
}

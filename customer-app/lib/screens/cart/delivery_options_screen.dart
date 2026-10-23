import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../models/cart_item.dart';
import '../../models/order_record.dart';
import '../../providers/cart_provider.dart';
import '../../providers/order_provider.dart';
import '../../routes/app_routes.dart';
import '../../services/customer_info_service.dart';
import '../home/widgets/home_colors.dart';
import '../orders/order_placed_screen.dart';
import 'schedule_bottom_sheet.dart';

enum DeliveryOptionType { pickupOnly, deliveryOnly, pickupAndDelivery }

extension DeliveryOptionTypeExtension on DeliveryOptionType {
  String toBackendOrderType() {
    switch (this) {
      case DeliveryOptionType.pickupOnly:
        return 'pickup_only';
      case DeliveryOptionType.deliveryOnly:
        return 'drop_only';
      case DeliveryOptionType.pickupAndDelivery:
        return 'both';
    }
  }
}

class DeliveryOptionsScreen extends StatefulWidget {
  const DeliveryOptionsScreen({super.key});

  @override
  State<DeliveryOptionsScreen> createState() => _DeliveryOptionsScreenState();
}

class _DeliveryOptionsScreenState extends State<DeliveryOptionsScreen> {
  bool _expressWash = false;
  bool _instantCollect = false;
  bool _expressReturn = false;
  bool _fromHomePickup = false;
  bool _lockInstantCollect = false;
  SchedulePick? _collectPick;
  SchedulePick? _returnPick;
  String? _collectScheduleLabel;
  String? _returnScheduleLabel;
  CustomerAddress? _pickupAddress;
  CustomerAddress? _deliveryAddress;
  bool _loadingAddresses = true;
  final _instructionsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadAddresses();
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args == 'schedule' || args is SchedulePick) {
        setState(() {
          _fromHomePickup = true;
          _lockInstantCollect = false;
          _instantCollect = false;
          if (args is SchedulePick) {
            _collectPick = args;
            _collectScheduleLabel = schedulePickupHeadline(args.date, args.slot);
          }
        });
      } else if (args == 'instant') {
        setState(() {
          _fromHomePickup = true;
          _lockInstantCollect = true;
          _instantCollect = true;
          _collectPick = null;
          _collectScheduleLabel = null;
        });
      }
    });
  }

  @override
  void dispose() {
    _instructionsController.dispose();
    super.dispose();
  }

  String get _earliestLabel {
    final now = DateTime.now();
    var slot = DateTime(now.year, now.month, now.day, now.hour);
    if (now.minute > 0 || now.second > 0) {
      slot = slot.add(const Duration(hours: 1));
    }
    if (slot.hour >= 21) {
      slot = DateTime(now.year, now.month, now.day + 1, 9);
    }
    final isToday = slot.year == now.year && slot.month == now.month && slot.day == now.day;
    final hour12 = slot.hour % 12 == 0 ? 12 : slot.hour % 12;
    final period = slot.hour >= 12 ? 'PM' : 'AM';
    final day = isToday ? 'Today' : 'Tomorrow';
    return 'Earliest - $day $hour12:00 $period';
  }

  Future<void> _placeOrder() async {
    if (_fromHomePickup) {
      await _placeHomePickup();
      return;
    }
    final cart = context.read<CartProvider>();
    final items = List<CartItem>.from(cart.items);
    final now = DateTime.now();
    final schedule = _splitSchedule(_collectScheduleLabel);
    final savedLine = await _defaultAddressLine();
    if (!mounted) return;
    final chosenLine = (_pickupAddress?.fullAddress ?? '').trim();
    final address = chosenLine.isEmpty ? savedLine : chosenLine;

    final serviceNames = items
        .map((item) => item.serviceName.trim())
        .where((name) => name.isNotEmpty)
        .toSet();
    final title = serviceNames.length == 1
        ? serviceNames.first
        : (serviceNames.isEmpty ? 'Laundry' : 'Mixed');
    final totalItems = items.fold<int>(0, (sum, item) {
      final qty = item.totalQuantity;
      return sum + (qty > 0 ? qty : 1);
    });
    final totalInr = items.fold<int>(0, (sum, item) => sum + item.subtotalInr);
    final orderNumber = (now.millisecondsSinceEpoch % 90000) + 10000;

    context.read<OrderProvider>().addOrder(
          OrderRecord(
            id: 'LD$orderNumber',
            title: title,
            items: items,
            totalItems: totalItems,
            totalInr: totalInr,
            orderType: 'both',
            dateLabel: schedule.dateLabel,
            timeLabel: schedule.timeLabel,
            scheduledPickupAt: schedule.at,
            placedAt: now,
            placedDateLabel: '${now.day} ${_monthShort(now.month)}',
            placedTimeLabel: _clockLabel(now),
            status: OrderStatus.inProgress,
            backendStatus: 'placed',
            pickupAddress: address,
            isExpress: _expressWash,
          ),
        );
    cart.clear();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const OrderPlacedScreen()),
      (route) => false,
    );
  }

  Future<void> _placeHomePickup() async {
    final now = DateTime.now();
    final saved = await _savedAddress();
    if (!mounted) return;
    final instant = _instantCollect || _lockInstantCollect;
    final pick = _collectPick;
    if (!instant && pick == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choose a pickup time first')),
      );
      return;
    }
    final returnPick = _returnPick;
    final orderNumber = (now.millisecondsSinceEpoch % 90000) + 10000;
    final id = 'LD$orderNumber';
    final chosen = _pickupAddress ?? saved;
    final line = (chosen?.fullAddress ?? '').trim();
    context.read<OrderProvider>().addOrder(
          OrderRecord(
            id: id,
            title: instant ? 'Instant pickup' : 'Scheduled pickup',
            items: const [],
            totalItems: 0,
            totalInr: 0,
            orderType: instant ? 'instant_pickup' : 'schedule_pickup',
            dateLabel: instant
                ? '${now.day} ${_monthShort(now.month)}'
                : '${pick!.date.day} ${_monthShort(pick.date.month)}',
            timeLabel: instant ? 'Within 20 mins' : pick!.slot,
            scheduledPickupAt: instant ? null : scheduleSlotStart(pick!.date, pick.slot),
            deliveryDateLabel: returnPick == null
                ? null
                : '${returnPick.date.day} ${_monthShort(returnPick.date.month)}',
            deliveryTimeLabel: returnPick != null
                ? returnPick.slot
                : (_expressReturn ? 'Express' : null),
            scheduledDeliveryAt:
                returnPick == null ? null : scheduleSlotStart(returnPick.date, returnPick.slot),
            placedAt: now,
            placedDateLabel: '${now.day} ${_monthShort(now.month)}',
            placedTimeLabel: _clockLabel(now),
            status: OrderStatus.inProgress,
            backendStatus: 'placed',
            pickupAddress: line.isEmpty ? null : line,
            pickupLat: chosen?.latitude,
            pickupLng: chosen?.longitude,
            isExpress: instant || _expressWash,
          ),
        );
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => OrderPlacedScreen(
          orderId: id,
          slotText: instant
              ? 'Within 20 mins'
              : schedulePickupHeadline(pick!.date, pick.slot),
          scheduleOnly: !instant,
          instant: instant,
        ),
      ),
      (route) => false,
    );
  }

  Future<void> _loadAddresses() async {
    final saved = await _savedAddress();
    if (!mounted) return;
    setState(() {
      _pickupAddress ??= saved;
      _deliveryAddress ??= saved;
      _loadingAddresses = false;
    });
  }

  Future<void> _changeAddress({required bool pickup}) async {
    final result = await Navigator.of(context).pushNamed(AppRoutes.selectLocation);
    if (!mounted || result is! CustomerAddress) return;
    setState(() {
      if (pickup) {
        _pickupAddress = result;
      } else {
        _deliveryAddress = result;
      }
    });
  }

  String _addressLine(CustomerAddress? address) {
    if (_loadingAddresses) return 'Loading address';
    final line = (address?.fullAddress ?? '').trim();
    if (line.isNotEmpty) return line;
    final label = (address?.addressLabel ?? '').trim();
    if (label.isNotEmpty) return label;
    return 'Add an address';
  }

  Future<CustomerAddress?> _savedAddress() async {
    try {
      final addresses = await CustomerInfoService().getAddresses();
      if (addresses.isEmpty) return null;
      return addresses.firstWhere(
        (item) => item.isDefault,
        orElse: () => addresses.first,
      );
    } catch (_) {
      return null;
    }
  }

  Future<String?> _defaultAddressLine() async {
    try {
      final addresses = await CustomerInfoService().getAddresses();
      if (addresses.isEmpty) return null;
      final address = addresses.firstWhere(
        (item) => item.isDefault,
        orElse: () => addresses.first,
      );
      final line = address.fullAddress.trim();
      return line.isEmpty ? address.addressLabel.trim() : line;
    } catch (_) {
      return null;
    }
  }

  ({String dateLabel, String timeLabel, DateTime at}) _splitSchedule(String? label) {
    final now = DateTime.now();
    if (label != null && label.contains(',')) {
      final parts = label.split(',');
      final dateLabel = parts.first.trim();
      final timeLabel = parts.sublist(1).join(',').trim();
      return (
        dateLabel: dateLabel,
        timeLabel: timeLabel,
        at: now.add(const Duration(hours: 2)),
      );
    }
    var slot = DateTime(now.year, now.month, now.day, now.hour);
    if (now.minute > 0 || now.second > 0) {
      slot = slot.add(const Duration(hours: 1));
    }
    if (slot.hour >= 21) {
      slot = DateTime(now.year, now.month, now.day + 1, 9);
    }
    final isToday = slot.year == now.year && slot.month == now.month && slot.day == now.day;
    return (
      dateLabel: isToday ? 'Today' : 'Tomorrow',
      timeLabel: _clockLabel(slot),
      at: slot,
    );
  }

  String _clockLabel(DateTime time) {
    final hour12 = time.hour % 12 == 0 ? 12 : time.hour % 12;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour12:$minute $period';
  }

  Future<void> _openSchedule({required bool forReturn}) async {
    if (!forReturn && _lockInstantCollect) return;
    final picked = await showScheduleBottomSheet(context);
    if (picked == null || !mounted) return;
    final label = schedulePickupHeadline(picked.date, picked.slot);
    setState(() {
      if (forReturn) {
        _returnPick = picked;
        _returnScheduleLabel = label;
        _expressReturn = false;
      } else {
        _collectPick = picked;
        _collectScheduleLabel = label;
        _instantCollect = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HomeColors.background,
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
                      child: _CircleBackButton(
                        onTap: () => Navigator.of(context).maybePop(),
                      ),
                    ),
                    Text(
                      'Delivery Options',
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
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                children: [
                  _ExpressWashCard(
                    selected: _expressWash,
                    onTap: () => setState(() => _expressWash = !_expressWash),
                  ),
                  const SizedBox(height: 22),
                  const _SectionTitle('When should we collect'),
                  const SizedBox(height: 10),
                  _TimingCard(
                    children: [
                      _TimingRow(
                        icon: Icons.bolt_rounded,
                        iconColor: const Color(0xFFF5B400),
                        title: 'Instant',
                        subtitle: _lockInstantCollect ? 'Within 20 mins' : _earliestLabel,
                        selected: _instantCollect,
                        onTap: () => setState(() {
                          _instantCollect = true;
                          _collectScheduleLabel = null;
                          _collectPick = null;
                        }),
                      ),
                      if (!_lockInstantCollect) ...[
                        const _CardDivider(),
                        _TimingRow(
                          icon: Icons.calendar_today_outlined,
                          iconColor: const Color(0xFF667085),
                          title: 'Schedule',
                          subtitle: _collectScheduleLabel ?? 'Choose your pickup date and time',
                          selected: !_instantCollect && _collectPick != null,
                          showChevron: true,
                          onTap: () => _openSchedule(forReturn: false),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 22),
                  const _SectionTitle('And when should we bring it back?'),
                  const SizedBox(height: 10),
                  _TimingCard(
                    children: [
                      _TimingRow(
                        icon: Icons.bolt_rounded,
                        iconColor: const Color(0xFFF5B400),
                        title: 'Express',
                        subtitle: _earliestLabel,
                        selected: _expressReturn,
                        onTap: () => setState(() {
                          _expressReturn = true;
                          _returnScheduleLabel = null;
                        }),
                      ),
                      const _CardDivider(),
                      _TimingRow(
                        icon: Icons.calendar_today_outlined,
                        iconColor: const Color(0xFF667085),
                        title: 'Schedule',
                        subtitle: _returnScheduleLabel ?? 'Choose your pickup date and time',
                        showChevron: true,
                        onTap: () => _openSchedule(forReturn: true),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  const _SectionTitle('Address'),
                  const SizedBox(height: 10),
                  _AddressCard(
                    pickup: _addressLine(_pickupAddress),
                    delivery: _addressLine(_deliveryAddress),
                    onChangePickup: () => _changeAddress(pickup: true),
                    onChangeDelivery: () => _changeAddress(pickup: false),
                  ),
                  const SizedBox(height: 22),
                  const _SectionTitle('Any special washing or care instructions?'),
                  const SizedBox(height: 10),
                  _InstructionsCard(controller: _instructionsController),
                  const SizedBox(height: 22),
                  const _SectionTitle('Charges'),
                  const SizedBox(height: 10),
                  const _ChargesCard(),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: _SlideToOrderButton(onCompleted: () => _placeOrder()),
            ),
          ],
        ),
      ),
    );
  }
}

class _CircleBackButton extends StatelessWidget {
  final VoidCallback onTap;

  const _CircleBackButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 2,
      shadowColor: const Color(0x14000000),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: const SizedBox(
          width: 36,
          height: 36,
          child: Icon(
            Icons.chevron_left_rounded,
            size: 26,
            color: Color(0xFF1F2430),
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.poppins(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: const Color(0xFF1F2430),
      ),
    );
  }
}

class _AddressCard extends StatelessWidget {
  final String pickup;
  final String delivery;
  final VoidCallback onChangePickup;
  final VoidCallback onChangeDelivery;

  const _AddressCard({
    required this.pickup,
    required this.delivery,
    required this.onChangePickup,
    required this.onChangeDelivery,
  });

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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              const _AddressPin(),
              Container(
                width: 2,
                height: 52,
                color: const Color(0xFF22C55E),
              ),
              const _AddressPin(),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _AddressLine(
                  title: 'Pick-up Address',
                  address: pickup,
                  onChange: onChangePickup,
                ),
                const SizedBox(height: 18),
                _AddressLine(
                  title: 'Delivery Address',
                  address: delivery,
                  onChange: onChangeDelivery,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AddressPin extends StatelessWidget {
  const _AddressPin();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: HomeColors.primary.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.location_on_outlined, size: 16, color: HomeColors.primary),
    );
  }
}

class _AddressLine extends StatelessWidget {
  final String title;
  final String address;
  final VoidCallback onChange;

  const _AddressLine({
    required this.title,
    required this.address,
    required this.onChange,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: HomeColors.text,
                ),
              ),
            ),
            TextButton(
              onPressed: onChange,
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 28),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'Change',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: HomeColors.primary,
                ),
              ),
            ),
          ],
        ),
        Text(
          address,
          style: GoogleFonts.poppins(
            fontSize: 12,
            height: 1.4,
            color: HomeColors.muted,
          ),
        ),
      ],
    );
  }
}

class _ExpressWashCard extends StatelessWidget {
  final bool selected;
  final VoidCallback onTap;

  const _ExpressWashCard({
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          height: 78,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFF3C6C6)),
          ),
          child: Row(
            children: [
              const SizedBox(width: 14),
              _RadioDot(selected: selected),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Express Wash',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1F2430),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Get your laundry done in 8 hrs',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF98A2B3),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 108,
                height: 78,
                child: Image.asset(
                  'assets/images/delivery_options/express_type_avatar.png',
                  fit: BoxFit.contain,
                  alignment: Alignment.centerRight,
                ),
              ),
              const SizedBox(width: 6),
            ],
          ),
        ),
      ),
    );
  }
}

class _TimingCard extends StatelessWidget {
  final List<Widget> children;

  const _TimingCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8ECF4)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }
}

class _CardDivider extends StatelessWidget {
  const _CardDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(height: 1, thickness: 1, color: Color(0xFFF2F4F7));
  }
}

class _TimingRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool selected;
  final bool showChevron;
  final VoidCallback onTap;

  const _TimingRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.selected = false,
    this.showChevron = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFF4F6FB),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1F2430),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF98A2B3),
                    ),
                  ),
                ],
              ),
            ),
            if (showChevron)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (selected) ...[
                    const _RadioDot(selected: true, size: 20),
                    const SizedBox(width: 8),
                  ],
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: Color(0xFF98A2B3),
                    size: 22,
                  ),
                ],
              )
            else
              _RadioDot(selected: selected, size: 20),
          ],
        ),
      ),
    );
  }
}

class _RadioDot extends StatelessWidget {
  final bool selected;
  final double size;

  const _RadioDot({
    required this.selected,
    this.size = 18,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? HomeColors.primary : const Color(0xFFD0D5DD),
          width: 1.6,
        ),
      ),
      child: selected
          ? Center(
              child: Container(
                width: size * 0.45,
                height: size * 0.45,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: HomeColors.primary,
                ),
              ),
            )
          : null,
    );
  }
}

class _InstructionsCard extends StatefulWidget {
  final TextEditingController controller;

  const _InstructionsCard({required this.controller});

  @override
  State<_InstructionsCard> createState() => _InstructionsCardState();
}

class _InstructionsCardState extends State<_InstructionsCard> {
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _openKeyboard() {
    _focusNode.requestFocus();
    SystemChannels.textInput.invokeMethod<void>('TextInput.show');
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _openKeyboard,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE8ECF4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Theme(
              data: Theme.of(context).copyWith(
                inputDecorationTheme: const InputDecorationTheme(
                  filled: false,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  focusedErrorBorder: InputBorder.none,
                ),
                textSelectionTheme: const TextSelectionThemeData(
                  cursorColor: Color(0xFF98A2B3),
                  selectionColor: Color(0x3398A2B3),
                  selectionHandleColor: Color(0xFF98A2B3),
                ),
              ),
              child: TextField(
                focusNode: _focusNode,
                controller: widget.controller,
                maxLength: 500,
                minLines: 2,
                maxLines: 4,
                cursorColor: const Color(0xFF98A2B3),
                cursorWidth: 1.5,
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.newline,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                  color: const Color(0xFF1F2430),
                ),
                decoration: InputDecoration(
                  filled: false,
                  counterText: '',
                  contentPadding: EdgeInsets.zero,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  focusedErrorBorder: InputBorder.none,
                  hintText: 'Anything that we need to know',
                  hintStyle: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                    color: const Color(0xFF1F2430),
                  ),
                ),
              ),
            ),
            ListenableBuilder(
              listenable: widget.controller,
              builder: (context, _) {
                final count = widget.controller.text.characters.length;
                final isEmpty = widget.controller.text.isEmpty;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isEmpty) ...[
                      Text(
                        'We will notify the hub team',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: const Color(0xFF98A2B3),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ] else
                      const SizedBox(height: 12),
                    const _DottedLine(),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        '$count/500',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: const Color(0xFF98A2B3),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _DottedLine extends StatelessWidget {
  const _DottedLine();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const dashWidth = 3.0;
        const gap = 3.0;
        final count = (constraints.maxWidth / (dashWidth + gap)).floor();
        return Row(
          children: [
            for (var i = 0; i < count; i++)
              Container(
                width: dashWidth,
                height: 1,
                margin: const EdgeInsets.only(right: gap),
                color: const Color(0xFFD0D5DD),
              ),
          ],
        );
      },
    );
  }
}

class _ChargesCard extends StatelessWidget {
  const _ChargesCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8ECF4)),
      ),
      child: const Column(
        children: [
          _ChargeRow(title: 'Delivery Charges', value: 'Free'),
          _CardDivider(),
          _ChargeRow(title: 'Handling Charges', value: 'Free'),
          _CardDivider(),
          _ChargeRow(
            title: 'Laundry Charges',
            subtitle: 'Bill generated after weighing and counting at our hub',
          ),
        ],
      ),
    );
  }
}

class _ChargeRow extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? value;

  const _ChargeRow({
    required this.title,
    this.subtitle,
    this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1F2430),
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      height: 1.3,
                      color: const Color(0xFF98A2B3),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (value != null)
            Text(
              value!,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF16A34A),
              ),
            ),
        ],
      ),
    );
  }
}

class _SlideToOrderButton extends StatefulWidget {
  final VoidCallback onCompleted;

  const _SlideToOrderButton({required this.onCompleted});

  @override
  State<_SlideToOrderButton> createState() => _SlideToOrderButtonState();
}

class _SlideToOrderButtonState extends State<_SlideToOrderButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _progress;
  bool _completed = false;

  @override
  void initState() {
    super.initState();
    _progress = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
      lowerBound: 0,
      upperBound: 1,
    )..addListener(() {
        if (mounted) setState(() {});
      });
  }

  @override
  void dispose() {
    _progress.dispose();
    super.dispose();
  }

  Future<void> _settle(bool complete) async {
    if (_completed) return;
    if (complete) {
      _completed = true;
      await _progress.animateTo(1, curve: Curves.easeOut);
      if (!mounted) return;
      await Future<void>.delayed(const Duration(milliseconds: 120));
      if (!mounted) return;
      widget.onCompleted();
      return;
    }
    await _progress.animateTo(0, curve: Curves.easeOut);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const knob = 42.0;
        const inset = 6.0;
        final maxDrag = (constraints.maxWidth - knob - inset * 2).clamp(1.0, double.infinity);
        final progress = _progress.value.clamp(0.0, 1.0);

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragStart: (_) {
            if (_completed) return;
            _progress.stop();
          },
          onHorizontalDragUpdate: (details) {
            if (_completed) return;
            final next = _progress.value + (details.delta.dx / maxDrag);
            _progress.value = next.clamp(0.0, 1.0);
          },
          onHorizontalDragEnd: (_) => _settle(_progress.value >= 0.85),
          onHorizontalDragCancel: () => _settle(false),
          child: Container(
            height: 56,
            decoration: BoxDecoration(
              color: HomeColors.primary,
              borderRadius: BorderRadius.circular(28),
            ),
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                Center(
                  child: Opacity(
                    opacity: 1 - progress,
                    child: Text(
                      'Slide to place your order',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: inset + (maxDrag * progress),
                  child: Container(
                    width: knob,
                    height: knob,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      progress >= 1 ? Icons.check_rounded : Icons.chevron_right_rounded,
                      color: HomeColors.primary,
                      size: 28,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
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
    'Dec',
  ];
  return months[month - 1];
}

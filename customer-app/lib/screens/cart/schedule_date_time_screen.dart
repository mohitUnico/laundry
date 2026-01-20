import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../theme/app_text_styles.dart';
import '../home/widgets/home_colors.dart';
import '../../routes/app_routes.dart';
import '../../providers/cart_provider.dart';
import '../../providers/order_provider.dart';
import '../../models/order_record.dart';
import '../../repositories/order_repository.dart';
import '../../repositories/customer_info_repository.dart';
import '../../services/customer_info_service.dart';
import 'delivery_options_screen.dart';
import 'order_confirmation_screen.dart';

class ScheduleDateTimeArgs {
  final DeliveryOptionType option;
  final String? orderId; // If provided, update existing order instead of creating new one

  const ScheduleDateTimeArgs({
    required this.option,
    this.orderId,
  });
}

class ScheduleDateTimeScreen extends StatefulWidget {
  const ScheduleDateTimeScreen({super.key});

  @override
  State<ScheduleDateTimeScreen> createState() => _ScheduleDateTimeScreenState();
}

class _ScheduleDateTimeScreenState extends State<ScheduleDateTimeScreen> {
  int _selectedDayIndex = 2; // Center selected like the screenshot

  int _fromAmPm = 1; // 0 = AM, 1 = PM
  int _fromHour = 6; // 1..12
  int _fromMinute = 30; // 0..59

  int _toAmPm = 1; // PM
  int _toHour = 9; // 1..12
  int _toMinute = 0; // 0..59

  String _formatTime(int hour, int minute, int amPm) {
    final hh = hour.toString().padLeft(2, '0');
    final mm = minute.toString().padLeft(2, '0');
    final suffix = amPm == 0 ? 'AM' : 'PM';
    return '$hh:$mm $suffix';
  }

  String _formatTime12h(int hour, int minute, int amPm) {
    final h = hour.toString();
    final mm = minute.toString().padLeft(2, '0');
    final suffix = amPm == 0 ? 'AM' : 'PM';
    return '$h:$mm $suffix';
  }

  String _dateLabel(DateTime d, bool isSelected) {
    // Only the selected pill needs "Today, 17 Dec" style for now.
    final isToday = DateUtils.isSameDay(d, DateTime.now());
    final day = d.day.toString();
    final month = _monthShort(d.month);
    if (isSelected && isToday) return 'Today, $day $month';
    return day;
  }

  String _monthShort(int m) {
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
    return months[(m - 1).clamp(0, 11)];
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as ScheduleDateTimeArgs?;
    final option = args?.option ?? DeliveryOptionType.pickupOnly;

    final now = DateTime.now();
    final days = List.generate(5, (i) => DateTime(now.year, now.month, now.day + i));
    final selectedDate = days[_selectedDayIndex.clamp(0, days.length - 1)];

    final fromText = _formatTime(_fromHour, _fromMinute, _fromAmPm);
    final toText = _formatTime(_toHour, _toMinute, _toAmPm);

    return Scaffold(
      backgroundColor: HomeColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Row(
                children: [
                  InkWell(
                    onTap: () => Navigator.of(context).maybePop(),
                    borderRadius: BorderRadius.circular(999),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: HomeColors.borderSoft),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 16,
                          color: HomeColors.text,
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Schedule Date & Time',
                    style: AppTextStyles.header(color: HomeColors.text),
                  ),
                  const Spacer(),
                  const SizedBox(width: 44, height: 44),
                ],
              ),
              const SizedBox(height: 16),
              _DateChipRow(
                dates: days,
                selectedIndex: _selectedDayIndex,
                onSelect: (i) => setState(() => _selectedDayIndex = i),
                labelFor: (d, isSelected) => _dateLabel(d, isSelected),
              ),
              const SizedBox(height: 14),
              _TimeCard(
                fromText: fromText,
                toText: toText,
                fromPicker: _TimePickerRow(
                  amPmIndex: _fromAmPm,
                  hour: _fromHour,
                  minute: _fromMinute,
                  onAmPmChanged: (v) => setState(() => _fromAmPm = v),
                  onHourChanged: (v) => setState(() => _fromHour = v),
                  onMinuteChanged: (v) => setState(() => _fromMinute = v),
                ),
                toPicker: _TimePickerRow(
                  amPmIndex: _toAmPm,
                  hour: _toHour,
                  minute: _toMinute,
                  onAmPmChanged: (v) => setState(() => _toAmPm = v),
                  onHourChanged: (v) => setState(() => _toHour = v),
                  onMinuteChanged: (v) => setState(() => _toMinute = v),
                ),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () async {
                        final dateLabel = '${_monthShort(selectedDate.month)} ${selectedDate.day}';
                        final timeLabel = _formatTime12h(_fromHour, _fromMinute, _fromAmPm);

                        // If orderId is provided, update existing order
                        if (args?.orderId != null) {
                          context.read<OrderProvider>().updateOrderSchedule(
                                args!.orderId!,
                                dateLabel,
                                timeLabel,
                              );
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Schedule updated successfully')),
                          );
                          return;
                        }

                        // Otherwise, create order via backend
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

                        // Check cart type to determine flow
                        final hasAnyKgWise = cart.hasAnyKgWiseItems;

                        // If cart has ANY kg-wise items (even if mixed with per-piece), 
                        // navigate to order confirmation screen
                        if (hasAnyKgWise) {
                          if (!mounted) return;
                          Navigator.of(context).pushNamed(
                            AppRoutes.orderConfirmation,
                            arguments: OrderConfirmationArgs(
                              deliveryOption: option,
                              dateLabel: dateLabel,
                              timeLabel: timeLabel,
                            ),
                          );
                        } else {
                          // If cart has ONLY per-piece items (no kg-wise items), navigate to payment screen
                          // Payment screen will create the order after payment confirmation
                          if (!mounted) return;
                          Navigator.of(context).pushNamed(
                            AppRoutes.payment,
                            arguments: {
                              'dateLabel': dateLabel,
                              'timeLabel': timeLabel,
                              'deliveryOption': option.name,
                            },
                          );
                        }
                      },
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
                        child: Center(
                          child: Text(
                            args?.orderId != null ? 'Update Schedule' : 'Confirm Order',
                            style: AppTextStyles.header(color: Colors.white)
                                .copyWith(fontSize: 14),
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
      ),
    );
  }
}

class _DateChipRow extends StatelessWidget {
  final List<DateTime> dates;
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final String Function(DateTime date, bool isSelected) labelFor;

  const _DateChipRow({
    required this.dates,
    required this.selectedIndex,
    required this.onSelect,
    required this.labelFor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: HomeColors.borderSoft),
      ),
      child: Row(
        children: List.generate(dates.length, (i) {
          final isSelected = i == selectedIndex;
          final label = labelFor(dates[i], isSelected);
          return Expanded(
            child: InkWell(
              onTap: () => onSelect(i),
              borderRadius: BorderRadius.circular(999),
              child: Container(
                height: 36,
                alignment: Alignment.center,
                decoration: isSelected
                    ? BoxDecoration(
                        color: HomeColors.primary,
                        borderRadius: BorderRadius.circular(999),
                      )
                    : null,
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.body(
                    color: isSelected ? Colors.white : HomeColors.text,
                  ).copyWith(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _TimeCard extends StatelessWidget {
  final String fromText;
  final String toText;
  final Widget fromPicker;
  final Widget toPicker;

  const _TimeCard({
    required this.fromText,
    required this.toText,
    required this.fromPicker,
    required this.toPicker,
  });

  @override
  Widget build(BuildContext context) {
    final labelStyle = AppTextStyles.stepTitle(color: HomeColors.primary).copyWith(
      fontSize: 13,
    );
    final timeStyle = AppTextStyles.stepTitle(color: HomeColors.primary).copyWith(
      fontSize: 15,
    );
    final suffixStyle = AppTextStyles.body(color: HomeColors.primary).copyWith(
      fontSize: 10,
      fontWeight: FontWeight.w600,
      height: 1.0,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: HomeColors.borderSoft),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 14,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: _FromToLabel(
              prefix: 'From - ',
              timeText: fromText,
              prefixStyle: labelStyle,
              timeStyle: timeStyle,
              suffixStyle: suffixStyle,
            ),
          ),
          const SizedBox(height: 12),
          fromPicker,
          const SizedBox(height: 18),
          Align(
            alignment: Alignment.centerLeft,
            child: _FromToLabel(
              prefix: 'To - ',
              timeText: toText,
              prefixStyle: labelStyle,
              timeStyle: timeStyle,
              suffixStyle: suffixStyle,
            ),
          ),
          const SizedBox(height: 12),
          toPicker,
        ],
      ),
    );
  }
}

class _FromToLabel extends StatelessWidget {
  final String prefix;
  final String timeText; // "HH:MM AM/PM"
  final TextStyle prefixStyle;
  final TextStyle timeStyle;
  final TextStyle suffixStyle;

  const _FromToLabel({
    required this.prefix,
    required this.timeText,
    required this.prefixStyle,
    required this.timeStyle,
    required this.suffixStyle,
  });

  @override
  Widget build(BuildContext context) {
    final parts = timeText.split(' ');
    final hhmm = parts.isNotEmpty ? parts.first : timeText;
    final suffix = parts.length > 1 ? parts.last : '';

    return RichText(
      text: TextSpan(
        children: [
          TextSpan(text: prefix, style: prefixStyle),
          TextSpan(text: hhmm, style: timeStyle),
          if (suffix.isNotEmpty) ...[
            const TextSpan(text: ' '),
            TextSpan(text: suffix, style: suffixStyle),
          ],
        ],
      ),
    );
  }
}

class _TimePickerRow extends StatelessWidget {
  final int amPmIndex;
  final int hour;
  final int minute;
  final ValueChanged<int> onAmPmChanged;
  final ValueChanged<int> onHourChanged;
  final ValueChanged<int> onMinuteChanged;

  const _TimePickerRow({
    required this.amPmIndex,
    required this.hour,
    required this.minute,
    required this.onAmPmChanged,
    required this.onHourChanged,
    required this.onMinuteChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 150,
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: HomeColors.borderSoft),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: _WheelPicker(
              values: const ['AM', 'PM'],
              selectedIndex: amPmIndex,
              onSelectedIndexChanged: onAmPmChanged,
            ),
          ),
          const _VLine(),
          Expanded(
            flex: 2,
            child: _WheelPicker(
              values: List.generate(12, (i) => (i + 1).toString().padLeft(2, '0')),
              selectedIndex: (hour - 1).clamp(0, 11),
              onSelectedIndexChanged: (i) => onHourChanged(i + 1),
            ),
          ),
          const _VLine(),
          Expanded(
            flex: 2,
            child: _WheelPicker(
              values: List.generate(60, (i) => i.toString().padLeft(2, '0')),
              selectedIndex: minute.clamp(0, 59),
              onSelectedIndexChanged: onMinuteChanged,
            ),
          ),
        ],
      ),
    );
  }
}

class _VLine extends StatelessWidget {
  const _VLine();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: double.infinity,
      color: const Color(0xFFE5E7EB),
    );
  }
}

class _WheelPicker extends StatelessWidget {
  final List<String> values;
  final int selectedIndex;
  final ValueChanged<int> onSelectedIndexChanged;

  const _WheelPicker({
    required this.values,
    required this.selectedIndex,
    required this.onSelectedIndexChanged,
  });

  @override
  Widget build(BuildContext context) {
    final baseStyle = AppTextStyles.body(color: HomeColors.muted).copyWith(
      fontSize: 16,
      fontWeight: FontWeight.w500,
    );
    final selectedStyle = AppTextStyles.stepTitle(color: HomeColors.text).copyWith(
      fontSize: 18,
    );

    return CupertinoPicker(
      scrollController: FixedExtentScrollController(initialItem: selectedIndex),
      itemExtent: 38,
      selectionOverlay: Container(
        margin: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      onSelectedItemChanged: onSelectedIndexChanged,
      children: [
        for (int i = 0; i < values.length; i++)
          Center(
            child: Text(
              values[i],
              style: i == selectedIndex ? selectedStyle : baseStyle,
            ),
          ),
      ],
    );
  }
}



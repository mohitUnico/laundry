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

  // Pickup time
  int _fromAmPm = 1; // 0 = AM, 1 = PM
  int _fromHour = 6; // 1..12
  int _fromMinute = 30; // 0..59

  int _toAmPm = 1; // PM
  int _toHour = 9; // 1..12
  int _toMinute = 0; // 0..59

  // Delivery time (for "both" orders)
  int _deliverySelectedDayIndex = 3; // Default to day after pickup
  int _deliveryFromAmPm = 1; // 0 = AM, 1 = PM
  int _deliveryFromHour = 6; // 1..12
  int _deliveryFromMinute = 30; // 0..59

  int _deliveryToAmPm = 1; // PM
  int _deliveryToHour = 9; // 1..12
  int _deliveryToMinute = 0; // 0..59

  int _to24Hour(int hour12, int amPm) {
    // amPm: 0=AM, 1=PM
    if (amPm == 0) {
      return hour12 == 12 ? 0 : hour12;
    }
    return hour12 == 12 ? 12 : hour12 + 12;
  }

  DateTime _asLocalDateTime(DateTime dateOnly, int hour12, int minute, int amPm) {
    final h24 = _to24Hour(hour12, amPm);
    return DateTime(dateOnly.year, dateOnly.month, dateOnly.day, h24, minute);
  }

  int _roundUpToStep(int value, int step) {
    if (step <= 1) return value;
    return ((value + (step - 1)) ~/ step) * step;
  }

  int _minuteStep() => 5;

  int _minMinutesForSelectedDay(DateTime selectedDate) {
    final now = DateTime.now(); // local
    if (!DateUtils.isSameDay(selectedDate, now)) return 0;

    // Earliest selectable time is "now" (rounded to the nearest step).
    final next = now;
    final roundedMinute = _roundUpToStep(next.minute, _minuteStep());
    final carryHour = roundedMinute >= 60 ? 1 : 0;
    final minute = roundedMinute % 60;
    final hour = (next.hour + carryHour).clamp(0, 23);
    return hour * 60 + minute;
  }

  int _toMinutesSinceMidnight(int hour12, int minute, int amPm) {
    return _to24Hour(hour12, amPm) * 60 + minute;
  }

  void _showInvalidTimeSnack(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please select a time from the current time onwards')),
    );
  }

  List<String> _allowedAmPmValues(int minMinutes) {
    // If min time is already in PM range, hide AM to avoid confusion.
    if (minMinutes >= 12 * 60) return const ['PM'];
    return const ['AM', 'PM'];
  }

  List<String> _allowedHourValues({
    required int minMinutes,
    required String selectedAmPm, // "AM"/"PM"
  }) {
    final periodStart = selectedAmPm == 'AM' ? 0 : 12;
    final periodEnd = selectedAmPm == 'AM' ? 11 : 23;

    final minHour = (minMinutes ~/ 60).clamp(0, 23);
    final startHour = (minHour > periodEnd) ? periodStart : (minHour < periodStart ? periodStart : minHour);

    final hours = <String>[];
    for (int h24 = startHour; h24 <= periodEnd; h24++) {
      // If we are on the min hour, ensure there is at least one valid minute.
      if (h24 == minHour) {
        final minMinute = (minMinutes % 60).clamp(0, 59);
        final rounded = _roundUpToStep(minMinute, _minuteStep());
        if (rounded >= 60) continue; // no valid minute left in this hour
      }

      final h12 = h24 == 0 ? 12 : (h24 > 12 ? h24 - 12 : h24);
      hours.add(h12.toString().padLeft(2, '0'));
    }
    return hours.isEmpty ? const ['12'] : hours;
  }

  List<String> _allowedMinuteValues({
    required int minMinutes,
    required int selectedHour12,
    required int selectedAmPm, // 0/1
  }) {
    final minHour24 = (minMinutes ~/ 60).clamp(0, 23);
    final minMinute = (minMinutes % 60).clamp(0, 59);

    final selectedHour24 = _to24Hour(selectedHour12, selectedAmPm);
    final startMinute = (selectedHour24 == minHour24) ? _roundUpToStep(minMinute, _minuteStep()) : 0;

    final values = <String>[];
    for (int m = startMinute; m < 60; m += _minuteStep()) {
      values.add(m.toString().padLeft(2, '0'));
    }
    return values.isEmpty ? const ['00'] : values;
  }

  void _ensureValidSelections({
    required DateTime selectedDate,
  }) {
    final minFrom = _minMinutesForSelectedDay(selectedDate);

    // Ensure FROM is not before minFrom (and its wheels are within allowed values).
    final allowedFromAmPm = _allowedAmPmValues(minFrom);
    int fromAmPm = _fromAmPm;
    if (!allowedFromAmPm.contains(fromAmPm == 0 ? 'AM' : 'PM')) {
      fromAmPm = allowedFromAmPm.first == 'AM' ? 0 : 1;
    }

    final allowedFromHours =
        _allowedHourValues(minMinutes: minFrom, selectedAmPm: fromAmPm == 0 ? 'AM' : 'PM');
    int fromHour = _fromHour;
    if (!allowedFromHours.contains(fromHour.toString().padLeft(2, '0'))) {
      fromHour = int.tryParse(allowedFromHours.first) ?? fromHour;
    }

    final allowedFromMinutes =
        _allowedMinuteValues(minMinutes: minFrom, selectedHour12: fromHour, selectedAmPm: fromAmPm);
    int fromMinute = _fromMinute;
    if (!allowedFromMinutes.contains(fromMinute.toString().padLeft(2, '0'))) {
      fromMinute = int.tryParse(allowedFromMinutes.first) ?? fromMinute;
    }

    final fromMinutes = _toMinutesSinceMidnight(fromHour, fromMinute, fromAmPm);

    // Ensure TO is after FROM (minimum + 5 minutes), and not before minFrom as well.
    final minTo = (fromMinutes + _minuteStep()).clamp(0, 24 * 60 - 1);
    final effectiveMinTo = (minTo > minFrom) ? minTo : minFrom;

    final allowedToAmPm = _allowedAmPmValues(effectiveMinTo);
    int toAmPm = _toAmPm;
    if (!allowedToAmPm.contains(toAmPm == 0 ? 'AM' : 'PM')) {
      toAmPm = allowedToAmPm.first == 'AM' ? 0 : 1;
    }

    final allowedToHours =
        _allowedHourValues(minMinutes: effectiveMinTo, selectedAmPm: toAmPm == 0 ? 'AM' : 'PM');
    int toHour = _toHour;
    if (!allowedToHours.contains(toHour.toString().padLeft(2, '0'))) {
      toHour = int.tryParse(allowedToHours.first) ?? toHour;
    }

    final allowedToMinutes =
        _allowedMinuteValues(minMinutes: effectiveMinTo, selectedHour12: toHour, selectedAmPm: toAmPm);
    int toMinute = _toMinute;
    if (!allowedToMinutes.contains(toMinute.toString().padLeft(2, '0'))) {
      toMinute = int.tryParse(allowedToMinutes.first) ?? toMinute;
    }

    // If any correction is needed, apply it after build.
    if (fromAmPm != _fromAmPm ||
        fromHour != _fromHour ||
        fromMinute != _fromMinute ||
        toAmPm != _toAmPm ||
        toHour != _toHour ||
        toMinute != _toMinute) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _fromAmPm = fromAmPm;
          _fromHour = fromHour;
          _fromMinute = fromMinute;
          _toAmPm = toAmPm;
          _toHour = toHour;
          _toMinute = toMinute;
        });
      });
    }
  }

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
    var selectedDate = days[_selectedDayIndex.clamp(0, days.length - 1)];
    // If today has no valid time slots left from "now", force tomorrow.
    final minForSelected = _minMinutesForSelectedDay(selectedDate);
    if (DateUtils.isSameDay(selectedDate, now) && minForSelected >= 24 * 60 && days.length > 1) {
      selectedDate = days[1];
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No slots available today. Please select tomorrow.')),
        );
        setState(() => _selectedDayIndex = 1);
      });
    }
    _ensureValidSelections(selectedDate: selectedDate);

    final fromText = _formatTime(_fromHour, _fromMinute, _fromAmPm);
    final toText = _formatTime(_toHour, _toMinute, _toAmPm);

    final minFromMinutes = _minMinutesForSelectedDay(selectedDate);
    final fromAmPmValues = _allowedAmPmValues(minFromMinutes);
    final fromHourValues = _allowedHourValues(
      minMinutes: minFromMinutes,
      selectedAmPm: _fromAmPm == 0 ? 'AM' : 'PM',
    );
    final fromMinuteValues = _allowedMinuteValues(
      minMinutes: minFromMinutes,
      selectedHour12: _fromHour,
      selectedAmPm: _fromAmPm,
    );

    final fromMinutes = _toMinutesSinceMidnight(_fromHour, _fromMinute, _fromAmPm);
    final minToMinutes = (fromMinutes + _minuteStep()).clamp(0, 24 * 60 - 1);
    final effectiveMinTo = (minToMinutes > minFromMinutes) ? minToMinutes : minFromMinutes;

    final toAmPmValues = _allowedAmPmValues(effectiveMinTo);
    final toHourValues = _allowedHourValues(
      minMinutes: effectiveMinTo,
      selectedAmPm: _toAmPm == 0 ? 'AM' : 'PM',
    );
    final toMinuteValues = _allowedMinuteValues(
      minMinutes: effectiveMinTo,
      selectedHour12: _toHour,
      selectedAmPm: _toAmPm,
    );

    return Scaffold(
      backgroundColor: HomeColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header (fixed at top)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Row(
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
            ),
            // Scrollable content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    // Date chips: for delivery_only, only the Delivery section has date row; for others, this is pickup date
                    if (option != DeliveryOptionType.deliveryOnly)
                      _DateChipRow(
                        dates: days,
                        selectedIndex: _selectedDayIndex,
                        onSelect: (i) {
                          setState(() {
                            _selectedDayIndex = i;
                            // If delivery date is now before pickup date, adjust it (only for both)
                            if (option == DeliveryOptionType.pickupAndDelivery) {
                              final newPickupDate = days[i];
                              final currentDeliveryDate = days[_deliverySelectedDayIndex.clamp(0, days.length - 1)];
                              if (currentDeliveryDate.isBefore(newPickupDate)) {
                                _deliverySelectedDayIndex = i;
                              }
                            }
                          });
                        },
                        labelFor: (d, isSelected) => _dateLabel(d, isSelected),
                      ),
                    if (option != DeliveryOptionType.deliveryOnly) const SizedBox(height: 14),
                    // Pickup Time Section (not shown for delivery_only - no pickup from customer)
                    if (option != DeliveryOptionType.deliveryOnly) ...[
                    Text(
                      'Pickup Time (IST)',
                      style: AppTextStyles.header(color: HomeColors.text),
                    ),
                    const SizedBox(height: 8),
                    _TimeCard(
                      fromText: fromText,
                      toText: toText,
                      fromPicker: _TimePickerRow(
                        amPmValues: fromAmPmValues,
                        hourValues: fromHourValues,
                        minuteValues: fromMinuteValues,
                        amPmIndex: (_fromAmPm == 0 ? 'AM' : 'PM') == 'AM'
                            ? fromAmPmValues.indexOf('AM').clamp(0, fromAmPmValues.length - 1)
                            : fromAmPmValues.indexOf('PM').clamp(0, fromAmPmValues.length - 1),
                        hourIndex: fromHourValues.indexOf(_fromHour.toString().padLeft(2, '0')).clamp(0, fromHourValues.length - 1),
                        minuteIndex: fromMinuteValues.indexOf(_fromMinute.toString().padLeft(2, '0')).clamp(0, fromMinuteValues.length - 1),
                        onAmPmChanged: (label) => setState(() => _fromAmPm = label == 'AM' ? 0 : 1),
                        onHourChanged: (label) => setState(() => _fromHour = int.tryParse(label) ?? _fromHour),
                        onMinuteChanged: (label) => setState(() => _fromMinute = int.tryParse(label) ?? _fromMinute),
                      ),
                      toPicker: _TimePickerRow(
                        amPmValues: toAmPmValues,
                        hourValues: toHourValues,
                        minuteValues: toMinuteValues,
                        amPmIndex: (_toAmPm == 0 ? 'AM' : 'PM') == 'AM'
                            ? toAmPmValues.indexOf('AM').clamp(0, toAmPmValues.length - 1)
                            : toAmPmValues.indexOf('PM').clamp(0, toAmPmValues.length - 1),
                        hourIndex: toHourValues.indexOf(_toHour.toString().padLeft(2, '0')).clamp(0, toHourValues.length - 1),
                        minuteIndex: toMinuteValues.indexOf(_toMinute.toString().padLeft(2, '0')).clamp(0, toMinuteValues.length - 1),
                        onAmPmChanged: (label) => setState(() => _toAmPm = label == 'AM' ? 0 : 1),
                        onHourChanged: (label) => setState(() => _toHour = int.tryParse(label) ?? _toHour),
                        onMinuteChanged: (label) => setState(() => _toMinute = int.tryParse(label) ?? _toMinute),
                      ),
                    ),
                    ],
                    // Delivery Time Section (for "both" and "delivery_only" - when we deliver to customer)
                    if (option == DeliveryOptionType.pickupAndDelivery ||
                        option == DeliveryOptionType.deliveryOnly) ...[
                      const SizedBox(height: 20),
                      Text(
                        'Delivery Time (IST)',
                        style: AppTextStyles.header(color: HomeColors.text),
                      ),
                      const SizedBox(height: 8),
                      Builder(
                        builder: (context) {
                          // Filter delivery dates: for "both", must be >= pickup date; for delivery_only, all dates
                          final pickupDate = option == DeliveryOptionType.pickupAndDelivery
                              ? selectedDate
                              : DateTime(1900, 1, 1); // No constraint for delivery_only
                          final availableDeliveryDates = days.where((date) {
                            return !date.isBefore(pickupDate);
                          }).toList();
                          
                          // Ensure delivery date index is valid
                          if (availableDeliveryDates.isEmpty) {
                            // Fallback: use all dates if somehow no dates are available
                            availableDeliveryDates.addAll(days);
                          }
                          
                          // Find the current delivery date in the available dates list
                          final currentDeliveryDate = days[_deliverySelectedDayIndex.clamp(0, days.length - 1)];
                          int deliveryIndexInAvailable = availableDeliveryDates.indexWhere(
                            (d) => DateUtils.isSameDay(d, currentDeliveryDate),
                          );
                          
                          // If current delivery date is before pickup, select the first available date
                          if (deliveryIndexInAvailable < 0 ||
                              (option == DeliveryOptionType.pickupAndDelivery &&
                                  currentDeliveryDate.isBefore(pickupDate))) {
                            deliveryIndexInAvailable = 0;
                            // Update the state to reflect the valid date
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (mounted) {
                                final newIndex = days.indexWhere((d) => DateUtils.isSameDay(d, availableDeliveryDates[0]));
                                if (newIndex >= 0) {
                                  setState(() => _deliverySelectedDayIndex = newIndex);
                                }
                              }
                            });
                          }
                          
                          return _DateChipRow(
                            dates: availableDeliveryDates,
                            selectedIndex: deliveryIndexInAvailable.clamp(0, availableDeliveryDates.length - 1),
                            onSelect: (i) {
                              if (i < 0 || i >= availableDeliveryDates.length) return;
                              final selectedDeliveryDate = availableDeliveryDates[i];
                              // Find the index in the original days list
                              final indexInDays = days.indexWhere((d) => DateUtils.isSameDay(d, selectedDeliveryDate));
                              if (indexInDays >= 0) {
                                setState(() => _deliverySelectedDayIndex = indexInDays);
                              }
                            },
                            labelFor: (d, isSelected) => _dateLabel(d, isSelected),
                          );
                        },
                      ),
                      const SizedBox(height: 14),
                      Builder(
                        builder: (context) {
                          final deliverySelectedDate = days[_deliverySelectedDayIndex.clamp(0, days.length - 1)];
                          final deliveryMinFromMinutes = _minMinutesForSelectedDay(deliverySelectedDate);
                          final deliveryFromAmPmValues = _allowedAmPmValues(deliveryMinFromMinutes);
                          final deliveryFromHourValues = _allowedHourValues(
                            minMinutes: deliveryMinFromMinutes,
                            selectedAmPm: _deliveryFromAmPm == 0 ? 'AM' : 'PM',
                          );
                          final deliveryFromMinuteValues = _allowedMinuteValues(
                            minMinutes: deliveryMinFromMinutes,
                            selectedHour12: _deliveryFromHour,
                            selectedAmPm: _deliveryFromAmPm,
                          );

                          final deliveryFromMinutes = _toMinutesSinceMidnight(_deliveryFromHour, _deliveryFromMinute, _deliveryFromAmPm);
                          final deliveryMinToMinutes = (deliveryFromMinutes + _minuteStep()).clamp(0, 24 * 60 - 1);
                          final deliveryEffectiveMinTo = (deliveryMinToMinutes > deliveryMinFromMinutes) ? deliveryMinToMinutes : deliveryMinFromMinutes;

                          final deliveryToAmPmValues = _allowedAmPmValues(deliveryEffectiveMinTo);
                          final deliveryToHourValues = _allowedHourValues(
                            minMinutes: deliveryEffectiveMinTo,
                            selectedAmPm: _deliveryToAmPm == 0 ? 'AM' : 'PM',
                          );
                          final deliveryToMinuteValues = _allowedMinuteValues(
                            minMinutes: deliveryEffectiveMinTo,
                            selectedHour12: _deliveryToHour,
                            selectedAmPm: _deliveryToAmPm,
                          );

                          final deliveryFromText = _formatTime(_deliveryFromHour, _deliveryFromMinute, _deliveryFromAmPm);
                          final deliveryToText = _formatTime(_deliveryToHour, _deliveryToMinute, _deliveryToAmPm);

                          return _TimeCard(
                            fromText: deliveryFromText,
                            toText: deliveryToText,
                            fromPicker: _TimePickerRow(
                              amPmValues: deliveryFromAmPmValues,
                              hourValues: deliveryFromHourValues,
                              minuteValues: deliveryFromMinuteValues,
                              amPmIndex: (_deliveryFromAmPm == 0 ? 'AM' : 'PM') == 'AM'
                                  ? deliveryFromAmPmValues.indexOf('AM').clamp(0, deliveryFromAmPmValues.length - 1)
                                  : deliveryFromAmPmValues.indexOf('PM').clamp(0, deliveryFromAmPmValues.length - 1),
                              hourIndex: deliveryFromHourValues.indexOf(_deliveryFromHour.toString().padLeft(2, '0')).clamp(0, deliveryFromHourValues.length - 1),
                              minuteIndex: deliveryFromMinuteValues.indexOf(_deliveryFromMinute.toString().padLeft(2, '0')).clamp(0, deliveryFromMinuteValues.length - 1),
                              onAmPmChanged: (label) => setState(() => _deliveryFromAmPm = label == 'AM' ? 0 : 1),
                              onHourChanged: (label) => setState(() => _deliveryFromHour = int.tryParse(label) ?? _deliveryFromHour),
                              onMinuteChanged: (label) => setState(() => _deliveryFromMinute = int.tryParse(label) ?? _deliveryFromMinute),
                            ),
                            toPicker: _TimePickerRow(
                              amPmValues: deliveryToAmPmValues,
                              hourValues: deliveryToHourValues,
                              minuteValues: deliveryToMinuteValues,
                              amPmIndex: (_deliveryToAmPm == 0 ? 'AM' : 'PM') == 'AM'
                                  ? deliveryToAmPmValues.indexOf('AM').clamp(0, deliveryToAmPmValues.length - 1)
                                  : deliveryToAmPmValues.indexOf('PM').clamp(0, deliveryToAmPmValues.length - 1),
                              hourIndex: deliveryToHourValues.indexOf(_deliveryToHour.toString().padLeft(2, '0')).clamp(0, deliveryToHourValues.length - 1),
                              minuteIndex: deliveryToMinuteValues.indexOf(_deliveryToMinute.toString().padLeft(2, '0')).clamp(0, deliveryToMinuteValues.length - 1),
                              onAmPmChanged: (label) => setState(() => _deliveryToAmPm = label == 'AM' ? 0 : 1),
                              onHourChanged: (label) => setState(() => _deliveryToHour = int.tryParse(label) ?? _deliveryToHour),
                              onMinuteChanged: (label) => setState(() => _deliveryToMinute = int.tryParse(label) ?? _deliveryToMinute),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 20), // Extra spacing before button
                    ] else ...[
                      const SizedBox(height: 20), // Spacing when no delivery section
                    ],
                  ],
                ),
              ),
            ),
            // Button (fixed at bottom)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () async {
                        String dateLabel;
                        String timeLabel;
                        String? deliveryDateLabel;
                        String? deliveryTimeLabel;

                        if (option == DeliveryOptionType.deliveryOnly) {
                          // Delivery only: validate delivery time only (no pickup)
                          final deliverySelectedDate = days[_deliverySelectedDayIndex.clamp(0, days.length - 1)];
                          final deliveryFromDt = _asLocalDateTime(deliverySelectedDate, _deliveryFromHour, _deliveryFromMinute, _deliveryFromAmPm);
                          final deliveryToDt = _asLocalDateTime(deliverySelectedDate, _deliveryToHour, _deliveryToMinute, _deliveryToAmPm);

                          final deliveryMinFromMinutes = _minMinutesForSelectedDay(deliverySelectedDate);
                          final minAllowed = DateTime(
                            deliverySelectedDate.year,
                            deliverySelectedDate.month,
                            deliverySelectedDate.day,
                            (deliveryMinFromMinutes ~/ 60).clamp(0, 23),
                            (deliveryMinFromMinutes % 60).clamp(0, 59),
                          );
                          if (deliveryFromDt.isBefore(minAllowed)) {
                            _showInvalidTimeSnack(context);
                            return;
                          }
                          if (!deliveryToDt.isAfter(deliveryFromDt)) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Delivery To time must be after From time')),
                            );
                            return;
                          }

                          dateLabel = '${_monthShort(deliverySelectedDate.month)} ${deliverySelectedDate.day}';
                          timeLabel = _formatTime12h(_deliveryFromHour, _deliveryFromMinute, _deliveryFromAmPm);
                          deliveryDateLabel = dateLabel;
                          deliveryTimeLabel = timeLabel;
                        } else {
                          // Pickup only or both: validate pickup schedule
                          final fromDt = _asLocalDateTime(selectedDate, _fromHour, _fromMinute, _fromAmPm);
                          final toDt = _asLocalDateTime(selectedDate, _toHour, _toMinute, _toAmPm);
                          final minFromMinutes = _minMinutesForSelectedDay(selectedDate);
                          final minAllowed = DateTime(
                            selectedDate.year,
                            selectedDate.month,
                            selectedDate.day,
                            (minFromMinutes ~/ 60).clamp(0, 23),
                            (minFromMinutes % 60).clamp(0, 59),
                          );
                          if (fromDt.isBefore(minAllowed)) {
                            _showInvalidTimeSnack(context);
                            return;
                          }
                          if (!toDt.isAfter(fromDt)) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Pickup To time must be after From time')),
                            );
                            return;
                          }

                          dateLabel = '${_monthShort(selectedDate.month)} ${selectedDate.day}';
                          timeLabel = _formatTime12h(_fromHour, _fromMinute, _fromAmPm);

                          // Validate delivery schedule for "both" orders
                          if (option == DeliveryOptionType.pickupAndDelivery) {
                          final deliverySelectedDate = days[_deliverySelectedDayIndex.clamp(0, days.length - 1)];
                          final deliveryFromDt = _asLocalDateTime(deliverySelectedDate, _deliveryFromHour, _deliveryFromMinute, _deliveryFromAmPm);
                          final deliveryToDt = _asLocalDateTime(deliverySelectedDate, _deliveryToHour, _deliveryToMinute, _deliveryToAmPm);

                          // Delivery date must be on or after pickup date
                          if (deliverySelectedDate.isBefore(selectedDate)) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Delivery date cannot be earlier than pickup date')),
                            );
                            return;
                          }
                          
                          // If same day, delivery time must be after pickup time
                          if (DateUtils.isSameDay(deliverySelectedDate, selectedDate) && deliveryFromDt.isBefore(toDt)) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Delivery time must be after pickup time')),
                            );
                            return;
                          }

                          if (!deliveryToDt.isAfter(deliveryFromDt)) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Delivery To time must be after From time')),
                            );
                            return;
                          }

                            deliveryDateLabel = '${_monthShort(deliverySelectedDate.month)} ${deliverySelectedDate.day}';
                            deliveryTimeLabel = _formatTime12h(_deliveryFromHour, _deliveryFromMinute, _deliveryFromAmPm);
                          }
                        }

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
                              deliveryDateLabel: deliveryDateLabel,
                              deliveryTimeLabel: deliveryTimeLabel,
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
                              'deliveryDateLabel': deliveryDateLabel,
                              'deliveryTimeLabel': deliveryTimeLabel,
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
  final List<String> amPmValues;
  final List<String> hourValues;
  final List<String> minuteValues;
  final int amPmIndex;
  final int hourIndex;
  final int minuteIndex;
  final ValueChanged<String> onAmPmChanged;
  final ValueChanged<String> onHourChanged;
  final ValueChanged<String> onMinuteChanged;

  const _TimePickerRow({
    required this.amPmValues,
    required this.hourValues,
    required this.minuteValues,
    required this.amPmIndex,
    required this.hourIndex,
    required this.minuteIndex,
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
              values: amPmValues,
              selectedIndex: amPmIndex,
              onSelectedIndexChanged: (i) {
                final v = amPmValues[i.clamp(0, amPmValues.length - 1)];
                onAmPmChanged(v);
              },
            ),
          ),
          const _VLine(),
          Expanded(
            flex: 2,
            child: _WheelPicker(
              values: hourValues,
              selectedIndex: hourIndex,
              onSelectedIndexChanged: (i) {
                final v = hourValues[i.clamp(0, hourValues.length - 1)];
                onHourChanged(v);
              },
            ),
          ),
          const _VLine(),
          Expanded(
            flex: 2,
            child: _WheelPicker(
              values: minuteValues,
              selectedIndex: minuteIndex,
              onSelectedIndexChanged: (i) {
                final v = minuteValues[i.clamp(0, minuteValues.length - 1)];
                onMinuteChanged(v);
              },
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



import 'package:flutter/material.dart';

import '../../theme/app_text_styles.dart';
import '../home/widgets/home_colors.dart';

class SchedulePick {
  final DateTime date;
  final String slot;

  const SchedulePick({required this.date, required this.slot});
}

/// [changing] is the "Change Schedule" mode used on an existing order: the
/// [current] date and slot are preselected in green, and once another one is
/// picked the old one turns red and the new one is green. [current] is null for
/// an instant pickup (nothing to preselect).
Future<SchedulePick?> showScheduleBottomSheet(
  BuildContext context, {
  required bool forDelivery,
  bool changing = false,
  SchedulePick? current,
}) {
  return showModalBottomSheet<SchedulePick>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _ScheduleDialog(
      forDelivery: forDelivery,
      changing: changing,
      current: current,
    ),
  );
}

/// The date and slot of an order's current pickup time, or null when it does
/// not line up with a slot in the list.
SchedulePick? schedulePickFromTime(DateTime? at) {
  if (at == null) return null;
  for (final slots in _slotsByPart.values) {
    for (final slot in slots) {
      if (scheduleSlotStart(at, slot) == at) {
        return SchedulePick(date: DateTime(at.year, at.month, at.day), slot: slot);
      }
    }
  }
  return null;
}

enum _DayPart { morning, afternoon, evening }

const _slotsByPart = <_DayPart, List<String>>{
  _DayPart.morning: [
    '8:00AM-8:30AM',
    '8:30AM-9:00AM',
    '9:00AM-9:30AM',
    '9:30AM-10:00AM',
    '10:00AM-10:30AM',
    '10:30AM-11:00AM',
    '11:00AM-11:30AM',
    '11:30AM-12:00PM',
  ],
  _DayPart.afternoon: [
    '12:00PM-12:30PM',
    '12:30PM-1:00PM',
    '1:00PM-1:30PM',
    '1:30PM-2:00PM',
    '2:00PM-2:30PM',
    '2:30PM-3:00PM',
    '3:00PM-3:30PM',
    '3:30PM-4:00PM',
    '4:00PM-4:30PM',
    '4:30PM-5:00PM',
  ],
  _DayPart.evening: [
    '5:00PM-5:30PM',
    '5:30PM-6:00PM',
    '6:00PM-6:30PM',
    '6:30PM-7:00PM',
    '7:00PM-7:30PM',
    '7:30PM-8:00PM',
    '8:00PM-8:30PM',
    '8:30PM-9:00PM',
  ],
};

DateTime scheduleSlotStart(DateTime date, String slot) {
  final start = slot.split('-').first.trim();
  final match = RegExp(r'(\d{1,2}):(\d{2})\s*(AM|PM)?', caseSensitive: false).firstMatch(start);
  var hour = int.tryParse(match?.group(1) ?? '') ?? 14;
  final minute = int.tryParse(match?.group(2) ?? '') ?? 0;
  final marker = match?.group(3)?.toUpperCase();
  final isPm = marker != null ? marker == 'PM' : slot.toUpperCase().contains('PM');
  if (isPm && hour != 12) hour += 12;
  if (!isPm && hour == 12) hour = 0;
  return DateTime(date.year, date.month, date.day, hour, minute);
}

/// Example: "Sun, 8 – 9:30 am".
String schedulePickupHeadline(DateTime date, String slot) {
  const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  return '${days[date.weekday - 1]}, ${_prettySlot(slot)}';
}

String _prettySlot(String slot) {
  final match = RegExp(
    r'(\d{1,2}):(\d{2})\s*(AM|PM)?\s*-\s*(\d{1,2}):(\d{2})\s*(AM|PM)',
    caseSensitive: false,
  ).firstMatch(slot);
  if (match == null) return slot;
  final startPeriod = (match.group(3) ?? match.group(6)!).toLowerCase();
  final endPeriod = match.group(6)!.toLowerCase();
  final start = _clock(match.group(1)!, match.group(2)!);
  final end = _clock(match.group(4)!, match.group(5)!);
  if (startPeriod == endPeriod) return '$start – $end $endPeriod';
  return '$start $startPeriod – $end $endPeriod';
}

String _clock(String hour, String minute) {
  if (minute == '00') return hour;
  return '$hour:$minute';
}

class _ScheduleDialog extends StatefulWidget {
  final bool forDelivery;
  final bool changing;
  final SchedulePick? current;

  const _ScheduleDialog({
    required this.forDelivery,
    required this.changing,
    required this.current,
  });

  @override
  State<_ScheduleDialog> createState() => _ScheduleDialogState();
}

class _ScheduleDialogState extends State<_ScheduleDialog> {
  late final DateTime _today;
  late final List<DateTime> _dates;
  DateTime? _selectedDate;
  late _DayPart _part;
  String? _selectedSlot;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _today = DateTime(now.year, now.month, now.day);
    _dates = [for (var i = 0; i < 10; i++) _today.add(Duration(days: i))];
    _part = now.hour < 12
        ? _DayPart.morning
        : now.hour < 17
            ? _DayPart.afternoon
            : _DayPart.evening;

    final current = widget.current;
    if (widget.changing && current != null) {
      final day = DateTime(current.date.year, current.date.month, current.date.day);
      // The current date may be outside the usual date chips; keep it visible.
      if (!_dates.contains(day)) {
        _dates
          ..add(day)
          ..sort();
      }
      _selectedDate = day;
      _selectedSlot = current.slot;
      for (final entry in _slotsByPart.entries) {
        if (entry.value.contains(current.slot)) _part = entry.key;
      }
    }
  }

  List<String> get _slots => _slotsByPart[_part]!;

  bool get _hasPick => _selectedDate != null && (_selectedSlot ?? '').isNotEmpty;

  bool get _matchesCurrent {
    final current = widget.current;
    if (current == null) return false;
    final day = DateTime(current.date.year, current.date.month, current.date.day);
    return _selectedDate == day && _selectedSlot == current.slot;
  }

  // Changing an order: Confirm only once the pick differs from the current one.
  bool get _canConfirm => _hasPick && !(widget.changing && _matchesCurrent);

  _ChipTone _toneFor({required bool selected, required bool isCurrent}) {
    if (!widget.changing) return selected ? _ChipTone.primary : _ChipTone.idle;
    if (selected) return _ChipTone.keep;
    return isCurrent ? _ChipTone.drop : _ChipTone.idle;
  }

  bool _isCurrentDate(DateTime date) {
    final current = widget.current;
    return current != null &&
        date == DateTime(current.date.year, current.date.month, current.date.day);
  }

  void _selectPart(_DayPart part) {
    setState(() {
      _part = part;
      if (!_slotsByPart[part]!.contains(_selectedSlot)) _selectedSlot = null;
    });
  }

  String _caption(DateTime date) {
    final diff = date.difference(_today).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Tomorrow';
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[date.weekday - 1];
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.88),
        decoration: const BoxDecoration(
          color: HomeColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: HomeColors.borderSoft,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(18, 16, 18, 12 + bottomInset),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.changing
                          ? (widget.forDelivery
                              ? 'Change delivery schedule'
                              : 'Change pickup schedule')
                          : (widget.forDelivery ? 'Schedule delivery' : 'Schedule pickup'),
                      style: AppTextStyles.header(color: HomeColors.text).copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Select date',
                      style: AppTextStyles.header(color: HomeColors.text).copyWith(fontSize: 14),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 64,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _dates.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 10),
                        itemBuilder: (context, index) {
                          final date = _dates[index];
                          final selected = date == _selectedDate;
                          final tone = _toneFor(
                            selected: selected,
                            isCurrent: _isCurrentDate(date),
                          );
                          final titleColor = tone == _ChipTone.idle ? HomeColors.text : tone.color;
                          final captionColor = tone == _ChipTone.idle ? HomeColors.muted : tone.color;
                          return _ChoiceChip(
                            tone: tone,
                            width: 78,
                            onTap: () => setState(() => _selectedDate = date),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '${date.day} ${_monthShort(date.month)}',
                                  style: AppTextStyles.header(color: titleColor).copyWith(
                                    fontSize: 13,
                                    height: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _caption(date),
                                  style: AppTextStyles.body(color: captionColor).copyWith(
                                    fontSize: 11,
                                    height: 1.2,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Select time slot',
                      style: AppTextStyles.header(color: HomeColors.text).copyWith(fontSize: 14),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE7F8EF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.delivery_dining_outlined, size: 18, color: Color(0xFF1F8A5B)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Our WashBee delivery partner will arrive soon.',
                              style: AppTextStyles.body(color: const Color(0xFF1F8A5B)).copyWith(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        for (final part in _DayPart.values) ...[
                          if (part != _DayPart.morning) const SizedBox(width: 10),
                          Expanded(child: _partChip(part)),
                        ],
                      ],
                    ),
                    const SizedBox(height: 12),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _slots.length,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        mainAxisExtent: 48,
                      ),
                      itemBuilder: (context, index) {
                        final slot = _slots[index];
                        final tone = _toneFor(
                          selected: slot == _selectedSlot,
                          isCurrent: slot == widget.current?.slot,
                        );
                        return _ChoiceChip(
                          tone: tone,
                          onTap: () => setState(() => _selectedSlot = slot),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              _prettySlot(slot),
                              textAlign: TextAlign.center,
                              style: AppTextStyles.body(
                                color: tone == _ChipTone.idle ? HomeColors.text : tone.color,
                              ).copyWith(
                                fontSize: 13,
                                height: 1.35,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 22),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: TextButton(
                        onPressed: _canConfirm
                            ? () {
                                Navigator.of(context).pop(
                                  SchedulePick(date: _selectedDate!, slot: _selectedSlot!),
                                );
                              }
                            : null,
                        style: TextButton.styleFrom(
                          backgroundColor: _canConfirm ? HomeColors.primary : const Color(0xFFE4E7EE),
                          disabledBackgroundColor: const Color(0xFFE4E7EE),
                          foregroundColor: Colors.white,
                          disabledForegroundColor: HomeColors.muted,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                        ),
                        child: Text(
                          widget.changing ? 'Confirm' : 'Select date and time',
                          style: AppTextStyles.button(
                            color: _canConfirm ? Colors.white : HomeColors.muted,
                          ).copyWith(fontSize: 15),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _partChip(_DayPart part) {
    final selected = _part == part;
    final label = switch (part) {
      _DayPart.morning => 'Morning',
      _DayPart.afternoon => 'Afternoon',
      _DayPart.evening => 'Evening',
    };
    return _ChoiceChip(
      tone: selected ? _ChipTone.primary : _ChipTone.idle,
      onTap: () => _selectPart(part),
      child: Text(
        label,
        style: AppTextStyles.header(
          color: selected ? HomeColors.primary : HomeColors.text,
        ).copyWith(fontSize: 14, height: 1.2),
      ),
    );
  }
}

/// How a chip looks. [primary] is the normal booking selection (blue). In the
/// change-schedule sheet the picked chip is [keep] (green) and the schedule
/// being replaced is [drop] (red).
enum _ChipTone {
  idle(HomeColors.borderSoft),
  primary(HomeColors.primary),
  keep(Color(0xFF1F8A5B)),
  drop(Color(0xFFD92D20));

  const _ChipTone(this.color);
  final Color color;
}

class _ChoiceChip extends StatelessWidget {
  final _ChipTone tone;
  final VoidCallback onTap;
  final Widget child;
  final double? width;

  const _ChoiceChip({
    required this.tone,
    required this.onTap,
    required this.child,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final active = tone != _ChipTone.idle;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: width,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: active ? tone.color.withValues(alpha: 0.12) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: tone.color),
        ),
        child: child,
      ),
    );
  }
}

String _monthShort(int month) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return months[month - 1];
}

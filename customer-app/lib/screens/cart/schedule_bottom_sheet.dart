import 'package:flutter/material.dart';

import '../../theme/app_text_styles.dart';
import '../home/widgets/home_colors.dart';

class SchedulePick {
  final DateTime date;
  final String slot;

  const SchedulePick({required this.date, required this.slot});
}

Future<SchedulePick?> showScheduleBottomSheet(BuildContext context) {
  return showModalBottomSheet<SchedulePick>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => const _ScheduleDialog(),
  );
}

const _afternoonSlots = [
  '2:30-3:00PM',
  '3:00-3:30PM',
  '3:30-4:00PM',
  '4:00-4:30PM',
  '4:30-5:00PM',
];

const _eveningSlots = [
  '5:30-6:00PM',
  '6:00-6:30PM',
  '6:30-7:00PM',
  '7:00-7:30PM',
  '7:30-8:00PM',
  '8:00-8:30PM',
  '8:30-9:00PM',
];

DateTime scheduleSlotStart(DateTime date, String slot) {
  final start = slot.split('-').first.trim();
  final parts = start.split(':');
  var hour = int.tryParse(parts.first) ?? 14;
  final minute = int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0;
  final period = slot.toUpperCase().contains('PM');
  if (period && hour != 12) hour += 12;
  if (!period && hour == 12) hour = 0;
  return DateTime(date.year, date.month, date.day, hour, minute);
}

/// Example: "Sun, 8:30 – 9 am".
String schedulePickupHeadline(DateTime date, String slot) {
  const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  return '${days[date.weekday - 1]}, ${_prettySlot(slot)}';
}

String _prettySlot(String slot) {
  final match = RegExp(
    r'(\d{1,2}):(\d{2})\s*-\s*(\d{1,2}):(\d{2})\s*(AM|PM)',
    caseSensitive: false,
  ).firstMatch(slot);
  if (match == null) return slot;
  final period = match.group(5)!.toLowerCase();
  return '${_clock(match.group(1)!, match.group(2)!)} – ${_clock(match.group(3)!, match.group(4)!)} $period';
}

String _clock(String hour, String minute) {
  if (minute == '00') return hour;
  return '$hour:$minute';
}

class _ScheduleDialog extends StatefulWidget {
  const _ScheduleDialog();

  @override
  State<_ScheduleDialog> createState() => _ScheduleDialogState();
}

class _ScheduleDialogState extends State<_ScheduleDialog> {
  late final List<DateTime> _dates;
  DateTime? _selectedDate;
  bool _afternoon = true;
  String? _selectedSlot;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    _dates = [for (var i = 0; i < 10; i++) today.add(Duration(days: i))];
    _afternoon = now.hour < 17;
  }

  List<String> get _slots => _afternoon ? _afternoonSlots : _eveningSlots;

  bool get _canConfirm => _selectedDate != null && (_selectedSlot ?? '').isNotEmpty;

  void _selectBand(bool afternoon) {
    final slots = afternoon ? _afternoonSlots : _eveningSlots;
    setState(() {
      _afternoon = afternoon;
      if (!slots.contains(_selectedSlot)) _selectedSlot = null;
    });
  }

  String _caption(DateTime date) {
    final diff = date.difference(_dates.first).inDays;
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
                      'Schedule pickup / delivery',
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
                          final titleColor = selected ? HomeColors.primary : HomeColors.text;
                          final captionColor = selected ? HomeColors.primary : HomeColors.muted;
                          return _ChoiceChip(
                            selected: selected,
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
                              'Our layrr partner will reach you within the selected slot',
                              style: AppTextStyles.body(color: const Color(0xFF1F8A5B)).copyWith(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _ChoiceChip(
                            selected: _afternoon,
                            onTap: () => _selectBand(true),
                            child: Text(
                              'Afternoon',
                              style: AppTextStyles.header(
                                color: _afternoon ? HomeColors.primary : HomeColors.text,
                              ).copyWith(fontSize: 14, height: 1.2),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _ChoiceChip(
                            selected: !_afternoon,
                            onTap: () => _selectBand(false),
                            child: Text(
                              'Evening',
                              style: AppTextStyles.header(
                                color: !_afternoon ? HomeColors.primary : HomeColors.text,
                              ).copyWith(fontSize: 14, height: 1.2),
                            ),
                          ),
                        ),
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
                        final selected = slot == _selectedSlot;
                        return _ChoiceChip(
                          selected: selected,
                          onTap: () => setState(() => _selectedSlot = slot),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              slot,
                              textAlign: TextAlign.center,
                              style: AppTextStyles.body(
                                color: selected ? HomeColors.primary : HomeColors.text,
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
                          'Select date and time',
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
}

class _ChoiceChip extends StatelessWidget {
  final bool selected;
  final VoidCallback onTap;
  final Widget child;
  final double? width;

  const _ChoiceChip({
    required this.selected,
    required this.onTap,
    required this.child,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: width,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? HomeColors.primary.withValues(alpha: 0.12) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? HomeColors.primary : HomeColors.borderSoft,
          ),
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

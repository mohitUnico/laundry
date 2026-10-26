import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../home/widgets/home_colors.dart';

class SchedulePick {
  final DateTime date;
  final String slot;

  const SchedulePick({required this.date, required this.slot});
}

Future<SchedulePick?> showScheduleBottomSheet(
  BuildContext context, {
  required bool forDelivery,
}) {
  return showModalBottomSheet<SchedulePick>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _ScheduleDialog(forDelivery: forDelivery),
  );
}

enum _DayPart { morning, afternoon, evening }

class _ScheduleDialog extends StatefulWidget {
  final bool forDelivery;

  const _ScheduleDialog({required this.forDelivery});

  @override
  State<_ScheduleDialog> createState() => _ScheduleDialogState();
}

class _ScheduleDialogState extends State<_ScheduleDialog> {
  static const _slots = <_DayPart, List<String>>{
    _DayPart.morning: [
      '8:00AM-9:30AM',
      '9:30AM-11:00AM',
      '11:00AM-12:30PM',
    ],
    _DayPart.afternoon: [
      '12:30PM-2:00PM',
      '2:00PM-3:30PM',
      '3:30PM-5:00PM',
    ],
    _DayPart.evening: [
      '5:00PM-6:30PM',
      '6:30PM-8:00PM',
      '8:00PM-9:30PM',
    ],
  };

  late final List<DateTime> _dates;
  late DateTime _selectedDate;
  _DayPart _part = _DayPart.afternoon;
  String? _selectedSlot;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    _dates = [for (var i = 0; i < 10; i++) today.add(Duration(days: i))];
    _selectedDate = _dates.first;
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
    final slots = _slots[_part]!;
    final canConfirm = _selectedSlot != null;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(16, 10, 16, 16 + bottomInset),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE4E7EC),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              Text(
                widget.forDelivery ? 'Schedule delivery' : 'Schedule pickup',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1F2430),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Select date',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1F2430),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 64,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _dates.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final date = _dates[index];
                    final selected = date == _selectedDate;
                    return InkWell(
                      onTap: () => setState(() => _selectedDate = date),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        width: 76,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: selected ? HomeColors.primary : const Color(0xFFE4E7EC),
                            width: selected ? 1.6 : 1,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${date.day} ${_monthShort(date.month)}',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF1F2430),
                              ),
                            ),
                            Text(
                              _caption(date),
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.w400,
                                color: const Color(0xFF98A2B3),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Select time slot',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1F2430),
                ),
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F8EF),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.two_wheeler_outlined,
                      size: 16,
                      color: Color(0xFF22C55E),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Our WashBee delivery partner will arrive soon.',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF16A34A),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  for (final part in _DayPart.values) ...[
                    if (part != _DayPart.morning) const SizedBox(width: 8),
                    Expanded(child: _partChip(part)),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: slots.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 2.2,
                ),
                itemBuilder: (context, index) {
                  final slot = slots[index];
                  final selected = slot == _selectedSlot;
                  return InkWell(
                    onTap: () => setState(() => _selectedSlot = slot),
                    borderRadius: BorderRadius.circular(22),
                    child: Container(
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: selected ? const Color(0xFFF4F6FF) : Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: selected ? HomeColors.primary : const Color(0xFFE4E7EC),
                        ),
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          slot,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF1F2430),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: canConfirm
                      ? () {
                          Navigator.of(context).pop(
                            SchedulePick(date: _selectedDate, slot: _selectedSlot!),
                          );
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: canConfirm ? HomeColors.primary : const Color(0xFFF2F4F7),
                    disabledBackgroundColor: const Color(0xFFF2F4F7),
                    foregroundColor: Colors.white,
                    disabledForegroundColor: const Color(0xFF98A2B3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: Text(
                    'Select date and time',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
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

  Widget _partChip(_DayPart part) {
    final selected = _part == part;
    final label = switch (part) {
      _DayPart.morning => 'Morning',
      _DayPart.afternoon => 'Afternoon',
      _DayPart.evening => 'Evening',
    };
    return InkWell(
      onTap: () => setState(() {
        _part = part;
        _selectedSlot = null;
      }),
      borderRadius: BorderRadius.circular(24),
      child: Container(
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: selected ? HomeColors.primary : const Color(0xFFE4E7EC),
            width: selected ? 1.6 : 1,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: selected ? HomeColors.primary : const Color(0xFF1F2430),
          ),
        ),
      ),
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

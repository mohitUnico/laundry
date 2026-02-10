/// Indian Standard Time (IST) = UTC+5:30.
/// Backend returns UTC; all displayed times in the app should be in IST.

const Duration istOffset = Duration(hours: 5, minutes: 30);

/// Converts a UTC [DateTime] to IST wall-clock for display.
DateTime utcToIst(DateTime utc) {
  return utc.toUtc().add(istOffset);
}

/// Formats a UTC [DateTime] as time in IST (e.g. "6:30 PM IST").
/// Returns '--' if [utc] is null.
String formatTimeIst(DateTime? utc) {
  if (utc == null) return '--';
  final ist = utcToIst(utc);
  int hour = ist.hour;
  final minute = ist.minute.toString().padLeft(2, '0');
  final suffix = hour >= 12 ? 'PM' : 'AM';
  hour = hour % 12;
  if (hour == 0) hour = 12;
  return '${hour.toString().padLeft(2, '0')}:$minute $suffix IST';
}

/// Formats a UTC [DateTime] as date in IST (e.g. "Feb 9").
String formatDateIst(DateTime? utc) {
  if (utc == null) return '--';
  final ist = utcToIst(utc);
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return '${months[ist.month - 1]} ${ist.day}';
}

/// Parses backend date/time (ISO string or DateTime) as UTC.
/// Strings without a timezone (e.g. "2026-02-10T01:17:00") are treated as UTC so they are not
/// misinterpreted as device local time; then [formatDateIst]/[formatTimeIst] show IST correctly.
DateTime? parseUtc(Object? raw) {
  if (raw is DateTime) return raw.toUtc();
  if (raw is String && raw.isNotEmpty) {
    String s = raw.trim();
    if (s.isEmpty) return null;
    // Backend sends UTC. If no 'Z' or +/- offset, assume UTC to avoid local-time interpretation.
    final hasTz = s.endsWith('Z') || RegExp(r'[+-]\d{2}:?\d{2}$').hasMatch(s);
    if (!hasTz) s = '$s${s.contains('.') ? '' : '.000'}Z';
    final dt = DateTime.tryParse(s);
    return dt?.toUtc();
  }
  return null;
}

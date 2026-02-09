/// Indian Standard Time (IST) = UTC+5:30.
/// All user-facing times in the app are shown in IST; the server stores UTC.

const Duration istOffset = Duration(hours: 5, minutes: 30);

/// Interprets the given date and time as IST (wall clock) and returns the
/// equivalent UTC [DateTime]. Use this when sending pickup/delivery times to the server.
DateTime istToUtc(int year, int month, int day, int hour24, int minute) {
  // Treat (year, month, day, hour24, minute) as IST.
  // UTC = IST - 5h30
  final asUtc = DateTime.utc(year, month, day, hour24, minute);
  return asUtc.subtract(istOffset);
}

/// Converts an IST wall-clock [DateTime] (naive, no timezone) to UTC [DateTime].
/// The input should represent a local time in IST (e.g. from a time picker).
DateTime istDateTimeToUtc(DateTime istWallClock) {
  return DateTime.utc(
    istWallClock.year,
    istWallClock.month,
    istWallClock.day,
    istWallClock.hour,
    istWallClock.minute,
  ).subtract(istOffset);
}

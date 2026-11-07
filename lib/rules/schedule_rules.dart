import '../utils/pala_clock.dart';

/// True when [date] is today or later (local time); false for earlier days
/// and a missing date. Upcoming exam and homework lists use it. The
/// extension mirrors it in `KretaApi.isUpcoming`.
bool isUpcoming(DateTime? date, [DateTime? now]) {
  if (date == null) return false;
  final n = now ?? PalaClock.now();
  final today = DateTime(n.year, n.month, n.day);
  return !date.toLocal().isBefore(today);
}

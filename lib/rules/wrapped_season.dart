/// Pala Wrapped sums up a finished school year, so it opens only in the
/// summer break: from 14 June to 30 September (demo mode shows it any time).
/// The extension mirrors this in `KretaApi.isWrappedSeason`.
bool isWrappedSeason(DateTime now) {
  final m = now.month, d = now.day;
  return (m == 6 && d >= 14) || m == 7 || m == 8 || m == 9;
}

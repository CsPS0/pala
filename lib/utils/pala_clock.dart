/// The current time as Pala's screens and demo data see it. Normally this is
/// DateTime.now(); the preview-capture test fixes it (for example to a school
/// Monday morning) so screenshots do not depend on when they are taken.
abstract final class PalaClock {
  static DateTime? _fixed;

  static DateTime now() => _fixed ?? DateTime.now();

  /// Fixes the clock to [time]; null returns to the real time.
  static void fix(DateTime? time) => _fixed = time;
}

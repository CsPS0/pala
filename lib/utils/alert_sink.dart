/// A chat channel the daemon posts its alerts to (Slack, Discord).
///
/// Each sink formats text its own way, so callers never build channel markup
/// themselves: bold goes through [bold], and [send] adds the bold title.
abstract class AlertSink {
  /// True when a valid webhook is configured.
  bool get isEnabled;

  /// Wraps [text] in this channel's bold markup.
  String bold(String text);

  /// Posts one message. Returns false when disabled or when the channel
  /// rejects it. Never throws and never logs the webhook URL.
  Future<bool> send(String title, String message);
}

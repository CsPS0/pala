import 'package:pala/utils/alert_sink.dart';
import 'package:pala/utils/discord_notifier.dart';
import 'package:pala/utils/gemini_summarizer.dart';
import 'package:pala/utils/logger.dart';
import 'package:pala/utils/slack_notifier.dart';

/// One alert of a daemon run. [text] is the full line for the chat channels.
/// [gemini] is the same alert without names or free text (a teacher, a Moodle
/// notification subject), and is the only form that goes to the Gemini prompt.
typedef RunAlert = ({String text, String gemini});

/// Every chat channel that has a valid webhook. Slack and Discord work at the
/// same time, so a move from one to the other needs no gap.
List<AlertSink> configuredAlertSinks(String configDir) {
  return [
    SlackNotifier.fromConfig(configDir),
    DiscordNotifier.fromConfig(configDir),
  ].where((sink) => sink.isEnabled).toList();
}

/// Sends one message to every sink. A failing sink never stops the others.
Future<void> sendToAllSinks(List<AlertSink> sinks, String title, String message) async {
  for (final sink in sinks) {
    try {
      await sink.send(title, message);
    } catch (e) {
      // Sinks are written not to throw; this is only a safety net, and it logs
      // the type because a message could hold a webhook URL.
      PalaLogger.debug('Alert sink failed: ${e.runtimeType}');
    }
  }
}

/// Sends the alerts of one run as a single message per sink. The Gemini
/// summary is added only when there is at least one alert and at least one
/// sink, so a run without news posts nothing and costs no API call. Bold
/// markup is each sink's own (`*x*` for Slack, `**x**` for Discord).
Future<void> sendAlertDigest(
  List<RunAlert> alerts,
  List<AlertSink> sinks,
  GeminiSummarizer gemini,
) async {
  if (alerts.isEmpty || sinks.isEmpty) return;
  final summary = await gemini.summarize(alerts.map((a) => a.gemini).toList());
  final lines = alerts.map((a) => '• ${a.text}').join('\n');
  for (final sink in sinks) {
    final body = summary == null ? lines : '$lines\n\n${sink.bold('Összefoglaló:')} $summary';
    await sendToAllSinks([sink], 'Pala', body);
  }
}

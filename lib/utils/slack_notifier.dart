import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:pala/utils/alert_sink.dart';
import 'package:pala/utils/logger.dart';

/// Posts daemon notifications to a Slack channel through an Incoming Webhook.
///
/// The webhook URL is a secret (anyone holding it can post to the channel), so
/// it is read from the `PALA_SLACK_WEBHOOK` environment variable or from the
/// owner-only `slack_webhook` file in the config directory, never from argv.
class SlackNotifier implements AlertSink {
  final String? webhookUrl;
  final http.Client _client;

  SlackNotifier(this.webhookUrl, {http.Client? client})
      : _client = client ?? http.Client();

  /// Builds a notifier from the environment, falling back to
  /// `<configDir>/slack_webhook`. Returns a disabled notifier when neither is set.
  factory SlackNotifier.fromConfig(String configDir, {http.Client? client}) {
    final fromEnv = Platform.environment['PALA_SLACK_WEBHOOK']?.trim();
    if (fromEnv != null && fromEnv.isNotEmpty) {
      return SlackNotifier(fromEnv, client: client);
    }
    final file = File('$configDir/slack_webhook');
    if (file.existsSync()) {
      final value = file.readAsStringSync().trim();
      if (value.isNotEmpty) return SlackNotifier(value, client: client);
    }
    return SlackNotifier(null, client: client);
  }

  @override
  bool get isEnabled => isValidWebhook(webhookUrl);

  @override
  String bold(String text) => '*$text*';

  /// Only Slack's own webhook host is accepted, so a typo or a tampered config
  /// file cannot send Kréta data to an arbitrary server.
  static bool isValidWebhook(String? url) {
    if (url == null) return false;
    final uri = Uri.tryParse(url);
    return uri != null &&
        uri.scheme == 'https' &&
        uri.host == 'hooks.slack.com' &&
        uri.path.startsWith('/services/');
  }

  /// The Slack message body. Kréta text is sent as plain text inside the JSON
  /// payload, with Slack's control characters escaped so a subject name cannot
  /// trigger @channel pings or fake links.
  static Map<String, dynamic> buildPayload(String title, String message) {
    return {
      'text': '*${escape(title)}*\n${escape(message)}',
      'unfurl_links': false,
    };
  }

  static String escape(String input) => input
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;');

  /// Sends one message. Returns false when disabled or when Slack rejects it.
  /// Errors are logged, never thrown, so a Slack outage does not stop the
  /// desktop notification or the rest of the daemon run.
  @override
  Future<bool> send(String title, String message) async {
    if (!isEnabled) return false;
    try {
      final response = await _client
          .post(
            Uri.parse(webhookUrl!),
            headers: {'Content-Type': 'application/json; charset=utf-8'},
            body: jsonEncode(buildPayload(title, message)),
          )
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) {
        PalaLogger.debug('Slack webhook HTTP ${response.statusCode}: ${response.body}');
        return false;
      }
      return true;
    } catch (e) {
      // The http package puts the request URI (the secret webhook) into
      // ClientException messages, so only the exception type is logged.
      PalaLogger.debug('Slack webhook failed: ${e.runtimeType}');
      return false;
    }
  }
}

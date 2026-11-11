import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:pala/utils/alert_sink.dart';
import 'package:pala/utils/logger.dart';

/// Posts daemon notifications to a Discord channel through a webhook.
///
/// The webhook URL holds a secret token (anyone with it can post to the
/// channel), so it is read from the `PALA_DISCORD_WEBHOOK` environment
/// variable or from the owner-only `discord_webhook` file in the config
/// directory, never from argv, and it is never written to a log.
class DiscordNotifier implements AlertSink {
  /// Discord rejects a message whose content is longer than this.
  static const maxContentLength = 2000;

  static const _hosts = {
    'discord.com',
    'discordapp.com',
    'ptb.discord.com',
    'canary.discord.com',
  };
  static final _pathPattern = RegExp(r'^/api/webhooks/\d+/[A-Za-z0-9_-]+$');
  static const _requestTimeout = Duration(seconds: 15);
  static const _maxRetryWait = Duration(seconds: 30);

  final String? webhookUrl;
  final http.Client _client;
  final Future<void> Function(Duration) _delay;

  /// [delay] is how a rate-limit wait happens; tests pass a recorder so they
  /// do not sleep.
  DiscordNotifier(
    this.webhookUrl, {
    http.Client? client,
    Future<void> Function(Duration)? delay,
  })  : _client = client ?? http.Client(),
        _delay = delay ?? Future.delayed;

  /// Builds a notifier from the environment, falling back to
  /// `<configDir>/discord_webhook`. Returns a disabled notifier when neither
  /// is set.
  factory DiscordNotifier.fromConfig(String configDir, {http.Client? client}) {
    final fromEnv = Platform.environment['PALA_DISCORD_WEBHOOK']?.trim();
    if (fromEnv != null && fromEnv.isNotEmpty) {
      return DiscordNotifier(fromEnv, client: client);
    }
    final file = File('$configDir/discord_webhook');
    if (file.existsSync()) {
      final value = file.readAsStringSync().trim();
      if (value.isNotEmpty) return DiscordNotifier(value, client: client);
    }
    return DiscordNotifier(null, client: client);
  }

  @override
  bool get isEnabled => isValidWebhook(webhookUrl);

  @override
  String bold(String text) => '**$text**';

  /// Only Discord's own webhook hosts are accepted, so a typo or a tampered
  /// config file cannot send Kréta data to an arbitrary server. A port, user
  /// info, query or fragment makes the address invalid.
  static bool isValidWebhook(String? url) {
    if (url == null) return false;
    final uri = Uri.tryParse(url);
    return uri != null &&
        uri.scheme == 'https' &&
        _hosts.contains(uri.host) &&
        !uri.hasPort &&
        uri.userInfo.isEmpty &&
        !uri.hasQuery &&
        !uri.hasFragment &&
        _pathPattern.hasMatch(uri.path);
  }

  /// The request body. `allowed_mentions.parse` is empty, so text that came
  /// from Kréta or Moodle (`@everyone`, `<@123>`) can never ping anyone.
  static Map<String, dynamic> buildPayload(String content) {
    return {
      'content': content,
      'allowed_mentions': {'parse': <String>[]},
    };
  }

  /// Splits [text] into pieces of at most [limit] characters, cutting at line
  /// boundaries. A single line longer than [limit] is cut at the limit, never
  /// in the middle of a surrogate pair.
  static List<String> splitMessage(String text, {int limit = maxContentLength}) {
    if (text.length <= limit) return [text];
    final chunks = <String>[];
    var current = StringBuffer();
    var length = 0;

    void flush() {
      if (length > 0) {
        chunks.add(current.toString());
        current = StringBuffer();
        length = 0;
      }
    }

    for (final line in text.split('\n')) {
      var rest = line;
      while (rest.length > limit) {
        flush();
        var cut = limit;
        final last = rest.codeUnitAt(cut - 1);
        if (last >= 0xD800 && last <= 0xDBFF) cut--;
        chunks.add(rest.substring(0, cut));
        rest = rest.substring(cut);
      }
      final needed = rest.length + (length > 0 ? 1 : 0);
      if (length + needed > limit) flush();
      if (length > 0) {
        current.write('\n');
        length++;
      }
      current.write(rest);
      length += rest.length;
    }
    flush();
    return chunks;
  }

  /// Sends one message, split into several posts when it is over the limit.
  /// Returns false when disabled or when Discord rejects a part. Errors are
  /// logged by type only, never thrown, so a Discord outage does not stop the
  /// rest of the daemon run.
  @override
  Future<bool> send(String title, String message) async {
    if (!isEnabled) return false;
    for (final chunk in splitMessage('${bold(title)}\n$message')) {
      if (chunk.trim().isEmpty) continue;
      if (!await _post(chunk)) return false;
    }
    return true;
  }

  Future<bool> _post(String content) async {
    final body = jsonEncode(buildPayload(content));
    for (var attempt = 0; attempt < 2; attempt++) {
      try {
        final response = await _client
            .post(
              Uri.parse(webhookUrl!),
              headers: {'Content-Type': 'application/json; charset=utf-8'},
              body: body,
            )
            .timeout(_requestTimeout);
        if (response.statusCode == 204) return true;
        if (response.statusCode == 429 && attempt == 0) {
          await _delay(_retryAfter(response));
          continue;
        }
        PalaLogger.debug('Discord webhook HTTP ${response.statusCode}');
        return false;
      } catch (e) {
        // ClientException messages carry the request URI, which holds the
        // secret token, so only the exception type is logged.
        PalaLogger.debug('Discord webhook failed: ${e.runtimeType}');
        return false;
      }
    }
    return false;
  }

  /// How long a 429 asks to wait: `retry_after` (seconds, may be fractional)
  /// in the JSON body, else the `Retry-After` header, else one second. Capped
  /// so a scheduled run cannot hang on a huge value.
  static Duration _retryAfter(http.Response response) {
    num? seconds;
    try {
      final data = jsonDecode(response.body);
      if (data is Map && data['retry_after'] is num) {
        seconds = data['retry_after'] as num;
      }
    } catch (_) {}
    seconds ??= num.tryParse(response.headers['retry-after'] ?? '');
    seconds ??= 1;
    final wait = Duration(milliseconds: (seconds * 1000).round());
    if (wait.isNegative) return Duration.zero;
    return wait > _maxRetryWait ? _maxRetryWait : wait;
  }
}

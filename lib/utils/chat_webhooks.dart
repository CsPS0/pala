import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:pala/utils/alert_sink.dart';
import 'package:pala/utils/discord_notifier.dart';
import 'package:pala/utils/owner_only.dart';
import 'package:pala/utils/slack_notifier.dart';

/// A chat service that can receive Pala's alerts through a webhook.
enum ChatService {
  slack('Slack', 'slack_webhook', 'PALA_SLACK_WEBHOOK'),
  discord('Discord', 'discord_webhook', 'PALA_DISCORD_WEBHOOK');

  const ChatService(this.label, this.fileName, this.envName);

  final String label;

  /// The file in the config directory that holds the webhook URL.
  final String fileName;

  /// The environment variable that wins over the file.
  final String envName;

  bool isValidWebhook(String? url) => switch (this) {
        ChatService.slack => SlackNotifier.isValidWebhook(url),
        ChatService.discord => DiscordNotifier.isValidWebhook(url),
      };
}

/// Saves and removes the webhook files that [SlackNotifier.fromConfig] and
/// [DiscordNotifier.fromConfig] read, so a settings screen can turn chat
/// alerts on without the user editing files by hand.
///
/// A webhook URL is a secret (anyone holding it can post to the channel), so
/// this class never returns a saved URL and never logs one.
class ChatWebhookStore {
  final String configDir;

  /// Stands in for `Platform.environment` in tests.
  final Map<String, String> _environment;

  ChatWebhookStore(this.configDir, {Map<String, String>? environment})
      : _environment = environment ?? Platform.environment;

  File _file(ChatService service) => File('$configDir/${service.fileName}');

  /// True when the webhook comes from the environment variable. The file is
  /// ignored then, so saving or removing it changes nothing.
  bool isSetByEnvironment(ChatService service) => (_environment[service.envName]?.trim() ?? '').isNotEmpty;

  /// True when a valid webhook is saved in the config directory.
  bool hasSaved(ChatService service) {
    final file = _file(service);
    if (!file.existsSync()) return false;
    try {
      return service.isValidWebhook(file.readAsStringSync().trim());
    } catch (_) {
      return false;
    }
  }

  /// Saves [url] for [service]. Returns false and writes nothing when the
  /// address is not one of the service's own webhook addresses.
  bool save(ChatService service, String url) {
    final value = url.trim();
    if (!service.isValidWebhook(value)) return false;
    ensureOwnerOnlyDir(configDir);
    final file = _file(service);
    // Created empty and restricted first, so the secret is never readable by
    // other accounts, not even for a moment.
    file.writeAsStringSync('');
    if (Platform.isLinux || Platform.isMacOS) {
      try {
        Process.runSync('chmod', ['600', file.path]);
      } catch (_) {}
    }
    file.writeAsStringSync(value);
    return true;
  }

  void remove(ChatService service) {
    final file = _file(service);
    if (file.existsSync()) file.deleteSync();
  }

  /// The notifier for [service], enabled only when a webhook is configured.
  AlertSink sink(ChatService service, {http.Client? client}) => switch (service) {
        ChatService.slack => SlackNotifier.fromConfig(configDir, client: client),
        ChatService.discord => DiscordNotifier.fromConfig(configDir, client: client),
      };
}

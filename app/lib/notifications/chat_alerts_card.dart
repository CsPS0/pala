import 'dart:io';

import 'package:material_ui/material_ui.dart';
import 'package:pala/utils/alert_sink.dart';
import 'package:pala/utils/chat_webhooks.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/pala_theme.dart';

/// Settings card that turns Slack and Discord alerts on: the user pastes a
/// webhook address, the card checks it and saves it where the background
/// check (Android) and `pala --daemon` (desktop) read it.
///
/// The saved address is a secret, so it is never shown again; the card only
/// says whether one is set.
class ChatAlertsCard extends StatefulWidget {
  final ChatWebhookStore store;

  /// Stands in for the real notifier in tests.
  final AlertSink Function(ChatService service)? sinkFor;

  const ChatAlertsCard({super.key, required this.store, this.sinkFor});

  @override
  State<ChatAlertsCard> createState() => _ChatAlertsCardState();
}

class _ChatAlertsCardState extends State<ChatAlertsCard> {
  static const _help = {
    ChatService.slack: (
      steps: 'Az api.slack.com/apps oldalon: Create New App, Incoming Webhooks bekapcsolása, '
          'Add New Webhook to Workspace, majd másold ki a címet.',
      hint: 'https://hooks.slack.com/services/...',
      url: 'https://api.slack.com/messaging/webhooks',
    ),
    ChatService.discord: (
      steps: 'A csatornán: Csatorna szerkesztése, Integrációk, Webhookok, Új webhook, '
          'majd Webhook URL másolása.',
      hint: 'https://discord.com/api/webhooks/...',
      url: 'https://support.discord.com/hc/articles/228383668',
    ),
  };

  final _controllers = {for (final s in ChatService.values) s: TextEditingController()};
  final _errors = <ChatService, String>{};
  ChatService? _testing;

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _snack(String text, {bool ok = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text), backgroundColor: ok ? PalaTheme.success : PalaTheme.danger),
    );
  }

  void _save(ChatService service) {
    final saved = widget.store.save(service, _controllers[service]!.text);
    setState(() {
      if (saved) {
        _errors.remove(service);
        _controllers[service]!.clear();
      } else {
        _errors[service] = 'Ez nem ${service.label} webhook cím. Így kell kezdődnie: ${_help[service]!.hint}';
      }
    });
    if (saved) _snack('${service.label} webhook elmentve.');
  }

  void _remove(ChatService service) {
    widget.store.remove(service);
    setState(() => _errors.remove(service));
    _snack('${service.label} értesítések kikapcsolva.');
  }

  Future<void> _sendTest(ChatService service) async {
    setState(() => _testing = service);
    final sink = widget.sinkFor?.call(service) ?? widget.store.sink(service);
    final ok = await sink.send('Pala', 'Teszt üzenet: a ${service.label} értesítések be vannak állítva.');
    if (!mounted) return;
    setState(() => _testing = null);
    _snack(
      ok
          ? 'Teszt üzenet elküldve, nézd meg a csatornát.'
          : 'Nem sikerült elküldeni. Ellenőrizd a netet, és hogy a webhook még létezik-e.',
      ok: ok,
    );
  }

  String get _whenItRuns {
    if (Platform.isAndroid) {
      return 'A háttérellenőrzés nagyjából 15 percenként fut, és az újdonságokat egy üzenetben küldi el.';
    }
    if (Platform.isIOS) {
      return 'iPhone-on a Pala nem fut a háttérben, ezért innen nem megy üzenet. '
          'Az itt mentett cím csak ezen az eszközön él.';
    }
    return 'Asztali gépen az üzeneteket a háttérellenőrzés (pala --daemon) küldi. Windowson a terminálos Pala '
        'Beállítások menüjében kapcsolható be (Háttér-értesítések beállítása), Linuxon és macOS-en ütemezd cronnal.';
  }

  @override
  Widget build(BuildContext context) {
    final muted = TextStyle(color: PalaTheme.textMuted, fontSize: 12);
    return Material(
      color: PalaTheme.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: PalaTheme.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Slack és Discord értesítések',
              style: TextStyle(color: PalaTheme.text, fontSize: 15, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Text(
              'Nem kötelező. Ha megadsz egy webhook címet, a Pala az új jegyeket, házi feladatokat, '
              'számonkéréseket és óraváltozásokat a csatornádba is elküldi.',
              style: muted,
            ),
            for (final service in ChatService.values) ...[
              const SizedBox(height: 16),
              _buildService(service, muted),
            ],
            const SizedBox(height: 16),
            Text(_whenItRuns, style: muted),
            const SizedBox(height: 8),
            Text(
              'Az üzenet szövege (tantárgy, jegy, helyettesítő tanár neve) a Slackhez vagy a Discordhoz kerül. '
              'A webhook cím titok: aki ismeri, írhat a csatornádba.',
              style: muted,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildService(ChatService service, TextStyle muted) {
    final help = _help[service]!;
    final fromEnv = widget.store.isSetByEnvironment(service);
    final saved = widget.store.hasSaved(service);
    final active = fromEnv || saved;
    final statusColor = active ? PalaTheme.success : PalaTheme.textMuted;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              service.label,
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: PalaTheme.text),
            ),
            const SizedBox(width: 10),
            Icon(active ? Icons.check_circle : Icons.radio_button_unchecked, size: 14, color: statusColor),
            const SizedBox(width: 4),
            Text(
              active ? 'Beállítva' : 'Nincs beállítva',
              style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 6),
        if (fromEnv)
          Text('A cím a ${service.envName} környezeti változóból jön, itt nem módosítható.', style: muted)
        else ...[
          Text(help.steps, style: muted),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  key: ValueKey('webhook-${service.name}'),
                  controller: _controllers[service],
                  obscureText: true,
                  autocorrect: false,
                  enableSuggestions: false,
                  keyboardType: TextInputType.url,
                  onSubmitted: (_) => _save(service),
                  decoration: InputDecoration(
                    hintText: saved ? 'Új cím a cseréhez' : help.hint,
                    errorText: _errors[service],
                    errorMaxLines: 3,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                key: ValueKey('save-${service.name}'),
                onPressed: () => _save(service),
                child: const Text('Mentés'),
              ),
            ],
          ),
        ],
        const SizedBox(height: 4),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            if (active)
              OutlinedButton.icon(
                key: ValueKey('test-${service.name}'),
                onPressed: _testing == null ? () => _sendTest(service) : null,
                icon: const Icon(Icons.send_outlined, size: 16),
                label: Text(_testing == service ? 'Küldés...' : 'Teszt üzenet', style: const TextStyle(fontSize: 12)),
              ),
            if (saved && !fromEnv)
              OutlinedButton.icon(
                key: ValueKey('remove-${service.name}'),
                onPressed: () => _remove(service),
                style: OutlinedButton.styleFrom(
                  foregroundColor: PalaTheme.danger,
                  side: BorderSide(color: PalaTheme.danger),
                ),
                icon: const Icon(Icons.delete_outline, size: 16),
                label: const Text('Törlés', style: TextStyle(fontSize: 12)),
              ),
            TextButton.icon(
              onPressed: () => launchUrl(Uri.parse(help.url), mode: LaunchMode.externalApplication),
              icon: const Icon(Icons.open_in_new, size: 14),
              label: const Text('Részletes útmutató', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
      ],
    );
  }
}

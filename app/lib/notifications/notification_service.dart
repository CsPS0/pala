import 'dart:io';
import 'package:awesome_notifications/awesome_notifications.dart';

/// Thin wrapper around awesome_notifications, scoped to what Pala needs:
/// one channel, fire-and-forget alerts. Picked over flutter_local_notifications
/// because that package's only Dart-resolvable version here (8.2.0 — the
/// CLI's `interact` dependency pins an old `ffi` that blocks anything newer)
/// ships an Android build script that predates AGP 9 and fails to build.
/// awesome_notifications has no such conflict and is a real Flutter plugin,
/// so it's auto-registered on the headless engine workmanager spins up too.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  bool _initialized = false;

  static const _channelKey = 'pala_updates';

  bool get _supported => Platform.isAndroid || Platform.isIOS;

  Future<void> init() async {
    if (_initialized || !_supported) return;
    await AwesomeNotifications().initialize(null, [
      NotificationChannel(
        channelKey: _channelKey,
        channelName: 'Kréta frissítések',
        channelDescription: 'Új jegyek, házi feladatok, dolgozatok és órarendváltozások.',
        importance: NotificationImportance.High,
      ),
    ]);
    _initialized = true;
  }

  /// Android 13+ and iOS both require an explicit runtime grant.
  Future<void> requestPermission() async {
    if (!_supported) return;
    await init();
    final allowed = await AwesomeNotifications().isNotificationAllowed();
    if (!allowed) {
      await AwesomeNotifications().requestPermissionToSendNotifications();
    }
  }

  Future<void> show(String title, String body) async {
    if (!_supported) return;
    await init();
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
        channelKey: _channelKey,
        title: title,
        body: body,
      ),
    );
  }
}

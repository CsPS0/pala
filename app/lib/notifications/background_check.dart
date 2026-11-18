import 'dart:io';
import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import 'package:pala/api/client.dart';
import 'package:pala/app/state/app_state.dart';
import 'package:pala/utils/alert_digest.dart';
import 'package:pala/utils/encryption.dart';
import 'package:pala/utils/gemini_summarizer.dart';
import '../state/session_store.dart';
import 'notification_service.dart';

const backgroundTaskUniqueName = 'pala_check_updates';
const backgroundTaskName = 'pala_check_updates_task';

/// Runs on Android's WorkManager, in a separate headless engine — this is
/// how notifications fire even when the app isn't open. Must stay a
/// top-level function (workmanager looks it up by name in the background
/// isolate, a class method reference wouldn't survive that).
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    await checkForUpdatesAndNotify();
    return true;
  });
}

/// Same checks as the desktop CLI daemon (lib/app/daemon/daemon_logic.dart):
/// new grades/homework, tomorrow's exams, and today/tomorrow's cancelled or
/// substituted lessons. Kept separate from that file because it needs its
/// own session loading (no CLI process context here) and Flutter-only
/// notification/storage APIs.
///
/// Every alert also goes to the chat channels set up in Settings (Slack,
/// Discord), as one message per run, like the daemon's digest.
Future<void> checkForUpdatesAndNotify() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isAndroid || Platform.isIOS) {
    final dir = await getApplicationSupportDirectory();
    AppState.configDirOverride = dir.path;
    EncryptionUtil.configDirOverride = dir.path;
    AppState.cacheDirOverride = '${(await getTemporaryDirectory()).path}/pala';
  }
  await SessionStore.initKey();

  final session = await SessionStore.load();
  if (session == null) return;

  final client = KretaClient(instituteCode: session['instituteCode']!);
  client.accessToken = session['accessToken'];
  client.refreshToken = session['refreshToken'];
  SessionStore.attach(client);

  final prefs = await SharedPreferences.getInstance();
  final alerts = <RunAlert>[];
  try {
    await _runChecks(client, prefs, alerts);
  } finally {
    // Sent even when a later check failed, so alerts that were already shown
    // on the phone are not lost for the chat channels.
    final configDir = AppState.instance.configDir;
    await sendAlertDigest(alerts, configuredAlertSinks(configDir), GeminiSummarizer.fromConfig(configDir));
  }
}

/// Shows a phone notification and queues the same line for the chat digest.
/// [geminiText] is the line without names, the only form a Gemini summary
/// may see (see [RunAlert]).
Future<void> _alert(List<RunAlert> alerts, String message, {String? geminiText}) async {
  alerts.add((text: message, gemini: geminiText ?? message));
  await NotificationService.instance.show('Pala (Kréta)', message);
}

Future<void> _runChecks(KretaClient client, SharedPreferences prefs, List<RunAlert> alerts) async {
  final grades = await client.getGrades();
  if (grades != null) {
    final oldCount = prefs.getInt('pala_bg_grades_count') ?? 0;
    if (oldCount > 0 && grades.length > oldCount) {
      await _alert(alerts, 'Kaptál ${grades.length - oldCount} új jegyet!');
    }
    await prefs.setInt('pala_bg_grades_count', grades.length);
  }

  final homework = await client.getHomework(start: DateTime.now().subtract(const Duration(days: 7)));
  if (homework != null) {
    final oldCount = prefs.getInt('pala_bg_homework_count') ?? 0;
    if (oldCount > 0 && homework.length > oldCount) {
      await _alert(alerts, 'Kaptál ${homework.length - oldCount} új házi feladatot!');
    }
    await prefs.setInt('pala_bg_homework_count', homework.length);
  }

  final exams = await client.getExams();
  if (exams != null) {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    for (final exam in exams) {
      if (exam.date != null && _isSameDay(exam.date!, tomorrow)) {
        await _alert(alerts, 'Holnap dolgozat: ${exam.subject} (${exam.mode})');
        break;
      }
    }
  }

  await _checkScheduleChanges(client, prefs, alerts);
}

bool _isSameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

Future<void> _checkScheduleChanges(KretaClient client, SharedPreferences prefs, List<RunAlert> alerts) async {
  final today = DateTime.now();
  final start = DateTime(today.year, today.month, today.day);
  final end = start.add(const Duration(days: 2));

  final lessons = await client.getTimetable(start, end);
  if (lessons == null) return;

  final changed = lessons.where((l) => l.isCancelled || (l.substituteTeacher?.isNotEmpty ?? false));
  final notifiedIds = (prefs.getStringList('pala_bg_notified_schedule_ids') ?? []).toSet();

  for (final lesson in changed) {
    final id = lesson.uid ?? '${lesson.date}_${lesson.lessonNumber}_${lesson.subject}';
    if (notifiedIds.contains(id)) continue;

    final dayLabel = _isSameDay(lesson.date ?? today, today) ? 'Ma' : 'Holnap';
    if (lesson.isCancelled) {
      await _alert(alerts, '$dayLabel elmarad: ${lesson.subject} (${lesson.lessonNumber}. óra)');
    } else {
      await _alert(
        alerts,
        '$dayLabel helyettesítés: ${lesson.subject} — ${lesson.substituteTeacher}',
        geminiText: '$dayLabel helyettesítés: ${lesson.subject}',
      );
    }
    notifiedIds.add(id);
  }

  final currentIds = lessons.map((l) => l.uid ?? '${l.date}_${l.lessonNumber}_${l.subject}').toSet();
  notifiedIds.retainWhere(currentIds.contains);
  await prefs.setStringList('pala_bg_notified_schedule_ids', notifiedIds.toList());
}

part of '../cli_app.dart';

extension PalaAppDaemonLogic on PalaApp {
  Future<void> _checkNewItems() async {
      final state = AppState.instance;
      final oldGradesCount = int.tryParse(state.getAuthData()['gradesCount']?.toString() ?? '0') ?? 0;
      
      final grades = await _client!.getGrades();
      if (grades != null) {
        if (grades.length > oldGradesCount && oldGradesCount > 0) {
          final newGradesCount = grades.length - oldGradesCount;
          await _showToast('Pala (Kréta)', 'Kaptál $newGradesCount új jegyet!');
        }
        final currentData = state.getAuthData();
        currentData['gradesCount'] = grades.length;
        state.saveAuthData(currentData);
      }
  
      final oldHwCount = int.tryParse(state.getAuthData()['homeworkCount']?.toString() ?? '0') ?? 0;
      final homeworks = await _client!.getHomework(start: DateTime.now().subtract(Duration(days: 7)));
      if (homeworks != null) {
        if (homeworks.length > oldHwCount && oldHwCount > 0) {
          final newHwCount = homeworks.length - oldHwCount;
          await _showToast('Pala (Kréta)', 'Kaptál $newHwCount új házi feladatot!');
        }
        final currentData = state.getAuthData();
        currentData['homeworkCount'] = homeworks.length;
        state.saveAuthData(currentData);
      }

      final exams = await _client!.getExams();
      if (exams != null) {
        final tomorrow = DateTime.now().add(Duration(days: 1));
        final tomorrowStr = '${tomorrow.year}-${tomorrow.month.toString().padLeft(2, '0')}-${tomorrow.day.toString().padLeft(2, '0')}';

        for (var exam in exams) {
          final examDateStr = exam.date?.toString().split(' ').first;
          if (examDateStr == tomorrowStr) {
            await _showToast('Pala (Kréta)', 'Holnap dolgozat: ${exam.subject} (${exam.mode})');
            break;
          }
        }
      }

      await _checkScheduleChanges();
    }

  bool _isSameDay(DateTime? a, DateTime b) {
    return a != null && a.year == b.year && a.month == b.month && a.day == b.day;
  }

  // Kréta only marks a substitution or cancellation once it's decided, so a
  // student otherwise finds out by opening the timetable. This mirrors the
  // grade/homework check above but tracks notified lesson ids instead of a
  // count, since "new" here means "changed", not "added".
  Future<void> _checkScheduleChanges() async {
    final state = AppState.instance;
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day);
    final end = start.add(Duration(days: 2));

    final lessons = await _client!.getTimetable(start, end);
    if (lessons == null) return;

    final changed = lessons.where((l) => l.isCancelled || (l.substituteTeacher?.isNotEmpty ?? false));

    final authData = state.getAuthData();
    final notifiedIds = ((authData['notifiedScheduleChangeIds'] as List?)?.map((e) => e.toString()) ?? const <String>[]).toSet();

    for (final lesson in changed) {
      final id = lesson.uid ?? '${lesson.date}_${lesson.lessonNumber}_${lesson.subject}';
      if (notifiedIds.contains(id)) continue;

      final dayLabel = _isSameDay(lesson.date, today) ? 'Ma' : 'Holnap';
      if (lesson.isCancelled) {
        await _showToast('Pala (Kréta)', '$dayLabel elmarad: ${lesson.subject} (${lesson.lessonNumber}. óra)');
      } else {
        await _showToast('Pala (Kréta)', '$dayLabel helyettesítés: ${lesson.subject} — ${lesson.substituteTeacher}');
      }
      notifiedIds.add(id);
    }

    final currentIds = lessons.map((l) => l.uid ?? '${l.date}_${l.lessonNumber}_${l.subject}').toSet();
    notifiedIds.retainWhere(currentIds.contains);

    authData['notifiedScheduleChangeIds'] = notifiedIds.toList();
    state.saveAuthData(authData);
  }

  Future<void> _showToast(String title, String message) async {
      final safeTitle = title.replaceAll("'", "''").replaceAll('"', '\\"');
      final safeMessage = message.replaceAll("'", "''").replaceAll('"', '\\"');
      
      if (Platform.isWindows) {
        final script = '''
  [Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime] > \$null
  \$template = [Windows.UI.Notifications.ToastNotificationManager]::GetTemplateContent([Windows.UI.Notifications.ToastTemplateType]::ToastText02)
  \$texts = \$template.GetElementsByTagName("text")
  \$texts[0].AppendChild(\$template.CreateTextNode('$safeTitle')) > \$null
  \$texts[1].AppendChild(\$template.CreateTextNode('$safeMessage')) > \$null
  \$toast = [Windows.UI.Notifications.ToastNotification]::new(\$template)
  \$notifier = [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier("Pala")
  \$notifier.Show(\$toast)
  ''';
        await Process.run('powershell', ['-Command', script]);
      } else if (Platform.isLinux) {
        await Process.run('notify-send', [title, message]);
      } else if (Platform.isMacOS) {
        final script = 'display notification "$safeMessage" with title "$safeTitle"';
        await Process.run('osascript', ['-e', script]);
      }
    }

  void _setupDaemon(bool enable) {
    if (enable) {
      installDaemon();
    } else {
      uninstallDaemon();
    }
  }

  void installDaemon() {
    if (!Platform.isWindows) return;
    try {
      final exePath = Platform.resolvedExecutable;
      final script = '''
\$action = New-ScheduledTaskAction -Execute "$exePath" -Argument "--daemon"
\$trigger = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Minutes 60)
Register-ScheduledTask -Action \$action -Trigger \$trigger -TaskName "PalaDaemon" -Description "Pala háttérfolyamat (értesítések)" -Force
''';
      Process.runSync('powershell', ['-Command', script]);
      print('Háttérfolyamat sikeresen telepítve (óránként fut).');
    } catch (e) {
      print('Hiba a telepítés során: \$e');
    }
  }

  void uninstallDaemon() {
    if (!Platform.isWindows) return;
    try {
      Process.runSync('schtasks', ['/Delete', '/TN', 'PalaDaemon', '/F']);
      try {
        Process.runSync('schtasks', ['/Delete', '/TN', 'FolioCLIDaemon', '/F']);
      } catch (_) {}
      print('Háttérfolyamat eltávolítva.');
    } catch (e) {
      print('Hiba az eltávolítás során: \$e');
    }
  }
}

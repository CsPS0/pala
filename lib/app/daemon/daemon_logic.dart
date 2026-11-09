part of '../cli_app.dart';

extension PalaAppDaemonLogic on PalaApp {
  Future<void> _checkNewItems() async {
      final state = AppState.instance;
      final oldGradesCount = int.tryParse(state.getAuthData()['gradesCount']?.toString() ?? '0') ?? 0;
      
      final grades = await _client!.getGrades();
      if (grades != null) {
        if (grades.length > oldGradesCount && oldGradesCount > 0) {
          final newGradesCount = grades.length - oldGradesCount;
          // Kréta grades carry no stable id, so the newest ones by date stand
          // in for "the new ones" when listing them.
          final newest = [...grades]
            ..sort((a, b) => (b.date ?? DateTime(0)).compareTo(a.date ?? DateTime(0)));
          final details = newest
              .take(newGradesCount)
              .map((g) => '${g.subject}: ${g.displayValue}${g.theme != null && g.theme!.isNotEmpty ? ' (${g.theme})' : ''}')
              .join('\n');
          await _showToast('Pala (Kréta)', 'Kaptál $newGradesCount új jegyet!\n$details');
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
        await _checkExams(exams);
      }

      await _checkScheduleChanges();
    }

  // The daemon runs on a timer (hourly by default), so every notification is
  // remembered by exam id. Without that, a scheduled run would repeat the same
  // "tomorrow" reminder every hour, which is noise on Slack.
  // Two notices per exam: one when it first appears in Kréta, one the day before.
  Future<void> _checkExams(List<Exam> exams) async {
    final state = AppState.instance;
    final authData = state.getAuthData();
    final firstRun = authData['notifiedExamIds'] == null;
    final announced = ((authData['notifiedExamIds'] as List?)?.map((e) => e.toString()) ?? const <String>[]).toSet();
    final reminded = ((authData['remindedExamIds'] as List?)?.map((e) => e.toString()) ?? const <String>[]).toSet();

    final today = DateTime.now();
    final startOfToday = DateTime(today.year, today.month, today.day);
    final tomorrow = startOfToday.add(const Duration(days: 1));

    final upcoming = exams.where((e) => e.date != null && !e.date!.isBefore(startOfToday)).toList()
      ..sort((a, b) => a.date!.compareTo(b.date!));

    for (final exam in upcoming) {
      final id = exam.uid ?? '${exam.date}_${exam.subject}_${exam.mode}';
      final d = exam.date!;
      final dateLabel = '${d.year}.${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')}.';
      final theme = (exam.theme != null && exam.theme!.isNotEmpty) ? '\nTéma: ${exam.theme}' : '';

      // On the very first run every existing exam would look new; record them
      // silently instead of flooding the channel.
      if (!announced.contains(id)) {
        if (!firstRun) {
          await _showToast('Pala (Kréta)', 'Új számonkérés: ${exam.subject} (${exam.mode}), $dateLabel$theme');
        }
        announced.add(id);
      }

      if (_isSameDay(d, tomorrow) && !reminded.contains(id)) {
        await _showToast('Pala (Kréta)', 'Holnap ${exam.mode.toLowerCase()}: ${exam.subject}$theme');
        reminded.add(id);
      }
    }

    final currentIds = upcoming.map((e) => e.uid ?? '${e.date}_${e.subject}_${e.mode}').toSet();
    announced.retainWhere(currentIds.contains);
    reminded.retainWhere(currentIds.contains);

    authData['notifiedExamIds'] = announced.toList();
    authData['remindedExamIds'] = reminded.toList();
    state.saveAuthData(authData);
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
        await _showToast('Pala (Kréta)', '$dayLabel helyettesítés: ${lesson.subject} — ${lesson.substituteTeacher}',
            geminiText: '$dayLabel helyettesítés: ${lesson.subject}');
      }
      notifiedIds.add(id);
    }

    final currentIds = lessons.map((l) => l.uid ?? '${l.date}_${l.lessonNumber}_${l.subject}').toSet();
    notifiedIds.retainWhere(currentIds.contains);

    authData['notifiedScheduleChangeIds'] = notifiedIds.toList();
    state.saveAuthData(authData);
  }

  // The text comes from Kréta (subject and teacher names), so it is passed as
  // data (environment variables or argv) and never spliced into script source.
  //
  // [geminiText] is what the Gemini summary sees instead of [message]. Pass it
  // whenever the message holds a person's name or free text from a server
  // (a teacher, a Moodle notification), so only subjects, grades, dates and
  // course or deadline titles reach Gemini.
  Future<void> _showToast(String title, String message, {String? geminiText}) async {
      // Slack goes first: it is the channel that reaches the phone, and a
      // missing desktop notifier (no notify-send on a server or in Termux)
      // must not block it.
      final collecting = _runAlerts;
      if (collecting != null) {
        collecting.add((slack: message, gemini: geminiText ?? message));
      } else {
        await SlackNotifier.fromConfig(AppState.instance.configDir).send(title, message);
      }

      if (Platform.isWindows) {
        const script = r'''
  [Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime] > $null
  $template = [Windows.UI.Notifications.ToastNotificationManager]::GetTemplateContent([Windows.UI.Notifications.ToastTemplateType]::ToastText02)
  $texts = $template.GetElementsByTagName("text")
  $texts[0].AppendChild($template.CreateTextNode($env:PALA_TOAST_TITLE)) > $null
  $texts[1].AppendChild($template.CreateTextNode($env:PALA_TOAST_MESSAGE)) > $null
  $toast = [Windows.UI.Notifications.ToastNotification]::new($template)
  $notifier = [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier("Pala")
  $notifier.Show($toast)
  ''';
        await Process.run('powershell', ['-NoProfile', '-Command', script],
            environment: {'PALA_TOAST_TITLE': title, 'PALA_TOAST_MESSAGE': message});
      } else if (Platform.isLinux) {
        // Termux and headless servers have no notify-send.
        try {
          await Process.run('notify-send', [title, message]);
        } on ProcessException catch (_) {}
      } else if (Platform.isMacOS) {
        await Process.run('osascript', [
          '-e', 'on run argv',
          '-e', 'display notification (item 1 of argv) with title (item 2 of argv)',
          '-e', 'end run',
          message,
          title,
        ]);
      }
    }

  /// Sends the alerts of one run as a single Slack message. The Gemini
  /// summary is added only when there is at least one alert, so a run without
  /// news posts nothing and costs no API call.
  Future<void> _flushAlertsToSlack(List<({String slack, String gemini})> alerts) async {
    if (alerts.isEmpty) return;
    final configDir = AppState.instance.configDir;
    final slack = SlackNotifier.fromConfig(configDir);
    if (!slack.isEnabled) return;
    final summary = await GeminiSummarizer.fromConfig(configDir).summarize(alerts.map((a) => a.gemini).toList());
    final body = StringBuffer(alerts.map((a) => '• ${a.slack}').join('\n'));
    if (summary != null) {
      body.write('\n\nÖsszefoglaló: $summary');
    }
    await slack.send('Pala', body.toString());
  }

  // Moodle is optional: it runs only when PALA_MOODLE_URL is set. The first run
  // logs in with PALA_MOODLE_USER and PALA_MOODLE_PASSWORD and keeps only the
  // token in the auth data, later runs reuse that token.
  Future<void> _checkMoodle() async {
    final url = Platform.environment['PALA_MOODLE_URL']?.trim();
    if (url == null || url.isEmpty) return;
    if (!MoodleClient.isValidBaseUrl(url)) {
      await _showToast('Pala (Moodle)', 'A PALA_MOODLE_URL érvénytelen, https cím kell.');
      return;
    }

    final state = AppState.instance;
    var authData = state.getAuthData();
    final moodle = MoodleClient(url, token: authData['moodleToken']?.toString());

    try {
      if (moodle.token == null) {
        final user = Platform.environment['PALA_MOODLE_USER'];
        final password = Platform.environment['PALA_MOODLE_PASSWORD'];
        if (user == null || password == null) return;
        await moodle.login(user, password);
        authData = state.getAuthData();
        authData['moodleToken'] = moodle.token;
        state.saveAuthData(authData);
      }

      final firstRun = authData['moodleNotifiedIds'] == null;
      final seenNotifications =
          ((authData['moodleNotifiedIds'] as List?)?.map((e) => e.toString()) ?? const <String>[]).toSet();
      final seenEvents =
          ((authData['moodleEventIds'] as List?)?.map((e) => e.toString()) ?? const <String>[]).toSet();

      final notifications = await moodle.getNotifications();
      if (notifications != null) {
        for (final n in notifications) {
          if (seenNotifications.add('${n.id}') && !firstRun) {
            // Notification subjects often name the sender or the poster.
            await _showToast('Pala (Moodle)', 'Moodle: ${n.subject}', geminiText: 'Új Moodle értesítés');
          }
        }
        seenNotifications.retainWhere(notifications.map((n) => '${n.id}').toSet().contains);
      }

      final events = await moodle.getUpcomingEvents();
      if (events != null) {
        for (final e in events) {
          if (seenEvents.add('${e.id}') && !firstRun) {
            final due = e.due;
            final dueLabel = due == null
                ? ''
                : ', határidő: ${due.year}.${due.month.toString().padLeft(2, '0')}.${due.day.toString().padLeft(2, '0')}.';
            final course = e.course != null ? ' (${e.course})' : '';
            await _showToast('Pala (Moodle)', 'Új Moodle esemény: ${e.name}$course$dueLabel');
          }
        }
        seenEvents.retainWhere(events.map((e) => '${e.id}').toSet().contains);
      }

      authData = state.getAuthData();
      authData['moodleNotifiedIds'] = seenNotifications.toList();
      authData['moodleEventIds'] = seenEvents.toList();
      state.saveAuthData(authData);
    } on MoodleLoginException catch (e) {
      // Drop a dead token so the next run logs in again.
      authData = state.getAuthData();
      authData.remove('moodleToken');
      state.saveAuthData(authData);
      await _showToast('Pala (Moodle)', '$e');
    } catch (e) {
      PalaLogger.debug('Moodle ellenőrzés sikertelen: $e');
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

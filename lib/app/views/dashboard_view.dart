part of '../cli_app.dart';

extension PalaAppDashboardView on PalaApp {
  Future<void> _showDashboard() async {
    if (!await _ensureClientReady()) return;

    final state = TuiWorkspaceState()..isDemo = isDemo;
    final screenBuffer = TuiScreenBuffer();
    final console = Console();
    final client = _client!;

    // Fetches run in the background while keys keep being handled. A newer
    // request bumps its generation, so an older one finishing late is dropped.
    var syncGeneration = 0;
    var timetableGeneration = 0;
    var inFlight = 0;
    var dirty = true;

    Future<void> loadDashboardData({bool timetableOnly = false}) async {
      final sync = timetableOnly ? syncGeneration : ++syncGeneration;
      final timetable = ++timetableGeneration;
      inFlight++;
      state.isLoading = true;
      state.statusBannerMessage = 'Adatok szinkronizálása a Kréta szerverrel...';
      dirty = true;

      final now = DateTime.now();
      final midnight = DateTime(now.year, now.month, now.day);
      final startOfWeek = midnight.subtract(Duration(days: now.weekday - 1));
      final endOfNextWeek = startOfWeek.add(
        const Duration(days: 13, hours: 23, minutes: 59, seconds: 59),
      );

      try {
        if (timetableOnly) {
          final tt = await client.getTimetable(
            startOfWeek,
            endOfNextWeek,
            overrideAWeek: state.overrideAWeek,
          );
          final wt = await client.getWeekType(
            startOfWeek,
            overrideAWeek: state.overrideAWeek,
          );
          if (timetable != timetableGeneration) return;
          state.timetable = tt ?? state.timetable;
          state.weekTypeLabel = wt;
        } else {
          final results = await Future.wait([
            client.getGrades(),
            client.getTimetable(
              startOfWeek,
              endOfNextWeek,
              overrideAWeek: state.overrideAWeek,
            ),
            client.getAverages(),
            client.getGroupAverages(),
            client.getAbsences(),
            client.getExams(),
            client.getHomework(),
            client.getMessages(),
            client.getStudentData(silent: true),
            client.getWeekType(
              startOfWeek,
              overrideAWeek: state.overrideAWeek,
            ),
          ]);
          if (sync != syncGeneration) return;

          // A failed endpoint returns null: keep what is already on screen.
          state.grades = (results[0] as List<Grade>?) ?? state.grades;
          if (timetable == timetableGeneration) {
            state.timetable = (results[1] as List<TimetableEntry>?) ?? state.timetable;
            state.weekTypeLabel = results[9] as String?;
          }
          final averages = results[2] as List<dynamic>?;
          if (averages != null) {
            state.averages = averages
                .whereType<Map>()
                .map((e) => Map<String, dynamic>.from(e))
                .toList();
          }
          final groupAverages = results[3] as List<dynamic>?;
          if (groupAverages != null) {
            state.groupAverages = groupAverages
                .whereType<Map>()
                .map((e) => Map<String, dynamic>.from(e))
                .toList();
          }
          state.absences = (results[4] as List<Absence>?) ?? state.absences;
          state.exams = (results[5] as List<Exam>?) ?? state.exams;
          state.homeworks = (results[6] as List<Homework>?) ?? state.homeworks;
          state.messages = (results[7] as List<Message>?) ?? state.messages;
          state.student = (results[8] as Student?) ?? state.student;
        }

        state.isMaintenance = client.isMaintenanceMode;
        state.maintenanceStatusCode = client.maintenanceStatusCode;
        state.sessionExpired = client.sessionExpired;
        state.isNetworkDown = client.isNetworkDown;
        if (state.sessionExpired) {
          state.statusBannerMessage =
              'A munkamenet lejárt, a mentett adatokat látod. Lépj ki (q) és jelentkezz be újra.';
        } else if (state.isNetworkDown) {
          state.statusBannerMessage =
              'Nincs kapcsolat a Kréta szerverrel, a mentett adatokat látod. Újrapróbálás: [r]';
        } else if (state.isMaintenance) {
          state.statusBannerMessage =
              'A Kréta karbantartás alatt áll, a mentett adatokat látod. Újrapróbálás: [r]';
        } else {
          state.lastSync = DateTime.now();
          state.statusBannerMessage = timetableOnly
              ? 'Órarend frissítve (${state.weekTypeLabel ?? "Alapértelmezett"}).'
              : 'Sikeres szinkronizálás.';
        }
      } catch (e) {
        PalaLogger.debug('Dashboard sync failed: $e');
        if (sync == syncGeneration && timetable == timetableGeneration) {
          state.statusBannerMessage =
              'Hiba a szinkronizálás közben, a mentett adatokat látod. Újrapróbálás: [r]';
        }
      } finally {
        inFlight--;
        state.isLoading = inFlight > 0;
        dirty = true;
      }
    }

    // The client prints its offline/limit notices; inside the alternate screen
    // those would scroll the frame, so they go to the debug log instead. The
    // zone follows the fetch even if it finishes after the dashboard closed.
    void startLoad({bool timetableOnly = false}) {
      runZoned(
        () => unawaited(loadDashboardData(timetableOnly: timetableOnly)),
        zoneSpecification: ZoneSpecification(
          print: (self, parent, zone, line) => PalaLogger.debug(line),
        ),
      );
    }

    screenBuffer.enter();
    try {
      // Raw for the whole session, so keys pressed during a fetch are queued
      // instead of being echoed into the frame.
      if (stdin.hasTerminal) console.rawMode = true;
      startLoad();
      if (!stdin.hasTerminal) {
        while (inFlight > 0) {
          await Future.delayed(const Duration(milliseconds: 20));
        }
      }

      var lastCols = 0;
      var lastRows = 0;
      var running = true;
      while (running) {
        // Re-read every tick: Windows has no SIGWINCH, and polling covers resizes everywhere.
        final cols = stdout.hasTerminal ? stdout.terminalColumns : 100;
        final rows = stdout.hasTerminal ? stdout.terminalLines : 32;
        if (dirty || cols != lastCols || rows != lastRows) {
          screenBuffer.render(
            TuiViews.buildScreen(state, width: cols, height: rows),
            width: cols,
            height: rows,
          );
          dirty = false;
          lastCols = cols;
          lastRows = rows;
        }

        if (!stdin.hasTerminal) {
          break;
        }

        final key = readKeyNonBlocking();
        if (key == null) {
          await Future.delayed(const Duration(milliseconds: 30));
          continue;
        }
        dirty = true;
        state.statusBannerMessage = null;

        if (key.isControl) {
          switch (key.controlChar) {
            case ControlCharacter.tab:
              state.togglePane();
              break;
            case ControlCharacter.arrowUp:
              if (state.activePane == TuiPane.left) {
                final prev =
                    (state.activeTab - 1 + TuiWorkspaceState.tabTitles.length) %
                        TuiWorkspaceState.tabTitles.length;
                state.switchTab(prev);
              } else {
                state.currentScroll = state.currentScroll - 1;
              }
              break;
            case ControlCharacter.arrowDown:
              if (state.activePane == TuiPane.left) {
                final next =
                    (state.activeTab + 1) % TuiWorkspaceState.tabTitles.length;
                state.switchTab(next);
              } else {
                state.currentScroll = state.currentScroll + 1;
              }
              break;
            case ControlCharacter.pageUp:
              state.currentScroll = state.currentScroll - 10;
              break;
            case ControlCharacter.pageDown:
              state.currentScroll = state.currentScroll + 10;
              break;
            case ControlCharacter.arrowLeft:
              if (state.ghostDrawerOpen) {
                final subjs = state.availableSubjects;
                if (subjs.isNotEmpty) {
                  state.ghostSubjectIndex =
                      (state.ghostSubjectIndex - 1 + subjs.length) %
                          subjs.length;
                }
              } else if (state.activeTab == 2 && state.timetableSubMode == 1) {
                state.timetableDayOffset = max(0, state.timetableDayOffset - 1);
              } else {
                final prev =
                    (state.activeTab - 1 + TuiWorkspaceState.tabTitles.length) %
                        TuiWorkspaceState.tabTitles.length;
                state.switchTab(prev);
              }
              break;
            case ControlCharacter.arrowRight:
              if (state.ghostDrawerOpen) {
                final subjs = state.availableSubjects;
                if (subjs.isNotEmpty) {
                  state.ghostSubjectIndex =
                      (state.ghostSubjectIndex + 1) % subjs.length;
                }
              } else if (state.activeTab == 2 && state.timetableSubMode == 1) {
                state.timetableDayOffset = state.timetableDayOffset + 1;
              } else {
                final next =
                    (state.activeTab + 1) % TuiWorkspaceState.tabTitles.length;
                state.switchTab(next);
              }
              break;
            case ControlCharacter.enter:
              if (state.ghostDrawerOpen) {
                state.addCurrentGhostGrade();
              } else if (state.activePane == TuiPane.left) {
                state.activePane = TuiPane.right;
              }
              break;
            case ControlCharacter.escape:
              if (state.ghostDrawerOpen) {
                state.ghostDrawerOpen = false;
              } else {
                running = false;
              }
              break;
            case ControlCharacter.ctrlC:
              running = false;
              break;
            default:
              break;
          }
          continue;
        }

        final ch = key.char;
        if (ch.isEmpty) continue;
        final lower = ch.toLowerCase();

        // When Szellem Jegy drawer is open, 1-5 sets the simulated grade value
        if (state.ghostDrawerOpen &&
            (ch == '1' || ch == '2' || ch == '3' || ch == '4' || ch == '5')) {
          state.ghostGradeValue = int.parse(ch);
          continue;
        }

        switch (lower) {
          case '1':
            state.switchTab(0);
            break;
          case '2':
            state.switchTab(1);
            break;
          case '3':
            state.switchTab(2);
            break;
          case '4':
            state.switchTab(3);
            break;
          case 'j':
            if (state.activePane == TuiPane.left) {
              state.switchTab(
                (state.activeTab + 1) % TuiWorkspaceState.tabTitles.length,
              );
            } else {
              state.currentScroll = state.currentScroll + 1;
            }
            break;
          case 'k':
            if (state.activePane == TuiPane.left) {
              state.switchTab(
                (state.activeTab - 1 + TuiWorkspaceState.tabTitles.length) %
                    TuiWorkspaceState.tabTitles.length,
              );
            } else {
              state.currentScroll = state.currentScroll - 1;
            }
            break;
          case 'h':
            if (state.ghostDrawerOpen) {
              final subjs = state.availableSubjects;
              if (subjs.isNotEmpty) {
                state.ghostSubjectIndex =
                    (state.ghostSubjectIndex - 1 + subjs.length) % subjs.length;
              }
            } else if (state.activeTab == 2 && state.timetableSubMode == 1) {
              state.timetableDayOffset = max(0, state.timetableDayOffset - 1);
            } else {
              state.switchTab(
                (state.activeTab - 1 + TuiWorkspaceState.tabTitles.length) %
                    TuiWorkspaceState.tabTitles.length,
              );
            }
            break;
          case 'l':
            if (state.ghostDrawerOpen) {
              final subjs = state.availableSubjects;
              if (subjs.isNotEmpty) {
                state.ghostSubjectIndex =
                    (state.ghostSubjectIndex + 1) % subjs.length;
              }
            } else if (state.activeTab == 2 && state.timetableSubMode == 1) {
              state.timetableDayOffset = state.timetableDayOffset + 1;
            } else {
              state.switchTab(
                (state.activeTab + 1) % TuiWorkspaceState.tabTitles.length,
              );
            }
            break;
          case 'r':
            if (!state.isLoading) startLoad();
            break;
          case 's':
            state.ghostDrawerOpen = !state.ghostDrawerOpen;
            break;
          case 'c':
            state.clearGhostGrades();
            break;
          case 'v':
            state.gradesSubMode = (state.gradesSubMode + 1) % 2;
            state.currentScroll = 0;
            break;
          case 'w':
            if (state.ghostDrawerOpen) {
              state.ghostWeightIndex =
                  (state.ghostWeightIndex + 1) %
                      TuiWorkspaceState.weightPresets.length;
            } else {
              state.timetableSubMode = (state.timetableSubMode + 1) % 2;
              state.currentScroll = 0;
            }
            break;
          case 'a':
            final curA = state.overrideAWeek ??
                (state.weekTypeLabel?.toLowerCase().startsWith('a') ?? true);
            state.overrideAWeek = !curA;
            startLoad(timetableOnly: true);
            break;
          case '0':
            state.timetableDayOffset = 0;
            break;
          case 'e':
            if (state.timetable.isNotEmpty || state.exams.isNotEmpty) {
              try {
                final icsContent =
                    IcsExporter.generate(state.timetable, state.exams);
                final home = Platform.environment['USERPROFILE'] ??
                    Platform.environment['HOME'] ??
                    '.';
                final desktop = Directory(p.join(home, 'Desktop'));
                final outDir = desktop.existsSync() ? desktop.path : home;
                final file = File(p.join(outDir, 'pala_naptar.ics'));
                await file.writeAsString(icsContent);
                state.statusBannerMessage =
                    'Naptár exportálva: ${file.path}';
              } catch (err) {
                state.statusBannerMessage = 'Export hiba: $err';
              }
            } else {
              state.statusBannerMessage = 'Nincs exportálható órarendi adat.';
            }
            break;
          case 'f':
            state.absenceFilter = (state.absenceFilter + 1) %
                TuiWorkspaceState.absenceFilterLabels.length;
            state.currentScroll = 0;
            break;
          case 'q':
            running = false;
            break;
          default:
            break;
        }
      }
    } finally {
      screenBuffer.exit();
      try {
        if (stdin.hasTerminal) console.rawMode = false;
      } catch (e) {
        PalaLogger.debug('Failed to leave raw mode: $e');
      }
      try {
        if (stdin.hasTerminal) {
          stdin.echoMode = true;
          stdin.lineMode = true;
        }
      } catch (e) {
        PalaLogger.debug('Failed to restore terminal mode: $e');
      }
      forceRestoreConsoleMode();
    }
  }
}

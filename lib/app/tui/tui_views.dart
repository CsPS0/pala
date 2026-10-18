import 'dart:math';

import '../../models/models.dart';
import '../../version.dart';
import '../state/app_state.dart';
import '../theme.dart';
import 'screen_buffer.dart';
import 'tui_state.dart';

/// Modular TUI view builders for the Pala terminal workspace.
class TuiViews {
  /// Builds the complete full-screen frame for the given terminal [width] and [height].
  static List<String> buildScreen(
    TuiWorkspaceState state, {
    required int width,
    required int height,
  }) {
    final safeWidth = max(60, width);
    final safeHeight = max(18, height);

    final headerBox = buildHeaderBar(state, width: safeWidth);
    final ghostBox = state.ghostDrawerOpen
        ? buildGhostSimulatorBar(state, width: safeWidth)
        : const <String>[];
    final footerBox = buildFooterBar(state, width: safeWidth);

    final bodyHeight = max(
      8,
      safeHeight - headerBox.length - ghostBox.length - footerBox.length,
    );

    List<String> bodyLines;
    if (safeWidth >= 82) {
      // Responsive dual-pane layout: Left Pane (Nav/Overview) + Right Pane (Main Content)
      final leftWidth = (safeWidth * 0.30).round().clamp(28, 36);
      final rightWidth = safeWidth - leftWidth - 1;

      final leftPane = buildLeftPane(
        state,
        width: leftWidth,
        height: bodyHeight,
      );
      final rightPane = buildRightPane(
        state,
        width: rightWidth,
        height: bodyHeight,
      );
      bodyLines = TuiScreenBuffer.joinColumns(
        leftPane,
        leftWidth,
        rightPane,
        rightWidth,
        gap: ' ',
      );
    } else {
      // Compact single-pane layout for narrow viewports (< 82 columns)
      bodyLines = buildRightPane(
        state,
        width: safeWidth,
        height: bodyHeight,
      );
    }

    return <String>[
      ...headerBox,
      ...bodyLines,
      ...ghostBox,
      ...footerBox,
    ];
  }

  /// Builds the top Header Bar with Pala logo, logged-in student, active term,
  /// and Kréta connection status indicator inside a rounded Unicode box.
  static List<String> buildHeaderBar(
    TuiWorkspaceState state, {
    required int width,
  }) {
    final innerContentWidth = max(10, width - 4);
    final now = DateTime.now();
    final schoolYearStart = now.month >= 9 ? now.year : now.year - 1;
    final semester = (now.month >= 9 || now.month == 1) ? 'I. félév' : 'II. félév';
    final weekTag =
        (state.weekTypeLabel != null && state.weekTypeLabel!.isNotEmpty)
            ? ' · ${state.weekTypeLabel}'
            : '';
    final termLabel = '$schoolYearStart/${schoolYearStart + 1} · $semester$weekTag';

    final studentName = state.student?.name ?? (state.isDemo ? 'Teszt Elek' : 'Diák');
    final instName = state.student?.institutionName ??
        (state.isDemo ? 'Pala Minta Gimnázium' : '');
    final userDisplay = instName.isNotEmpty && innerContentWidth >= 90
        ? '$studentName ${PalaTheme.muted}($instName)${PalaTheme.reset}'
        : studentName;

    String statusBadge;
    if (state.isLoading) {
      statusBadge = '\x1B[1;38;5;45m◌ SZINKRONIZÁLÁS...${PalaTheme.reset}';
    } else if (state.sessionExpired) {
      statusBadge = '${PalaTheme.grade1Fg}● MUNKAMENET LEJÁRT${PalaTheme.reset}';
    } else if (state.isNetworkDown) {
      statusBadge = '${PalaTheme.grade1Fg}● NINCS KAPCSOLAT (GYORSÍTÓTÁR)${PalaTheme.reset}';
    } else if (state.isMaintenance) {
      statusBadge =
          '${PalaTheme.absencePendingFg}● KARBANTARTÁS (${state.maintenanceStatusCode ?? "HTTP"})${PalaTheme.reset}';
    } else if (AppState.instance.isOffline) {
      statusBadge = '${PalaTheme.grade1Fg}● OFFLINE (GYORSÍTÓTÁR)${PalaTheme.reset}';
    } else if (state.isDemo) {
      statusBadge = '${PalaTheme.primaryBold}● DEMÓ MÓD${PalaTheme.reset}';
    } else {
      statusBadge = '${PalaTheme.grade5Fg}● KRÉTA ONLINE${PalaTheme.reset}';
    }

    final syncTime =
        '${state.lastSync.hour.toString().padLeft(2, '0')}:${state.lastSync.minute.toString().padLeft(2, '0')}:${state.lastSync.second.toString().padLeft(2, '0')}';

    final logoBadge =
        '\x1B[48;5;208m\x1B[1;38;5;232m ◆ PALA TUI \x1B[0m ${PalaTheme.muted}v$appVersion${PalaTheme.reset}';
    final leftPart =
        '$logoBadge  ${PalaTheme.borderMuted}│${PalaTheme.reset}  ${PalaTheme.textBright}$userDisplay${PalaTheme.reset}';
    final rightPart =
        '${PalaTheme.borderHighlight}$termLabel${PalaTheme.reset}  ${PalaTheme.borderMuted}│${PalaTheme.reset}  $statusBadge ${PalaTheme.muted}[$syncTime]${PalaTheme.reset}';

    final leftVis = TuiScreenBuffer.visibleLength(leftPart);
    final rightVis = TuiScreenBuffer.visibleLength(rightPart);

    String headerLine;
    if (leftVis + rightVis + 2 <= innerContentWidth) {
      final spaces = innerContentWidth - leftVis - rightVis;
      headerLine = '$leftPart${' ' * spaces}$rightPart';
    } else {
      final maxLeft = max(10, innerContentWidth - rightVis - 2);
      final truncLeft = TuiScreenBuffer.truncateAnsi(leftPart, maxLeft);
      final gap = max(
        1,
        innerContentWidth -
            TuiScreenBuffer.visibleLength(truncLeft) -
            rightVis,
      );
      headerLine = '$truncLeft${' ' * gap}$rightPart';
    }

    return TuiScreenBuffer.drawRoundedBox(
      width: width,
      height: 3,
      lines: [headerLine],
      customBorderColor: PalaTheme.borderMuted,
    );
  }

  /// Builds the Left Pane containing Navigation, Overall GPA badge,
  /// Today's Timetable Summary, and Unread Notices Counter.
  static List<String> buildLeftPane(
    TuiWorkspaceState state, {
    required int width,
    required int height,
  }) {
    final isFocused = state.activePane == TuiPane.left;
    final innerW = max(12, width - 4);
    final lines = <String>[];

    // 1. Navigation items
    for (var i = 0; i < TuiWorkspaceState.tabTitles.length; i++) {
      final isSelected = state.activeTab == i;
      final label = '[${i + 1}] ${TuiWorkspaceState.tabTitles[i]}';
      if (isSelected) {
        final marker = isFocused ? '▸' : '•';
        lines.add(
          '\x1B[48;5;236m${PalaTheme.primaryBold} $marker ${TuiScreenBuffer.padRightAnsi(label, max(1, innerW - 3))}${PalaTheme.reset}',
        );
      } else {
        lines.add('   ${PalaTheme.muted}[${i + 1}]${PalaTheme.reset} ${TuiWorkspaceState.tabTitles[i]}');
      }
    }

    // 2. Overall GPA Badge & Best/Worst Subject
    lines.add('__DIVIDER__${PalaTheme.primaryBold}Tanulmányi Átlag${PalaTheme.reset}');
    final baseGpa = state.overallGpa(includeGhost: false);
    final simGpa = state.overallGpa(includeGhost: true);
    final gpaColor = PalaTheme.averageColor(simGpa);
    final gpaText = simGpa > 0 ? simGpa.toStringAsFixed(2) : '--';

    String deltaStr = '';
    if (state.ghostGrades.isNotEmpty && baseGpa > 0) {
      final diff = simGpa - baseGpa;
      final sign = diff >= 0 ? '+' : '';
      final dColor = diff >= 0 ? PalaTheme.grade5Fg : PalaTheme.grade1Fg;
      deltaStr = ' $dColor($sign${diff.toStringAsFixed(2)})${PalaTheme.reset}';
    }

    lines.add(
      'Átlag: $gpaColor$gpaText${PalaTheme.reset}$deltaStr',
    );
    final barWidth = max(8, innerW - 2);
    final gpaRatio = simGpa > 0 ? ((simGpa - 1.0) / 4.0).clamp(0.0, 1.0) : 0.0;
    lines.add(
      TuiScreenBuffer.progressBar(
        gpaRatio,
        barWidth,
        fillColor: gpaColor,
        useThinLine: true,
      ),
    );

    final subjects = state.availableSubjects;
    if (subjects.isNotEmpty) {
      String? bestSub;
      var bestVal = 0.0;
      String? worstSub;
      var worstVal = 6.0;
      for (final s in subjects) {
        final avg = state.subjectAverage(s, includeGhost: true);
        if (avg > 0) {
          if (avg > bestVal) {
            bestVal = avg;
            bestSub = s;
          }
          if (avg < worstVal) {
            worstVal = avg;
            worstSub = s;
          }
        }
      }
      if (bestSub != null) {
        final alias = AppState.instance.applyAlias(bestSub);
        lines.add(
          '${PalaTheme.muted}Csúcs:${PalaTheme.reset} ${TuiScreenBuffer.truncateAnsi(alias, max(6, innerW - 13))} ${PalaTheme.grade5Fg}${bestVal.toStringAsFixed(2)}${PalaTheme.reset}',
        );
      }
      if (worstSub != null) {
        final alias = AppState.instance.applyAlias(worstSub);
        final wColor = PalaTheme.averageColor(worstVal);
        lines.add(
          '${PalaTheme.muted}Minimum:${PalaTheme.reset} ${TuiScreenBuffer.truncateAnsi(alias, max(6, innerW - 15))} $wColor${worstVal.toStringAsFixed(2)}${PalaTheme.reset}',
        );
      }
    }

    // 3. Today's Timetable Summary
    lines.add('__DIVIDER__${PalaTheme.borderHighlight}Mai Órarend${PalaTheme.reset}');
    final todayLessons = _getTodayOrNextLessons(state);
    final now = DateTime.now();

    if (todayLessons.isEmpty) {
      lines.add('${PalaTheme.muted}Nincs rögzített óra mára.${PalaTheme.reset}');
    } else {
      final firstDate = todayLessons.first.date;
      final isToday = firstDate != null &&
          firstDate.year == now.year &&
          firstDate.month == now.month &&
          firstDate.day == now.day;
      if (!isToday && firstDate != null) {
        final dateLabel =
            '${firstDate.month.toString().padLeft(2, '0')}.${firstDate.day.toString().padLeft(2, '0')}.';
        lines.add('${PalaTheme.muted}Következő nap ($dateLabel):${PalaTheme.reset}');
      }

      for (final lesson in todayLessons.take(max(2, height - lines.length - 8))) {
        final startStr = lesson.startTime != null
            ? '${lesson.startTime!.hour.toString().padLeft(2, '0')}:${lesson.startTime!.minute.toString().padLeft(2, '0')}'
            : '--:--';
        final subName = AppState.instance.applyAlias(lesson.subject);
        final isActive = isToday &&
            lesson.startTime != null &&
            lesson.endTime != null &&
            now.isAfter(lesson.startTime!) &&
            now.isBefore(lesson.endTime!);
        final isPast =
            isToday && lesson.endTime != null && lesson.endTime!.isBefore(now);

        String tag = '';
        String rowColor = '';
        if (lesson.isCancelled) {
          rowColor = PalaTheme.grade1Fg;
          tag = ' [ELM]';
        } else if (lesson.substituteTeacher != null &&
            lesson.substituteTeacher!.isNotEmpty) {
          rowColor = PalaTheme.grade3Fg;
          tag = ' [HELY]';
        } else if (isActive) {
          rowColor = PalaTheme.grade5Fg;
          tag = ' <';
        } else if (isPast) {
          rowColor = PalaTheme.muted;
        }

        final roomStr =
            (lesson.room != null && lesson.room!.isNotEmpty) ? ' (${lesson.room})' : '';
        lines.add(
          '$rowColor${lesson.lessonNumber}. $startStr $subName$roomStr$tag${PalaTheme.reset}',
        );
      }
    }

    // 4. Unread Notices & Alerts Counter
    lines.add('__DIVIDER__${PalaTheme.primaryBold}Értesítések${PalaTheme.reset}');
    final unreadMsgs = state.unreadMessagesCount;
    final activeHw = state.activeHomeworkCount;
    final upcomingEx = state.upcomingExamsCount;
    final unexcused = state.unexcusedHours;
    final pending = state.pendingHours;

    final msgColor = unreadMsgs > 0 ? PalaTheme.primaryBold : PalaTheme.muted;
    final hwColor = activeHw > 0 ? PalaTheme.borderHighlight : PalaTheme.muted;
    final exColor = upcomingEx > 0 ? PalaTheme.grade3Fg : PalaTheme.muted;
    final absColor = unexcused > 0
        ? PalaTheme.absenceUnexcusedFg
        : (pending > 0 ? PalaTheme.absencePendingFg : PalaTheme.absenceExcusedFg);

    lines.add('Üzenetek (új):   $msgColor$unreadMsgs db${PalaTheme.reset}');
    lines.add('Házi feladatok:  $hwColor$activeHw db${PalaTheme.reset}');
    lines.add('Számonkérések:   $exColor$upcomingEx db${PalaTheme.reset}');
    lines.add(
      'Igazolatlan/Függő: $absColor$unexcused / $pending óra${PalaTheme.reset}',
    );

    return TuiScreenBuffer.drawRoundedBox(
      width: width,
      height: height,
      title: isFocused
          ? '${PalaTheme.primaryBold}Navigáció [AKTÍV]${PalaTheme.reset}'
          : '${PalaTheme.textBright}Navigáció & Áttekintés${PalaTheme.reset}',
      rightBadge: '${PalaTheme.muted}[Tab]${PalaTheme.reset}',
      lines: lines,
      focused: isFocused,
    );
  }

  /// Builds the Right Pane with the Tab Bar and the currently active view's content.
  static List<String> buildRightPane(
    TuiWorkspaceState state, {
    required int width,
    required int height,
  }) {
    final isFocused = state.activePane == TuiPane.right;
    final innerW = max(20, width - 4);
    final viewportRows = max(4, height - 2);

    // Build top tab bar title
    final tabChips = <String>[];
    for (var i = 0; i < TuiWorkspaceState.tabTitles.length; i++) {
      final label = '[${i + 1}] ${TuiWorkspaceState.tabTitles[i]}';
      if (state.activeTab == i) {
        tabChips.add('\x1B[48;5;208m\x1B[1;38;5;232m $label ${PalaTheme.reset}');
      } else {
        tabChips.add('${PalaTheme.muted}$label${PalaTheme.reset}');
      }
    }
    final tabHeaderTitle = tabChips.join(' ');

    List<String> allContentLines;
    switch (state.activeTab) {
      case 0:
        allContentLines = _buildDashboardTabLines(state, innerW);
        break;
      case 1:
        allContentLines = _buildGradesMatrixTabLines(state, innerW);
        break;
      case 2:
        allContentLines = _buildTimetableTabLines(state, innerW);
        break;
      case 3:
        allContentLines = _buildAbsencesTabLines(state, innerW);
        break;
      default:
        allContentLines = _buildDashboardTabLines(state, innerW);
        break;
    }

    // Apply scroll offset safely
    final maxScroll = max(0, allContentLines.length - viewportRows);
    if (state.currentScroll > maxScroll) {
      state.currentScroll = maxScroll;
    }
    final startRow = state.currentScroll;
    final visibleLines =
        allContentLines.skip(startRow).take(viewportRows).toList();

    final scrollBadge = allContentLines.length > viewportRows
        ? '${PalaTheme.muted}↑↓ ${startRow + 1}-${min(allContentLines.length, startRow + viewportRows)}/${allContentLines.length}${PalaTheme.reset}'
        : '${PalaTheme.muted}${allContentLines.length} sor${PalaTheme.reset}';

    return TuiScreenBuffer.drawRoundedBox(
      width: width,
      height: height,
      title: tabHeaderTitle,
      rightBadge: scrollBadge,
      lines: visibleLines,
      focused: isFocused,
    );
  }

  /// Tab 1: Dashboard (Vezérlőpult)
  static List<String> _buildDashboardTabLines(
    TuiWorkspaceState state,
    int width,
  ) {
    final lines = <String>[];
    final now = DateTime.now();

    // 1. Live Class Countdown Banner
    final todayLessons = state.timetable.where((l) {
      final d = l.date;
      return d != null &&
          d.year == now.year &&
          d.month == now.month &&
          d.day == now.day;
    }).toList()
      ..sort((a, b) => a.lessonNumber.compareTo(b.lessonNumber));

    TimetableEntry? activeLesson;
    TimetableEntry? nextLesson;
    for (final l in todayLessons) {
      if (l.startTime != null &&
          l.endTime != null &&
          now.isAfter(l.startTime!) &&
          now.isBefore(l.endTime!)) {
        activeLesson = l;
        break;
      }
      if (l.startTime != null && l.startTime!.isAfter(now) && nextLesson == null) {
        nextLesson = l;
      }
    }

    final heroLines = <String>[];
    if (activeLesson != null) {
      final totalMins = max(
        1,
        activeLesson.endTime!.difference(activeLesson.startTime!).inMinutes,
      );
      final elapsedMins =
          now.difference(activeLesson.startTime!).inMinutes.clamp(0, totalMins);
      final remMins =
          activeLesson.endTime!.difference(now).inMinutes.clamp(0, totalMins);
      final ratio = elapsedMins / totalMins;
      final sub = AppState.instance.applyAlias(activeLesson.subject);
      final room = activeLesson.room ?? '-';
      final teacher = activeLesson.substituteTeacher?.isNotEmpty == true
          ? '${activeLesson.substituteTeacher} (Helyettesítés!)'
          : (activeLesson.teacher ?? '-');

      heroLines.add(
        '${PalaTheme.grade5Fg}● AKTUÁLIS ÓRA:${PalaTheme.reset} ${PalaTheme.textBright}${activeLesson.lessonNumber}. $sub${PalaTheme.reset}  ${PalaTheme.surfaceBadge} Terem: $room ${PalaTheme.reset}  ${PalaTheme.muted}Tanár: $teacher${PalaTheme.reset}',
      );
      final pBar = TuiScreenBuffer.progressBar(
        ratio,
        max(10, width - 32),
        fillColor: PalaTheme.grade5Fg,
      );
      heroLines.add(
        'Hátralévő idő: ${PalaTheme.primaryBold}$remMins perc${PalaTheme.reset}  $pBar ${(ratio * 100).round()}%',
      );
    } else if (nextLesson != null) {
      final diffMins = max(0, nextLesson.startTime!.difference(now).inMinutes);
      final sub = AppState.instance.applyAlias(nextLesson.subject);
      final room = nextLesson.room ?? '-';
      final startStr =
          '${nextLesson.startTime!.hour.toString().padLeft(2, '0')}:${nextLesson.startTime!.minute.toString().padLeft(2, '0')}';
      heroLines.add(
        '${PalaTheme.borderHighlight}▸ KÖVETKEZŐ ÓRA ($startStr):${PalaTheme.reset} ${PalaTheme.textBright}${nextLesson.lessonNumber}. $sub${PalaTheme.reset}  ${PalaTheme.surfaceBadge} Terem: $room ${PalaTheme.reset}  ${PalaTheme.primaryBold}$diffMins perc múlva${PalaTheme.reset}',
      );
      if (nextLesson.isCancelled) {
        heroLines.add(
          '${PalaTheme.absenceUnexcusedBadge} ELMARAD ${PalaTheme.reset} Ez az óra elmarad!',
        );
      } else if (nextLesson.substituteTeacher != null &&
          nextLesson.substituteTeacher!.isNotEmpty) {
        heroLines.add(
          '${PalaTheme.absencePendingBadge} HELYETTESÍTÉS ${PalaTheme.reset} Helyettesítő tanár: ${nextLesson.substituteTeacher}',
        );
      }
    } else {
      final nextDayLessons = _getTodayOrNextLessons(state);
      if (todayLessons.isNotEmpty) {
        heroLines.add(
          '${PalaTheme.grade5Fg}✓ A mai tanítási óráid véget értek!${PalaTheme.reset} (${todayLessons.length} tanóra teljesítve)',
        );
      } else if (nextDayLessons.isNotEmpty) {
        final d = nextDayLessons.first.date;
        final dStr = d != null
            ? '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}'
            : 'Következő tanítási nap';
        final firstSub = AppState.instance.applyAlias(nextDayLessons.first.subject);
        heroLines.add(
          '${PalaTheme.borderHighlight}◆ Ma nincs tanítás.${PalaTheme.reset} Következő nap ($dStr): ${nextDayLessons.length} óra (1. óra: ${PalaTheme.textBright}$firstSub${PalaTheme.reset})',
        );
      } else {
        heroLines.add('${PalaTheme.grade5Fg}◆ Ma nincsenek tanítási óráid!${PalaTheme.reset}');
      }
    }

    lines.addAll(TuiScreenBuffer.drawRoundedBox(
      width: width,
      title: '${PalaTheme.primaryBold}Élő Órafigyelő${PalaTheme.reset}',
      lines: heroLines,
    ));

    // 2. KPI Summary Strip
    final simGpa = state.overallGpa(includeGhost: true);
    final gpaColor = PalaTheme.averageColor(simGpa);
    final ghostTag = state.ghostGrades.isNotEmpty
        ? ' ${PalaTheme.gradeGhostFg}[+${state.ghostGrades.length} szellem]${PalaTheme.reset}'
        : '';
    final totalMissed = state.totalMissedHours;
    final unexcused = state.unexcusedHours;
    final absColor = unexcused > 0
        ? PalaTheme.absenceUnexcusedFg
        : (totalMissed >= 200 ? PalaTheme.grade1Fg : PalaTheme.grade5Fg);

    lines.add(
      ' ${PalaTheme.textBright}Súlyozott átlag:${PalaTheme.reset} $gpaColor${simGpa > 0 ? simGpa.toStringAsFixed(2) : "--"}${PalaTheme.reset}$ghostTag   ${PalaTheme.borderMuted}│${PalaTheme.reset}   ${PalaTheme.textBright}Összes jegy:${PalaTheme.reset} ${state.grades.length} db   ${PalaTheme.borderMuted}│${PalaTheme.reset}   ${PalaTheme.textBright}Mulasztás:${PalaTheme.reset} $absColor$totalMissed / 250 óra${PalaTheme.reset} (Igazolatlan: ${unexcused > 0 ? "${PalaTheme.absenceUnexcusedFg}$unexcused${PalaTheme.reset}" : "0"})',
    );
    lines.add('__DIVIDER__');

    // 3. Split Columns: Recent Grades (Left) & Upcoming Exams/Homework (Right)
    final colLeftW = (width * 0.52).round().clamp(24, width - 20);
    final colRightW = max(18, width - colLeftW - 3);

    final recentGradesLines = <String>[
      '${PalaTheme.primaryBold}Legutóbbi Érdemjegyek${PalaTheme.reset}',
    ];
    final sortedGrades = List<Grade>.from(state.grades)
      ..sort(
        (a, b) => (b.date ?? DateTime(2000)).compareTo(a.date ?? DateTime(2000)),
      );

    if (sortedGrades.isEmpty) {
      recentGradesLines.add('${PalaTheme.muted}Nincsenek rögzített jegyek.${PalaTheme.reset}');
    } else {
      for (final g in sortedGrades.take(8)) {
        final pill = PalaTheme.formatGradePill(
          g.numericValue,
          fallback: g.textValue,
        );
        final subj = AppState.instance.applyAlias(g.subject);
        final dateStr = g.date != null
            ? '${g.date!.month.toString().padLeft(2, '0')}.${g.date!.day.toString().padLeft(2, '0')}.'
            : '  -  ';
        final weightStr =
            g.weight != 100 && g.weight > 0 ? ' ${PalaTheme.muted}${g.weight.toInt()}%${PalaTheme.reset}' : '';
        final themeStr =
            (g.theme != null && g.theme!.isNotEmpty) ? ' ${PalaTheme.muted}· ${g.theme}${PalaTheme.reset}' : '';
        recentGradesLines.add(
          '$pill ${PalaTheme.muted}$dateStr${PalaTheme.reset} ${PalaTheme.textBright}$subj${PalaTheme.reset}$weightStr$themeStr',
        );
      }
    }

    final tasksLines = <String>[
      '${PalaTheme.borderHighlight}Közelgő Számonkérések & Házik${PalaTheme.reset}',
    ];
    final cutoff = now.subtract(const Duration(days: 1));
    final upcomingExams = state.exams
        .where((e) => e.date != null && e.date!.isAfter(cutoff))
        .toList()
      ..sort((a, b) => a.date!.compareTo(b.date!));

    if (upcomingExams.isEmpty) {
      tasksLines.add('${PalaTheme.muted}Nincs közelgő számonkérés.${PalaTheme.reset}');
    } else {
      for (final ex in upcomingExams.take(4)) {
        final dStr =
            '${ex.date!.month.toString().padLeft(2, '0')}.${ex.date!.day.toString().padLeft(2, '0')}.';
        final subj = AppState.instance.applyAlias(ex.subject);
        final theme = (ex.theme != null && ex.theme!.isNotEmpty) ? ' (${ex.theme})' : '';
        tasksLines.add(
          '${PalaTheme.grade3Pill} DOLG ${PalaTheme.reset} ${PalaTheme.muted}$dStr${PalaTheme.reset} ${PalaTheme.textBright}$subj${PalaTheme.reset}$theme',
        );
      }
    }

    tasksLines.add('');
    tasksLines.add('${PalaTheme.primaryBold}Aktuális Házi Feladatok${PalaTheme.reset}');
    final upcomingHw = state.homeworks
        .where((h) => h.deadline == null || h.deadline!.isAfter(cutoff))
        .toList();
    if (upcomingHw.isEmpty) {
      tasksLines.add('${PalaTheme.muted}Nincs aktív házi feladat.${PalaTheme.reset}');
    } else {
      for (final hw in upcomingHw.take(3)) {
        final dStr = hw.deadline != null
            ? '${hw.deadline!.month.toString().padLeft(2, '0')}.${hw.deadline!.day.toString().padLeft(2, '0')}.'
            : '--.--';
        final subj = AppState.instance.applyAlias(hw.subject);
        final cleanText = hw.text.replaceAll(RegExp(r'\s+'), ' ').trim();
        tasksLines.add(
          '${PalaTheme.surfaceBadge} HÁZI ${PalaTheme.reset} ${PalaTheme.muted}$dStr${PalaTheme.reset} ${PalaTheme.textBright}$subj${PalaTheme.reset}: $cleanText',
        );
      }
    }

    final splitRows = max(recentGradesLines.length, tasksLines.length);
    for (var i = 0; i < splitRows; i++) {
      final l = i < recentGradesLines.length ? recentGradesLines[i] : '';
      final r = i < tasksLines.length ? tasksLines[i] : '';
      final lPad = TuiScreenBuffer.padRightAnsi(
        TuiScreenBuffer.truncateAnsi(l, colLeftW),
        colLeftW,
      );
      final rPad = TuiScreenBuffer.padRightAnsi(
        TuiScreenBuffer.truncateAnsi(r, colRightW),
        colRightW,
      );
      lines.add('$lPad ${PalaTheme.borderMuted}│${PalaTheme.reset} $rPad');
    }

    return lines;
  }

  /// Tab 2: Grades & Matrix (Jegyek és Mátrix)
  static List<String> _buildGradesMatrixTabLines(
    TuiWorkspaceState state,
    int width,
  ) {
    final lines = <String>[];
    final mode0Active = state.gradesSubMode == 0;
    final modeBadge0 = mode0Active
        ? '\x1B[48;5;208m\x1B[1;38;5;232m Tantárgyi Jegy-Mátrix ${PalaTheme.reset}'
        : '${PalaTheme.muted}Tantárgyi Jegy-Mátrix${PalaTheme.reset}';
    final modeBadge1 = !mode0Active
        ? '\x1B[48;5;208m\x1B[1;38;5;232m Bizonyítvány Tervező & Eloszlás ${PalaTheme.reset}'
        : '${PalaTheme.muted}Bizonyítvány Tervező & Eloszlás${PalaTheme.reset}';

    lines.add(
      '$modeBadge0  $modeBadge1   ${PalaTheme.muted}[v] Nézetváltás  [s] Szellem Jegy (${state.ghostGrades.length} aktív)  [c] Szellem törlés${PalaTheme.reset}',
    );
    lines.add('__DIVIDER__');

    // Legend for Grade Color Psychology
    lines.add(
      '${PalaTheme.muted}Színkód:${PalaTheme.reset} ${PalaTheme.formatGradePill(5)} Jeles(5)  ${PalaTheme.formatGradePill(4)} Jó(4)  ${PalaTheme.formatGradePill(3)} Közepes(3)  ${PalaTheme.formatGradePill(2)} Elégséges(2)  ${PalaTheme.formatGradePill(1)} Elégtelen(1)  ${PalaTheme.formatGradePill(5, isGhost: true)} Szellem',
    );
    lines.add('');

    final subjects = state.availableSubjects;
    if (subjects.isEmpty) {
      lines.add('${PalaTheme.muted}Nincsenek megjeleníthető tantárgyak és jegyek.${PalaTheme.reset}');
      return lines;
    }

    // Map class averages
    final classAvgMap = <String, double>{};
    for (final item in state.groupAverages) {
      final sub = item['Tantargy']?['Nev']?.toString() ?? '';
      final valStr =
          (item['OsztalyAtlag'] ?? item['Atlag'] ?? item['Ertek'] ?? '0').toString();
      final val = double.tryParse(valStr.replaceAll(',', '.')) ?? 0.0;
      if (sub.isNotEmpty && val > 0) {
        classAvgMap[sub.toLowerCase()] = val;
      }
    }

    if (mode0Active) {
      // Tantárgyi Jegy-Mátrix Table with rounded Unicode borders
      final subColW = (width * 0.26).round().clamp(16, 26);
      const trendColW = 5;
      const classColW = 6;
      const avgColW = 12;
      final gradesColW =
          max(14, width - subColW - trendColW - classColW - avgColW - 10);

      final b = PalaTheme.borderMuted;
      final r = PalaTheme.reset;

      lines.add(
        '$b╭${'─' * (subColW + 2)}┬${'─' * (gradesColW + 2)}┬${'─' * (trendColW + 2)}┬${'─' * (classColW + 2)}┬${'─' * (avgColW + 2)}╮$r',
      );
      lines.add(
        '$b│$r ${PalaTheme.textBright}${TuiScreenBuffer.padRightAnsi('Tantárgy', subColW)}$r $b│$r ${PalaTheme.textBright}${TuiScreenBuffer.padRightAnsi('Érdemjegyek (Időrendben)', gradesColW)}$r $b│$r ${PalaTheme.textBright}${TuiScreenBuffer.padCenterAnsi('Trend', trendColW)}$r $b│$r ${PalaTheme.textBright}${TuiScreenBuffer.padCenterAnsi('Oszt.', classColW)}$r $b│$r ${PalaTheme.textBright}${TuiScreenBuffer.padCenterAnsi('Átlag', avgColW)}$r $b│$r',
      );
      lines.add(
        '$b├${'─' * (subColW + 2)}┼${'─' * (gradesColW + 2)}┼${'─' * (trendColW + 2)}┼${'─' * (classColW + 2)}┼${'─' * (avgColW + 2)}┤$r',
      );

      for (final subj in subjects) {
        final displaySub = TuiScreenBuffer.padRightAnsi(
          TuiScreenBuffer.truncateAnsi(
            AppState.instance.applyAlias(subj),
            subColW,
          ),
          subColW,
        );

        final subjGrades = state.grades
            .where((g) =>
                g.subject.toLowerCase() == subj.toLowerCase() &&
                !g.isSummaryGrade)
            .toList()
          ..sort(
            (a, b) =>
                (a.date ?? DateTime(2000)).compareTo(b.date ?? DateTime(2000)),
          );

        final tokens = <String>[];
        for (final g in subjGrades) {
          final val = g.numericValue;
          if (val != null && val >= 1 && val <= 5) {
            final c = PalaTheme.gradeColor(val);
            final boldMarker = g.weight >= 200 ? '!' : '';
            tokens.add('$c$val$boldMarker$r');
          } else if (g.textValue != null && g.textValue!.isNotEmpty) {
            tokens.add('${PalaTheme.muted}${g.textValue}$r');
          }
        }

        // Append simulated ghost grades for this subject
        final subjGhosts = state.ghostGrades
            .where((gg) => gg.subject.toLowerCase() == subj.toLowerCase())
            .toList();
        for (final gg in subjGhosts) {
          tokens.add('${PalaTheme.gradeGhostFg}*${gg.grade}*$r');
        }

        final gradesJoined =
            tokens.isEmpty ? '${PalaTheme.muted}-${PalaTheme.reset}' : tokens.join(' ');
        final gradesCell = TuiScreenBuffer.padRightAnsi(
          TuiScreenBuffer.truncateAnsi(gradesJoined, gradesColW),
          gradesColW,
        );

        final baseAvg = state.subjectAverage(subj, includeGhost: false);
        final simAvg = state.subjectAverage(subj, includeGhost: true);

        // Compute trend from last 3 numeric grades
        final numericOnly = subjGrades
            .where((g) =>
                g.numericValue != null &&
                g.numericValue! >= 1 &&
                g.numericValue! <= 5)
            .toList();
        var trendStr = '${PalaTheme.muted}→$r';
        if (numericOnly.length >= 2 && baseAvg > 0) {
          final recentSlice = numericOnly.length >= 3
              ? numericOnly.sublist(numericOnly.length - 3)
              : numericOnly.sublist(numericOnly.length - 2);
          final recentAvg =
              recentSlice.map((e) => e.numericValue!).reduce((a, b) => a + b) /
                  recentSlice.length;
          if (recentAvg > baseAvg + 0.12) {
            trendStr = '${PalaTheme.grade5Fg}↑$r';
          } else if (recentAvg < baseAvg - 0.12) {
            trendStr = '${PalaTheme.grade1Fg}↓$r';
          }
        }
        final trendCell = TuiScreenBuffer.padCenterAnsi(trendStr, trendColW);

        final classAvg = classAvgMap[subj.toLowerCase()] ?? 0.0;
        final classCell = TuiScreenBuffer.padCenterAnsi(
          classAvg > 0
              ? '${PalaTheme.muted}${classAvg.toStringAsFixed(2)}$r'
              : '${PalaTheme.muted}-$r',
          classColW,
        );

        final avgColor = PalaTheme.averageColor(simAvg);
        String avgText = simAvg > 0 ? '$avgColor${simAvg.toStringAsFixed(2)}$r' : '${PalaTheme.muted}-$r';
        if (subjGhosts.isNotEmpty && baseAvg > 0) {
          final diff = simAvg - baseAvg;
          final sign = diff >= 0 ? '+' : '';
          avgText =
              '$avgColor${simAvg.toStringAsFixed(2)}$r ${PalaTheme.gradeGhostFg}($sign${diff.toStringAsFixed(1)})$r';
        }
        final avgCell = TuiScreenBuffer.padCenterAnsi(avgText, avgColW);

        lines.add(
          '$b│$r $displaySub $b│$r $gradesCell $b│$r $trendCell $b│$r $classCell $b│$r $avgCell $b│$r',
        );
      }

      lines.add(
        '$b╰${'─' * (subColW + 2)}┴${'─' * (gradesColW + 2)}┴${'─' * (trendColW + 2)}┴${'─' * (classColW + 2)}┴${'─' * (avgColW + 2)}╯$r',
      );
    } else {
      // Sub-mode 1: Certificate Planner (Bizonyítvány Tervező) + Grade Distribution
      lines.add('${PalaTheme.primaryBold}Bizonyítvány Tervező (Hány db 100%-os 5-ös kell a következő jegyhez?)${PalaTheme.reset}');
      final subColW = (width * 0.34).round().clamp(18, 32);
      const curColW = 10;
      const targetColW = 8;
      final needColW = max(16, width - subColW - curColW - targetColW - 10);
      final b = PalaTheme.borderMuted;
      final r = PalaTheme.reset;

      lines.add(
        '$b╭${'─' * (subColW + 2)}┬${'─' * (curColW + 2)}┬${'─' * (targetColW + 2)}┬${'─' * (needColW + 2)}╮$r',
      );
      lines.add(
        '$b│$r ${PalaTheme.textBright}${TuiScreenBuffer.padRightAnsi('Tantárgy', subColW)}$r $b│$r ${PalaTheme.textBright}${TuiScreenBuffer.padCenterAnsi('Jelenlegi', curColW)}$r $b│$r ${PalaTheme.textBright}${TuiScreenBuffer.padCenterAnsi('Cél', targetColW)}$r $b│$r ${PalaTheme.textBright}${TuiScreenBuffer.padRightAnsi('Szükséges 100%-os 5-ös', needColW)}$r $b│$r',
      );
      lines.add(
        '$b├${'─' * (subColW + 2)}┼${'─' * (curColW + 2)}┼${'─' * (targetColW + 2)}┼${'─' * (needColW + 2)}┤$r',
      );

      for (final subj in subjects) {
        final subjGrades = state.grades
            .where((g) =>
                g.subject.toLowerCase() == subj.toLowerCase() &&
                !g.isSummaryGrade &&
                g.numericValue != null &&
                g.numericValue! >= 1 &&
                g.numericValue! <= 5)
            .toList();
        var sum = 0.0;
        var wSum = 0.0;
        for (final g in subjGrades) {
          final w = g.weight > 0 ? g.weight : 100.0;
          sum += g.numericValue! * w;
          wSum += w;
        }
        for (final gg in state.ghostGrades) {
          if (gg.subject.toLowerCase() == subj.toLowerCase()) {
            sum += gg.grade * gg.weight;
            wSum += gg.weight;
          }
        }
        if (wSum <= 0) continue;
        final avg = sum / wSum;

        var targetInt = 5;
        var threshold = 4.5;
        if (avg < 1.5) {
          targetInt = 2;
          threshold = 1.5;
        } else if (avg < 2.5) {
          targetInt = 3;
          threshold = 2.5;
        } else if (avg < 3.5) {
          targetInt = 4;
          threshold = 3.5;
        } else {
          targetInt = 5;
          threshold = 4.5;
        }

        String neededText;
        if (avg >= 4.5) {
          neededText = '${PalaTheme.grade5Fg}✓ Elérted a jeles (5) szintet!$r';
        } else {
          final req = ((threshold * wSum - sum) / (500.0 - threshold * 100.0)).ceil();
          neededText = req <= 0
              ? '${PalaTheme.grade5Fg}✓ Elérve!$r'
              : '${PalaTheme.primaryBold}$req db 5-ös$r ${PalaTheme.muted}(${threshold.toStringAsFixed(1)} határhoz)$r';
        }

        final sCell = TuiScreenBuffer.padRightAnsi(
          TuiScreenBuffer.truncateAnsi(AppState.instance.applyAlias(subj), subColW),
          subColW,
        );
        final cCell = TuiScreenBuffer.padCenterAnsi(
          '${PalaTheme.averageColor(avg)}${avg.toStringAsFixed(2)}$r',
          curColW,
        );
        final tCell = TuiScreenBuffer.padCenterAnsi(
          '${PalaTheme.gradeColor(targetInt)}$targetInt.0$r',
          targetColW,
        );
        final nCell = TuiScreenBuffer.padRightAnsi(
          TuiScreenBuffer.truncateAnsi(neededText, needColW),
          needColW,
        );
        lines.add('$b│$r $sCell $b│$r $cCell $b│$r $tCell $b│$r $nCell $b│$r');
      }
      lines.add(
        '$b╰${'─' * (subColW + 2)}┴${'─' * (curColW + 2)}┴${'─' * (targetColW + 2)}┴${'─' * (needColW + 2)}╯$r',
      );

      // Grade distribution histogram
      lines.add('');
      lines.add('${PalaTheme.primaryBold}Érdemjegyek Eloszlása:${PalaTheme.reset}');
      final dist = <int, int>{5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
      var totalValid = 0;
      for (final g in state.grades) {
        if (!g.isSummaryGrade &&
            g.numericValue != null &&
            g.numericValue! >= 1 &&
            g.numericValue! <= 5) {
          final v = g.numericValue!.round();
          dist[v] = (dist[v] ?? 0) + 1;
          totalValid++;
        }
      }
      for (var grade = 5; grade >= 1; grade--) {
        final cnt = dist[grade] ?? 0;
        final ratio = totalValid > 0 ? cnt / totalValid : 0.0;
        final pct = (ratio * 100).toStringAsFixed(1).padLeft(5);
        final bar = TuiScreenBuffer.progressBar(
          ratio,
          max(12, width - 36),
          fillColor: PalaTheme.gradeColor(grade),
        );
        lines.add(
          ' ${PalaTheme.formatGradePill(grade)}  $bar  ${cnt.toString().padLeft(3)} db ($pct%)',
        );
      }
    }

    return lines;
  }

  /// Tab 3: Timetable (Órarend)
  static List<String> _buildTimetableTabLines(
    TuiWorkspaceState state,
    int width,
  ) {
    final lines = <String>[];
    final isWeekly = state.timetableSubMode == 0;
    final modeChip0 = isWeekly
        ? '\x1B[48;5;208m\x1B[1;38;5;232m Heti Mátrix ${PalaTheme.reset}'
        : '${PalaTheme.muted}Heti Mátrix${PalaTheme.reset}';
    final modeChip1 = !isWeekly
        ? '\x1B[48;5;208m\x1B[1;38;5;232m Napi Részletes ${PalaTheme.reset}'
        : '${PalaTheme.muted}Napi Részletes${PalaTheme.reset}';
    final abText = state.weekTypeLabel ?? 'Alapértelmezett hét';

    lines.add(
      '$modeChip0  $modeChip1   ${PalaTheme.borderHighlight}[$abText]${PalaTheme.reset}   ${PalaTheme.muted}[w] Nézet  [a] A/B hét  [←/→] Nap/Hét  [0] Ma  [e] .ics Export${PalaTheme.reset}',
    );
    lines.add('__DIVIDER__');

    if (state.timetable.isEmpty) {
      lines.add('${PalaTheme.muted}Nincsenek órák rögzítve erre az időszakra.${PalaTheme.reset}');
      return lines;
    }

    if (isWeekly) {
      var minLesson = 99;
      var maxLesson = -1;
      var maxWeekday = 5;
      final matrix = <int, Map<int, List<TimetableEntry>>>{};

      for (final entry in state.timetable) {
        final d = entry.date;
        if (d == null) continue;
        final w = d.weekday;
        if (w > 7) continue;
        if (w > maxWeekday) maxWeekday = w;
        final num = entry.lessonNumber;
        if (num > 20) continue;
        if (num < minLesson) minLesson = num;
        if (num > maxLesson) maxLesson = num;
        matrix.putIfAbsent(num, () => {});
        matrix[num]!.putIfAbsent(w, () => []).add(entry);
      }

      if (minLesson > maxLesson) {
        lines.add('${PalaTheme.muted}Nincs megjeleníthető órarendi mátrix.${PalaTheme.reset}');
        return lines;
      }

      const dayNames = [
        'Hétfő',
        'Kedd',
        'Szerda',
        'Csütörtök',
        'Péntek',
        'Szombat',
        'Vasárnap',
      ];
      const oraColW = 5;
      final colWidth =
          ((width - oraColW - 2 - maxWeekday) ~/ maxWeekday).clamp(11, 26);
      final b = PalaTheme.borderMuted;
      final r = PalaTheme.reset;

      var top = '$b╭${'─' * oraColW}';
      var head = '$b│$r ${PalaTheme.textBright}Óra$r ';
      var mid = '$b├${'─' * oraColW}';
      var bot = '$b╰${'─' * oraColW}';

      for (var w = 1; w <= maxWeekday; w++) {
        top += '┬${'─' * colWidth}';
        head +=
            '$b│$r ${PalaTheme.primaryBold}${TuiScreenBuffer.padRightAnsi(dayNames[w - 1], colWidth - 1)}$r';
        mid += '┼${'─' * colWidth}';
        bot += '┴${'─' * colWidth}';
      }
      top += '╮$r';
      head += '$b│$r';
      mid += '┤$r';
      bot += '╯$r';

      lines.add(top);
      lines.add(head);
      lines.add(mid);

      for (var ora = minLesson; ora <= maxLesson; ora++) {
        final rowTop = <String>[];
        final rowSub = <String>[];

        for (var w = 1; w <= maxWeekday; w++) {
          final cellLessons = matrix[ora]?[w] ?? const [];
          if (cellLessons.isEmpty) {
            rowTop.add(TuiScreenBuffer.padRightAnsi('', colWidth - 1));
            rowSub.add(TuiScreenBuffer.padRightAnsi('', colWidth - 1));
          } else {
            final entry = cellLessons.first;
            final sub = AppState.instance.applyAlias(entry.subject);
            final truncSub = TuiScreenBuffer.truncateAnsi(sub, colWidth - 2);

            String styledSub;
            if (entry.isCancelled) {
              styledSub = '${PalaTheme.grade1Fg}$truncSub$r';
            } else if (entry.substituteTeacher != null &&
                entry.substituteTeacher!.isNotEmpty) {
              styledSub = '${PalaTheme.grade3Fg}$truncSub$r';
            } else {
              styledSub = '${PalaTheme.textBright}$truncSub$r';
            }
            rowTop.add(TuiScreenBuffer.padRightAnsi(styledSub, colWidth - 1));

            String meta;
            if (entry.isCancelled) {
              meta = '${PalaTheme.grade1Fg}[ELMARAD]$r';
            } else if (entry.substituteTeacher != null &&
                entry.substituteTeacher!.isNotEmpty) {
              meta =
                  '${PalaTheme.grade3Fg}Hely: ${entry.substituteTeacher}$r';
            } else {
              final rm = entry.room != null && entry.room!.isNotEmpty
                  ? '[${entry.room}] '
                  : '';
              final tch = entry.teacher != null
                  ? AppState.instance.applyAlias(entry.teacher!)
                  : '';
              meta = '${PalaTheme.muted}$rm$tch$r';
            }
            rowSub.add(
              TuiScreenBuffer.padRightAnsi(
                TuiScreenBuffer.truncateAnsi(meta, colWidth - 2),
                colWidth - 1,
              ),
            );
          }
        }

        var line1 = '$b│$r ${ora.toString().padLeft(2)}. $b│$r';
        var line2 = '$b│$r     $b│$r';
        for (var w = 0; w < maxWeekday; w++) {
          line1 += ' ${rowTop[w]}$b│$r';
          line2 += ' ${rowSub[w]}$b│$r';
        }
        lines.add(line1);
        lines.add(line2);
        if (ora < maxLesson) {
          lines.add(mid);
        }
      }
      lines.add(bot);
    } else {
      // Daily detailed view
      final uniqueDays = <DateTime>[];
      final seen = <String>{};
      for (final l in state.timetable) {
        if (l.date == null) continue;
        final key =
            '${l.date!.year}-${l.date!.month.toString().padLeft(2, '0')}-${l.date!.day.toString().padLeft(2, '0')}';
        if (seen.add(key)) {
          uniqueDays.add(DateTime(l.date!.year, l.date!.month, l.date!.day));
        }
      }
      uniqueDays.sort();

      if (uniqueDays.isEmpty) {
        lines.add('${PalaTheme.muted}Nincs megjeleníthető nap.${PalaTheme.reset}');
        return lines;
      }

      final dayIdx = state.timetableDayOffset.clamp(0, uniqueDays.length - 1);
      final targetDay = uniqueDays[dayIdx];
      const weekdayNames = [
        'Hétfő',
        'Kedd',
        'Szerda',
        'Csütörtök',
        'Péntek',
        'Szombat',
        'Vasárnap',
      ];
      final dayTitle =
          '${targetDay.year}-${targetDay.month.toString().padLeft(2, '0')}-${targetDay.day.toString().padLeft(2, '0')} (${weekdayNames[targetDay.weekday - 1]}) — Nap ${dayIdx + 1}/${uniqueDays.length}';
      lines.add('${PalaTheme.primaryBold}$dayTitle${PalaTheme.reset}');
      lines.add('');

      final dayLessons = state.timetable
          .where((l) =>
              l.date != null &&
              l.date!.year == targetDay.year &&
              l.date!.month == targetDay.month &&
              l.date!.day == targetDay.day)
          .toList()
        ..sort((a, b) => a.lessonNumber.compareTo(b.lessonNumber));

      for (final l in dayLessons) {
        final start = l.startTime != null
            ? '${l.startTime!.hour.toString().padLeft(2, '0')}:${l.startTime!.minute.toString().padLeft(2, '0')}'
            : '--:--';
        final end = l.endTime != null
            ? '${l.endTime!.hour.toString().padLeft(2, '0')}:${l.endTime!.minute.toString().padLeft(2, '0')}'
            : '--:--';
        final sub = AppState.instance.applyAlias(l.subject);
        final room = l.room != null && l.room!.isNotEmpty ? 'Terem: ${l.room}' : '';
        final teacher = l.teacher != null && l.teacher!.isNotEmpty
            ? 'Tanár: ${AppState.instance.applyAlias(l.teacher!)}'
            : '';

        String statusTag = '';
        if (l.isCancelled) {
          statusTag = ' ${PalaTheme.absenceUnexcusedBadge} ELMARADT ${PalaTheme.reset}';
        } else if (l.substituteTeacher != null &&
            l.substituteTeacher!.isNotEmpty) {
          statusTag =
              ' ${PalaTheme.absencePendingBadge} HELYETTESÍTÉS: ${AppState.instance.applyAlias(l.substituteTeacher!)} ${PalaTheme.reset}';
        }

        lines.add(
          ' ${PalaTheme.primaryBold}${l.lessonNumber.toString().padLeft(2)}. óra${PalaTheme.reset} ${PalaTheme.muted}($start - $end)${PalaTheme.reset}  ${PalaTheme.textBright}$sub${PalaTheme.reset}  ${PalaTheme.surfaceBadge} $room ${PalaTheme.reset}  ${PalaTheme.muted}$teacher${PalaTheme.reset}$statusTag',
        );
        if (l.theme != null && l.theme!.isNotEmpty) {
          lines.add('      ${PalaTheme.muted}Téma: ${l.theme}${PalaTheme.reset}');
        }
      }
    }

    return lines;
  }

  /// Tab 4: Absences (Mulasztások) with Red (Unexcused), Yellow (Pending), and Grey (Excused) highlights.
  static List<String> _buildAbsencesTabLines(
    TuiWorkspaceState state,
    int width,
  ) {
    final lines = <String>[];

    // Filter chips bar
    final chips = <String>[];
    for (var i = 0; i < TuiWorkspaceState.absenceFilterLabels.length; i++) {
      final lbl = TuiWorkspaceState.absenceFilterLabels[i];
      if (state.absenceFilter == i) {
        chips.add('\x1B[48;5;208m\x1B[1;38;5;232m $lbl ${PalaTheme.reset}');
      } else {
        chips.add('${PalaTheme.muted}$lbl${PalaTheme.reset}');
      }
    }
    lines.add(
      'Szűrő: ${chips.join("  ")}   ${PalaTheme.muted}[f] Szűrő váltása${PalaTheme.reset}',
    );
    lines.add('__DIVIDER__');

    // 1. 250-Hour Legal Limit & Parental Excuse Quota Card
    final totalHours = state.totalMissedHours;
    final unexcused = state.unexcusedHours;
    final pending = state.pendingHours;
    final excused = state.excusedHours;
    final delays = state.delayCount;
    final delayMins = state.totalDelayMinutes;

    final quota = AppState.instance.parentalQuota;
    final parentalDays = <String>{};
    for (final a in state.absences) {
      final t = (a.type ?? '').toLowerCase();
      final s = a.status.toLowerCase();
      if (t.contains('szülő') ||
          t.contains('gondviselő') ||
          s.contains('szülő') ||
          s.contains('gondviselő')) {
        final dStr = a.date?.toString().split(' ').first.split('T').first ?? '';
        if (dStr.isNotEmpty) parentalDays.add(dStr);
      }
    }
    final usedParental = parentalDays.length;

    final ratio250 = (totalHours / 250.0).clamp(0.0, 1.0);
    final barColor250 = totalHours >= 200
        ? PalaTheme.grade1Fg
        : (totalHours >= 120 ? PalaTheme.grade3Fg : PalaTheme.grade5Fg);
    final bar250 = TuiScreenBuffer.progressBar(
      ratio250,
      max(12, (width * 0.35).round()),
      fillColor: barColor250,
    );

    final summaryBoxLines = <String>[
      '250 órás törvényi határ: $barColor250$totalHours / 250 óra${PalaTheme.reset} (${(ratio250 * 100).toStringAsFixed(1)}%)  $bar250',
      'Státusz megoszlás:       ${PalaTheme.absenceUnexcusedBadge} Igazolatlan: $unexcused óra ${PalaTheme.reset}  ${PalaTheme.absencePendingBadge} Igazolandó: $pending óra ${PalaTheme.reset}  ${PalaTheme.absenceExcusedBadge} Igazolt: $excused óra ${PalaTheme.reset}',
      'Szülői igazolási keret:  ${PalaTheme.primaryBold}$usedParental / $quota nap${PalaTheme.reset} felhasznva   ${PalaTheme.borderMuted}│${PalaTheme.reset}   Késések: ${PalaTheme.absenceDelayFg}$delays db ($delayMins perc)${PalaTheme.reset}',
    ];

    lines.addAll(TuiScreenBuffer.drawRoundedBox(
      width: width,
      title: '${PalaTheme.primaryBold}Mulasztási Kvóták & 250 Órás Veszélyzóna${PalaTheme.reset}',
      lines: summaryBoxLines,
    ));
    lines.add('');

    // Filter absences list
    final filtered = state.absences.where((a) {
      final sLower = a.status.toLowerCase();
      final tLower = (a.type ?? '').toLowerCase();
      final isDelay = tLower.contains('késés') || sLower.contains('késés');
      switch (state.absenceFilter) {
        case 1: // Igazolatlan
          return !isDelay && sLower.contains('igazolatlan');
        case 2: // Igazolandó
          return !isDelay &&
              (sLower.contains('igazolando') || sLower.contains('igazolandó'));
        case 3: // Igazolt
          return !isDelay && sLower == 'igazolt';
        case 4: // Késések
          return isDelay;
        default:
          return true;
      }
    }).toList()
      ..sort(
        (a, b) => (b.date ?? DateTime(2000)).compareTo(a.date ?? DateTime(2000)),
      );

    if (filtered.isEmpty) {
      lines.add('${PalaTheme.muted}Nincs a szűrőnek megfelelő mulasztás.${PalaTheme.reset}');
      return lines;
    }

    const dateColW = 11;
    final subColW = (width * 0.32).round().clamp(16, 30);
    final typeColW = (width * 0.22).round().clamp(12, 22);
    final statusColW = max(16, width - dateColW - subColW - typeColW - 11);
    final b = PalaTheme.borderMuted;
    final r = PalaTheme.reset;

    lines.add(
      '$b╭${'─' * (dateColW + 2)}┬${'─' * (subColW + 2)}┬${'─' * (typeColW + 2)}┬${'─' * (statusColW + 2)}╮$r',
    );
    lines.add(
      '$b│$r ${PalaTheme.textBright}${TuiScreenBuffer.padRightAnsi('Dátum', dateColW)}$r $b│$r ${PalaTheme.textBright}${TuiScreenBuffer.padRightAnsi('Tantárgy', subColW)}$r $b│$r ${PalaTheme.textBright}${TuiScreenBuffer.padRightAnsi('Mulasztás Típusa', typeColW)}$r $b│$r ${PalaTheme.textBright}${TuiScreenBuffer.padRightAnsi('Státusz', statusColW)}$r $b│$r',
    );
    lines.add(
      '$b├${'─' * (dateColW + 2)}┼${'─' * (subColW + 2)}┼${'─' * (typeColW + 2)}┼${'─' * (statusColW + 2)}┤$r',
    );

    for (final a in filtered) {
      final dateStr = a.date != null
          ? '${a.date!.year}-${a.date!.month.toString().padLeft(2, '0')}-${a.date!.day.toString().padLeft(2, '0')}'
          : '-';
      final subj = AppState.instance.applyAlias(a.subject);
      final typeStr = a.type ?? 'Hiányzás';
      final rowColor = PalaTheme.absenceColor(a.status, type: a.type);
      final badge = PalaTheme.formatAbsenceBadge(
        a.status,
        type: a.type,
        delayMinutes: a.delayMinutes,
      );

      final dCell = TuiScreenBuffer.padRightAnsi(
        '$rowColor$dateStr$r',
        dateColW,
      );
      final sCell = TuiScreenBuffer.padRightAnsi(
        '$rowColor${TuiScreenBuffer.truncateAnsi(subj, subColW)}$r',
        subColW,
      );
      final tCell = TuiScreenBuffer.padRightAnsi(
        '${PalaTheme.muted}${TuiScreenBuffer.truncateAnsi(typeStr, typeColW)}$r',
        typeColW,
      );
      final stCell = TuiScreenBuffer.padRightAnsi(
        TuiScreenBuffer.truncateAnsi(badge, statusColW),
        statusColW,
      );

      lines.add('$b│$r $dCell $b│$r $sCell $b│$r $tCell $b│$r $stCell $b│$r');
    }

    lines.add(
      '$b╰${'─' * (dateColW + 2)}┴${'─' * (subColW + 2)}┴${'─' * (typeColW + 2)}┴${'─' * (statusColW + 2)}╯$r',
    );

    return lines;
  }

  /// Interactive Szellem Jegy (Ghost Grade) bar displayed when [state.ghostDrawerOpen] is true.
  static List<String> buildGhostSimulatorBar(
    TuiWorkspaceState state, {
    required int width,
  }) {
    final subj = state.selectedGhostSubject ?? 'Nincs tantárgy';
    final displaySub = AppState.instance.applyAlias(subj);
    final gradePill = PalaTheme.formatGradePill(state.ghostGradeValue);
    final weight = state.selectedGhostWeight.toInt();
    final curAvg = state.subjectAverage(subj, includeGhost: false);
    final simAvg = state.subjectAverage(subj, includeGhost: true);

    final line1 =
        '${PalaTheme.gradeGhostFg}◆ SZELLEM JEGY KALKULÁTOR:${PalaTheme.reset}  Tantárgy ${PalaTheme.muted}[←/→]${PalaTheme.reset}: ${PalaTheme.primaryBold}< $displaySub >${PalaTheme.reset}   Jegy ${PalaTheme.muted}[1-5]${PalaTheme.reset}: $gradePill   Súly ${PalaTheme.muted}[w]${PalaTheme.reset}: ${PalaTheme.textBright}$weight%${PalaTheme.reset}   Tárgyi átlag: ${curAvg.toStringAsFixed(2)} -> ${PalaTheme.gradeGhostFg}${simAvg.toStringAsFixed(2)}${PalaTheme.reset}';
    final line2 =
        '${PalaTheme.muted}Vezérlés: [←/→] Tantárgy váltás  [1-5] Érdemjegy  [w] Súly (50/100/200/300%)  [Enter] Hozzáadás (${state.ghostGrades.length} aktív)  [c] Összes törlése  [s/Esc] Bezárás${PalaTheme.reset}';

    return TuiScreenBuffer.drawRoundedBox(
      width: width,
      height: 4,
      title: '${PalaTheme.gradeGhostFg}Szellem Jegy Szimulátor${PalaTheme.reset}',
      lines: [line1, line2],
      customBorderColor: PalaTheme.gradeGhostFg,
    );
  }

  /// Builds the Footer Status Bar with keyboard shortcut legend and status feedback.
  static List<String> buildFooterBar(
    TuiWorkspaceState state, {
    required int width,
  }) {
    final innerW = max(10, width - 4);
    final keyBadge = (String k, String label) =>
        '${PalaTheme.surfaceBadge} $k ${PalaTheme.reset} $label';

    final shortcuts = <String>[
      keyBadge('Tab', 'Panelváltás'),
      keyBadge('1-4', 'Nézet'),
      keyBadge('↑/↓ j/k', 'Görgetés'),
      keyBadge('r', 'Frissítés'),
      keyBadge('s', 'Szellem Jegy'),
      if (state.activeTab == 1) keyBadge('v', 'Mátrix/Tervező'),
      if (state.activeTab == 2) keyBadge('w/a', 'Heti/Napi & A/B'),
      if (state.activeTab == 3) keyBadge('f', 'Szűrő'),
      keyBadge('q', 'Kilépés'),
    ];

    final legendStr = shortcuts.join('  ');
    String footerLine = legendStr;

    if (state.statusBannerMessage != null &&
        state.statusBannerMessage!.isNotEmpty) {
      final msg =
          '${PalaTheme.primaryBold}▸ ${state.statusBannerMessage}${PalaTheme.reset}';
      final legendVis = TuiScreenBuffer.visibleLength(legendStr);
      final msgVis = TuiScreenBuffer.visibleLength(msg);
      if (legendVis + msgVis + 3 <= innerW) {
        final pad = innerW - legendVis - msgVis;
        footerLine = '$legendStr${' ' * pad}$msg';
      } else {
        footerLine = '$msg  $legendStr';
      }
    }

    return TuiScreenBuffer.drawRoundedBox(
      width: width,
      height: 3,
      lines: [footerLine],
      customBorderColor: PalaTheme.borderMuted,
    );
  }

  static List<TimetableEntry> _getTodayOrNextLessons(TuiWorkspaceState state) {
    if (state.timetable.isEmpty) return const [];
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final todayList = state.timetable
        .where((l) =>
            l.date != null &&
            l.date!.year == today.year &&
            l.date!.month == today.month &&
            l.date!.day == today.day)
        .toList()
      ..sort((a, b) => a.lessonNumber.compareTo(b.lessonNumber));

    if (todayList.isNotEmpty) return todayList;

    // Otherwise find the next available teaching day in the loaded timetable
    final futureDates = state.timetable
        .where((l) => l.date != null && l.date!.isAfter(today))
        .map((l) => DateTime(l.date!.year, l.date!.month, l.date!.day))
        .toSet()
        .toList()
      ..sort();

    if (futureDates.isNotEmpty) {
      final nextDay = futureDates.first;
      return state.timetable
          .where((l) =>
              l.date != null &&
              l.date!.year == nextDay.year &&
              l.date!.month == nextDay.month &&
              l.date!.day == nextDay.day)
          .toList()
        ..sort((a, b) => a.lessonNumber.compareTo(b.lessonNumber));
    }

    // Fallback to the first day in the timetable
    final allDates = state.timetable
        .where((l) => l.date != null)
        .map((l) => DateTime(l.date!.year, l.date!.month, l.date!.day))
        .toSet()
        .toList()
      ..sort();
    if (allDates.isEmpty) return const [];
    final firstDay = allDates.first;
    return state.timetable
        .where((l) =>
            l.date != null &&
            l.date!.year == firstDay.year &&
            l.date!.month == firstDay.month &&
            l.date!.day == firstDay.day)
        .toList()
      ..sort((a, b) => a.lessonNumber.compareTo(b.lessonNumber));
  }
}

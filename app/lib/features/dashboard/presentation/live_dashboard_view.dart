import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pala/models/timetable_entry.dart';
import 'package:pala/utils/ics_exporter.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/adaptive/adaptive_breakpoints.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../core/widgets/quick_action_button.dart';
import '../../../core/widgets/skeleton_container.dart';
import '../../../state/app_model.dart';
import '../widgets/countdown_hero_card.dart';
import '../widgets/timetable_tile.dart';

/// Overhauled Live Dashboard ("Élő Dashboard") View for real-time academic tracking.
class LiveDashboardView extends StatefulWidget {
  final AppModel appModel;
  final void Function(int index)? onNavigate;

  const LiveDashboardView({super.key, required this.appModel, this.onNavigate});

  @override
  State<LiveDashboardView> createState() => _LiveDashboardViewState();
}

class _LiveDashboardViewState extends State<LiveDashboardView> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 15), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  List<TimetableEntry> _getTodayLessons() {
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    return widget.appModel.timetable.where((l) {
      if (l.startTime == null) return false;
      final dateStr = DateFormat('yyyy-MM-dd').format(l.startTime!);
      return dateStr == todayStr;
    }).toList()..sort((a, b) => a.lessonNumber.compareTo(b.lessonNumber));
  }

  String _formatTodayDate(DateTime date) {
    try {
      return DateFormat('yyyy. MMMM d., EEEE', 'hu').format(date);
    } catch (_) {
      return DateFormat('yyyy. MM. dd.').format(date);
    }
  }

  Future<void> _exportCalendar(BuildContext context, List<TimetableEntry> lessons) async {
    try {
      final ics = IcsExporter.generate(
        widget.appModel.timetable.isNotEmpty ? widget.appModel.timetable : lessons,
        widget.appModel.exams,
      );
      final dir = await getApplicationDocumentsDirectory();
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final file = File('${dir.path}${Platform.pathSeparator}orarend_$timestamp.ics');
      await file.writeAsString(ics);

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Órarend sikeresen exportálva: ${file.path.split(RegExp(r'[\\/]')).last}'),
          action: SnackBarAction(label: 'OK', onPressed: () {}),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Theme.of(context).colorScheme.errorContainer,
          content: Text(
            'Nem sikerült az órarend exportálása.',
            style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final now = DateTime.now();
    final todayLessons = _getTodayLessons();

    TimetableEntry? currentLesson;
    TimetableEntry? nextLesson;

    for (final l in todayLessons) {
      if (l.startTime != null && l.endTime != null) {
        if (now.isAfter(l.startTime!) && now.isBefore(l.endTime!)) {
          currentLesson = l;
          break;
        } else if (l.startTime!.isAfter(now) && nextLesson == null) {
          nextLesson = l;
        }
      }
    }

    final hasNoCachedData =
        widget.appModel.timetable.isEmpty && widget.appModel.grades.isEmpty && widget.appModel.absences.isEmpty;

    // Non-blocking skeleton loader when there is no data at all yet
    final isInitialLoading = widget.appModel.isLoading && hasNoCachedData;

    if (isInitialLoading) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: const [
            SkeletonContainer.card(height: 160),
            SizedBox(height: 16),
            SkeletonContainer.tile(),
            SkeletonContainer.tile(),
            SkeletonContainer.tile(),
            SkeletonContainer.tile(),
          ],
        ),
      );
    }

    if (widget.appModel.errorMessage != null && hasNoCachedData && !widget.appModel.isDemo) {
      return EmptyStateWidget.offline(onPrimaryAction: widget.appModel.refreshAll);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isExpanded = AdaptiveBreakpoints.isExpandedConstraints(constraints);

        if (isExpanded) {
          // Master-Detail split layout on Expanded viewports (>= 600dp):
          // Left column: CountdownHeroCard, Quick Actions, KPI Metrics
          // Right column: Daily Timetable Feed header + .ics export + TimetableTile list
          return RefreshIndicator(
            color: colorScheme.primary,
            onRefresh: widget.appModel.refreshAll,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverToBoxAdapter(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 5,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              CountdownHeroCard(
                                currentLesson: currentLesson,
                                nextLesson: nextLesson,
                                todayLessons: todayLessons,
                                now: now,
                                getDisplaySubject: widget.appModel.getDisplaySubject,
                              ),
                              const SizedBox(height: 16),
                              _buildQuickActions(context, colorScheme),
                              const SizedBox(height: 20),
                              _buildKpiMetrics(context, theme, colorScheme),
                            ],
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          flex: 6,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildTimetableHeader(context, theme, colorScheme, now, todayLessons),
                              const SizedBox(height: 12),
                              if (todayLessons.isEmpty)
                                EmptyStateWidget(
                                  icon: Icons.event_available_outlined,
                                  title: 'Mára nincs tanítás',
                                  description: 'Nincsenek bejegyzett tanórák mára a Kréta rendszerben.',
                                  primaryActionLabel: 'Órarend megnyitása',
                                  onPrimaryAction: widget.onNavigate != null ? () => widget.onNavigate!(2) : null,
                                )
                              else
                                ...todayLessons.map((lesson) {
                                  final isNow =
                                      lesson.startTime != null &&
                                      lesson.endTime != null &&
                                      now.isAfter(lesson.startTime!) &&
                                      now.isBefore(lesson.endTime!);
                                  final isPast = lesson.endTime != null && now.isAfter(lesson.endTime!);
                                  return TimetableTile(
                                    lesson: lesson,
                                    isNow: isNow,
                                    isPast: isPast,
                                    getDisplaySubject: widget.appModel.getDisplaySubject,
                                  );
                                }),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        // Compact (< 600dp): Single-column scrollable feed
        return RefreshIndicator(
          color: colorScheme.primary,
          onRefresh: widget.appModel.refreshAll,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Countdown Hero Card
                      CountdownHeroCard(
                        currentLesson: currentLesson,
                        nextLesson: nextLesson,
                        todayLessons: todayLessons,
                        now: now,
                        getDisplaySubject: widget.appModel.getDisplaySubject,
                      ),
                      const SizedBox(height: 16),

                      // Quick Action Buttons Row
                      _buildQuickActions(context, colorScheme),
                      const SizedBox(height: 20),

                      // KPI Summary Row
                      _buildKpiMetrics(context, theme, colorScheme),
                      const SizedBox(height: 24),

                      // Daily Timetable Feed Header with .ics Export trigger
                      _buildTimetableHeader(context, theme, colorScheme, now, todayLessons),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),

              // Daily Lessons Feed
              if (todayLessons.isEmpty)
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                  sliver: SliverToBoxAdapter(
                    child: EmptyStateWidget(
                      icon: Icons.event_available_outlined,
                      title: 'Mára nincs tanítás',
                      description: 'Nincsenek bejegyzett tanórák mára a Kréta rendszerben.',
                      primaryActionLabel: 'Órarend megnyitása',
                      onPrimaryAction: widget.onNavigate != null ? () => widget.onNavigate!(2) : null,
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final lesson = todayLessons[index];
                      final isNow =
                          lesson.startTime != null &&
                          lesson.endTime != null &&
                          now.isAfter(lesson.startTime!) &&
                          now.isBefore(lesson.endTime!);
                      final isPast = lesson.endTime != null && now.isAfter(lesson.endTime!);

                      return TimetableTile(
                        lesson: lesson,
                        isNow: isNow,
                        isPast: isPast,
                        getDisplaySubject: widget.appModel.getDisplaySubject,
                      );
                    }, childCount: todayLessons.length),
                  ),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTimetableHeader(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
    DateTime now,
    List<TimetableEntry> todayLessons,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Mai órarend',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800, color: colorScheme.onSurface),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                _formatTodayDate(now),
                style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.outline),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        IconButton.filledTonal(
          tooltip: 'Naptár export (.ics)',
          icon: const Icon(Icons.calendar_month_outlined, size: 20),
          onPressed: () => _exportCalendar(context, todayLessons),
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context, ColorScheme colorScheme) {
    // Wraps onto a second line on narrow screens instead of hiding buttons off-screen.
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        QuickActionButton(
          icon: Icons.school_outlined,
          label: 'Jegyek & Átlagok',
          color: colorScheme.primaryContainer,
          textColor: colorScheme.onPrimaryContainer,
          onPressed: widget.onNavigate != null ? () => widget.onNavigate!(1) : null,
        ),
        QuickActionButton(
          icon: Icons.calendar_today_outlined,
          label: 'Heti Órarend',
          color: colorScheme.secondaryContainer,
          textColor: colorScheme.onSecondaryContainer,
          onPressed: widget.onNavigate != null ? () => widget.onNavigate!(2) : null,
        ),
        QuickActionButton(
          icon: Icons.person_off_outlined,
          label: 'Mulasztások',
          color: colorScheme.tertiaryContainer,
          textColor: colorScheme.onTertiaryContainer,
          onPressed: widget.onNavigate != null ? () => widget.onNavigate!(3) : null,
        ),
      ],
    );
  }

  Widget _buildKpiMetrics(BuildContext context, ThemeData theme, ColorScheme colorScheme) {
    final gpa = widget.appModel.overallGpa;
    final missed = widget.appModel.totalMissedHours;
    final hwCount = widget.appModel.homework.where((h) => !widget.appModel.completedHomework.contains(h.uid)).length;
    final examCount = widget.appModel.exams.length;

    final tiles = <Widget>[
      _buildMetricTile(
        context,
        theme,
        colorScheme,
        title: 'Átlag',
        value: gpa > 0 ? gpa.toStringAsFixed(2) : '-',
        color: colorScheme.primary,
        onTap: widget.onNavigate != null ? () => widget.onNavigate!(1) : null,
      ),
      _buildMetricTile(
        context,
        theme,
        colorScheme,
        title: 'Hiányzás',
        value: '$missed óra',
        color: missed >= 200 ? colorScheme.error : (missed >= 150 ? colorScheme.tertiary : colorScheme.primary),
        onTap: widget.onNavigate != null ? () => widget.onNavigate!(3) : null,
      ),
      _buildMetricTile(
        context,
        theme,
        colorScheme,
        title: 'Házi',
        value: '$hwCount db',
        color: colorScheme.secondary,
        onTap: widget.onNavigate != null ? () => widget.onNavigate!(4) : null,
      ),
      _buildMetricTile(
        context,
        theme,
        colorScheme,
        title: 'Dolgozat',
        value: '$examCount db',
        color: colorScheme.tertiary,
        onTap: widget.onNavigate != null ? () => widget.onNavigate!(4) : null,
      ),
    ];
    Widget rowOf(List<Widget> items) => Row(
      children: [
        for (var i = 0; i < items.length; i++) ...[if (i > 0) const SizedBox(width: 8), Expanded(child: items[i])],
      ],
    );

    // Four tiles in one row truncate their labels below ~380px; go 2x2 there.
    return LayoutBuilder(
      builder: (context, constraints) => constraints.maxWidth < 380
          ? Column(children: [rowOf(tiles.sublist(0, 2)), rowOf(tiles.sublist(2))]) // Card margins already space the rows
          : rowOf(tiles),
    );
  }

  Widget _buildMetricTile(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme, {
    required String title,
    required String value,
    required Color color,
    VoidCallback? onTap,
  }) {
    return Semantics(
      button: onTap != null,
      label: '$title: $value',
      child: Card(
        color: colorScheme.surfaceContainerLow,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: colorScheme.outlineVariant, width: 1),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: theme.textTheme.labelSmall?.copyWith(color: colorScheme.outline),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800, color: color),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

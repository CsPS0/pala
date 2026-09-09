import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pala/models/timetable_entry.dart';
import '../state/app_model.dart';
import '../theme/pala_theme.dart';
import 'absences_view.dart';
import 'global_search_view.dart';
import 'stats_view.dart';
import 'tasks_view.dart';
import 'wrapped_view.dart';

class DashboardView extends StatefulWidget {
  final AppModel appModel;

  const DashboardView({super.key, required this.appModel});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  List<TimetableEntry> _getTodayLessons() {
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    return widget.appModel.timetable.where((l) {
      if (l.startTime == null) return false;
      final dateStr = DateFormat('yyyy-MM-dd').format(l.startTime!);
      return dateStr == todayStr;
    }).toList()
      ..sort((a, b) => a.lessonNumber.compareTo(b.lessonNumber));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.primaryColor;
    final todayLessons = _getTodayLessons();
    final now = DateTime.now();

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

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 850;

        if (isDesktop) {
          return RefreshIndicator(
            onRefresh: widget.appModel.refreshAll,
            color: primary,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left Column (50%): Countdown Card + Today's Lessons
                    Expanded(
                      flex: 5,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildCountdownCard(currentLesson, nextLesson, todayLessons, now, primary),
                          const SizedBox(height: 16),
                          _buildTodayScheduleSection(todayLessons, now, primary),
                        ],
                      ),
                    ),

                    const SizedBox(width: 20),

                    // Right Column (50%): Quick Actions + KPI Metrics + Recent Activity
                    Expanded(
                      flex: 5,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildQuickActionsRow(primary),
                          const SizedBox(height: 16),
                          _buildMetricsGrid(todayLessons, now, primary),
                          const SizedBox(height: 16),
                          _buildUpcomingPreviewSection(primary),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }

        // Mobile Single-column
        return RefreshIndicator(
          onRefresh: widget.appModel.refreshAll,
          color: primary,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            children: [
              _buildCountdownCard(currentLesson, nextLesson, todayLessons, now, primary),
              const SizedBox(height: 14),
              _buildQuickActionsRow(primary),
              const SizedBox(height: 14),
              _buildMetricsGrid(todayLessons, now, primary),
              const SizedBox(height: 20),
              _buildTodayScheduleSection(todayLessons, now, primary),
              const SizedBox(height: 20),
              _buildUpcomingPreviewSection(primary),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCountdownCard(
    TimetableEntry? currentLesson,
    TimetableEntry? nextLesson,
    List<TimetableEntry> todayLessons,
    DateTime now,
    Color primary,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            primary.withValues(alpha: 0.15),
            primary.withValues(alpha: 0.04),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (currentLesson != null && currentLesson.startTime != null && currentLesson.endTime != null) ...[
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: primary,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'FOLYAMATBAN',
                    style: TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.w900),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Terem: ${currentLesson.room != null && currentLesson.room!.isNotEmpty ? currentLesson.room : "N/A"}',
                  style: TextStyle(fontSize: 12, color: PalaTheme.textMuted),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              widget.appModel.getDisplaySubject(currentLesson.subject),
              style: TextStyle(color: primary, fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              'Hátra van még: ${currentLesson.endTime!.difference(now).inMinutes} perc',
              style: TextStyle(color: PalaTheme.textMuted, fontSize: 13),
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (now.difference(currentLesson.startTime!).inSeconds / currentLesson.endTime!.difference(currentLesson.startTime!).inSeconds).clamp(0.0, 1.0),
                backgroundColor: Colors.white10,
                valueColor: AlwaysStoppedAnimation<Color>(primary),
                minHeight: 6,
              ),
            ),
          ] else if (nextLesson != null && nextLesson.startTime != null) ...[
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: PalaTheme.warning.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'KÖVETKEZŐ ÓRA',
                    style: TextStyle(color: PalaTheme.warning, fontSize: 10, fontWeight: FontWeight.w900),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Terem: ${nextLesson.room != null && nextLesson.room!.isNotEmpty ? nextLesson.room : "N/A"}',
                  style: TextStyle(fontSize: 12, color: PalaTheme.textMuted),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              widget.appModel.getDisplaySubject(nextLesson.subject),
              style: TextStyle(color: primary, fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              'Kezdődik ${nextLesson.startTime!.difference(now).inMinutes} perc múlva (${DateFormat('HH:mm').format(nextLesson.startTime!)})',
              style: TextStyle(color: PalaTheme.textMuted, fontSize: 13),
            ),
          ] else if (todayLessons.isNotEmpty) ...[
            Text(
              'A mai tanítási nap véget ért!',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              'Szép estét és jó pihenést a holnapi napra!',
              style: TextStyle(color: PalaTheme.textMuted, fontSize: 13),
            ),
          ] else ...[
            Text(
              'Ma nincsenek óráid!',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              'Jó pihenést a mai napra!',
              style: TextStyle(color: PalaTheme.textMuted, fontSize: 13),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuickActionsRow(Color primary) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildQuickActionPill(
            icon: Icons.person_off_outlined,
            label: 'Hiányzások',
            color: PalaTheme.danger,
            onTap: () => _openSheet(context, AbsencesView(appModel: widget.appModel)),
          ),
          _buildQuickActionPill(
            icon: Icons.insights_outlined,
            label: 'Statisztikák',
            color: primary,
            onTap: () => _openSheet(context, StatsView(appModel: widget.appModel)),
          ),
          _buildQuickActionPill(
            icon: Icons.auto_awesome_outlined,
            label: 'Pala Wrapped',
            color: const Color(0xFFFF8800),
            onTap: () => WrappedModal.show(context, widget.appModel),
          ),
          _buildQuickActionPill(
            icon: Icons.search,
            label: 'Keresés',
            color: Colors.blue,
            onTap: () => GlobalSearchView.show(context, widget.appModel),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsGrid(List<TimetableEntry> todayLessons, DateTime now, Color primary) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.5,
      children: [
        // Metric 1: GPA
        _buildMetricCard(
          title: 'Tanulmányi Átlag',
          value: widget.appModel.overallGpa > 0 ? widget.appModel.overallGpa.toStringAsFixed(2) : '--',
          subtitle: '${widget.appModel.grades.length} rögzített jegy',
          valueColor: widget.appModel.overallGpa >= 4.0 ? PalaTheme.success : (widget.appModel.overallGpa >= 3.0 ? primary : PalaTheme.danger),
          onTap: () => _openSheet(context, StatsView(appModel: widget.appModel)),
        ),

        // Metric 2: Today's lessons
        _buildMetricCard(
          title: 'Mai Órák',
          value: '${todayLessons.length}',
          subtitle: '${todayLessons.where((l) => l.endTime != null && l.endTime!.isAfter(now)).length} hátralévő óra',
          valueColor: Colors.white,
          onTap: () {},
        ),

        // Metric 3: Parental Quota
        _buildMetricCard(
          title: 'Szülői Keret',
          value: '${widget.appModel.usedParentalDays} / ${widget.appModel.parentalQuota}',
          subtitle: 'felhasznált napok',
          valueColor: widget.appModel.usedParentalDays >= widget.appModel.parentalQuota ? PalaTheme.danger : PalaTheme.warning,
          onTap: () => _openSheet(context, AbsencesView(appModel: widget.appModel)),
        ),

        // Metric 4: Upcoming exams
        _buildMetricCard(
          title: 'Közelgő Dolgozatok',
          value: '${widget.appModel.exams.length}',
          subtitle: 'bejelentett számonkérés',
          valueColor: primary,
          onTap: () => _openSheet(context, TasksView(appModel: widget.appModel)),
        ),
      ],
    );
  }

  Widget _buildTodayScheduleSection(List<TimetableEntry> todayLessons, DateTime now, Color primary) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: PalaTheme.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: PalaTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Mai Órarend',
                style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700),
              ),
              Text(
                DateFormat('yyyy. MMMM d., EEEE', 'hu').format(DateTime.now()),
                style: TextStyle(color: PalaTheme.textMuted, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (todayLessons.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              alignment: Alignment.center,
              child: Text('Mára nincs beütemezett tanítási óra.', style: TextStyle(color: PalaTheme.textMuted)),
            )
          else
            ...todayLessons.map((l) {
              final isCancelled = l.isCancelled;
              final hasSubstitute = !isCancelled && (l.substituteTeacher?.isNotEmpty ?? false);
              final startTime = l.startTime;
              final endTime = l.endTime;
              final isNow = startTime != null && endTime != null && now.isAfter(startTime) && now.isBefore(endTime);
              final isPast = endTime != null && now.isAfter(endTime);

              return Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: isNow ? primary.withValues(alpha: 0.08) : PalaTheme.sidebar,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isNow
                        ? primary
                        : (isCancelled
                            ? PalaTheme.danger.withValues(alpha: 0.5)
                            : (hasSubstitute ? PalaTheme.warning.withValues(alpha: 0.5) : PalaTheme.border)),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 26,
                      height: 26,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isNow ? primary : Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${l.lessonNumber}',
                        style: TextStyle(color: isNow ? Colors.black : Colors.white, fontWeight: FontWeight.w800, fontSize: 12),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.appModel.getDisplaySubject(l.subject),
                            style: TextStyle(
                              color: isPast ? PalaTheme.textMuted : Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              decoration: isCancelled ? TextDecoration.lineThrough : null,
                            ),
                          ),
                          Text(
                            '${startTime != null ? DateFormat('HH:mm').format(startTime) : "-"} - ${endTime != null ? DateFormat('HH:mm').format(endTime) : "-"} • Terem: ${l.room != null && l.room!.isNotEmpty ? l.room : "N/A"}'
                            '${hasSubstitute ? " • Helyettesítő: ${l.substituteTeacher}" : ""}',
                            style: TextStyle(color: hasSubstitute ? PalaTheme.warning : PalaTheme.textMuted, fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                    if (isCancelled)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: PalaTheme.danger.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text('Elmarad', style: TextStyle(color: PalaTheme.danger, fontSize: 9, fontWeight: FontWeight.w700)),
                      )
                    else if (hasSubstitute)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: PalaTheme.warning.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text('Helyettesítés', style: TextStyle(color: PalaTheme.warning, fontSize: 9, fontWeight: FontWeight.w700)),
                      )
                    else if (isNow)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: primary.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text('Folyamatban', style: TextStyle(color: primary, fontSize: 9, fontWeight: FontWeight.w700)),
                      ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildUpcomingPreviewSection(Color primary) {
    final upcomingExams = widget.appModel.exams.take(3).toList();
    final recentGrades = widget.appModel.grades.take(3).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: PalaTheme.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: PalaTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Közelgő Dolgozatok & Legutóbbi Jegyek', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          if (upcomingExams.isEmpty && recentGrades.isEmpty)
            Text('Nincsenek aktív bejegyzések.', style: TextStyle(color: PalaTheme.textMuted, fontSize: 12))
          else ...[
            ...upcomingExams.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          '${e.mode.isNotEmpty ? e.mode : "Dolgozat"}: ${widget.appModel.getDisplaySubject(e.subject)}',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        e.date != null ? DateFormat('MM.dd.').format(e.date!) : '',
                        style: TextStyle(color: primary, fontSize: 11, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                )),
            if (recentGrades.isNotEmpty) ...[
              Divider(height: 14),
              ...recentGrades.map((g) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            '${widget.appModel.getDisplaySubject(g.subject)}: ${g.theme ?? g.type ?? ""}',
                            style: TextStyle(fontSize: 12, color: PalaTheme.textMuted),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${g.numericValue ?? g.textValue ?? "-"}',
                            style: TextStyle(color: primary, fontWeight: FontWeight.w800, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  )),
            ],
          ],
        ],
      ),
    );
  }

  void _openSheet(BuildContext context, Widget child) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: PalaTheme.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.88,
          maxChildSize: 0.96,
          minChildSize: 0.5,
          expand: false,
          builder: (_, scrollController) => ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: child,
          ),
        );
      },
    );
  }

  Widget _buildQuickActionPill({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: Material(
        color: PalaTheme.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: PalaTheme.border),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 14, color: color),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required Color valueColor,
    VoidCallback? onTap,
  }) {
    return Material(
      color: PalaTheme.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: PalaTheme.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: PalaTheme.textMuted),
              ),
              Text(
                value,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: valueColor),
              ),
              Text(
                subtitle,
                style: TextStyle(fontSize: 10, color: PalaTheme.textMuted),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

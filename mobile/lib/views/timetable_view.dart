import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pala/models/timetable_entry.dart';
import '../state/app_model.dart';
import '../theme/pala_theme.dart';

class TimetableView extends StatefulWidget {
  final AppModel appModel;

  const TimetableView({super.key, required this.appModel});

  @override
  State<TimetableView> createState() => _TimetableViewState();
}

class _TimetableViewState extends State<TimetableView> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _days = ['Hétfő', 'Kedd', 'Szerda', 'Csütörtök', 'Péntek'];

  @override
  void initState() {
    super.initState();
    final todayWeekday = DateTime.now().weekday;
    final initialIndex = (todayWeekday >= 1 && todayWeekday <= 5) ? todayWeekday - 1 : 0;
    _tabController = TabController(length: 5, vsync: this, initialIndex: initialIndex);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<TimetableEntry> _getLessonsForDay(int dayIndex) {
    final targetWeekday = dayIndex + 1; // Monday = 1
    return widget.appModel.timetable.where((l) => l.startTime != null && l.startTime!.weekday == targetWeekday).toList()
      ..sort((a, b) => a.lessonNumber.compareTo(b.lessonNumber));
  }

  String _getDateForDay(int dayIndex) {
    final lessons = _getLessonsForDay(dayIndex);
    if (lessons.isNotEmpty && lessons.first.startTime != null) {
      return DateFormat('MM.dd.').format(lessons.first.startTime!);
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.primaryColor;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 750;

        return Scaffold(
          body: Column(
            children: [
              // Week switcher bar
              Container(
                color: PalaTheme.sidebar,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          tooltip: 'Előző hét',
                          icon: const Icon(Icons.chevron_left, size: 22),
                          onPressed: () => widget.appModel.setWeekOffset(widget.appModel.weekOffset - 1),
                        ),
                        TextButton(
                          onPressed: () => widget.appModel.setWeekOffset(0),
                          child: Text(
                            widget.appModel.weekOffset == 0
                                ? 'Aktuális hét'
                                : (widget.appModel.weekOffset > 0 ? '+${widget.appModel.weekOffset}. hét' : '${widget.appModel.weekOffset}. hét'),
                            style: TextStyle(
                              color: widget.appModel.weekOffset == 0 ? primary : Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Következő hét',
                          icon: const Icon(Icons.chevron_right, size: 22),
                          onPressed: () => widget.appModel.setWeekOffset(widget.appModel.weekOffset + 1),
                        ),
                      ],
                    ),
                    if (isDesktop)
                      Text(
                        '${widget.appModel.timetable.length} tanóra rögzítve erre a hétre',
                        style: const TextStyle(color: PalaTheme.textMuted, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                  ],
                ),
              ),

              if (isDesktop) ...[
                // Desktop: 5-column side-by-side weekly grid
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: widget.appModel.refreshAll,
                    color: primary,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: List.generate(5, (dayIdx) {
                          final lessons = _getLessonsForDay(dayIdx);
                          final dateStr = _getDateForDay(dayIdx);
                          final isToday = DateTime.now().weekday == (dayIdx + 1) && widget.appModel.weekOffset == 0;

                          return Expanded(
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              decoration: BoxDecoration(
                                color: isToday ? primary.withValues(alpha: 0.04) : PalaTheme.card,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isToday ? primary.withValues(alpha: 0.5) : PalaTheme.border,
                                  width: isToday ? 1.5 : 1.0,
                                ),
                              ),
                              child: Column(
                                children: [
                                  // Column Day Header
                                  Container(
                                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                                    decoration: BoxDecoration(
                                      color: isToday ? primary.withValues(alpha: 0.15) : PalaTheme.sidebar,
                                      borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          _days[dayIdx],
                                          style: TextStyle(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 13,
                                            color: isToday ? primary : Colors.white,
                                          ),
                                        ),
                                        if (dateStr.isNotEmpty)
                                          Text(
                                            dateStr,
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: isToday ? primary : PalaTheme.textMuted,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),

                                  // Lesson list
                                  Expanded(
                                    child: lessons.isEmpty
                                        ? Center(
                                            child: Text(
                                              'Nincs tanóra',
                                              style: TextStyle(color: PalaTheme.textMuted.withValues(alpha: 0.5), fontSize: 12),
                                            ),
                                          )
                                        : ListView.builder(
                                            padding: const EdgeInsets.all(8),
                                            itemCount: lessons.length,
                                            itemBuilder: (context, i) {
                                              final l = lessons[i];
                                              return _buildLessonCard(l, primary, compact: true);
                                            },
                                          ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                  ),
                ),
              ] else ...[
                // Mobile: Day tab bar + TabBarView
                Container(
                  color: PalaTheme.sidebar,
                  child: TabBar(
                    controller: _tabController,
                    indicatorColor: primary,
                    labelColor: primary,
                    unselectedLabelColor: PalaTheme.textMuted,
                    labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                    tabs: _days.map((d) => Tab(text: d)).toList(),
                  ),
                ),

                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: List.generate(5, (idx) {
                      final lessons = _getLessonsForDay(idx);

                      if (lessons.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.event_busy, size: 48, color: PalaTheme.textMuted.withValues(alpha: 0.5)),
                              const SizedBox(height: 12),
                              Text(
                                'Nincsenek órák erre a napra (${_days[idx]}).',
                                style: const TextStyle(color: PalaTheme.textMuted, fontSize: 13),
                              ),
                            ],
                          ),
                        );
                      }

                      return RefreshIndicator(
                        onRefresh: widget.appModel.refreshAll,
                        color: primary,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          itemCount: lessons.length,
                          itemBuilder: (context, i) {
                            return _buildLessonCard(lessons[i], primary, compact: false);
                          },
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildLessonCard(TimetableEntry l, Color primary, {required bool compact}) {
    final isCancelled = l.isCancelled;
    final now = DateTime.now();
    final startTime = l.startTime;
    final endTime = l.endTime;
    final isToday = startTime != null && startTime.year == now.year && startTime.month == now.month && startTime.day == now.day;
    final isNow = isToday && endTime != null && now.isAfter(startTime) && now.isBefore(endTime);

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: EdgeInsets.all(compact ? 10 : 14),
      decoration: BoxDecoration(
        color: isNow ? primary.withValues(alpha: 0.08) : PalaTheme.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isNow ? primary : (isCancelled ? PalaTheme.danger.withValues(alpha: 0.5) : PalaTheme.border),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Lesson period badge
          Container(
            width: compact ? 26 : 32,
            height: compact ? 26 : 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isNow ? primary : Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '${l.lessonNumber}.',
              style: TextStyle(
                color: isNow ? Colors.black : Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: compact ? 12 : 14,
              ),
            ),
          ),
          SizedBox(width: compact ? 8 : 14),

          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.appModel.getDisplaySubject(l.subject),
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: compact ? 13 : 15,
                    decoration: isCancelled ? TextDecoration.lineThrough : null,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${startTime != null ? DateFormat('HH:mm').format(startTime) : "-"}${endTime != null ? " - ${DateFormat('HH:mm').format(endTime)}" : ""}${l.room != null && l.room!.isNotEmpty ? " • ${l.room}" : ""}',
                  style: TextStyle(color: PalaTheme.textMuted, fontSize: compact ? 10 : 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (l.teacher != null && l.teacher!.isNotEmpty && !compact) ...[
                  const SizedBox(height: 2),
                  Text(
                    l.teacher!,
                    style: const TextStyle(color: PalaTheme.textMuted, fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),

          // Status indicator
          if (isCancelled)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: PalaTheme.danger.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text('Elmarad', style: TextStyle(color: PalaTheme.danger, fontSize: 10, fontWeight: FontWeight.w700)),
            )
          else if (isNow)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text('Most', style: TextStyle(color: primary, fontSize: 10, fontWeight: FontWeight.w700)),
            ),
        ],
      ),
    );
  }
}

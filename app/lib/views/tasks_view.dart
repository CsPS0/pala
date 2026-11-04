import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pala/models/exam.dart';
import 'package:pala/models/homework.dart';
import 'package:pala/rules/schedule_rules.dart';
import '../state/app_model.dart';
import '../theme/pala_theme.dart';

class TasksView extends StatefulWidget {
  final AppModel appModel;

  const TasksView({super.key, required this.appModel});

  @override
  State<TasksView> createState() => _TasksViewState();
}

class _TasksViewState extends State<TasksView> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  static List<T> _byDeadline<T>(List<T> items, DateTime? Function(T) dateOf) {
    final upcoming = items.where((i) => isUpcoming(dateOf(i))).toList()
      ..sort((a, b) => dateOf(a)!.compareTo(dateOf(b)!));
    final past = items.where((i) => !isUpcoming(dateOf(i))).toList()
      ..sort((a, b) => (dateOf(b) ?? DateTime(0)).compareTo(dateOf(a) ?? DateTime(0)));
    return [...upcoming, ...past];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.primaryColor;
    final homework = _byDeadline<Homework>(widget.appModel.homework, (h) => h.deadline);
    final exams = _byDeadline<Exam>(widget.appModel.exams, (e) => e.date);

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(48),
        child: Container(
          color: PalaTheme.sidebar,
          child: TabBar(
            controller: _tabController,
            indicatorColor: primary,
            labelColor: primary,
            unselectedLabelColor: PalaTheme.textMuted,
            labelStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
            tabs: const [
              Tab(text: 'Házi'),
              Tab(text: 'Dolgozatok'),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // 1. Homework Checklist Tab
          RefreshIndicator(
            onRefresh: widget.appModel.refreshAll,
            color: primary,
            child: homework.isEmpty
                ? Center(child: Text('Nincsenek aktív házi feladatok.', style: TextStyle(color: PalaTheme.textMuted)))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    itemCount: homework.length,
                    itemBuilder: (context, idx) {
                      final h = homework[idx];
                      final hwId = (h.uid != null && h.uid!.isNotEmpty) ? h.uid! : 'hw_$idx';
                      final isDone = widget.appModel.completedHomework.contains(hwId);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: Material(
                          color: PalaTheme.card,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: PalaTheme.border),
                          ),
                          child: CheckboxListTile(
                            value: isDone,
                            activeColor: primary,
                            checkColor: Colors.black,
                            onChanged: (_) => widget.appModel.toggleHomework(hwId),
                            title: Text(
                              widget.appModel.getDisplaySubject(h.subject),
                              style: TextStyle(
                                color: isDone ? PalaTheme.textMuted : PalaTheme.text,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                decoration: isDone ? TextDecoration.lineThrough : null,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(
                                  h.text,
                                  style: TextStyle(
                                    color: isDone ? PalaTheme.textMuted.withValues(alpha: 0.6) : PalaTheme.text,
                                    fontSize: 12,
                                    decoration: isDone ? TextDecoration.lineThrough : null,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Határidő: ${h.deadline != null ? DateFormat('yyyy.MM.dd').format(h.deadline!) : "-"}',
                                  style: TextStyle(color: PalaTheme.warning, fontSize: 11, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // 2. Exams Tab
          RefreshIndicator(
            onRefresh: widget.appModel.refreshAll,
            color: primary,
            child: exams.isEmpty
                ? Center(child: Text('Nincsenek bejelentett dolgozatok.', style: TextStyle(color: PalaTheme.textMuted)))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    itemCount: exams.length,
                    itemBuilder: (context, idx) {
                      final e = exams[idx];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: PalaTheme.card,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: PalaTheme.border),
                        ),
                        // Type badge above the subject: beside it, long Kréta types
                        // ("Írásbeli témazáró dolgozat") squeezed the subject column.
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: primary.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                e.mode.isNotEmpty ? e.mode : 'Dolgozat',
                                style: TextStyle(color: primary, fontSize: 11, fontWeight: FontWeight.w700),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.appModel.getDisplaySubject(e.subject),
                                    style: TextStyle(color: PalaTheme.text, fontWeight: FontWeight.w700, fontSize: 14),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    e.theme != null && e.theme!.isNotEmpty ? e.theme! : 'Téma nincs megadva',
                                    style: TextStyle(color: PalaTheme.textMuted, fontSize: 12),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Dátum: ${e.date != null ? DateFormat('yyyy.MM.dd').format(e.date!) : "-"}',
                                    style: TextStyle(color: PalaTheme.textMuted, fontSize: 11),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      );
                    },
                  ),
          ),

        ],
      ),
    );
  }
}

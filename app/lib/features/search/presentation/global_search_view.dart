import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pala/models/absence.dart';
import 'package:pala/models/grade.dart';
import 'package:pala/models/homework.dart';
import 'package:pala/models/message.dart';
import 'package:pala/models/timetable_entry.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/accent_insensitive_search.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../state/app_model.dart';
import '../widgets/search_result_tile.dart';

/// Global Search ("Kereső") overlay with Hungarian accent-insensitive multi-category matching.
class GlobalSearchView extends StatefulWidget {
  final AppModel appModel;

  const GlobalSearchView({super.key, required this.appModel});

  static void show(BuildContext context, AppModel appModel) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => GlobalSearchView(appModel: appModel),
    );
  }

  @override
  State<GlobalSearchView> createState() => _GlobalSearchViewState();
}

class _GlobalSearchViewState extends State<GlobalSearchView> {
  final TextEditingController _queryController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Auto focus search field after layout
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _queryController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final query = _queryController.text.trim();
    final isQueryTooShort = query.length < 2;

    List<Grade> matchGrades = [];
    List<TimetableEntry> matchLessons = [];
    List<dynamic> matchTasksAndMessages = [];
    List<Absence> matchAbsences = [];

    if (!isQueryTooShort) {
      matchGrades = widget.appModel.grades.where((g) {
        final sub = widget.appModel.getDisplaySubject(g.subject);
        return AccentInsensitiveSearch.matchesAny([
          sub,
          g.teacherName,
          g.theme,
          g.type,
          g.textValue,
          g.numericValue?.toString(),
        ], query);
      }).toList();

      matchLessons = widget.appModel.timetable.where((l) {
        final sub = widget.appModel.getDisplaySubject(l.subject);
        return AccentInsensitiveSearch.matchesAny([
          sub,
          l.teacher,
          l.substituteTeacher,
          l.room,
          l.theme,
        ], query);
      }).toList();

      final homeworkHits = widget.appModel.homework.where((h) {
        final sub = widget.appModel.getDisplaySubject(h.subject);
        return AccentInsensitiveSearch.matchesAny([
          sub,
          h.text,
        ], query);
      });

      final messageHits = widget.appModel.messages.where((m) {
        return AccentInsensitiveSearch.matchesAny([
          m.subject,
          m.senderName,
          m.text,
        ], query);
      });

      matchTasksAndMessages = [...homeworkHits, ...messageHits];

      matchAbsences = widget.appModel.absences.where((a) {
        final sub = widget.appModel.getDisplaySubject(a.subject);
        return AccentInsensitiveSearch.matchesAny([
          sub,
          a.status,
          a.type,
        ], query);
      }).toList();
    }

    final totalHits = matchGrades.length + matchLessons.length + matchTasksAndMessages.length + matchAbsences.length;

    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.5,
      maxChildSize: 0.96,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            // Drag Handle & Header Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Column(
                children: [
                  Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Persistent SearchBar
                  SearchBar(
                    controller: _queryController,
                    focusNode: _focusNode,
                    hintText: 'Keresés... (pl. "tortenelem")',
                    leading: const Icon(Icons.search_rounded, size: 22),
                    trailing: [
                      if (query.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 20),
                          onPressed: () {
                            _queryController.clear();
                            setState(() {});
                          },
                        ),
                    ],
                    onChanged: (_) => setState(() {}),
                  ),
                ],
              ),
            ),
            const Divider(),

            // Search Content Area
            Expanded(
              child: isQueryTooShort
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.manage_search_rounded, size: 54, color: colorScheme.outline),
                            const SizedBox(height: 16),
                            Text(
                              'Kezdj el gépelni...',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Írj be legalább 2 karaktert a jegyek, órák, házi feladatok és hiányzások közötti ékezetmentes kereséshez.',
                              style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.outline),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    )
                  : totalHits == 0
                      ? EmptyStateWidget.noResults(
                          title: 'Nincs találat',
                          description: 'Nem található egyetlen egyezés sem a következőre: "$query"',
                          primaryActionLabel: 'Keresés törlése',
                          onPrimaryAction: () {
                            _queryController.clear();
                            setState(() {});
                          },
                        )
                      : ListView(
                          controller: scrollController,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          children: [
                            // GRADES CATEGORY
                            if (matchGrades.isNotEmpty) ...[
                              _buildCategoryHeader(theme, colorScheme, 'JEGYEK', matchGrades.length),
                              ...matchGrades.map((g) {
                                final dateStr = g.date != null ? DateFormat('yyyy.MM.dd').format(g.date!) : '';
                                final val = g.numericValue?.toString() ?? g.textValue ?? '?';
                                final gradeColor = AppColors.getGradeColor(g.numericValue);

                                return SearchResultTile(
                                  category: SearchCategory.grade,
                                  title: '${widget.appModel.getDisplaySubject(g.subject)} - $val',
                                  subtitle: '${g.theme ?? g.type ?? "Értékelés"} • ${g.teacherName ?? ""}',
                                  extra: dateStr,
                                  trailing: Container(
                                    width: 32,
                                    height: 32,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: gradeColor.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: gradeColor),
                                    ),
                                    child: Text(
                                      val,
                                      style: TextStyle(
                                        color: gradeColor,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                );
                              }),
                              const SizedBox(height: 16),
                            ],

                            // TIMETABLE CATEGORY
                            if (matchLessons.isNotEmpty) ...[
                              _buildCategoryHeader(theme, colorScheme, 'ÓRAREND', matchLessons.length),
                              ...matchLessons.map((l) {
                                final dateStr = l.startTime != null ? DateFormat('yyyy.MM.dd HH:mm').format(l.startTime!) : '';
                                return SearchResultTile(
                                  category: SearchCategory.timetable,
                                  title: '${l.lessonNumber}. ${widget.appModel.getDisplaySubject(l.subject)}',
                                  subtitle: 'Terem: ${l.room ?? "N/A"} • Tanár: ${l.teacher ?? ""}',
                                  extra: dateStr,
                                );
                              }),
                              const SizedBox(height: 16),
                            ],

                            // TASKS & MESSAGES CATEGORY
                            if (matchTasksAndMessages.isNotEmpty) ...[
                              _buildCategoryHeader(theme, colorScheme, 'FELADATOK ÉS ÜZENETEK', matchTasksAndMessages.length),
                              ...matchTasksAndMessages.map((item) {
                                if (item is Homework) {
                                  final dateStr = item.deadline != null ? DateFormat('yyyy.MM.dd').format(item.deadline!) : '';
                                  return SearchResultTile(
                                    category: SearchCategory.taskOrMessage,
                                    title: 'Házi: ${widget.appModel.getDisplaySubject(item.subject)}',
                                    subtitle: item.text,
                                    extra: 'Határidő: $dateStr',
                                  );
                                } else if (item is Message) {
                                  final dateStr = item.sentDate != null ? DateFormat('yyyy.MM.dd').format(item.sentDate!) : '';
                                  return SearchResultTile(
                                    category: SearchCategory.taskOrMessage,
                                    title: 'Üzenet: ${item.subject}',
                                    subtitle: 'Feladó: ${item.senderName}',
                                    extra: dateStr,
                                  );
                                }
                                return const SizedBox.shrink();
                              }),
                              const SizedBox(height: 16),
                            ],

                            // ABSENCES CATEGORY
                            if (matchAbsences.isNotEmpty) ...[
                              _buildCategoryHeader(theme, colorScheme, 'HIÁNYZÁSOK', matchAbsences.length),
                              ...matchAbsences.map((a) {
                                final dateStr = a.date != null ? DateFormat('yyyy.MM.dd').format(a.date!) : '';
                                return SearchResultTile(
                                  category: SearchCategory.absence,
                                  title: widget.appModel.getDisplaySubject(a.subject),
                                  subtitle: 'Állapot: ${a.status}',
                                  extra: dateStr,
                                );
                              }),
                              const SizedBox(height: 16),
                            ],
                            const SizedBox(height: 24),
                          ],
                        ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCategoryHeader(ThemeData theme, ColorScheme colorScheme, String title, int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 12, 4, 8),
      child: Row(
        children: [
          Text(
            title,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

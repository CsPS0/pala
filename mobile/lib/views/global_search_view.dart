import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../state/app_model.dart';
import '../theme/pala_theme.dart';

class GlobalSearchView extends StatefulWidget {
  final AppModel appModel;

  const GlobalSearchView({super.key, required this.appModel});

  static void show(BuildContext context, AppModel appModel) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: PalaTheme.background,
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
  final _queryController = TextEditingController();

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.primaryColor;
    final q = _queryController.text.trim().toLowerCase();

    // Results
    final matchGrades = q.isEmpty
        ? []
        : widget.appModel.grades.where((g) {
            final s = widget.appModel.getDisplaySubject(g.subject).toLowerCase();
            final th = (g.theme ?? '').toLowerCase();
            final te = (g.teacherName ?? '').toLowerCase();
            return s.contains(q) || th.contains(q) || te.contains(q);
          }).toList();

    final matchLessons = q.isEmpty
        ? []
        : widget.appModel.timetable.where((l) {
            final s = widget.appModel.getDisplaySubject(l.subject).toLowerCase();
            final th = (l.theme ?? '').toLowerCase();
            final r = (l.room ?? '').toLowerCase();
            final te = (l.teacher ?? '').toLowerCase();
            return s.contains(q) || th.contains(q) || r.contains(q) || te.contains(q);
          }).toList();

    final matchHomework = q.isEmpty
        ? []
        : widget.appModel.homework.where((h) {
            final s = widget.appModel.getDisplaySubject(h.subject).toLowerCase();
            final t = h.text.toLowerCase();
            return s.contains(q) || t.contains(q);
          }).toList();

    final matchExams = q.isEmpty
        ? []
        : widget.appModel.exams.where((e) {
            final s = widget.appModel.getDisplaySubject(e.subject).toLowerCase();
            final th = (e.theme ?? '').toLowerCase();
            return s.contains(q) || th.contains(q);
          }).toList();

    final matchMessages = q.isEmpty
        ? []
        : widget.appModel.messages.where((m) {
            final su = m.subject.toLowerCase();
            final se = m.senderName.toLowerCase();
            final t = m.text.toLowerCase();
            return su.contains(q) || se.contains(q) || t.contains(q);
          }).toList();

    final matchAbsences = q.isEmpty
        ? []
        : widget.appModel.absences.where((a) {
            final s = widget.appModel.getDisplaySubject(a.subject).toLowerCase();
            final st = a.status.toLowerCase();
            final ty = (a.type ?? '').toLowerCase();
            return s.contains(q) || st.contains(q) || ty.contains(q);
          }).toList();

    final totalCount = matchGrades.length + matchLessons.length + matchHomework.length + matchExams.length + matchMessages.length + matchAbsences.length;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Search Bar
              TextField(
                controller: _queryController,
                autofocus: true,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Globális keresés tantárgy, tanár, téma alapján...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: q.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () => setState(() => _queryController.clear()),
                        )
                      : null,
                ),
              ),

              const SizedBox(height: 12),

              if (q.isNotEmpty)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '$totalCount találat erre: "$q"',
                    style: const TextStyle(color: PalaTheme.textMuted, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),

              const SizedBox(height: 8),

              Expanded(
                child: q.isEmpty
                    ? Center(
                        child: Text(
                          'Kezdj el gépelni a kereséshez!',
                          style: TextStyle(color: PalaTheme.textMuted.withValues(alpha: 0.6), fontSize: 13),
                        ),
                      )
                    : (totalCount == 0
                        ? const Center(
                            child: Text('Nincs találat a megadott keresésre.', style: TextStyle(color: PalaTheme.textMuted)),
                          )
                        : ListView(
                            controller: scrollController,
                            children: [
                              if (matchGrades.isNotEmpty) ...[
                                _buildCategoryHeader('Érdemjegyek (${matchGrades.length})', primary),
                                ...matchGrades.map((g) => _buildResultTile(
                                      title: '${widget.appModel.getDisplaySubject(g.subject)}: ${g.numericValue ?? g.textValue}',
                                      subtitle: '${g.date != null ? DateFormat('yyyy.MM.dd').format(g.date!) : ""} • ${g.theme ?? ""}',
                                      icon: Icons.school_outlined,
                                      iconColor: primary,
                                    )),
                              ],
                              if (matchLessons.isNotEmpty) ...[
                                _buildCategoryHeader('Órarendi Órák (${matchLessons.length})', const Color(0xFFFF8800)),
                                ...matchLessons.map((l) => _buildResultTile(
                                      title: '${l.lessonNumber}. óra: ${widget.appModel.getDisplaySubject(l.subject)}',
                                      subtitle: 'Terem: ${l.room ?? "N/A"} • ${l.teacher ?? ""}',
                                      icon: Icons.calendar_today_outlined,
                                      iconColor: const Color(0xFFFF8800),
                                    )),
                              ],
                              if (matchHomework.isNotEmpty) ...[
                                _buildCategoryHeader('Házi Feladatok (${matchHomework.length})', PalaTheme.warning),
                                ...matchHomework.map((h) => _buildResultTile(
                                      title: widget.appModel.getDisplaySubject(h.subject),
                                      subtitle: h.text,
                                      icon: Icons.assignment_outlined,
                                      iconColor: PalaTheme.warning,
                                    )),
                              ],
                              if (matchExams.isNotEmpty) ...[
                                _buildCategoryHeader('Dolgozatok (${matchExams.length})', PalaTheme.danger),
                                ...matchExams.map((e) => _buildResultTile(
                                      title: '${widget.appModel.getDisplaySubject(e.subject)} (${e.mode})',
                                      subtitle: '${e.theme ?? "Nincs megadva"} • ${e.date != null ? DateFormat('yyyy.MM.dd').format(e.date!) : ""}',
                                      icon: Icons.edit_calendar_outlined,
                                      iconColor: PalaTheme.danger,
                                    )),
                              ],
                              if (matchMessages.isNotEmpty) ...[
                                _buildCategoryHeader('Üzenetek (${matchMessages.length})', Colors.blue),
                                ...matchMessages.map((m) => _buildResultTile(
                                      title: m.subject,
                                      subtitle: '${m.senderName} • ${m.text}',
                                      icon: Icons.mail_outlined,
                                      iconColor: Colors.blue,
                                    )),
                              ],
                              if (matchAbsences.isNotEmpty) ...[
                                _buildCategoryHeader('Mulasztások (${matchAbsences.length})', PalaTheme.danger),
                                ...matchAbsences.map((a) => _buildResultTile(
                                      title: '${widget.appModel.getDisplaySubject(a.subject)} (${a.status})',
                                      subtitle: '${a.date != null ? DateFormat('yyyy.MM.dd').format(a.date!) : ""} • ${a.type ?? ""}',
                                      icon: Icons.person_off_outlined,
                                      iconColor: PalaTheme.danger,
                                    )),
                              ],
                            ],
                          )),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCategoryHeader(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 6),
      child: Text(
        title,
        style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _buildResultTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: PalaTheme.card,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: PalaTheme.border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: iconColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(fontSize: 11, color: PalaTheme.textMuted), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

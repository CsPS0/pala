import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import '../../../core/adaptive/adaptive_breakpoints.dart';
import '../../../core/theme/app_colors.dart';
import '../../../state/app_model.dart';
import '../widgets/wrapped_summary_card.dart';

/// Full-screen annual performance summary module ("Pala Wrapped").
class PalaWrappedView extends StatefulWidget {
  final AppModel appModel;

  const PalaWrappedView({super.key, required this.appModel});

  static void show(BuildContext context, AppModel appModel) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: true,
        barrierColor: Colors.black,
        pageBuilder: (context, _, _) => PalaWrappedView(appModel: appModel),
        transitionsBuilder: (context, animation, _, child) => FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  State<PalaWrappedView> createState() => _PalaWrappedViewState();
}

class _PalaWrappedViewState extends State<PalaWrappedView> {
  final PageController _pageController = PageController();
  final GlobalKey _shareBoundaryKey = GlobalKey();
  int _currentPage = 0;
  bool _isExporting = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _shareSummaryImage() async {
    setState(() => _isExporting = true);
    try {
      final boundary = _shareBoundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final pngBytes = byteData.buffer.asUint8List();
      final dir = await getApplicationDocumentsDirectory();
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final file = File('${dir.path}/pala_wrapped_$timestamp.png');
      await file.writeAsBytes(pngBytes);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Összegzés sikeresen mentve: ${file.path.split(RegExp(r'[\\/]')).last}'),
          action: SnackBarAction(label: 'OK', onPressed: () {}),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Theme.of(context).colorScheme.errorContainer,
          content: Text(
            'Nem sikerült az összegzés mentése.',
            style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Computed Stats
    final totalGrades = widget.appModel.grades.length;
    final gpa = widget.appModel.overallGpa;
    final totalMissed = widget.appModel.totalMissedHours;
    final totalLessons = widget.appModel.timetable.length;
    final completedHw = widget.appModel.completedHomework.length;

    // Grade Distribution
    final gradeCounts = <int, int>{5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
    for (final g in widget.appModel.grades) {
      if (g.numericValue != null) {
        final val = g.numericValue!.round();
        if (gradeCounts.containsKey(val)) {
          gradeCounts[val] = gradeCounts[val]! + 1;
        }
      }
    }

    // Top Subject
    String topSubject = 'N/A';
    double topAvg = 0.0;
    for (final entry in widget.appModel.subjectAverages.entries) {
      if (entry.value > topAvg) {
        topAvg = entry.value;
        topSubject = entry.key;
      }
    }

    final slides = [
      // Slide 1: Welcome & Annual Scope
      WrappedSummaryCard(
        supertitle: 'Visszatekintés',
        title: 'Itt a te tanéved összegzése',
        subtitle: 'Lássuk, milyen eredményeket értél el az idei tanévben!',
        icon: Icons.auto_awesome,
        content: Column(
          children: [
            Text(
              '$totalLessons',
              style: const TextStyle(
                fontSize: 64,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'rögzített tanítási óra a naptáradban',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.9),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),

      // Slide 2: Overall GPA & Grade Distribution Chart
      WrappedSummaryCard(
        supertitle: 'Akadémiai Teljesítmény',
        title: 'Összesített átlag: ${gpa > 0 ? gpa.toStringAsFixed(2) : '-'}',
        subtitle: 'Összesen $totalGrades db érdemjegyet szereztél a félév során.',
        icon: Icons.grade_rounded,
        content: Column(
          children: [
            Text(
              'JEGYEK MEGOSZLÁSA',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 16),
            ...[5, 4, 3, 2, 1].map((val) {
              final count = gradeCounts[val] ?? 0;
              final ratio = totalGrades > 0 ? (count / totalGrades) : 0.0;
              final color = AppColors.getGradeColor(val);

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    SizedBox(
                      width: 24,
                      child: Text(
                        '$val',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: ratio,
                          minHeight: 12,
                          backgroundColor: Colors.white.withValues(alpha: 0.15),
                          valueColor: AlwaysStoppedAnimation<Color>(color),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 40,
                      child: Text(
                        '$count db',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),

      // Slide 3: Best Subject
      WrappedSummaryCard(
        supertitle: 'Csúcsteljesítmény',
        title: 'A legerősebb tantárgyad',
        subtitle: 'Ebben a tárgyban nyújtottad a legkiemelkedőbb teljesítményt!',
        icon: Icons.emoji_events_outlined,
        content: Column(
          children: [
            Text(
              topSubject,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.success),
              ),
              child: Text(
                '${topAvg.toStringAsFixed(2)} Átlag',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: AppColors.success,
                ),
              ),
            ),
          ],
        ),
      ),

      // Slide 4: Attendance & Tasks + Monthly Absence Trends Chart
      WrappedSummaryCard(
        supertitle: 'Fegyelem & Szorgalom',
        title: 'Órák és Házi feladatok',
        subtitle: 'A szorgalom és a rendszeres jelenlét határozza meg a haladást.',
        icon: Icons.task_alt_rounded,
        content: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        '$totalMissed',
                        style: const TextStyle(
                          fontSize: 38,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'mulasztott óra',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                Container(width: 1, height: 48, color: Colors.white24),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        '$completedHw',
                        style: const TextStyle(
                          fontSize: 38,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'elvégzett házi',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildMonthlyAbsenceTrendChart(),
          ],
        ),
      ),

      // Slide 5: Shareable Summary Card
      WrappedSummaryCard(
        supertitle: 'Pala Éves Összegző',
        title: widget.appModel.student?.name ?? 'Diák Éves Bizonyítvány',
        subtitle: 'Egy újabb sikeres tanév a Pala alkalmazással!',
        icon: Icons.school_rounded,
        content: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white12),
          ),
          child: Column(
            children: [
              _buildRecapRow('Összesített átlag', gpa > 0 ? gpa.toStringAsFixed(2) : '-'),
              const Divider(color: Colors.white12),
              _buildRecapRow('Legjobb tantárgy', topSubject),
              const Divider(color: Colors.white12),
              _buildRecapRow('Jegyek száma', '$totalGrades db'),
              const Divider(color: Colors.white12),
              _buildRecapRow('Hiányzás', '$totalMissed / 250 óra'),
            ],
          ),
        ),
      ),
    ];

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: ConstrainedBox(
          constraints: AdaptiveBreakpoints.touchTargetConstraints(context),
          child: IconButton(
            tooltip: 'Bezárás',
            icon: const Icon(Icons.close_rounded, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: Row(
          children: List.generate(slides.length, (index) {
            final isActive = _currentPage == index;
            return Expanded(
              child: Container(
                height: 3,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: isActive ? Colors.white : Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            );
          }),
        ),
        actions: [
          IconButton(
            tooltip: 'Összegzés mentése képeként',
            icon: Icon(
              _isExporting ? Icons.hourglass_top_rounded : Icons.share_outlined,
              color: Colors.white,
            ),
            onPressed: _isExporting ? null : _shareSummaryImage,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RepaintBoundary(
        key: _shareBoundaryKey,
        child: PageView(
          controller: _pageController,
          onPageChanged: (page) => setState(() => _currentPage = page),
          children: slides,
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (_currentPage > 0)
                ConstrainedBox(
                  constraints: AdaptiveBreakpoints.touchTargetConstraints(context),
                  child: TextButton.icon(
                    style: TextButton.styleFrom(foregroundColor: Colors.white70),
                    onPressed: () => _pageController.previousPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    ),
                    icon: const Icon(Icons.chevron_left_rounded),
                    label: const Text('Előző'),
                  ),
                )
              else
                const SizedBox.shrink(),
              if (_currentPage < slides.length - 1)
                ConstrainedBox(
                  constraints: AdaptiveBreakpoints.touchTargetConstraints(context),
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: Colors.black,
                    ),
                    onPressed: () => _pageController.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    ),
                    icon: const Icon(Icons.chevron_right_rounded),
                    label: const Text('Következő'),
                  ),
                )
              else
                ConstrainedBox(
                  constraints: AdaptiveBreakpoints.touchTargetConstraints(context),
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: Colors.black,
                    ),
                    onPressed: _shareSummaryImage,
                    icon: const Icon(Icons.download_rounded),
                    label: const Text('Kép mentése'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMonthlyAbsenceTrendChart() {
    const schoolMonths = [
      (month: 9, label: 'Szep'),
      (month: 10, label: 'Okt'),
      (month: 11, label: 'Nov'),
      (month: 12, label: 'Dec'),
      (month: 1, label: 'Jan'),
      (month: 2, label: 'Feb'),
      (month: 3, label: 'Már'),
      (month: 4, label: 'Ápr'),
      (month: 5, label: 'Máj'),
      (month: 6, label: 'Jún'),
    ];

    final Map<int, int> monthlyCounts = {for (final m in schoolMonths) m.month: 0};
    int maxCount = 1;

    for (final a in widget.appModel.absences) {
      if (a.type?.toLowerCase() == 'késés' || a.date == null) continue;
      final m = a.date!.month;
      final nextVal = (monthlyCounts[m] ?? 0) + 1;
      monthlyCounts[m] = nextVal;
      if (nextVal > maxCount) {
        maxCount = nextVal;
      }
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'HAVI HIÁNYZÁSI TREND',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
              color: Colors.white.withValues(alpha: 0.75),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 76,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: schoolMonths.map((item) {
                final count = monthlyCounts[item.month] ?? 0;
                final ratio = (count / maxCount).clamp(0.08, 1.0);
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (count > 0)
                          Text(
                            '$count',
                            style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        const SizedBox(height: 2),
                        Container(
                          height: 40 * ratio,
                          decoration: BoxDecoration(
                            color: count > 0
                                ? AppColors.primary
                                : Colors.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.label,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withValues(alpha: 0.75),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.clip,
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecapRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.75),
              fontSize: 13,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

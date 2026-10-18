import 'package:flutter/material.dart';
import 'package:pala/models/grade.dart';
import '../../../core/adaptive/adaptive_breakpoints.dart';
import '../../../core/theme/app_colors.dart';

class MockGradeItem {
  final String id;
  final String subject;
  final int value;
  final int weight;

  MockGradeItem({
    required this.id,
    required this.subject,
    required this.value,
    required this.weight,
  });
}

/// Ephemeral in-memory controller for Ghost Grade Calculator ("Szellem jegy kalkulátor").
/// Never mutates persistent storage or sends network payloads.
class GhostGradeController extends ChangeNotifier {
  String _selectedSubject = '';
  int _selectedGrade = 5;
  int _selectedWeight = 100;
  final List<MockGradeItem> _mockGrades = [];

  String get selectedSubject => _selectedSubject;
  int get selectedGrade => _selectedGrade;
  int get selectedWeight => _selectedWeight;
  List<MockGradeItem> get mockGrades => List.unmodifiable(_mockGrades);

  void ensureDefaultSubject(Iterable<String> subjects) {
    if (_selectedSubject.isEmpty && subjects.isNotEmpty) {
      _selectedSubject = subjects.first;
    } else if (_selectedSubject.isNotEmpty &&
        subjects.isNotEmpty &&
        !subjects.contains(_selectedSubject)) {
      _selectedSubject = subjects.first;
    }
  }

  void setSelectedSubject(String subject) {
    if (_selectedSubject != subject) {
      _selectedSubject = subject;
      notifyListeners();
    }
  }

  void setSelectedGrade(int grade) {
    if (_selectedGrade != grade) {
      _selectedGrade = grade;
      notifyListeners();
    }
  }

  void setSelectedWeight(int weight) {
    if (_selectedWeight != weight) {
      _selectedWeight = weight;
      notifyListeners();
    }
  }

  void addMockGrade({String? fallbackSubject}) {
    final sub = _selectedSubject.isNotEmpty ? _selectedSubject : (fallbackSubject ?? '');
    if (sub.isEmpty) return;
    _selectedSubject = sub;
    _mockGrades.add(
      MockGradeItem(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        subject: sub,
        value: _selectedGrade,
        weight: _selectedWeight,
      ),
    );
    notifyListeners();
  }

  void removeMockGrade(String id) {
    _mockGrades.removeWhere((g) => g.id == id);
    notifyListeners();
  }

  void clearAllMockGrades() {
    _mockGrades.clear();
    notifyListeners();
  }
}

/// Ghost Grade Calculator ("Szellem jegy kalkulátor") operating strictly in local ephemeral state.
class GhostGradeCalculator extends StatefulWidget {
  final List<Grade> realGrades;
  final Map<String, double> subjectAverages;
  final String Function(String) getDisplaySubject;
  final GhostGradeController? controller;
  final bool isInlinePanel;

  const GhostGradeCalculator({
    super.key,
    required this.realGrades,
    required this.subjectAverages,
    required this.getDisplaySubject,
    this.controller,
    this.isInlinePanel = false,
  });

  static void show(
    BuildContext context, {
    required List<Grade> realGrades,
    required Map<String, double> subjectAverages,
    required String Function(String) getDisplaySubject,
    GhostGradeController? controller,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => GhostGradeCalculator(
        realGrades: realGrades,
        subjectAverages: subjectAverages,
        getDisplaySubject: getDisplaySubject,
        controller: controller,
      ),
    );
  }

  @override
  State<GhostGradeCalculator> createState() => _GhostGradeCalculatorState();
}

class _GhostGradeCalculatorState extends State<GhostGradeCalculator> {
  late GhostGradeController _controller;
  bool _ownsController = false;

  @override
  void initState() {
    super.initState();
    if (widget.controller != null) {
      _controller = widget.controller!;
    } else {
      _controller = GhostGradeController();
      _ownsController = true;
    }
    _controller.ensureDefaultSubject(widget.subjectAverages.keys);
    _controller.addListener(_onControllerChanged);
  }

  @override
  void didUpdateWidget(covariant GhostGradeCalculator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      _controller.removeListener(_onControllerChanged);
      if (_ownsController) {
        _controller.dispose();
      }
      if (widget.controller != null) {
        _controller = widget.controller!;
        _ownsController = false;
      } else {
        _controller = GhostGradeController();
        _ownsController = true;
      }
      _controller.addListener(_onControllerChanged);
    }
    _controller.ensureDefaultSubject(widget.subjectAverages.keys);
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    if (_ownsController) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final subjects = widget.subjectAverages.keys.toList();
    _controller.ensureDefaultSubject(subjects);
    final selectedSubject = _controller.selectedSubject;
    final selectedGrade = _controller.selectedGrade;
    final selectedWeight = _controller.selectedWeight;
    final mockGrades = _controller.mockGrades;

    // Calculate real vs projected stats for the selected subject
    double realSubSum = 0;
    double realSubWeight = 0;
    for (final g in widget.realGrades) {
      final s = widget.getDisplaySubject(g.subject);
      // Same 1..5 filter as AppModel.subjectAverages, so the current average matches the subject card.
      if (s == selectedSubject && g.numericValue != null && g.numericValue! >= 1 && g.numericValue! <= 5) {
        final w = g.weight / 100.0;
        realSubSum += g.numericValue! * w;
        realSubWeight += w;
      }
    }

    double mockSubSum = 0;
    double mockSubWeight = 0;
    for (final mg in mockGrades.where((g) => g.subject == selectedSubject)) {
      final w = mg.weight / 100.0;
      mockSubSum += mg.value * w;
      mockSubWeight += w;
    }

    final currentSubAvg = realSubWeight > 0 ? (realSubSum / realSubWeight) : 0.0;
    final projectedSubWeight = realSubWeight + mockSubWeight;
    final projectedSubAvg =
        projectedSubWeight > 0 ? ((realSubSum + mockSubSum) / projectedSubWeight) : 0.0;
    final subDelta = projectedSubAvg - currentSubAvg;

    // Overall projected GPA calculation
    double totalRealSum = 0;
    double totalRealWeight = 0;
    for (final g in widget.realGrades) {
      if (g.numericValue != null && g.numericValue! >= 1 && g.numericValue! <= 5) {
        final w = g.weight / 100.0;
        totalRealSum += g.numericValue! * w;
        totalRealWeight += w;
      }
    }

    double totalMockSum = 0;
    double totalMockWeight = 0;
    for (final mg in mockGrades) {
      final w = mg.weight / 100.0;
      totalMockSum += mg.value * w;
      totalMockWeight += w;
    }

    final currentGpa = totalRealWeight > 0 ? (totalRealSum / totalRealWeight) : 0.0;
    final totalProjectedWeight = totalRealWeight + totalMockWeight;
    final projectedGpa =
        totalProjectedWeight > 0 ? ((totalRealSum + totalMockSum) / totalProjectedWeight) : 0.0;
    final gpaDelta = projectedGpa - currentGpa;

    Widget buildCalculatorContent([ScrollController? scrollController]) {
      return SingleChildScrollView(
        controller: scrollController,
        padding: widget.isInlinePanel
            ? const EdgeInsets.all(16)
            : const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!widget.isInlinePanel) ...[
              // Drag Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Title Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.calculate_outlined, color: colorScheme.primary, size: 24),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'Szellem jegy kalkulátor',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                if (mockGrades.isNotEmpty)
                  ConstrainedBox(
                    constraints: AdaptiveBreakpoints.touchTargetConstraints(context),
                    child: TextButton.icon(
                      onPressed: _controller.clearAllMockGrades,
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: const Text('Törlés'),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Próbálj ki hipotetikus érdemjegyeket. A szimuláció kizárólag helyi memóriában fut, semmilyen adatot nem ment.',
              style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.outline),
            ),
            const SizedBox(height: 16),

            // Real-Time Projection Comparison Card
            Card.filled(
              color: colorScheme.surfaceContainerHigh,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: colorScheme.outlineVariant, width: 1),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Subject average comparison
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tantárgyi átlag',
                            style: theme.textTheme.labelSmall?.copyWith(color: colorScheme.outline),
                          ),
                          const SizedBox(height: 4),
                          Wrap(
                            crossAxisAlignment: WrapCrossAlignment.end,
                            spacing: 6,
                            runSpacing: 2,
                            children: [
                              Text(
                                projectedSubAvg > 0 ? projectedSubAvg.toStringAsFixed(2) : '-',
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.getGradeColor(projectedSubAvg),
                                ),
                              ),
                              if (subDelta.abs() > 0.001)
                                Text(
                                  '(${subDelta > 0 ? '+' : ''}${subDelta.toStringAsFixed(2)})',
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    color: subDelta >= 0 ? AppColors.success : colorScheme.error,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                            ],
                          ),
                          Text(
                            'Jelenlegi: ${currentSubAvg > 0 ? currentSubAvg.toStringAsFixed(2) : '-'}',
                            style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.outline),
                          ),
                        ],
                      ),
                    ),
                    Container(width: 1, height: 48, color: colorScheme.outlineVariant),
                    const SizedBox(width: 16),

                    // Overall GPA comparison
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Összesített átlag',
                            style: theme.textTheme.labelSmall?.copyWith(color: colorScheme.outline),
                          ),
                          const SizedBox(height: 4),
                          Wrap(
                            crossAxisAlignment: WrapCrossAlignment.end,
                            spacing: 6,
                            runSpacing: 2,
                            children: [
                              Text(
                                projectedGpa > 0 ? projectedGpa.toStringAsFixed(2) : '-',
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.getGradeColor(projectedGpa),
                                ),
                              ),
                              if (gpaDelta.abs() > 0.001)
                                Text(
                                  '(${gpaDelta > 0 ? '+' : ''}${gpaDelta.toStringAsFixed(2)})',
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    color: gpaDelta >= 0 ? AppColors.success : colorScheme.error,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                            ],
                          ),
                          Text(
                            'Jelenlegi: ${currentGpa > 0 ? currentGpa.toStringAsFixed(2) : '-'}',
                            style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.outline),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Subject Dropdown
            Text(
              'Válassz tantárgyat',
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              key: ValueKey<String>(selectedSubject),
              initialValue: subjects.contains(selectedSubject)
                  ? selectedSubject
                  : (subjects.isNotEmpty ? subjects.first : null),
              isExpanded: true,
              decoration: const InputDecoration(
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              items: subjects.map((sub) {
                return DropdownMenuItem<String>(
                  value: sub,
                  child: Text(sub, overflow: TextOverflow.ellipsis),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) _controller.setSelectedSubject(val);
              },
            ),
            const SizedBox(height: 16),

            // Grade Selector (1 to 5) with accessible 48x48 touch targets
            Text(
              'Tervezett érdemjegy',
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [1, 2, 3, 4, 5].map((val) {
                final isSelected = selectedGrade == val;
                final gradeColor = AppColors.getGradeColor(val);

                return Semantics(
                  button: true,
                  selected: isSelected,
                  label: 'Tervezett érdemjegy: $val',
                  child: ConstrainedBox(
                    constraints: AdaptiveBreakpoints.touchTargetConstraints(context),
                    child: InkWell(
                      onTap: () => _controller.setSelectedGrade(val),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: 48,
                        height: 48,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isSelected ? gradeColor : colorScheme.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? gradeColor : colorScheme.outlineVariant,
                            width: 2,
                          ),
                        ),
                        child: Text(
                          '$val',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: isSelected ? Colors.black : colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Weight Selector
            Text(
              'Súlyozás',
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [50, 100, 200].map((w) {
                final isSelected = selectedWeight == w;
                return Semantics(
                  button: true,
                  selected: isSelected,
                  label: '$w% súlyozás',
                  child: ConstrainedBox(
                    constraints: AdaptiveBreakpoints.touchTargetConstraints(context),
                    child: FilterChip(
                      selected: isSelected,
                      label: Text('$w%'),
                      onSelected: (_) => _controller.setSelectedWeight(w),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Add Mock Grade Button
            FilledButton.icon(
              onPressed: () => _controller.addMockGrade(
                fallbackSubject: subjects.isNotEmpty ? subjects.first : 'Általános',
              ),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Szellem jegy hozzáadása'),
            ),

            // List of Added Mock Grades
            if (mockGrades.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text(
                'Aktív szellem jegyek (${mockGrades.length})',
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              ...mockGrades.reversed.map((mg) {
                final color = AppColors.getGradeColor(mg.value);
                return Card(
                  color: colorScheme.surfaceContainerLow,
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: colorScheme.outlineVariant),
                  ),
                  child: ListTile(
                    dense: true,
                    leading: Container(
                      width: 32,
                      height: 32,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: color),
                      ),
                      child: Text(
                        '${mg.value}',
                        style: TextStyle(color: color, fontWeight: FontWeight.w900),
                      ),
                    ),
                    title: Text(mg.subject, style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text('${mg.weight}% súly'),
                    trailing: ConstrainedBox(
                      constraints: AdaptiveBreakpoints.touchTargetConstraints(context),
                      child: IconButton(
                        tooltip: 'Szellem jegy törlése',
                        icon: const Icon(Icons.delete_outline_rounded, size: 20),
                        onPressed: () => _controller.removeMockGrade(mg.id),
                      ),
                    ),
                  ),
                );
              }),
            ],
          ],
        ),
      );
    }

    if (widget.isInlinePanel) {
      return Card.filled(
        color: colorScheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colorScheme.outlineVariant, width: 1),
        ),
        child: buildCalculatorContent(),
      );
    }

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => buildCalculatorContent(scrollController),
    );
  }
}

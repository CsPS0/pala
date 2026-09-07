import 'package:flutter/material.dart';
import '../state/app_model.dart';
import '../theme/pala_theme.dart';

class StatsView extends StatefulWidget {
  final AppModel appModel;

  const StatsView({super.key, required this.appModel});

  @override
  State<StatsView> createState() => _StatsViewState();
}

class _StatsViewState extends State<StatsView> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Target Calculator state
  String? _targetSubject;
  double _targetAverage = 4.5;
  int _targetWeight = 100;

  // Report Card Planner state (Subject -> Target Grade)
  final Map<String, int> _plannedGrades = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initPlannedGrades();
  }

  void _initPlannedGrades() {
    final subAvgs = widget.appModel.subjectAverages;
    for (final e in subAvgs.entries) {
      _plannedGrades[e.key] = e.value.round().clamp(1, 5);
    }
    if (subAvgs.isNotEmpty && _targetSubject == null) {
      _targetSubject = subAvgs.keys.first;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Color _getAvgColor(double val) {
    if (val >= 4.5) return PalaTheme.success;
    if (val >= 3.5) return const Color(0xFFFF8800);
    if (val >= 2.5) return PalaTheme.warning;
    if (val >= 1.5) return const Color(0xFFFF9500);
    return PalaTheme.danger;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.primaryColor;
    final subAvgs = widget.appModel.subjectAverages;
    final groupAvgs = widget.appModel.groupAveragesMap;

    if (_targetSubject == null && subAvgs.isNotEmpty) {
      _targetSubject = subAvgs.keys.first;
    }

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
              Tab(text: 'Tantárgyi Átlagok'),
              Tab(text: 'Célátlag'),
              Tab(text: 'Bizonyítvány'),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // 1. Subject Averages & Class Comparison Tab
          RefreshIndicator(
            onRefresh: widget.appModel.refreshAll,
            color: primary,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              children: [
                // Top Overall Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: PalaTheme.card,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: primary.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Tanulmányi Összesített Átlag', style: TextStyle(color: PalaTheme.textMuted, fontSize: 12)),
                          const SizedBox(height: 4),
                          Text(
                            widget.appModel.overallGpa > 0 ? widget.appModel.overallGpa.toStringAsFixed(2) : '--',
                            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: _getAvgColor(widget.appModel.overallGpa)),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: primary.withValues(alpha: 0.3)),
                        ),
                        child: Text('${subAvgs.length} Tantárgy', style: TextStyle(color: primary, fontWeight: FontWeight.w700, fontSize: 12)),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                if (subAvgs.isEmpty)
                  Center(child: Text('Nincsenek elérhető tantárgyi jegyek.', style: TextStyle(color: PalaTheme.textMuted)))
                else
                  ...subAvgs.entries.map((e) {
                    final subName = e.key;
                    final myAvg = e.value;
                    final classAvg = groupAvgs[subName];
                    final diff = classAvg != null ? (myAvg - classAvg) : null;
                    final gradeCount = widget.appModel.grades.where((g) => widget.appModel.getDisplaySubject(g.subject) == subName && g.numericValue != null).length;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(14),
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
                              Expanded(
                                child: Text(
                                  subName,
                                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Colors.white),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                myAvg.toStringAsFixed(2),
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                  color: _getAvgColor(myAvg),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('$gradeCount jegy rögzítve', style: TextStyle(color: PalaTheme.textMuted, fontSize: 11)),
                              if (classAvg != null)
                                Row(
                                  children: [
                                    Text('Osztály: ${classAvg.toStringAsFixed(2)}', style: TextStyle(color: PalaTheme.textMuted, fontSize: 11)),
                                    if (diff != null) ...[
                                      const SizedBox(width: 4),
                                      Text(
                                        '(${diff >= 0 ? "+" : ""}${diff.toStringAsFixed(2)})',
                                        style: TextStyle(
                                          color: diff >= 0 ? PalaTheme.success : PalaTheme.danger,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: (myAvg / 5.0).clamp(0.0, 1.0),
                              minHeight: 4,
                              backgroundColor: Colors.white10,
                              valueColor: AlwaysStoppedAnimation<Color>(_getAvgColor(myAvg)),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
              ],
            ),
          ),

          // 2. Target Average Calculator Tab
          ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: PalaTheme.card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: PalaTheme.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Célátlag Számítás', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Colors.white)),
                    const SizedBox(height: 4),
                    Text('Számold ki, hány darab 5-ös kell a kívánt átlag eléréséhez!', style: TextStyle(color: PalaTheme.textMuted, fontSize: 12)),
                    const SizedBox(height: 16),

                    // Subject Dropdown
                    Text('Tantárgy', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: PalaTheme.textMuted)),
                    const SizedBox(height: 6),
                    if (subAvgs.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: PalaTheme.sidebar,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: PalaTheme.border),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _targetSubject ?? subAvgs.keys.first,
                            isExpanded: true,
                            dropdownColor: PalaTheme.card,
                            items: subAvgs.keys.map((s) => DropdownMenuItem(value: s, child: Text(s, style: TextStyle(fontSize: 13)))).toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => _targetSubject = val);
                            },
                          ),
                        ),
                      ),

                    const SizedBox(height: 14),

                    // Target Average Slider / Selector
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Kívánt célátlag:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: PalaTheme.textMuted)),
                        Text(_targetAverage.toStringAsFixed(2), style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: primary)),
                      ],
                    ),
                    Slider(
                      value: _targetAverage,
                      min: 2.0,
                      max: 4.9,
                      divisions: 29,
                      activeColor: primary,
                      onChanged: (val) => setState(() => _targetAverage = double.parse(val.toStringAsFixed(2))),
                    ),

                    const SizedBox(height: 8),

                    // Weight Choice
                    Text('Tervezett jegy súlya (%):', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: PalaTheme.textMuted)),
                    const SizedBox(height: 6),
                    Row(
                      children: [100, 200, 50].map((w) {
                        final isSel = _targetWeight == w;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text('$w%'),
                            selected: isSel,
                            onSelected: (_) => setState(() => _targetWeight = w),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Result Box
              if (_targetSubject != null) ...[
                Builder(
                  builder: (context) {
                    final needed = widget.appModel.calculateRequiredFives(
                      _targetSubject!,
                      _targetAverage,
                      weight: _targetWeight,
                    );
                    final curAvg = subAvgs[_targetSubject!] ?? 0.0;

                    return Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [primary.withValues(alpha: 0.15), primary.withValues(alpha: 0.05)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: primary.withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Jelenlegi átlagod:', style: TextStyle(color: PalaTheme.textMuted, fontSize: 13)),
                              Text(curAvg.toStringAsFixed(2), style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Colors.white)),
                            ],
                          ),
                          Divider(height: 20),
                          if (curAvg >= _targetAverage)
                            Text(
                              'Már elérted a célátlagot ebből a tantárgyból!',
                              style: TextStyle(color: PalaTheme.success, fontWeight: FontWeight.w800, fontSize: 15),
                              textAlign: TextAlign.center,
                            )
                          else if (needed >= 50)
                            Text(
                              'A célátlag túl magas a jelenlegi jegyekhez képest.',
                              style: TextStyle(color: PalaTheme.danger, fontWeight: FontWeight.w700, fontSize: 14),
                              textAlign: TextAlign.center,
                            )
                          else
                            Column(
                              children: [
                                Text(
                                  'Még $needed db ($_targetWeight%-os) 5-ös kell',
                                  style: TextStyle(color: primary, fontWeight: FontWeight.w900, fontSize: 18),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'a(z) ${_targetAverage.toStringAsFixed(2)} eléréséhez!',
                                  style: TextStyle(color: PalaTheme.textMuted, fontSize: 13),
                                ),
                              ],
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ],
          ),

          // 3. Report Card Planner Tab
          ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: PalaTheme.card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: PalaTheme.border),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Tervezett Bizonyítvány Átlag', style: TextStyle(color: PalaTheme.textMuted, fontSize: 12)),
                        Builder(
                          builder: (context) {
                            if (_plannedGrades.isEmpty) return Text('--');
                            final sum = _plannedGrades.values.fold(0, (a, b) => a + b);
                            final plannedGpa = sum / _plannedGrades.length;
                            return Text(
                              plannedGpa.toStringAsFixed(2),
                              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: _getAvgColor(plannedGpa)),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text('Állítsd be a várható félévi vagy év végi jegyed minden tárgyhoz:', style: TextStyle(color: PalaTheme.textMuted, fontSize: 11)),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              ...subAvgs.keys.map((sub) {
                final planned = _plannedGrades[sub] ?? 5;
                final curAvg = subAvgs[sub] ?? 0.0;

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: PalaTheme.card,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: PalaTheme.border),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(sub, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Colors.white)),
                            Text('Jelenleg: ${curAvg.toStringAsFixed(2)}', style: TextStyle(fontSize: 11, color: PalaTheme.textMuted)),
                          ],
                        ),
                      ),
                      Row(
                        children: [5, 4, 3, 2, 1].map((val) {
                          final isSel = planned == val;
                          return GestureDetector(
                            onTap: () => setState(() => _plannedGrades[sub] = val),
                            child: Container(
                              margin: const EdgeInsets.only(left: 4),
                              width: 30,
                              height: 30,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: isSel ? primary : Colors.white.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '$val',
                                style: TextStyle(
                                  color: isSel ? Colors.black : Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ],
      ),
    );
  }
}

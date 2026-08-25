import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../state/app_model.dart';
import '../theme/pala_theme.dart';

class AbsencesView extends StatefulWidget {
  final AppModel appModel;

  const AbsencesView({super.key, required this.appModel});

  @override
  State<AbsencesView> createState() => _AbsencesViewState();
}

class _AbsencesViewState extends State<AbsencesView> {
  String _selectedFilter = 'Összes';

  void _openDangerZoneModal() {
    final totalMissed = widget.appModel.totalMissedHours;
    final dangerPercent = (totalMissed / 250.0).clamp(0.0, 1.0);
    final isCritical = totalMissed >= 200;
    final isWarning = totalMissed >= 150;

    final bySubject = widget.appModel.absencesBySubject;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: PalaTheme.sidebar,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final theme = Theme.of(ctx);
        final primary = theme.primaryColor;

        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Veszélyzóna Kalkulátor',
                    style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'A jogszabály szerint 250 mulasztott óra felett, vagy egy tantárgyból 30% hiányzás esetén osztályozó vizsga rendelhető el.',
                style: TextStyle(color: PalaTheme.textMuted, fontSize: 12),
              ),
              const SizedBox(height: 16),

              // 250h meter card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: PalaTheme.card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isCritical ? PalaTheme.danger : (isWarning ? PalaTheme.warning : PalaTheme.border),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Éves 250 Órás Limit', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                        Text(
                          '$totalMissed / 250 óra',
                          style: TextStyle(
                            color: isCritical ? PalaTheme.danger : (isWarning ? PalaTheme.warning : primary),
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: dangerPercent,
                        minHeight: 8,
                        backgroundColor: Colors.white10,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isCritical ? PalaTheme.danger : (isWarning ? PalaTheme.warning : PalaTheme.success),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isCritical
                          ? 'Kritikus veszélyzóna! Azonnali osztályozó vizsga kockázata áll fenn.'
                          : (isWarning ? 'Figyelem! Közeledsz a kritikus határhoz.' : 'Biztonságos zóna, a mulasztásaid alacsonyak.'),
                      style: TextStyle(
                        color: isCritical ? PalaTheme.danger : (isWarning ? PalaTheme.warning : PalaTheme.textMuted),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),
              const Text('Tantárgyi bontás:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
              const SizedBox(height: 8),

              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 180),
                child: bySubject.isEmpty
                    ? const Text('Nincsenek tantárgyi hiányzások.', style: TextStyle(color: PalaTheme.textMuted, fontSize: 12))
                    : ListView(
                        shrinkWrap: true,
                        children: bySubject.entries.map((e) {
                          final subDanger = e.value >= 25;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(child: Text(e.key, style: const TextStyle(fontSize: 13))),
                                Text(
                                  '${e.value} óra',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: subDanger ? PalaTheme.danger : Colors.white,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
              ),

              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Rendben'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _openExcuseGeneratorModal() {
    DateTime selectedDate = DateTime.now();
    String selectedReason = 'Betegség';
    final studentName = widget.appModel.student?.name ?? 'Tanuló';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: PalaTheme.sidebar,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final generatedText = widget.appModel.generateExcuseText(
              studentName: studentName,
              date: selectedDate,
              reason: selectedReason,
            );

            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Igazolás-kérvény Készítő',
                        style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text('Generálj hivatalos szülői igazoló szöveget egyetlen kattintással:', style: TextStyle(color: PalaTheme.textMuted, fontSize: 12)),
                  const SizedBox(height: 14),

                  // Reason Dropdown
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: PalaTheme.card,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: PalaTheme.border),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedReason,
                        isExpanded: true,
                        dropdownColor: PalaTheme.card,
                        items: ['Betegség', 'Családi ok', 'Hivatalos ügy'].map((r) => DropdownMenuItem(value: r, child: Text(r, style: const TextStyle(fontSize: 13)))).toList(),
                        onChanged: (val) {
                          if (val != null) setModalState(() => selectedReason = val);
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Preview Box
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: PalaTheme.card,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: PalaTheme.border),
                    ),
                    child: Text(
                      generatedText,
                      style: const TextStyle(color: PalaTheme.text, fontSize: 12, height: 1.4),
                    ),
                  ),

                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: generatedText));
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Igazolás szövege kimásolva a vágólapra!')),
                      );
                    },
                    icon: const Icon(Icons.copy, size: 16),
                    label: const Text('Másolás a vágólapra'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Color _getStatusColor(String status, String? type) {
    final sLower = status.toLowerCase();
    final tLower = type?.toLowerCase() ?? '';

    if (tLower == 'késés' || sLower == 'késés') return PalaTheme.warning;
    if (sLower.contains('igazolatlan')) return PalaTheme.danger;
    if (sLower.contains('igazolt')) return PalaTheme.success;
    return PalaTheme.warning;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.primaryColor;

    final filteredAbsences = widget.appModel.absences.where((a) {
      final s = a.status.toLowerCase();
      final t = a.type?.toLowerCase() ?? '';

      switch (_selectedFilter) {
        case 'Igazolt':
          return s.contains('igazolt') && !s.contains('igazolatlan') && t != 'késés';
        case 'Igazolatlan':
          return s.contains('igazolatlan') && t != 'késés';
        case 'Igazolandó':
          return (s.contains('igazolando') || s.contains('igazolandó') || s.contains('fuggoben')) && t != 'késés';
        case 'Késések':
          return t == 'késés' || (a.delayMinutes != null && a.delayMinutes! > 0);
        default:
          return true;
      }
    }).toList()
      ..sort((a, b) {
        final dA = a.date ?? DateTime(2000);
        final dB = b.date ?? DateTime(2000);
        return dB.compareTo(dA);
      });

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openExcuseGeneratorModal,
        backgroundColor: primary,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.note_add_outlined, size: 18),
        label: const Text('Igazolás Írása', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
      ),
      body: RefreshIndicator(
        onRefresh: widget.appModel.refreshAll,
        color: primary,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          children: [
            // KPI Summary Row
            Row(
              children: [
                Expanded(
                  child: _buildSummaryBox('Összes Óra', '${widget.appModel.totalMissedHours}', Colors.white),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildSummaryBox('Igazolt', '${widget.appModel.justifiedHours}', PalaTheme.success),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildSummaryBox('Igazolatlan', '${widget.appModel.unjustifiedHours}', widget.appModel.unjustifiedHours > 0 ? PalaTheme.danger : PalaTheme.textMuted),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildSummaryBox('Késés (perc)', '${widget.appModel.totalDelayMinutes}', PalaTheme.warning),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Parental Quota & Danger Zone Bar
            Container(
              padding: const EdgeInsets.all(14),
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
                      const Text('Szülői Keretfigyelő', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                      Text(
                        '${widget.appModel.usedParentalDays} / ${widget.appModel.parentalQuota} nap felhasznált',
                        style: TextStyle(
                          color: widget.appModel.usedParentalDays >= widget.appModel.parentalQuota ? PalaTheme.danger : primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (widget.appModel.usedParentalDays / widget.appModel.parentalQuota).clamp(0.0, 1.0),
                      minHeight: 6,
                      backgroundColor: Colors.white10,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        widget.appModel.usedParentalDays >= widget.appModel.parentalQuota ? PalaTheme.danger : primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '250 órás határ: ${widget.appModel.totalMissedHours} óra',
                        style: const TextStyle(fontSize: 11, color: PalaTheme.textMuted),
                      ),
                      GestureDetector(
                        onTap: _openDangerZoneModal,
                        child: Text(
                          'Veszélyzóna Kalkulátor >',
                          style: TextStyle(fontSize: 11, color: primary, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Filter Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['Összes', 'Igazolt', 'Igazolatlan', 'Igazolandó', 'Késések'].map((f) {
                  final isSelected = _selectedFilter == f;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      label: Text(f),
                      selected: isSelected,
                      onSelected: (_) => setState(() => _selectedFilter = f),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 14),

            // Absence list
            if (filteredAbsences.isEmpty)
              Container(
                padding: const EdgeInsets.all(32),
                alignment: Alignment.center,
                child: const Text('Nincsenek a feltételnek megfelelő mulasztások.', style: TextStyle(color: PalaTheme.textMuted)),
              )
            else
              ...filteredAbsences.map((a) {
                final statusCol = _getStatusColor(a.status, a.type);
                final isDelay = a.type?.toLowerCase() == 'késés' || (a.delayMinutes != null && a.delayMinutes! > 0);

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: PalaTheme.card,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: PalaTheme.border),
                  ),
                  child: Row(
                    children: [
                      // Icon badge
                      Container(
                        width: 36,
                        height: 36,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: statusCol.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          isDelay ? Icons.timer_outlined : Icons.person_off_outlined,
                          color: statusCol,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.appModel.getDisplaySubject(a.subject),
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Colors.white),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${a.date != null ? DateFormat('yyyy.MM.dd').format(a.date!) : "-"}${a.type != null && a.type!.isNotEmpty ? " • ${a.type}" : ""}',
                              style: const TextStyle(fontSize: 11, color: PalaTheme.textMuted),
                            ),
                          ],
                        ),
                      ),

                      // Status pill
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusCol.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: statusCol.withValues(alpha: 0.4)),
                        ),
                        child: Text(
                          isDelay ? '${a.delayMinutes ?? 0} perc' : a.status,
                          style: TextStyle(color: statusCol, fontWeight: FontWeight.w700, fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryBox(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      decoration: BoxDecoration(
        color: PalaTheme.card,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: PalaTheme.border),
      ),
      child: Column(
        children: [
          Text(value, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: color)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 9, color: PalaTheme.textMuted), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

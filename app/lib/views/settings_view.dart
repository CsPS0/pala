import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import '../state/app_model.dart';
import '../theme/pala_theme.dart';
import 'wrapped_view.dart';

class SettingsView extends StatefulWidget {
  final AppModel appModel;

  const SettingsView({super.key, required this.appModel});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _customAliasController = TextEditingController();
  final _quotaController = TextEditingController();
  String _aliasCategory = 'subject'; // 'subject' | 'teacher'
  String _origAliasValue = '';
  int _aliasResetKey = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _quotaController.text = widget.appModel.parentalQuota.toString();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _customAliasController.dispose();
    _quotaController.dispose();
    super.dispose();
  }

  /// Live name list for the alias "original name" picker. Teachers come from
  /// two sources merged together: the messaging directory (getTeachers, an
  /// e-Ügyintézés endpoint that can come back empty for some real accounts)
  /// and the timetable (TanarNeve/HelyettesTanarNeve, from the same reliable
  /// gateway grades/timetable already use) so a teacher still shows up even
  /// when the messaging directory fails or hasn't graded the student yet.
  /// Subjects come from the full-curriculum group averages, not just
  /// subjects that already have a grade.
  List<String> get _aliasOriginalOptions {
    if (_aliasCategory == 'teacher') {
      final names = <String>{};
      for (final t in widget.appModel.teachers) {
        final n = (t['Nev'] ?? t['nev'] ?? t['name'])?.toString();
        if (n != null && n.isNotEmpty) names.add(n);
      }
      for (final entry in widget.appModel.timetable) {
        if (entry.teacher != null && entry.teacher!.isNotEmpty) names.add(entry.teacher!);
        if (entry.substituteTeacher != null && entry.substituteTeacher!.isNotEmpty) {
          names.add(entry.substituteTeacher!);
        }
      }
      final sorted = names.toList();
      sorted.sort();
      return sorted;
    }
    // groupAveragesMap keys are already alias-resolved (display names), so we
    // read the raw curriculum list directly to offer the true original names.
    final names = widget.appModel.groupAverages
        .map((a) => a is Map ? (a['Tantargy']?['Nev'])?.toString() : null)
        .whereType<String>()
        .where((n) => n.isNotEmpty)
        .toSet()
        .toList();
    names.sort();
    return names;
  }

  void _addAlias() {
    final orig = _origAliasValue.trim();
    final custom = _customAliasController.text.trim();
    if (orig.isEmpty || custom.isEmpty) return;

    widget.appModel.setAlias(orig, custom);
    setState(() {
      _origAliasValue = '';
      _aliasResetKey++;
    });
    _customAliasController.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Átnevezés elmentve: $orig -> $custom')),
    );
  }

  void _saveQuota() {
    final q = int.tryParse(_quotaController.text.trim());
    if (q != null && q > 0) {
      widget.appModel.setParentalQuota(q);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Szülői keret elmentve: $q nap')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.primaryColor;
    final student = widget.appModel.student;

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
            labelStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            tabs: const [
              Tab(text: 'Tanulói Adatlap'),
              Tab(text: 'Beállítások'),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // 1. Student Profile Tab
          RefreshIndicator(
            onRefresh: widget.appModel.refreshAll,
            color: primary,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              children: [
                if (student != null) ...[
                  // Personal Information Card
                  _buildSectionCard(
                    title: 'Személyes Adatok',
                    children: [
                      _buildInfoRow('Teljes név', student.name),
                      _buildInfoRow('Születési név', student.birthName != null && student.birthName!.isNotEmpty ? student.birthName! : student.name),
                      _buildInfoRow(
                        'Születési hely és idő',
                        '${student.birthPlace != null && student.birthPlace!.isNotEmpty ? student.birthPlace : ""}${student.birthDate != null ? ", ${student.birthDate}" : ""}',
                      ),
                      _buildInfoRow('Anyja neve', student.mothersName ?? '-'),
                      _buildInfoRow('Oktatási Azonosító', student.uid ?? '-', highlight: true),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Contact Card
                  _buildSectionCard(
                    title: 'Elérhetőség & Cím',
                    children: [
                      _buildInfoRow('Email', student.email ?? '-'),
                      _buildInfoRow('Telefonszám', student.phone ?? '-'),
                      _buildInfoRow('Lakcímek', student.addresses.isNotEmpty ? student.addresses.join(', ') : '-'),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Institution Card
                  _buildSectionCard(
                    title: 'Oktatási Intézmény',
                    children: [
                      _buildInfoRow('Intézmény', student.institutionName),
                      _buildInfoRow('Karbantartás', student.nextDowntime != null ? DateFormat('yyyy.MM.dd HH:mm').format(student.nextDowntime!) : 'Nincs tervezett leállás'),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Guardians Card
                  _buildSectionCard(
                    title: 'Gondviselők (${student.guardians.length})',
                    children: student.guardians.isEmpty
                        ? [Text('Nincsenek elérhető gondviselői adatok.', style: TextStyle(color: PalaTheme.textMuted, fontSize: 13))]
                        : student.guardians.map((g) {
                            final gName = g['Nev'] ?? g['nev'] ?? g['name'] ?? 'Gondviselő';
                            final gType = g['Tipus'] ?? g['tipus'] ?? g['type'] ?? 'Gondviselő';
                            final gEmail = g['EmailCim'] ?? g['email'] ?? '';
                            final gPhone = g['Telefonszam'] ?? g['phone'] ?? '';

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(gName.toString(), style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white, fontSize: 14)),
                                  const SizedBox(height: 2),
                                  Text('$gType • $gEmail • $gPhone', style: TextStyle(color: PalaTheme.textMuted, fontSize: 12)),
                                ],
                              ),
                            );
                          }).toList(),
                  ),
                ] else
                  Center(child: Text('Nincsenek elérhető adatok.', style: TextStyle(color: PalaTheme.textMuted))),
              ],
            ),
          ),

          // 2. Settings Tab
          ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            children: [


              // Appearance Card
              _buildSectionCard(
                title: 'Megjelenés',
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Sötét mód',
                              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: PalaTheme.text),
                            ),
                            Text(
                              widget.appModel.isDarkMode
                                  ? 'Sötét felület (alapértelmezett).'
                                  : 'Világos felület.',
                              style: TextStyle(color: PalaTheme.textMuted, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: widget.appModel.isDarkMode,
                        activeTrackColor: PalaTheme.accent,
                        onChanged: (val) {
                          widget.appModel.setDarkMode(val);
                          setState(() {});
                        },
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Parental Quota Card
              _buildSectionCard(
                title: 'Szülői Igazolás Keret',
                children: [
                  Text('Állítsd be az éves szülői igazolási keretet (nap/tanév):', style: TextStyle(color: PalaTheme.textMuted, fontSize: 13)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _quotaController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(hintText: '5'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: _saveQuota,
                        child: Text('Mentés'),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Subject/Teacher Aliases Card
              _buildSectionCard(
                title: 'Tantárgy & Tanár Átnevezések (Aliasok)',
                children: [
                  Text('Egyéni rövid nevek hozzáadása hosszú tantárgyakhoz vagy tanárnevekhez. Nem kell pontosan tudnod a nevet — kezdj el gépelni, vagy válassz a listából:', style: TextStyle(color: PalaTheme.textMuted, fontSize: 13)),
                  const SizedBox(height: 10),
                  ToggleButtons(
                    borderRadius: BorderRadius.circular(8),
                    constraints: const BoxConstraints(minHeight: 36, minWidth: 96),
                    isSelected: [_aliasCategory == 'subject', _aliasCategory == 'teacher'],
                    onPressed: (i) => setState(() {
                      _aliasCategory = i == 0 ? 'subject' : 'teacher';
                      _origAliasValue = '';
                      _aliasResetKey++;
                    }),
                    children: [
                      Text('Tantárgy'),
                      Text('Tanár'),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final fieldWidth = constraints.maxWidth;
                            return Autocomplete<String>(
                          key: ValueKey('$_aliasCategory-$_aliasResetKey'),
                          optionsBuilder: (TextEditingValue value) {
                            if (value.text.isEmpty) return _aliasOriginalOptions;
                            final q = value.text.toLowerCase();
                            return _aliasOriginalOptions.where((o) => o.toLowerCase().contains(q));
                          },
                          onSelected: (selection) => _origAliasValue = selection,
                          fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                            return TextField(
                              controller: controller,
                              focusNode: focusNode,
                              onChanged: (v) => _origAliasValue = v,
                              decoration: InputDecoration(
                                hintText: _aliasCategory == 'teacher' ? 'Tanár neve' : 'Tantárgy neve',
                              ),
                            );
                          },
                          optionsViewBuilder: (context, onSelected, options) {
                            // Options overlays get unbounded constraints, so an
                            // explicit width/height (not just ConstrainedBox max*)
                            // is required or the Material can collapse to zero size.
                            final listHeight = (options.length * 42.0).clamp(0.0, 220.0);
                            return Align(
                              alignment: Alignment.topLeft,
                              child: Material(
                                elevation: 4,
                                borderRadius: BorderRadius.circular(8),
                                color: PalaTheme.sidebar,
                                child: SizedBox(
                                  width: fieldWidth,
                                  height: listHeight,
                                  child: ListView.builder(
                                    padding: EdgeInsets.zero,
                                    itemCount: options.length,
                                    itemBuilder: (context, index) {
                                      final option = options.elementAt(index);
                                      return InkWell(
                                        onTap: () => onSelected(option),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                          child: Text(option, style: TextStyle(fontSize: 13)),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            );
                          },
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _customAliasController,
                          decoration: const InputDecoration(hintText: 'Új név'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: _addAlias,
                    child: Text('+ Hozzáadás'),
                  ),
                  const SizedBox(height: 12),
                  if (widget.appModel.aliases.isEmpty)
                    Text('Nincsenek egyéni átnevezések.', style: TextStyle(color: PalaTheme.textMuted, fontSize: 12))
                  else
                    ...widget.appModel.aliases.keys.map((k) => Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: PalaTheme.sidebar,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('$k -> ${widget.appModel.aliases[k]}', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                          IconButton(
                            icon: Icon(Icons.delete_outline, size: 18, color: PalaTheme.danger),
                            onPressed: () => widget.appModel.removeAlias(k),
                          ),
                        ],
                      ),
                    )),
                ],
              ),
              const SizedBox(height: 12),

              // Tools & Summary
              _buildSectionCard(
                title: 'Eszközök & Összesítők',
                children: [
                  // Pala Wrapped Button
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF8800).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.auto_awesome, color: Color(0xFFFF8800), size: 20),
                    ),
                    title: Text('Pala Wrapped', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                    subtitle: Text('Nézd meg az idei tanéved összesítőjét!', style: TextStyle(color: PalaTheme.textMuted, fontSize: 12)),
                    trailing: Icon(Icons.chevron_right, size: 20, color: PalaTheme.textMuted),
                    onTap: () => WrappedModal.show(context, widget.appModel),
                  ),
                  Divider(height: 16),

                  // Export Grades
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.download, color: primary, size: 20),
                    ),
                    title: Text('Jegyek Exportálása (CSV)', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                    subtitle: Text('Mentés CSV fájlként és másolás a vágólapra', style: TextStyle(color: PalaTheme.textMuted, fontSize: 12)),
                    onTap: () async {
                      final csv = widget.appModel.exportGradesCsv();
                      Clipboard.setData(ClipboardData(text: csv));
                      String? savedPath;
                      try {
                        final home = Platform.environment['USERPROFILE'] ?? Platform.environment['HOME'] ?? '.';
                        final downloadsPath = '$home${Platform.pathSeparator}Downloads';
                        final downloadsDir = Directory(downloadsPath);
                        final outDir = downloadsDir.existsSync() ? downloadsDir.path : (await getApplicationDocumentsDirectory()).path;
                        final file = File('$outDir${Platform.pathSeparator}jegyek_export.csv');
                        await file.writeAsString(csv);
                        savedPath = file.path;
                      } catch (_) {}

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(savedPath != null
                                ? 'Jegyek CSV elmentve: $savedPath'
                                : 'Jegyek CSV sikeresen kimásolva a vágólapra!'),
                            backgroundColor: PalaTheme.success,
                          ),
                        );
                      }
                    },
                  ),
                  Divider(height: 16),

                  // Export Absences
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: PalaTheme.danger.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.file_copy_outlined, color: PalaTheme.danger, size: 20),
                    ),
                    title: Text('Mulasztások Exportálása (CSV)', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                    subtitle: Text('Mentés CSV fájlként és másolás a vágólapra', style: TextStyle(color: PalaTheme.textMuted, fontSize: 12)),
                    onTap: () async {
                      final csv = widget.appModel.exportAbsencesCsv();
                      Clipboard.setData(ClipboardData(text: csv));
                      String? savedPath;
                      try {
                        final home = Platform.environment['USERPROFILE'] ?? Platform.environment['HOME'] ?? '.';
                        final downloadsPath = '$home${Platform.pathSeparator}Downloads';
                        final downloadsDir = Directory(downloadsPath);
                        final outDir = downloadsDir.existsSync() ? downloadsDir.path : (await getApplicationDocumentsDirectory()).path;
                        final file = File('$outDir${Platform.pathSeparator}mulasztasok_export.csv');
                        await file.writeAsString(csv);
                        savedPath = file.path;
                      } catch (_) {}

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(savedPath != null
                                ? 'Mulasztások CSV elmentve: $savedPath'
                                : 'Mulasztások CSV sikeresen kimásolva a vágólapra!'),
                            backgroundColor: PalaTheme.success,
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // System Integration Card
              _buildSectionCard(
                title: 'Komponensek & Rendszerintegráció',
                children: [
                  Text('Asztali indítási parancsikonok és parancssori (TUI / CLI) elérés:', style: TextStyle(color: PalaTheme.textMuted, fontSize: 12)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {
                          Clipboard.setData(const ClipboardData(text: 'pala --install-shortcut'));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Parancs kimásolva a vágólapra: pala --install-shortcut')),
                          );
                        },
                        icon: Icon(Icons.desktop_windows_outlined, size: 16),
                        label: Text('Start Menü Parancsikon', style: TextStyle(fontSize: 12)),
                      ),
                      OutlinedButton.icon(
                        onPressed: () {
                          Clipboard.setData(const ClipboardData(text: 'pala --help'));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Parancssori segítség kimásolva (pala --help)')),
                          );
                        },
                        icon: Icon(Icons.terminal, size: 16),
                        label: Text('CLI & TUI Parancsok', style: TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Storage & Cache Card
              _buildSectionCard(
                title: 'Tárhely & Gyorsítótár',
                children: [
                  Text('Törölheted a helyben mentett gyorsítótárat és feladat állapotokat:', style: TextStyle(color: PalaTheme.textMuted, fontSize: 12)),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: () async {
                      await widget.appModel.clearLocalCache();
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Helyi gyorsítótár kiürítve!')),
                      );
                    },
                    icon: Icon(Icons.delete_sweep_outlined, size: 18),
                    label: Text('Gyorsítótár ürítése'),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Account & Logout
              OutlinedButton.icon(
                onPressed: () => widget.appModel.logout(),
                style: OutlinedButton.styleFrom(
                  foregroundColor: PalaTheme.danger,
                  side: BorderSide(color: PalaTheme.danger),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: Icon(Icons.logout, size: 18),
                label: Text('Kijelentkezés a fiókból', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({required String title, required List<Widget> children}) {
    return Material(
      color: PalaTheme.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: PalaTheme.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool highlight = false}) {
    final theme = Theme.of(context);
    final primary = theme.primaryColor;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: PalaTheme.textMuted, fontSize: 13)),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value.isNotEmpty ? value : '-',
              textAlign: TextAlign.end,
              style: TextStyle(
                color: highlight ? primary : Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}


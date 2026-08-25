import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
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
  final _origAliasController = TextEditingController();
  final _customAliasController = TextEditingController();
  final _quotaController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _quotaController.text = widget.appModel.parentalQuota.toString();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _origAliasController.dispose();
    _customAliasController.dispose();
    _quotaController.dispose();
    super.dispose();
  }

  void _addAlias() {
    final orig = _origAliasController.text.trim();
    final custom = _customAliasController.text.trim();
    if (orig.isEmpty || custom.isEmpty) return;

    widget.appModel.setAlias(orig, custom);
    _origAliasController.clear();
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
            labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
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
                        ? [const Text('Nincsenek elérhető gondviselői adatok.', style: TextStyle(color: PalaTheme.textMuted, fontSize: 13))]
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
                                  Text(gName.toString(), style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white, fontSize: 14)),
                                  const SizedBox(height: 2),
                                  Text('$gType • $gEmail • $gPhone', style: const TextStyle(color: PalaTheme.textMuted, fontSize: 12)),
                                ],
                              ),
                            );
                          }).toList(),
                  ),
                ] else
                  const Center(child: Text('Nincsenek elérhető adatok.', style: TextStyle(color: PalaTheme.textMuted))),
              ],
            ),
          ),

          // 2. Settings Tab
          ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            children: [
              // Theme Accent Picker Card
              _buildSectionCard(
                title: 'Kiemelő Színtéma',
                children: [
                  const Text('Válassz színtémát az alkalmazáshoz:', style: TextStyle(color: PalaTheme.textMuted, fontSize: 13)),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: PalaTheme.accents.keys.map((acc) {
                      final col = PalaTheme.accents[acc]!;
                      final isSelected = widget.appModel.themeAccent == acc;
                      return GestureDetector(
                        onTap: () => widget.appModel.setThemeAccent(acc),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: col,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? Colors.white : Colors.transparent,
                              width: 3,
                            ),
                            boxShadow: isSelected
                                ? [BoxShadow(color: col.withValues(alpha: 0.5), blurRadius: 10, spreadRadius: 2)]
                                : null,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Parental Quota Card
              _buildSectionCard(
                title: 'Szülői Igazolás Keret',
                children: [
                  const Text('Állítsd be az éves szülői igazolási keretet (nap/tanév):', style: TextStyle(color: PalaTheme.textMuted, fontSize: 13)),
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
                        child: const Text('Mentés'),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Subject Aliases Card
              _buildSectionCard(
                title: 'Tantárgy Átnevezések (Aliasok)',
                children: [
                  const Text('Egyéni rövid nevek hozzáadása hosszú tantárgyakhoz:', style: TextStyle(color: PalaTheme.textMuted, fontSize: 13)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _origAliasController,
                          decoration: const InputDecoration(hintText: 'Eredeti név'),
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
                    child: const Text('+ Hozzáadás'),
                  ),
                  const SizedBox(height: 12),
                  if (widget.appModel.aliases.isEmpty)
                    const Text('Nincsenek egyéni átnevezések.', style: TextStyle(color: PalaTheme.textMuted, fontSize: 12))
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
                          Text('$k -> ${widget.appModel.aliases[k]}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 18, color: PalaTheme.danger),
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
                      child: const Icon(Icons.auto_awesome, color: Color(0xFFFF8800), size: 20),
                    ),
                    title: const Text('Pala Wrapped', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                    subtitle: const Text('Nézd meg az idei tanéved összesítőjét!', style: TextStyle(color: PalaTheme.textMuted, fontSize: 12)),
                    trailing: const Icon(Icons.chevron_right, size: 20, color: PalaTheme.textMuted),
                    onTap: () => WrappedModal.show(context, widget.appModel),
                  ),
                  const Divider(height: 16),

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
                    title: const Text('Jegyek Exportálása (CSV)', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                    subtitle: const Text('Jegyek másolása CSV formátumban a vágólapra', style: TextStyle(color: PalaTheme.textMuted, fontSize: 12)),
                    onTap: () {
                      final csv = widget.appModel.exportGradesCsv();
                      Clipboard.setData(ClipboardData(text: csv));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Jegyek CSV sikeresen kimásolva a vágólapra!')),
                      );
                    },
                  ),
                  const Divider(height: 16),

                  // Export Absences
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: PalaTheme.danger.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.file_copy_outlined, color: PalaTheme.danger, size: 20),
                    ),
                    title: const Text('Mulasztások Exportálása (CSV)', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                    subtitle: const Text('Hiányzások másolása CSV formátumban a vágólapra', style: TextStyle(color: PalaTheme.textMuted, fontSize: 12)),
                    onTap: () {
                      final csv = widget.appModel.exportAbsencesCsv();
                      Clipboard.setData(ClipboardData(text: csv));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Mulasztások CSV sikeresen kimásolva a vágólapra!')),
                      );
                    },
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Storage & Cache Card
              _buildSectionCard(
                title: 'Tárhely & Gyorsítótár',
                children: [
                  const Text('Törölheted a helyben mentett gyorsítótárat és feladat állapotokat:', style: TextStyle(color: PalaTheme.textMuted, fontSize: 12)),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: () async {
                      await widget.appModel.clearLocalCache();
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Helyi gyorsítótár kiürítve!')),
                      );
                    },
                    icon: const Icon(Icons.delete_sweep_outlined, size: 18),
                    label: const Text('Gyorsítótár ürítése'),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Account & Logout
              OutlinedButton.icon(
                onPressed: () => widget.appModel.logout(),
                style: OutlinedButton.styleFrom(
                  foregroundColor: PalaTheme.danger,
                  side: const BorderSide(color: PalaTheme.danger),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.logout, size: 18),
                label: const Text('Kijelentkezés a fiókból', style: TextStyle(fontWeight: FontWeight.w700)),
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
        side: const BorderSide(color: PalaTheme.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
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
          Text(label, style: const TextStyle(color: PalaTheme.textMuted, fontSize: 13)),
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


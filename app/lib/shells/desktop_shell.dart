import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../state/app_model.dart';
import '../theme/pala_theme.dart';
import '../views/absences_view.dart';
import '../views/dashboard_view.dart';
import '../views/global_search_view.dart';
import '../views/grades_view.dart';
import '../views/settings_view.dart';
import '../views/stats_view.dart';
import '../views/tasks_view.dart';
import '../views/timetable_view.dart';
import '../views/wrapped_view.dart';

/// Sidebar + multi-pane layout for Windows/macOS/Linux. Desktop-only
/// screens or panels (more detail, more stats) belong here, not in
/// [MobileShell] — the two shells share only the view widgets and
/// AppModel, not their navigation chrome.
class DesktopShell extends StatefulWidget {
  final AppModel appModel;

  const DesktopShell({super.key, required this.appModel});

  @override
  State<DesktopShell> createState() => _DesktopShellState();
}

class _DesktopShellState extends State<DesktopShell> {
  int _currentIndex = 0;
  Timer? _clockTimer;
  DateTime _currentTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _currentTime = DateTime.now());
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    super.dispose();
  }

  static const _titles = [
    'Vezérlőpult',
    'Érdemjegyek',
    'Órarend',
    'Feladatok & Üzenetek',
    'Mulasztások',
    'Statisztikák & Célátlag',
    'Tanulói Adatlap & Beállítások',
  ];

  static const _subtitles = [
    'Aktuális órák, határidők és gyors műveletek',
    'Jegyek részletesen, szűrők és szimulációk',
    'Heti és napi tanórák részletes nézete',
    'Házi feladatok, dolgozatok és tanári üzenetek',
    'Hiányzások, késések és 250 órás veszélyzóna',
    'Tantárgyi átlagok és bizonyítvány tervező',
    'Fiókadatok, testreszabás és exportálás',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.primaryColor;

    final screens = [
      DashboardView(appModel: widget.appModel),
      GradesView(appModel: widget.appModel),
      TimetableView(appModel: widget.appModel),
      TasksView(appModel: widget.appModel),
      AbsencesView(appModel: widget.appModel),
      StatsView(appModel: widget.appModel),
      SettingsView(appModel: widget.appModel),
    ];

    return Scaffold(
      body: Row(
        children: [
          _buildSidebar(primary),
          Expanded(
            child: Column(
              children: [
                _buildHeader(primary),
                _buildMaintenanceBanner(),
                Expanded(
                  child: screens[_currentIndex.clamp(0, screens.length - 1)],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMaintenanceBanner() {
    if (!widget.appModel.isMaintenanceMode) return const SizedBox.shrink();
    final status = widget.appModel.maintenanceStatusCode;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      color: PalaTheme.warning.withValues(alpha: 0.15),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: PalaTheme.warning, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'A Kréta rendszer jelenleg karbantartás alatt áll${status != null ? ' (HTTP $status)' : ''}. Korábban mentett adatokat látsz.',
              style: const TextStyle(color: PalaTheme.warning, fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
          TextButton(
            onPressed: widget.appModel.isLoading ? null : () => widget.appModel.refreshAll(),
            child: const Text('Újrapróbálás', style: TextStyle(color: PalaTheme.warning, fontWeight: FontWeight.w800, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar(Color primary) {
    final student = widget.appModel.student;
    final studentName = student?.name ?? (widget.appModel.isDemo ? 'Teszt Elek' : 'Tanuló');
    final schoolName = student?.institutionName ?? 'Kréta Rendszer';

    final navItems = [
      {'title': 'Vezérlőpult', 'icon': Icons.dashboard_outlined, 'activeIcon': Icons.dashboard},
      {'title': 'Érdemjegyek', 'icon': Icons.school_outlined, 'activeIcon': Icons.school},
      {'title': 'Órarend', 'icon': Icons.calendar_today_outlined, 'activeIcon': Icons.calendar_today},
      {'title': 'Feladatok & Üzenetek', 'icon': Icons.assignment_outlined, 'activeIcon': Icons.assignment},
      {'title': 'Mulasztások', 'icon': Icons.person_off_outlined, 'activeIcon': Icons.person_off},
      {'title': 'Statisztikák', 'icon': Icons.insights_outlined, 'activeIcon': Icons.insights},
      {'title': 'Beállítások & Profil', 'icon': Icons.settings_outlined, 'activeIcon': Icons.settings},
    ];

    final collapsed = widget.appModel.isSidebarCollapsed;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: collapsed ? 72 : 250,
      // The label text swaps in/out instantly on `collapsed` while the width
      // above tweens over 180ms, so mid-animation frames briefly have full
      // labels laid out against a still-narrow container. Clip instead of
      // asserting/overflowing during that transition.
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: PalaTheme.sidebar,
        border: Border(right: BorderSide(color: PalaTheme.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: collapsed
                ? Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: primary, borderRadius: BorderRadius.circular(6)),
                        child: const Text(
                          'P',
                          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 13),
                        ),
                      ),
                      const SizedBox(height: 8),
                      _sidebarToggleButton(collapsed),
                    ],
                  )
                : Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: primary, borderRadius: BorderRadius.circular(6)),
                        child: const Text(
                          'PALA',
                          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'DESKTOP',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14, letterSpacing: 1.5),
                        ),
                      ),
                      _sidebarToggleButton(collapsed),
                    ],
                  ),
          ),
          Container(
            margin: EdgeInsets.symmetric(horizontal: collapsed ? 8 : 14, vertical: 4),
            padding: EdgeInsets.all(collapsed ? 8 : 12),
            decoration: BoxDecoration(
              color: PalaTheme.card,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: PalaTheme.border),
            ),
            child: Row(
              mainAxisAlignment: collapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
              children: [
                Tooltip(
                  message: collapsed ? '$studentName\n$schoolName' : '',
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: primary.withValues(alpha: 0.2),
                    child: Text(
                      studentName.isNotEmpty ? studentName[0] : 'P',
                      style: TextStyle(color: primary, fontWeight: FontWeight.w900, fontSize: 14),
                    ),
                  ),
                ),
                if (!collapsed) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          studentName,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Colors.white),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          schoolName,
                          style: TextStyle(color: PalaTheme.textMuted, fontSize: 11),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 10),
          Divider(height: 1, color: PalaTheme.border),
          const SizedBox(height: 10),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              itemCount: navItems.length,
              itemBuilder: (context, idx) {
                final item = navItems[idx];
                final isSelected = _currentIndex == idx;

                final navButton = Material(
                  color: isSelected ? primary.withValues(alpha: 0.15) : Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: isSelected ? BorderSide(color: primary.withValues(alpha: 0.3)) : BorderSide.none,
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => setState(() => _currentIndex = idx),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: collapsed ? 0 : 12, vertical: 10),
                      child: Row(
                        mainAxisAlignment: collapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
                        children: [
                          Icon(
                            isSelected ? item['activeIcon'] as IconData : item['icon'] as IconData,
                            size: 18,
                            color: isSelected ? primary : PalaTheme.textMuted,
                          ),
                          if (!collapsed) ...[
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                item['title'] as String,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                  color: isSelected ? Colors.white : PalaTheme.textMuted,
                                ),
                              ),
                            ),
                            if (isSelected)
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(shape: BoxShape.circle, color: primary),
                              ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );

                return Container(
                  margin: const EdgeInsets.only(bottom: 4),
                  child: collapsed ? Tooltip(message: item['title'] as String, child: navButton) : navButton,
                );
              },
            ),
          ),
          Divider(height: 1, color: PalaTheme.border),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _sidebarFooterAction(
                  collapsed: collapsed,
                  icon: Icons.auto_awesome,
                  iconColor: const Color(0xFFFF8800),
                  label: 'Pala Wrapped 2025',
                  background: const Color(0xFFFF8800).withValues(alpha: 0.12),
                  border: const Color(0xFFFF8800).withValues(alpha: 0.3),
                  onTap: () => WrappedModal.show(context, widget.appModel),
                ),
                const SizedBox(height: 10),
                if (collapsed)
                  Center(
                    child: Tooltip(
                      message: widget.appModel.isDarkMode ? 'Világos módra váltás' : 'Sötét módra váltás',
                      child: IconButton(
                        icon: Icon(widget.appModel.isDarkMode ? Icons.dark_mode_outlined : Icons.light_mode_outlined, size: 18),
                        color: PalaTheme.textMuted,
                        onPressed: () => widget.appModel.setDarkMode(!widget.appModel.isDarkMode),
                      ),
                    ),
                  )
                else
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Sötét mód:', style: TextStyle(color: PalaTheme.textMuted, fontSize: 11, fontWeight: FontWeight.w600)),
                      Switch(
                        value: widget.appModel.isDarkMode,
                        activeTrackColor: PalaTheme.accent,
                        onChanged: (val) => widget.appModel.setDarkMode(val),
                      ),
                    ],
                  ),
                const SizedBox(height: 10),
                _sidebarFooterAction(
                  collapsed: collapsed,
                  icon: Icons.logout,
                  iconColor: PalaTheme.danger,
                  label: 'Kijelentkezés',
                  onTap: () => widget.appModel.logout(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sidebarToggleButton(bool collapsed) {
    return Tooltip(
      message: collapsed ? 'Oldalsáv kinyitása' : 'Oldalsáv összecsukása',
      child: IconButton(
        icon: Icon(collapsed ? Icons.chevron_right : Icons.chevron_left, size: 18),
        color: PalaTheme.textMuted,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
        onPressed: () => widget.appModel.toggleSidebarCollapsed(),
      ),
    );
  }

  /// Shared by the Wrapped and Logout footer entries: a tappable row with an
  /// icon and a label, or just the icon (with a tooltip) once collapsed.
  Widget _sidebarFooterAction({
    required bool collapsed,
    required IconData icon,
    required Color iconColor,
    required String label,
    required VoidCallback onTap,
    Color? background,
    Color? border,
  }) {
    final content = Padding(
      padding: EdgeInsets.symmetric(horizontal: collapsed ? 0 : 10, vertical: 8),
      child: Row(
        mainAxisAlignment: collapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 16),
          if (!collapsed) ...[
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: iconColor == PalaTheme.danger ? PalaTheme.danger : Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
          ],
        ],
      ),
    );

    final button = Material(
      color: background ?? Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: border != null ? BorderSide(color: border) : BorderSide.none,
      ),
      child: InkWell(borderRadius: BorderRadius.circular(8), onTap: onTap, child: content),
    );

    return collapsed ? Tooltip(message: label, child: button) : button;
  }

  Widget _buildHeader(Color primary) {
    final title = _titles[_currentIndex.clamp(0, _titles.length - 1)];
    final subtitle = _subtitles[_currentIndex.clamp(0, _subtitles.length - 1)];
    final timeStr = DateFormat('HH:mm:ss').format(_currentTime);
    final dateStr = DateFormat('yyyy. MMMM d., EEEE', 'hu_HU').format(_currentTime);

    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: PalaTheme.sidebar,
        border: Border(bottom: BorderSide(color: PalaTheme.border)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Colors.white),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11, color: PalaTheme.textMuted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Row(
            children: [
              Material(
                color: PalaTheme.card,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: PalaTheme.border),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => GlobalSearchView.show(context, widget.appModel),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    child: Row(
                      children: [
                        Icon(Icons.search, size: 16, color: PalaTheme.textMuted),
                        const SizedBox(width: 8),
                        Text('Gyorskereső...', style: TextStyle(color: PalaTheme.textMuted, fontSize: 12)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: PalaTheme.card,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: PalaTheme.border),
                ),
                child: Row(
                  children: [
                    Icon(Icons.access_time, size: 14, color: PalaTheme.textMuted),
                    const SizedBox(width: 6),
                    Text('$dateStr  •  $timeStr', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              if (widget.appModel.isDemo) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  decoration: BoxDecoration(
                    color: PalaTheme.warning.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: PalaTheme.warning.withValues(alpha: 0.4)),
                  ),
                  child: const Text('DEMÓ MÓD', style: TextStyle(color: PalaTheme.warning, fontSize: 11, fontWeight: FontWeight.w800)),
                ),
                const SizedBox(width: 8),
              ],
              IconButton(
                tooltip: 'Adatok frissítése',
                icon: widget.appModel.isLoading
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.refresh, size: 20),
                onPressed: widget.appModel.isLoading ? null : () => widget.appModel.refreshAll(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

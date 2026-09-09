import 'package:flutter/material.dart';
import '../state/app_model.dart';
import '../theme/pala_theme.dart';
import '../views/dashboard_view.dart';
import '../views/global_search_view.dart';
import '../views/grades_view.dart';
import '../views/settings_view.dart';
import '../views/tasks_view.dart';
import '../views/timetable_view.dart';

/// Bottom-nav, quick-glance layout for Android/iOS. Mobile-only screens or
/// widgets (e.g. a compact "today" card) belong here, not in [DesktopShell]
/// — the two shells share only the view widgets and AppModel, not their
/// navigation chrome.
class MobileShell extends StatefulWidget {
  final AppModel appModel;

  const MobileShell({super.key, required this.appModel});

  @override
  State<MobileShell> createState() => _MobileShellState();
}

class _MobileShellState extends State<MobileShell> {
  int _currentIndex = 0;

  static const _titles = [
    'Vezérlőpult',
    'Érdemjegyek',
    'Órarend',
    'Feladatok & Üzenetek',
    'Beállítások',
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
      SettingsView(appModel: widget.appModel),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: primary,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'PALA',
                style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _titles[_currentIndex],
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          if (widget.appModel.isDemo)
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: PalaTheme.warning.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: PalaTheme.warning.withValues(alpha: 0.4)),
              ),
              child: const Text('DEMÓ', style: TextStyle(color: PalaTheme.warning, fontSize: 10, fontWeight: FontWeight.w800)),
            ),
          IconButton(
            icon: const Icon(Icons.search, size: 22),
            onPressed: () => GlobalSearchView.show(context, widget.appModel),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, size: 22),
            onPressed: widget.appModel.isLoading ? null : () => widget.appModel.refreshAll(),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildMaintenanceBanner(),
          Expanded(child: screens[_currentIndex]),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Főoldal',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.school_outlined),
            activeIcon: Icon(Icons.school),
            label: 'Jegyek',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today_outlined),
            activeIcon: Icon(Icons.calendar_today),
            label: 'Órarend',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment_outlined),
            activeIcon: Icon(Icons.assignment),
            label: 'Feladatok',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profil',
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
}

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pala/app/state/app_state.dart';
import 'package:pala/utils/encryption.dart';
import 'state/app_model.dart';
import 'theme/pala_theme.dart';
import 'views/absences_view.dart';
import 'views/dashboard_view.dart';
import 'views/global_search_view.dart';
import 'views/grades_view.dart';
import 'views/login_view.dart';
import 'views/settings_view.dart';
import 'views/stats_view.dart';
import 'views/tasks_view.dart';
import 'views/timetable_view.dart';
import 'views/wrapped_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Android/iOS have no HOME/USERPROFILE env var and a read-only process
  // working directory, so the shared package's default '~/.config/pala'
  // (falling back to './.config/pala') can't be created there. Point it at
  // a writable app-specific directory instead.
  if (Platform.isAndroid || Platform.isIOS) {
    final dir = await getApplicationSupportDirectory();
    AppState.configDirOverride = dir.path;
    EncryptionUtil.configDirOverride = dir.path;
  }

  await initializeDateFormatting('hu_HU', null);
  final appModel = AppModel();
  runApp(PalaMobileApp(appModel: appModel));
}

class PalaMobileApp extends StatelessWidget {
  final AppModel appModel;

  const PalaMobileApp({super.key, required this.appModel});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: appModel,
      builder: (context, _) {
        return MaterialApp(
          title: 'Pala',
          debugShowCheckedModeBanner: false,
          theme: appModel.isDarkMode ? PalaTheme.getDarkTheme() : PalaTheme.getLightTheme(),
          home: appModel.isAuthenticated
              ? MainNavigationScreen(appModel: appModel)
              : LoginView(appModel: appModel),
        );
      },
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  final AppModel appModel;

  const MainNavigationScreen({super.key, required this.appModel});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
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

  final List<String> _titles = [
    'Vezérlőpult',
    'Érdemjegyek',
    'Órarend',
    'Feladatok & Üzenetek',
    'Mulasztások',
    'Statisztikák & Célátlag',
    'Tanulói Adatlap & Beállítások',
  ];

  final List<String> _subtitles = [
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

    final List<Widget> screens = [
      DashboardView(appModel: widget.appModel),
      GradesView(appModel: widget.appModel),
      TimetableView(appModel: widget.appModel),
      TasksView(appModel: widget.appModel),
      AbsencesView(appModel: widget.appModel),
      StatsView(appModel: widget.appModel),
      SettingsView(appModel: widget.appModel),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 800;

        if (isDesktop) {
          return Scaffold(
            body: Row(
              children: [
                // Left Desktop Sidebar (240px)
                _buildDesktopSidebar(primary),

                // Main Area: Top Desktop Header + Active View Screen
                Expanded(
                  child: Column(
                    children: [
                      _buildDesktopHeader(primary),
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

        // Mobile Phone Layout
        final mobileIndex = _currentIndex > 4 ? 4 : _currentIndex;
        final List<Widget> mobileScreens = [
          screens[0], // Dashboard
          screens[1], // Grades
          screens[2], // Timetable
          screens[3], // Tasks
          screens[6], // Settings
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
                    _titles[mobileIndex],
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
              Expanded(child: mobileScreens[mobileIndex]),
            ],
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: mobileIndex,
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
      },
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

  Widget _buildDesktopSidebar(Color primary) {
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

    return Container(
      width: 250,
      decoration: BoxDecoration(
        color: PalaTheme.sidebar,
        border: Border(right: BorderSide(color: PalaTheme.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top Brand Header
          Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: primary,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'PALA',
                    style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1),
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'DESKTOP',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14, letterSpacing: 1.5),
                ),
                const Spacer(),
                Text(
                  'v1.2',
                  style: TextStyle(color: PalaTheme.textMuted, fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),

          // Student Profile Card
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: PalaTheme.card,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: PalaTheme.border),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: primary.withValues(alpha: 0.2),
                  child: Text(
                    studentName.isNotEmpty ? studentName[0] : 'P',
                    style: TextStyle(color: primary, fontWeight: FontWeight.w900, fontSize: 14),
                  ),
                ),
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
            ),
          ),

          const SizedBox(height: 10),
          Divider(height: 1, color: PalaTheme.border),
          const SizedBox(height: 10),

          // Navigation Links
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              itemCount: navItems.length,
              itemBuilder: (context, idx) {
                final item = navItems[idx];
                final isSelected = _currentIndex == idx;

                return Container(
                  margin: const EdgeInsets.only(bottom: 4),
                  child: Material(
                    color: isSelected ? primary.withValues(alpha: 0.15) : Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: isSelected ? BorderSide(color: primary.withValues(alpha: 0.3)) : BorderSide.none,
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () => setState(() => _currentIndex = idx),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        child: Row(
                          children: [
                            Icon(
                              isSelected ? item['activeIcon'] as IconData : item['icon'] as IconData,
                              size: 18,
                              color: isSelected ? primary : PalaTheme.textMuted,
                            ),
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
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: primary,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          Divider(height: 1, color: PalaTheme.border),

          // Sidebar Footer: Wrapped, dark/light toggle, Logout
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Pala Wrapped button
                Material(
                  color: const Color(0xFFFF8800).withValues(alpha: 0.12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: const Color(0xFFFF8800).withValues(alpha: 0.3)),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => WrappedModal.show(context, widget.appModel),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      child: Row(
                        children: const [
                          Icon(Icons.auto_awesome, color: Color(0xFFFF8800), size: 16),
                          SizedBox(width: 8),
                          Text('Pala Wrapped 2025', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // Dark / light mode toggle
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

                // Logout
                InkWell(
                  onTap: () => widget.appModel.logout(),
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                    child: Row(
                      children: const [
                        Icon(Icons.logout, size: 16, color: PalaTheme.danger),
                        SizedBox(width: 8),
                        Text('Kijelentkezés', style: TextStyle(color: PalaTheme.danger, fontSize: 12, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopHeader(Color primary) {
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
          // Section Title & Subtitle
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Colors.white),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(fontSize: 11, color: PalaTheme.textMuted),
              ),
            ],
          ),

          // Actions: Search Bar Trigger, Date Clock, Demo badge, Refresh
          Row(
            children: [
              // Universal Search Trigger Button
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

              // Live Date & Clock
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

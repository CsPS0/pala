import 'package:flutter/material.dart';
import 'package:pala/rules/wrapped_season.dart';
import '../../features/absences/presentation/absences_view.dart';
import '../../features/dashboard/presentation/live_dashboard_view.dart';
import '../../features/grades/presentation/grades_view.dart';
import '../../features/search/presentation/global_search_view.dart';
import '../../features/wrapped/presentation/pala_wrapped_view.dart';
import '../../state/app_model.dart';
import '../../views/settings_view.dart';
import '../../views/messages_view.dart';
import '../../views/tasks_view.dart';
import '../../views/timetable_view.dart';
import 'adaptive_breakpoints.dart';
import 'app_pages.dart';

/// Unified adaptive root scaffold auto-swapping between NavigationBar (<600dp)
/// and NavigationRail (>=600dp) while preserving state via IndexedStack and PageStorageKey.
class AdaptiveScaffold extends StatefulWidget {
  final AppModel appModel;

  const AdaptiveScaffold({super.key, required this.appModel});

  @override
  State<AdaptiveScaffold> createState() => _AdaptiveScaffoldState();
}

class _AdaptiveScaffoldState extends State<AdaptiveScaffold> {
  int _currentIndex = 0;
  final GlobalKey _indexedStackKey = GlobalKey();
  String? _lastShownError;

  // Same pages, names and order as the extension's sidebar (see AppPages).
  static const _titles = [
    'Vezérlőpult',
    'Órarend',
    'Osztályzatok',
    'Feladatok & Dolgozatok',
    'Üzenetek',
    'Mulasztások',
    'Fiók & Profil',
  ];

  @override
  void initState() {
    super.initState();
    widget.appModel.addListener(_onModelChanged);
  }

  @override
  void didUpdateWidget(covariant AdaptiveScaffold oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.appModel != widget.appModel) {
      oldWidget.appModel.removeListener(_onModelChanged);
      widget.appModel.addListener(_onModelChanged);
    }
  }

  @override
  void dispose() {
    widget.appModel.removeListener(_onModelChanged);
    super.dispose();
  }

  void _onModelChanged() {
    final err = widget.appModel.errorMessage;
    // Forget the last error once it clears, so the same problem is reported again next time.
    if (err == null) _lastShownError = null;
    if (err != null && err.isNotEmpty && err != _lastShownError && mounted) {
      _lastShownError = err;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final colorScheme = Theme.of(context).colorScheme;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: colorScheme.errorContainer,
            content: Text(
              err,
              style: TextStyle(color: colorScheme.onErrorContainer),
            ),
            action: SnackBarAction(
              label: 'Újra',
              textColor: colorScheme.onErrorContainer,
              onPressed: () => widget.appModel.refreshAll(),
            ),
          ),
        );
      });
    } else if (err == null) {
      _lastShownError = null;
    }
  }

  void _navigateToIndex(int index) {
    if (index >= 0 && index < _titles.length) {
      setState(() => _currentIndex = index);
    }
  }

  // (icon, selectedIcon, rail label, bar label) per branch, in IndexedStack order.
  // Bar labels stay short: five slots on a 320px phone leave about 64px each.
  static const _destinations = [
    (Icons.dashboard_outlined, Icons.dashboard, 'Vezérlőpult', 'Főoldal'),
    (Icons.calendar_today_outlined, Icons.calendar_today, 'Órarend', 'Órarend'),
    (Icons.school_outlined, Icons.school, 'Osztályzatok', 'Jegyek'),
    (Icons.assignment_outlined, Icons.assignment, 'Feladatok & Dolgozatok', 'Feladatok'),
    (Icons.mail_outline, Icons.mail, 'Üzenetek', 'Üzenetek'),
    (Icons.event_busy_outlined, Icons.event_busy, 'Mulasztások', 'Mulasztás'),
    (Icons.person_outline, Icons.person, 'Fiók & Profil', 'Profil'),
  ];

  // The phone bar fits five slots: four pages and "Több", a sheet with the rest.
  static const _compactBranches = [AppPages.dashboard, AppPages.timetable, AppPages.grades, AppPages.absences];
  static const _moreBranches = [AppPages.tasks, AppPages.messages, AppPages.profile];

  void _openMoreSheet() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final i in _moreBranches)
              ListTile(
                leading: Icon(_currentIndex == i ? _destinations[i].$2 : _destinations[i].$1),
                title: Text(_destinations[i].$3),
                selected: _currentIndex == i,
                onTap: () {
                  Navigator.pop(context);
                  _navigateToIndex(i);
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Branches wrapped with persistent PageStorageKey to prevent destruction on resize
    final screens = <Widget>[
      KeyedSubtree(
        key: const PageStorageKey<String>('branch_dashboard'),
        child: LiveDashboardView(
          appModel: widget.appModel,
          onNavigate: _navigateToIndex,
        ),
      ),
      KeyedSubtree(
        key: const PageStorageKey<String>('branch_timetable'),
        child: TimetableView(appModel: widget.appModel),
      ),
      KeyedSubtree(
        key: const PageStorageKey<String>('branch_grades'),
        child: GradesView(appModel: widget.appModel),
      ),
      KeyedSubtree(
        key: const PageStorageKey<String>('branch_tasks'),
        child: TasksView(appModel: widget.appModel),
      ),
      KeyedSubtree(
        key: const PageStorageKey<String>('branch_messages'),
        child: MessagesView(appModel: widget.appModel),
      ),
      KeyedSubtree(
        key: const PageStorageKey<String>('branch_absences'),
        child: AbsencesView(appModel: widget.appModel),
      ),
      KeyedSubtree(
        key: const PageStorageKey<String>('branch_settings'),
        child: SettingsView(appModel: widget.appModel),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = AdaptiveBreakpoints.isCompactConstraints(constraints);
        final isLargeDesktop = constraints.maxWidth >= 960;
        // Pages in the "Több" sheet light up its slot (the last one).
        final barSlot = _compactBranches.indexOf(_currentIndex);
        final bottomNavIndex = barSlot >= 0 ? barSlot : _compactBranches.length;

        return Scaffold(
          appBar: _buildAppBar(context, theme, colorScheme, isCompact: isCompact),
          body: Row(
            children: [
              if (!isCompact) ...[
                NavigationRail(
                  extended: isLargeDesktop,
                  // Rows narrower than this get centred in the rail, so keep it above the longest label.
                  minExtendedWidth: 256,
                  labelType: isLargeDesktop ? NavigationRailLabelType.none : NavigationRailLabelType.all,
                  selectedIndex: _currentIndex,
                  onDestinationSelected: _navigateToIndex,
                  destinations: [
                    for (final d in _destinations)
                      NavigationRailDestination(
                        icon: Icon(d.$1),
                        selectedIcon: Icon(d.$2),
                        label: Text(d.$3),
                      ),
                  ],
                ),
                const VerticalDivider(width: 1),
              ],
              Expanded(
                child: Column(
                  children: [
                    _buildMaintenanceBanner(colorScheme),
                    Expanded(
                      child: IndexedStack(
                        key: _indexedStackKey,
                        index: _currentIndex,
                        children: screens,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          bottomNavigationBar: isCompact
              ? NavigationBar(
                  selectedIndex: bottomNavIndex,
                  onDestinationSelected: (i) => i < _compactBranches.length ? _navigateToIndex(_compactBranches[i]) : _openMoreSheet(),
                  destinations: [
                    for (final i in _compactBranches)
                      NavigationDestination(
                        icon: Icon(_destinations[i].$1),
                        selectedIcon: Icon(_destinations[i].$2),
                        label: _destinations[i].$4,
                      ),
                    const NavigationDestination(
                      icon: Icon(Icons.more_horiz),
                      label: 'Több',
                    ),
                  ],
                )
              : null,
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme, {
    required bool isCompact,
  }) {
    return AppBar(
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Pala brand badge: wide layouts only, phones need the room for the screen title.
          if (!isCompact) ...[
            Semantics(
              header: true,
              label: 'Pala alkalmazás',
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'PALA',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Flexible(
            child: Text(
              _titles[_currentIndex],
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: colorScheme.onSurface,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      bottom: widget.appModel.isLoading
          ? PreferredSize(
              preferredSize: const Size.fromHeight(2),
              child: LinearProgressIndicator(
                minHeight: 2,
                backgroundColor: Colors.transparent,
                valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
              ),
            )
          : null,
      actions: [
        if (widget.appModel.isDemo)
          Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: colorScheme.tertiaryContainer,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: colorScheme.tertiary),
            ),
            child: Text(
              'DEMÓ',
              style: TextStyle(
                color: colorScheme.onTertiaryContainer,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
          ),
        // Pala Wrapped: wide layouts only (phones reach it from Settings >
        // Eszközök), and only in the summer break or demo mode. A text button,
        // so it does not read as an AI feature.
        if (!isCompact && (isWrappedSeason(DateTime.now()) || widget.appModel.isDemo))
          TextButton(
            onPressed: () => PalaWrappedView.show(context, widget.appModel),
            child: const Text('Pala Wrapped', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        // Global Search Trigger
        IconButton(
          tooltip: 'Globális kereső',
          icon: const Icon(Icons.search, size: 22),
          onPressed: () => GlobalSearchView.show(context, widget.appModel),
        ),
        // Refresh Trigger
        IconButton(
          tooltip: 'Frissítés',
          icon: const Icon(Icons.refresh, size: 22),
          onPressed: widget.appModel.isLoading ? null : () => widget.appModel.refreshAll(),
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  Widget _buildMaintenanceBanner(ColorScheme colorScheme) {
    if (!widget.appModel.isMaintenanceMode) return const SizedBox.shrink();
    final status = widget.appModel.maintenanceStatusCode;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: colorScheme.tertiaryContainer,
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: colorScheme.onTertiaryContainer, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'A Kréta rendszer jelenleg karbantartás alatt áll${status != null ? ' (HTTP $status)' : ''}. A helyileg mentett adatokat látod.',
              style: TextStyle(
                color: colorScheme.onTertiaryContainer,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          ConstrainedBox(
            constraints: AdaptiveBreakpoints.touchTargetConstraints(context),
            child: TextButton(
              onPressed: widget.appModel.isLoading ? null : () => widget.appModel.refreshAll(),
              child: Text(
                'Újrapróbálás',
                style: TextStyle(
                  color: colorScheme.onTertiaryContainer,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

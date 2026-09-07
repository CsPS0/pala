import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import '../state/app_model.dart';
import '../theme/pala_theme.dart';

const _slideDuration = Duration(seconds: 4);

class WrappedModal extends StatefulWidget {
  final AppModel appModel;

  const WrappedModal({super.key, required this.appModel});

  static void show(BuildContext context, AppModel appModel) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: true,
        barrierColor: Colors.black,
        transitionDuration: const Duration(milliseconds: 350),
        pageBuilder: (context, animation, secondaryAnimation) => WrappedModal(appModel: appModel),
        transitionsBuilder: (context, animation, secondaryAnimation, child) => FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  State<WrappedModal> createState() => _WrappedModalState();
}

class _WrappedModalState extends State<WrappedModal> {
  final GlobalKey _storyBoundaryKey = GlobalKey();
  bool _isExporting = false;
  int _slide = 0;
  int _slideCount = 1;
  Timer? _timer;
  bool _paused = false;
  DateTime _slideStartedAt = DateTime.now();
  Duration _pausedElapsed = Duration.zero;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _getMonthName(int m) {
    const months = [
      'Január', 'Február', 'Március', 'Április', 'Május', 'Június',
      'Július', 'Augusztus', 'Szeptember', 'Október', 'November', 'December'
    ];
    if (m >= 1 && m <= 12) return months[m - 1];
    return 'Ismeretlen';
  }

  void _startAutoAdvance() {
    _timer?.cancel();
    // The final slide holds the shareable recap card and action buttons —
    // it doesn't auto-advance so the user has time to save/share.
    if (_slide >= _slideCount - 1) return;
    _slideStartedAt = DateTime.now();
    _pausedElapsed = Duration.zero;
    _timer = Timer(_slideDuration, () => _goTo(_slide + 1));
  }

  void _goTo(int index) {
    if (index < 0 || index >= _slideCount) return;
    setState(() => _slide = index);
    _startAutoAdvance();
  }

  void _pause() {
    if (_paused) return;
    _paused = true;
    _pausedElapsed += DateTime.now().difference(_slideStartedAt);
    _timer?.cancel();
  }

  void _resume() {
    if (!_paused) return;
    _paused = false;
    _slideStartedAt = DateTime.now();
    final remaining = _slideDuration - _pausedElapsed;
    if (_slide < _slideCount - 1 && remaining > Duration.zero) {
      _timer = Timer(remaining, () => _goTo(_slide + 1));
    } else if (_slide < _slideCount - 1) {
      _goTo(_slide + 1);
    }
  }

  Future<File?> _captureStoryPng() async {
    try {
      final boundary = _storyBoundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return null;

      final pngBytes = byteData.buffer.asUint8List();
      final tempDir = await getTemporaryDirectory();
      final filePath = '${tempDir.path}/pala_wrapped_story.png';
      final file = File(filePath);
      await file.writeAsBytes(pngBytes);
      return file;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hiba a kép generálásakor: $e')),
        );
      }
      return null;
    }
  }

  /// "Share" on desktop: save the story image and open it in the OS's default
  /// viewer (Windows Photos, macOS Preview, etc.), which has its own native
  /// Share/Send-to flyout — one click further, without pulling in a
  /// Windows-native plugin dependency that conflicts with the TUI's win32 pin
  /// (interact -> dart_console -> win32 ^2.0.0, incompatible with modern
  /// share_plus_windows's win32 ^5.x requirement).
  Future<void> _shareStory() => _saveAndOpenStory(openDirectly: true, isShare: true);

  Future<void> _saveAndOpenStory({bool openDirectly = true, bool isShare = false}) async {
    setState(() => _isExporting = true);
    final file = await _captureStoryPng();
    if (!mounted) return;
    setState(() => _isExporting = false);

    if (file != null) {
      try {
        final home = Platform.environment['USERPROFILE'] ?? Platform.environment['HOME'] ?? '.';
        final downloadsPath = '$home${Platform.pathSeparator}Downloads';
        final downloadsDir = Directory(downloadsPath);
        final outDir = downloadsDir.existsSync() ? downloadsDir.path : (await getApplicationDocumentsDirectory()).path;
        final targetPath = '$outDir${Platform.pathSeparator}Pala_Wrapped_Story.png';
        await file.copy(targetPath);

        if (openDirectly) {
          try {
            if (Platform.isWindows) {
              await Process.run('cmd', ['/c', 'start', '', targetPath]);
            } else if (Platform.isMacOS) {
              await Process.run('open', [targetPath]);
            } else if (Platform.isLinux) {
              await Process.run('xdg-open', [targetPath]);
            }
          } catch (_) {}
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isShare
                  ? 'Kép megnyitva — a megjelenő ablak Megosztás/Küldés gombjával oszthatod meg Instagramon, Facebookon vagy WhatsApp-on.'
                  : 'Story kép sikeresen elmentve: $targetPath'),
              action: SnackBarAction(
                label: 'Megnyitás',
                onPressed: () {
                  if (Platform.isWindows) {
                    Process.run('explorer.exe', ['/select,', targetPath]);
                  } else if (Platform.isMacOS) {
                    Process.run('open', ['-R', targetPath]);
                  } else if (Platform.isLinux) {
                    Process.run('xdg-open', [outDir]);
                  }
                },
              ),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Kép elmentve ide: ${file.path}')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.primaryColor;
    final stats = widget.appModel.wrappedStats;

    final totalGrades = stats['totalGrades'] as int? ?? 0;
    final fivesCount = stats['fivesCount'] as int? ?? 0;
    final onesCount = stats['onesCount'] as int? ?? 0;
    final overallGpa = stats['overallGpa'] as double? ?? 0.0;
    final bestSubject = stats['bestSubject'] as String? ?? '-';
    final bestSubjectAvg = stats['bestSubjectAvg'] as double? ?? 0.0;
    final worstSubject = stats['worstSubject'] as String? ?? '-';
    final worstSubjectAvg = stats['worstSubjectAvg'] as double? ?? 0.0;
    final totalMissed = stats['totalMissedHours'] as int? ?? 0;
    final topMonth = stats['topMonth'] as int? ?? 1;
    final topMonthCount = stats['topMonthCount'] as int? ?? 0;
    final studentName = widget.appModel.student?.name ?? 'Tanuló';

    final now = DateTime.now();
    final isSummer = (now.month == 6 && now.day >= 14) ||
        (now.month == 7) ||
        (now.month == 8) ||
        (now.month == 9 && now.day <= 30);

    if (!isSummer && !widget.appModel.isDemo) {
      return Scaffold(
        backgroundColor: PalaTheme.background,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                      border: Border.all(color: primary.withValues(alpha: 0.3)),
                    ),
                    child: Icon(Icons.wb_sunny_outlined, size: 36, color: primary),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Pala Wrapped — Nyári Szüneti Funkció',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'A Pala Wrapped tanévzáró összefoglaló kizárólag a nyári szünetben érhető el (június 14. és szeptember 30. között), amikor az adott tanév minden érdemjegye és mulasztása hivatalosan lezárult.',
                    style: TextStyle(fontSize: 13, color: PalaTheme.textMuted, height: 1.5),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'A tanév közben a Statisztikák és Érdemjegyek menüpontban követheted az eredményeidet.',
                    style: TextStyle(fontSize: 12, color: PalaTheme.textMuted, height: 1.4),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: PalaTheme.card,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        side: BorderSide(color: PalaTheme.border),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: Text('Rendben, bezárás', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // Slide content builders, in Spotify-Wrapped-style story order.
    final slides = <Widget>[
      _buildIntroSlide(primary, studentName),
      _buildStatSlide(
        icon: Icons.school_outlined,
        color: primary,
        eyebrow: 'ÖSSZES JEGY',
        headline: '$totalGrades',
        headlineSuffix: ' db',
        subtitle: '$fivesCount darab ötös és $onesCount darab egyes közt telt az éved.',
      ),
      _buildStatSlide(
        icon: Icons.military_tech_outlined,
        color: PalaTheme.success,
        eyebrow: 'LEGJOBB TÁRGYAD',
        headline: bestSubject,
        subtitle: bestSubjectAvg > 0 ? 'Ebben a tárgyban átlagosan ${bestSubjectAvg.toStringAsFixed(2)}-öt hoztál.' : '',
      ),
      _buildStatSlide(
        icon: Icons.calendar_month_outlined,
        color: const Color(0xFFFF8800),
        eyebrow: 'LEGAKTÍVABB HÓNAPOD',
        headline: _getMonthName(topMonth),
        subtitle: '$topMonthCount jegyet szereztél ekkor — a leggazdaságosabb hónapod.',
      ),
      _buildStatSlide(
        icon: Icons.timer_outlined,
        color: totalMissed > 150 ? PalaTheme.danger : PalaTheme.warning,
        eyebrow: 'MULASZTOTT ÓRÁK',
        headline: '$totalMissed',
        headlineSuffix: ' óra',
        subtitle: totalMissed < 100 ? 'Kiváló részvétel egész évben!' : 'Jövőre figyelj kicsit jobban a hiányzásokra.',
      ),
      _buildRecapSlide(
        primary: primary,
        studentName: studentName,
        overallGpa: overallGpa,
        totalGrades: totalGrades,
        fivesCount: fivesCount,
        topMonth: topMonth,
        topMonthCount: topMonthCount,
        bestSubject: bestSubject,
        bestSubjectAvg: bestSubjectAvg,
        worstSubject: worstSubject,
        worstSubjectAvg: worstSubjectAvg,
        totalMissed: totalMissed,
      ),
    ];
    _slideCount = slides.length;
    if (_timer == null && !_paused) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _startAutoAdvance());
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: GestureDetector(
          onLongPressStart: (_) => _pause(),
          onLongPressEnd: (_) => _resume(),
          onTapUp: (details) {
            final width = MediaQuery.sizeOf(context).width;
            if (details.globalPosition.dx < width * 0.3) {
              _goTo(_slide - 1);
            } else {
              _goTo(_slide + 1);
            }
          },
          child: Stack(
            children: [
              Positioned.fill(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 320),
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: ScaleTransition(
                      scale: Tween<double>(begin: 0.96, end: 1.0).animate(animation),
                      child: child,
                    ),
                  ),
                  child: Container(
                    key: ValueKey<int>(_slide),
                    alignment: Alignment.center,
                    child: slides[_slide],
                  ),
                ),
              ),

              // Segmented progress bar (Instagram/Spotify Stories style)
              Positioned(
                top: 10,
                left: 12,
                right: 12,
                child: Row(
                  children: List.generate(_slideCount, (i) {
                    return Expanded(
                      child: Container(
                        height: 3,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: i < _slide
                              ? const _FullBar()
                              : (i == _slide
                                  ? _ProgressBar(
                                      key: ValueKey('progress-$_slide-${_timer?.hashCode}'),
                                      duration: _slide >= _slideCount - 1 ? Duration.zero : _slideDuration,
                                      paused: _paused,
                                    )
                                  : const SizedBox.shrink()),
                        ),
                      ),
                    );
                  }),
                ),
              ),

              // Close button
              Positioned(
                top: 20,
                right: 8,
                child: IconButton(
                  icon: Icon(Icons.close, color: Colors.white, size: 26),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIntroSlide(Color primary, String studentName) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(color: primary, borderRadius: BorderRadius.circular(8)),
            child: Text('PALA', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1)),
          ),
          const SizedBox(height: 10),
          Text('WRAPPED', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 34, letterSpacing: 4, color: Colors.white)),
          const SizedBox(height: 24),
          Text(
            'Szia, $studentName!',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Nézzük meg együtt, milyen tanéved volt!',
            style: TextStyle(fontSize: 14, color: PalaTheme.textMuted),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStatSlide({
    required IconData icon,
    required Color color,
    required String eyebrow,
    required String headline,
    String headlineSuffix = '',
    required String subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.15),
              border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
            ),
            child: Icon(icon, size: 32, color: color),
          ),
          const SizedBox(height: 22),
          Text(
            eyebrow,
            style: TextStyle(color: PalaTheme.textMuted, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.5),
          ),
          const SizedBox(height: 10),
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              children: [
                TextSpan(text: headline, style: TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: color)),
                if (headlineSuffix.isNotEmpty)
                  TextSpan(text: headlineSuffix, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white70)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (subtitle.isNotEmpty)
            Text(
              subtitle,
              style: TextStyle(fontSize: 14, color: Colors.white70, height: 1.4),
              textAlign: TextAlign.center,
            ),
        ],
      ),
    );
  }

  Widget _buildRecapSlide({
    required Color primary,
    required String studentName,
    required double overallGpa,
    required int totalGrades,
    required int fivesCount,
    required int topMonth,
    required int topMonthCount,
    required String bestSubject,
    required double bestSubjectAvg,
    required String worstSubject,
    required double worstSubjectAvg,
    required int totalMissed,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        RepaintBoundary(
          key: _storyBoundaryKey,
          child: Container(
            width: 320,
            height: 568, // Exact 9:16 aspect ratio, matches Instagram/Facebook Stories.
            decoration: BoxDecoration(
              gradient: const RadialGradient(
                center: Alignment(0.0, -0.6),
                radius: 1.2,
                colors: [Color(0xFF221F2E), Color(0xFF131318), Color(0xFF0A0A0D)],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: primary.withValues(alpha: 0.5), width: 1.5),
              boxShadow: [BoxShadow(color: primary.withValues(alpha: 0.2), blurRadius: 24, spreadRadius: 2)],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: primary, borderRadius: BorderRadius.circular(6)),
                          child: Text('PALA', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1)),
                        ),
                        const SizedBox(width: 8),
                        Text('WRAPPED', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 2)),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(12)),
                      child: Text('${DateTime.now().year - 1} / ${DateTime.now().year}', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
                Column(
                  children: [
                    Text(
                      studentName,
                      style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 2),
                    Text('Tanulmányi Évértékelő', style: TextStyle(color: PalaTheme.textMuted, fontSize: 11)),
                  ],
                ),
                Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [primary.withValues(alpha: 0.25), primary.withValues(alpha: 0.05)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(color: primary, width: 2),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('ÁTLAG', style: TextStyle(color: PalaTheme.textMuted, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1)),
                      const SizedBox(height: 2),
                      Text(
                        overallGpa > 0 ? overallGpa.toStringAsFixed(2) : '--',
                        style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: primary),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: overallGpa >= 4.5 ? PalaTheme.success : primary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          overallGpa >= 4.5 ? 'KIVÁLÓ' : (overallGpa >= 3.5 ? 'JÓ' : 'ÁTLAGOS'),
                          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 9),
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: _buildStoryPill(icon: Icons.grade, label: 'Összes Jegy', val: '$totalGrades db ($fivesCount db 5-ös)', color: primary)),
                        const SizedBox(width: 8),
                        Expanded(child: _buildStoryPill(icon: Icons.calendar_month, label: 'Csúcshónap', val: _getMonthName(topMonth), color: const Color(0xFFFF8800))),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(child: _buildStoryPill(icon: Icons.emoji_events, label: 'Legjobb Tárgy', val: '$bestSubject (${bestSubjectAvg.toStringAsFixed(2)})', color: PalaTheme.success)),
                        const SizedBox(width: 8),
                        Expanded(child: _buildStoryPill(icon: Icons.timer, label: 'Hiányzások', val: '$totalMissed óra', color: totalMissed > 150 ? PalaTheme.danger : PalaTheme.warning)),
                      ],
                    ),
                  ],
                ),
                Text(
                  '#PalaWrapped • github.com/CsPS0/pala',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 9, fontWeight: FontWeight.w600, letterSpacing: 0.5),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: _isExporting ? null : _shareStory,
                  icon: _isExporting
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                      : Icon(Icons.share, size: 18),
                  label: Text(_isExporting ? 'Előkészítés...' : 'Megosztás'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 1,
                child: OutlinedButton.icon(
                  onPressed: _isExporting ? null : () => _saveAndOpenStory(openDirectly: false),
                  icon: Icon(Icons.download, size: 18, color: Colors.white),
                  label: Text('Mentés', style: TextStyle(color: Colors.white)),
                  style: OutlinedButton.styleFrom(side: BorderSide(color: Colors.white24)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStoryPill({required IconData icon, required String label, required String val, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 12, color: color),
              const SizedBox(width: 4),
              Text(label, style: TextStyle(color: PalaTheme.textMuted, fontSize: 9, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            val,
            style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _FullBar extends StatelessWidget {
  const _FullBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 3,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(2)),
    );
  }
}

class _ProgressBar extends StatefulWidget {
  final Duration duration;
  final bool paused;

  const _ProgressBar({super.key, required this.duration, required this.paused});

  @override
  State<_ProgressBar> createState() => _ProgressBarState();
}

class _ProgressBarState extends State<_ProgressBar> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration.inMilliseconds > 0 ? widget.duration : const Duration(milliseconds: 1));
    if (widget.duration.inMilliseconds > 0) {
      _controller.forward();
    } else {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(covariant _ProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.paused && !oldWidget.paused) {
      _controller.stop();
    } else if (!widget.paused && oldWidget.paused) {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return FractionallySizedBox(
          widthFactor: _controller.value,
          child: Container(
            height: 3,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(2)),
          ),
        );
      },
    );
  }
}

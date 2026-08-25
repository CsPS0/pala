import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import '../state/app_model.dart';
import '../theme/pala_theme.dart';

class WrappedModal extends StatefulWidget {
  final AppModel appModel;

  const WrappedModal({super.key, required this.appModel});

  static void show(BuildContext context, AppModel appModel) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: PalaTheme.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => WrappedModal(appModel: appModel),
    );
  }

  @override
  State<WrappedModal> createState() => _WrappedModalState();
}

class _WrappedModalState extends State<WrappedModal> {
  final GlobalKey _storyBoundaryKey = GlobalKey();
  bool _isExporting = false;
  bool _showStoryPreview = false;

  String _getMonthName(int m) {
    const months = [
      'Január', 'Február', 'Március', 'Április', 'Május', 'Június',
      'Július', 'Augusztus', 'Szeptember', 'Október', 'November', 'December'
    ];
    if (m >= 1 && m <= 12) return months[m - 1];
    return 'Ismeretlen';
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

  Future<void> _saveAndOpenStory({bool openDirectly = true}) async {
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
              content: Text('Story kép sikeresen elmentve: $targetPath'),
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

    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      maxChildSize: 0.96,
      minChildSize: 0.5,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: ListView(
            controller: scrollController,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Title Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: primary,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text('PALA', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 12)),
                          ),
                          const SizedBox(width: 8),
                          const Text('WRAPPED', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 2, color: Colors.white)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text('A tanéved digitális lenyomata', style: TextStyle(color: PalaTheme.textMuted, fontSize: 12)),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Mode toggle: Standard vs 9:16 Story View
              Container(
                decoration: BoxDecoration(
                  color: PalaTheme.card,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: PalaTheme.border),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _showStoryPreview = false),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: !_showStoryPreview ? primary.withValues(alpha: 0.15) : Colors.transparent,
                            borderRadius: BorderRadius.circular(9),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Összefoglaló',
                            style: TextStyle(
                              color: !_showStoryPreview ? primary : PalaTheme.textMuted,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _showStoryPreview = true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _showStoryPreview ? primary.withValues(alpha: 0.15) : Colors.transparent,
                            borderRadius: BorderRadius.circular(9),
                          ),
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.crop_portrait, size: 16, color: _showStoryPreview ? primary : PalaTheme.textMuted),
                              const SizedBox(width: 6),
                              Text(
                                'Story Kártya (9:16)',
                                style: TextStyle(
                                  color: _showStoryPreview ? primary : PalaTheme.textMuted,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              if (!_showStoryPreview) ...[
                // Standard Summary View
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        primary.withValues(alpha: 0.2),
                        primary.withValues(alpha: 0.05),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: primary.withValues(alpha: 0.4)),
                  ),
                  child: Column(
                    children: [
                      const Text('TANULMÁNYI ÁTLAG', style: TextStyle(color: PalaTheme.textMuted, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
                      const SizedBox(height: 6),
                      Text(
                        overallGpa > 0 ? overallGpa.toStringAsFixed(2) : '--',
                        style: TextStyle(fontSize: 42, fontWeight: FontWeight.w900, color: primary),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: overallGpa >= 4.5 ? PalaTheme.success.withValues(alpha: 0.2) : (overallGpa >= 3.5 ? primary.withValues(alpha: 0.2) : PalaTheme.warning.withValues(alpha: 0.2)),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          overallGpa >= 4.5 ? 'Kiváló teljesítmény' : (overallGpa >= 3.5 ? 'Jó eredmény' : 'Fejlődési potenciál'),
                          style: TextStyle(
                            color: overallGpa >= 4.5 ? PalaTheme.success : (overallGpa >= 3.5 ? primary : PalaTheme.warning),
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // 2x2 Highlights Grid
                GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: 1.35,
                  children: [
                    _buildHighlightCard(
                      title: 'Összes Jegy',
                      value: '$totalGrades db',
                      subtitle: '$fivesCount db 5-ös • $onesCount db 1-es',
                      icon: Icons.school_outlined,
                      color: primary,
                    ),
                    _buildHighlightCard(
                      title: 'Legaktívabb Hónap',
                      value: _getMonthName(topMonth),
                      subtitle: '$topMonthCount kapott jegy',
                      icon: Icons.calendar_month_outlined,
                      color: const Color(0xFFFF8800),
                    ),
                    _buildHighlightCard(
                      title: 'Legjobb Tárgy',
                      value: bestSubject,
                      subtitle: 'Átlag: ${bestSubjectAvg.toStringAsFixed(2)}',
                      icon: Icons.military_tech_outlined,
                      color: PalaTheme.success,
                    ),
                    _buildHighlightCard(
                      title: 'Mulasztott Órák',
                      value: '$totalMissed óra',
                      subtitle: totalMissed < 100 ? 'Kiváló részvétel' : 'Figyelj a hiányzásokra!',
                      icon: Icons.timer_outlined,
                      color: totalMissed > 150 ? PalaTheme.danger : PalaTheme.warning,
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                if (worstSubject != '-' && worstSubjectAvg > 0)
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: PalaTheme.card,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: PalaTheme.border),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Legtöbb figyelmet igénylő tárgy:', style: TextStyle(color: PalaTheme.textMuted, fontSize: 11)),
                            const SizedBox(height: 2),
                            Text(worstSubject, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
                          ],
                        ),
                        Text(
                          worstSubjectAvg.toStringAsFixed(2),
                          style: const TextStyle(color: PalaTheme.warning, fontWeight: FontWeight.w800, fontSize: 16),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 18),

                // Share button triggering story mode
                ElevatedButton.icon(
                  onPressed: () => setState(() => _showStoryPreview = true),
                  icon: const Icon(Icons.share, size: 18),
                  label: const Text('Megosztás Story-ként (Instagram / Facebook)'),
                ),
              ] else ...[
                // Story 9:16 Card Container for RepaintBoundary
                Center(
                  child: RepaintBoundary(
                    key: _storyBoundaryKey,
                    child: Container(
                      width: 320,
                      height: 568, // Exact 9:16 Aspect Ratio Poster
                      decoration: BoxDecoration(
                        gradient: const RadialGradient(
                          center: Alignment(0.0, -0.6),
                          radius: 1.2,
                          colors: [
                            Color(0xFF221F2E),
                            Color(0xFF131318),
                            Color(0xFF0A0A0D),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: primary.withValues(alpha: 0.5), width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: primary.withValues(alpha: 0.2),
                            blurRadius: 24,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Header
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: primary,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text(
                                      'PALA',
                                      style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'WRAPPED',
                                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 2),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.white10,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text('2024 / 2025', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w600)),
                              ),
                            ],
                          ),

                          // Student Name
                          Column(
                            children: [
                              Text(
                                studentName,
                                style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: Colors.white),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 2),
                              const Text('Tanulmányi Évértékelő', style: TextStyle(color: PalaTheme.textMuted, fontSize: 11)),
                            ],
                          ),

                          // Center Big GPA Circle
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
                                const Text('ÁTLAG', style: TextStyle(color: PalaTheme.textMuted, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1)),
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
                                    style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 9),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // 4 Story Metric Tiles
                          Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildStoryPill(
                                      icon: Icons.grade,
                                      label: 'Összes Jegy',
                                      val: '$totalGrades db ($fivesCount db 5-ös)',
                                      color: primary,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _buildStoryPill(
                                      icon: Icons.calendar_month,
                                      label: 'Csúcshónap',
                                      val: _getMonthName(topMonth),
                                      color: const Color(0xFFFF8800),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildStoryPill(
                                      icon: Icons.emoji_events,
                                      label: 'Legjobb Tárgy',
                                      val: '$bestSubject (${bestSubjectAvg.toStringAsFixed(2)})',
                                      color: PalaTheme.success,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _buildStoryPill(
                                      icon: Icons.timer,
                                      label: 'Hiányzások',
                                      val: '$totalMissed óra',
                                      color: totalMissed > 150 ? PalaTheme.danger : PalaTheme.warning,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),

                          // Footer Watermark
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '#PalaWrapped • github.com/CsPS0/pala',
                                style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 9, fontWeight: FontWeight.w600, letterSpacing: 0.5),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                // Share / Download action buttons
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: _isExporting ? null : () => _saveAndOpenStory(openDirectly: true),
                        icon: _isExporting
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                            : const Icon(Icons.open_in_new, size: 18),
                        label: Text(_isExporting ? 'Mentés...' : 'Story Mentése & Megnyitás'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 1,
                      child: OutlinedButton.icon(
                        onPressed: _isExporting ? null : () => _saveAndOpenStory(openDirectly: false),
                        icon: const Icon(Icons.download, size: 18),
                        label: const Text('Letöltés'),
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStoryPill({
    required IconData icon,
    required String label,
    required String val,
    required Color color,
  }) {
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
              Text(label, style: const TextStyle(color: PalaTheme.textMuted, fontSize: 9, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            val,
            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildHighlightCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: PalaTheme.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: PalaTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(color: PalaTheme.textMuted, fontSize: 10, fontWeight: FontWeight.w600)),
              Icon(icon, size: 16, color: color),
            ],
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Colors.white),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            subtitle,
            style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

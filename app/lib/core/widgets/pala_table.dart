import 'package:material_ui/material_ui.dart';

import '../theme/app_colors.dart';
import '../theme/app_shapes.dart';
import '../theme/pala_tokens.dart';

/// One column of a [PalaTable]: either a fixed [width] or a share of the
/// remaining space ([flex]).
class PalaColumn {
  final String label;
  final int flex;
  final double? width;

  const PalaColumn(this.label, {this.flex = 1, this.width});
}

/// A desktop list in Kréta Web's table look (lib/web/pala_web_html.dart,
/// "Tables"): a bordered card, a shaded header row with small uppercase
/// labels and hairline-separated rows.
class PalaTable extends StatelessWidget {
  final List<PalaColumn> columns;

  /// One list of cells per row, in column order.
  final List<List<Widget>> rows;

  /// Called with the row index when a row is clicked; null makes rows inert.
  final ValueChanged<int>? onRowTap;

  /// Shown instead of rows when there are none.
  final String emptyText;

  const PalaTable({
    super.key,
    required this.columns,
    required this.rows,
    this.onRowTap,
    this.emptyText = 'Nincs megjeleníthető adat.',
  });

  Widget _cell(PalaColumn column, Widget child) {
    final padded = Padding(padding: const EdgeInsets.only(right: 16), child: child);
    return column.width != null ? SizedBox(width: column.width, child: padded) : Expanded(flex: column.flex, child: padded);
  }

  @override
  Widget build(BuildContext context) {
    final t = PalaTokens.of(context);
    final base = Theme.of(context).textTheme.bodyMedium ?? const TextStyle();
    final headStyle = base.copyWith(color: t.textMuted, fontSize: 12.5, fontWeight: FontWeight.w600, letterSpacing: 0.5);
    final cellStyle = base.copyWith(color: t.text, fontSize: 14.5, fontWeight: FontWeight.w400);

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: t.card,
        borderRadius: BorderRadius.circular(AppShapes.card),
        border: Border.all(color: t.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 13, 0, 13),
            decoration: BoxDecoration(color: t.shade, border: Border(bottom: BorderSide(color: t.border))),
            child: Row(
              children: [
                for (final c in columns)
                  _cell(c, Text(c.label.toUpperCase(), maxLines: 1, overflow: TextOverflow.ellipsis, style: headStyle)),
              ],
            ),
          ),
          if (rows.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text(emptyText, textAlign: TextAlign.center, style: cellStyle.copyWith(color: t.textMuted)),
            ),
          for (var i = 0; i < rows.length; i++)
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onRowTap == null ? null : () => onRowTap!(i),
                hoverColor: t.tint.withValues(alpha: 0.03),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 11, 0, 11),
                  decoration: BoxDecoration(
                    border: i == rows.length - 1 ? null : Border(bottom: BorderSide(color: t.border)),
                  ),
                  child: DefaultTextStyle.merge(
                    style: cellStyle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    child: Row(
                      children: [
                        for (var c = 0; c < columns.length; c++) _cell(columns[c], rows[i][c]),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// A cell whose text stands out (the subject, the sender), as in Kréta Web.
class PalaStrong extends StatelessWidget {
  final String text;

  const PalaStrong(this.text, {super.key});

  @override
  Widget build(BuildContext context) => Text(text, style: const TextStyle(fontWeight: FontWeight.w600));
}

/// A 28 px square grade badge in the shared grade colours. [label] defaults
/// to the grade itself; text evaluations and percentages pass their own.
class PalaGradeBadge extends StatelessWidget {
  final num? value;
  final String? label;

  const PalaGradeBadge({super.key, this.value, this.label});

  @override
  Widget build(BuildContext context) {
    final color = AppColors.getGradeColor(value, Theme.of(context).brightness);
    final text = label ?? (value == null ? '-' : value!.round().toString());
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
        padding: const EdgeInsets.symmetric(horizontal: 6),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(AppShapes.control),
        ),
        child: Text(text, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 14.5)),
      ),
    );
  }
}

/// A coloured status pill ("Megtartva", "Igazolt").
class PalaPill extends StatelessWidget {
  final String text;
  final Color color;

  const PalaPill(this.text, {super.key, required this.color});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(4)),
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

/// A summary tile: small uppercase title, large value, muted note.
class PalaStatTile extends StatelessWidget {
  final String title;
  final String value;
  final String? note;
  final Color? valueColor;

  const PalaStatTile({super.key, required this.title, required this.value, this.note, this.valueColor});

  @override
  Widget build(BuildContext context) {
    final t = PalaTokens.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: t.card,
        borderRadius: BorderRadius.circular(AppShapes.card),
        border: Border.all(color: t.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: t.textMuted, fontSize: 12.5, fontWeight: FontWeight.w600, letterSpacing: 0.5),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: valueColor ?? t.text, fontSize: 29, fontWeight: FontWeight.w700),
          ),
          if (note != null && note!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(note!, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: t.textMuted, fontSize: 13)),
          ],
        ],
      ),
    );
  }
}

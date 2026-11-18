import 'package:material_ui/material_ui.dart';

import '../theme/app_shapes.dart';
import '../theme/pala_tokens.dart';

/// One page in the [PalaSidebar].
class PalaSidebarItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;

  const PalaSidebarItem(this.icon, this.selectedIcon, this.label);
}

/// The desktop navigation, laid out like Kréta Web's sidebar: brand row, one
/// row per page (the open page gets an orange tint and a left accent bar) and
/// the student at the bottom. Below [extended] width only icons are shown.
class PalaSidebar extends StatelessWidget {
  static const double extendedWidth = 270;
  static const double collapsedWidth = 76;

  final List<PalaSidebarItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final bool extended;
  final String? userName;
  final String? userSubtitle;
  final VoidCallback? onUserTap;

  const PalaSidebar({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onSelected,
    this.extended = true,
    this.userName,
    this.userSubtitle,
    this.onUserTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = PalaTokens.of(context);
    return Container(
      width: extended ? extendedWidth : collapsedWidth,
      decoration: BoxDecoration(
        color: t.sidebar,
        border: Border(right: BorderSide(color: t.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: extended ? 20 : 12, vertical: 20),
            decoration: BoxDecoration(border: Border(bottom: BorderSide(color: t.border))),
            child: Row(
              mainAxisAlignment: extended ? MainAxisAlignment.start : MainAxisAlignment.center,
              children: [
                Semantics(
                  header: true,
                  label: 'Pala alkalmazás',
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                    decoration: AppShapes.primaryFill(),
                    child: const Text(
                      'PALA',
                      style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1),
                    ),
                  ),
                ),
                if (extended) ...[
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      'Kréta App',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: t.text, fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: 0.3),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              children: [
                for (var i = 0; i < items.length; i++)
                  _SidebarRow(
                    item: items[i],
                    selected: i == selectedIndex,
                    extended: extended,
                    onTap: () => onSelected(i),
                  ),
              ],
            ),
          ),
          if (extended && userName != null && userName!.isNotEmpty)
            Material(
              color: t.shade,
              child: InkWell(
                onTap: onUserTap,
                hoverColor: t.cardHover,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(border: Border(top: BorderSide(color: t.border))),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: t.text, fontSize: 14.5, fontWeight: FontWeight.w600),
                      ),
                      if (userSubtitle != null && userSubtitle!.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          userSubtitle!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: t.textMuted, fontSize: 12.5),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SidebarRow extends StatelessWidget {
  final PalaSidebarItem item;
  final bool selected;
  final bool extended;
  final VoidCallback onTap;

  const _SidebarRow({required this.item, required this.selected, required this.extended, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = PalaTokens.of(context);
    final color = selected ? t.primary : t.textMuted;
    final row = Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppShapes.control),
        child: Material(
          color: selected ? t.primary.withValues(alpha: 0.12) : Colors.transparent,
          child: InkWell(
            onTap: onTap,
            hoverColor: t.cardHover,
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Row(
                    mainAxisAlignment: extended ? MainAxisAlignment.start : MainAxisAlignment.center,
                    children: [
                      Icon(selected ? item.selectedIcon : item.icon, size: 20, color: color),
                      if (extended) ...[
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            item.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: color,
                              fontSize: 14.5,
                              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (selected)
                  Positioned(left: 0, top: 0, bottom: 0, child: Container(width: 3, color: t.primary)),
              ],
            ),
          ),
        ),
      ),
    );
    return Semantics(
      button: true,
      selected: selected,
      label: extended ? null : item.label,
      child: extended ? row : Tooltip(message: item.label, child: row),
    );
  }
}

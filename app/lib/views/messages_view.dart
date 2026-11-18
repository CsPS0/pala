import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import 'package:pala/models/message.dart';
import 'package:pala/models/note.dart';
import 'package:pala/utils/html_text.dart';
import 'package:url_launcher/url_launcher.dart';
import '../state/app_model.dart';
import '../theme/pala_theme.dart';
import 'compose_message_view.dart';
import '../core/adaptive/adaptive_breakpoints.dart';
import '../core/theme/app_shapes.dart';
import '../core/widgets/pala_table.dart';

/// Shows a downloaded attachment to the user and says whether that worked.
typedef AttachmentPresenter = Future<bool> Function(File file);

/// A phone opens the file in the system viewer. A desktop opens the folder
/// it was saved into instead: the content comes from the sender, so the app
/// never runs a downloaded file itself.
Future<bool> presentDownloadedAttachment(File file) async {
  if (Platform.isAndroid || Platform.isIOS) {
    return (await OpenFilex.open(file.path)).type == ResultType.done;
  }
  return launchUrl(Uri.directory(file.parent.path));
}

/// Üzenetek: the e-Ügyintézés inbox (sender filter, order, unread marks,
/// full text and attachments) and the teachers' notes (Feljegyzések), as on
/// the extension's Üzenetek page.
class MessagesView extends StatefulWidget {
  final AppModel appModel;
  final AttachmentPresenter presentAttachment;

  const MessagesView({super.key, required this.appModel, this.presentAttachment = presentDownloadedAttachment});

  @override
  State<MessagesView> createState() => _MessagesViewState();
}

class _MessagesViewState extends State<MessagesView> with SingleTickerProviderStateMixin {
  late final TabController _tabController = TabController(length: 2, vsync: this);
  String _sender = '';
  bool _oldestFirst = false;

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _date(DateTime? d, [String pattern = 'yyyy.MM.dd']) => d != null ? DateFormat(pattern).format(d) : '-';

  void _openMessage(Message msg) {
    // Wide screens open the message in a centred dialog, as Kréta Web does;
    // phones keep the bottom sheet.
    if (AdaptiveBreakpoints.isExpanded(context)) {
      showDialog(
        context: context,
        builder: (context) => Dialog(
          backgroundColor: PalaTheme.sidebar,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: PalaTheme.border),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 680, maxHeight: MediaQuery.sizeOf(context).height * 0.85),
            child: _MessageSheet(
              appModel: widget.appModel,
              message: msg,
              presentAttachment: widget.presentAttachment,
            ),
          ),
        ),
      );
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: PalaTheme.sidebar,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        builder: (context, scroll) => _MessageSheet(
          appModel: widget.appModel,
          message: msg,
          scroll: scroll,
          presentAttachment: widget.presentAttachment,
        ),
      ),
    );
  }

  Widget _toolbar(List<Message> all) {
    final senders = messageSenders(all);
    final sender = senders.contains(_sender) ? _sender : '';
    // The sender list takes the free width and cuts long names, so a phone
    // screen never overflows.
    return Row(
      children: [
        Expanded(
          child: DropdownButton<String>(
            value: sender,
            isDense: true,
            isExpanded: true,
            onChanged: (v) => setState(() => _sender = v ?? ''),
            items: [
              const DropdownMenuItem(value: '', child: Text('Minden feladó')),
              for (final s in senders)
                DropdownMenuItem(value: s, child: Text(s, maxLines: 1, overflow: TextOverflow.ellipsis)),
            ],
          ),
        ),
        const SizedBox(width: 12),
        DropdownButton<bool>(
          value: _oldestFirst,
          isDense: true,
          onChanged: (v) => setState(() => _oldestFirst = v ?? false),
          items: const [
            DropdownMenuItem(value: false, child: Text('Legújabb elöl')),
            DropdownMenuItem(value: true, child: Text('Legrégebbi elöl')),
          ],
        ),
      ],
    );
  }

  Widget _messageTile(Message m) {
    final primary = Theme.of(context).primaryColor;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: PalaTheme.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppShapes.card),
          side: BorderSide(color: m.isRead ? PalaTheme.border : primary.withValues(alpha: 0.5)),
        ),
        child: ListTile(
          leading: Semantics(
            label: m.isRead ? 'Olvasott' : 'Olvasatlan',
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: m.isRead ? Colors.transparent : primary, shape: BoxShape.circle),
            ),
          ),
          minLeadingWidth: 10,
          title: Text(
            m.subject.isNotEmpty ? m.subject : '(Nincs tárgy)',
            style: TextStyle(color: PalaTheme.text, fontWeight: m.isRead ? FontWeight.w600 : FontWeight.w800, fontSize: 14),
          ),
          subtitle: Text('${m.senderName} • ${_date(m.sentDate)}', style: TextStyle(color: PalaTheme.textMuted, fontSize: 12)),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (m.attachments.isNotEmpty) Icon(Icons.attach_file, size: 16, color: PalaTheme.textMuted),
              Icon(Icons.chevron_right, size: 20, color: PalaTheme.textMuted),
            ],
          ),
          onTap: () => _openMessage(m),
        ),
      ),
    );
  }

  /// Kréta Web's inbox table for wide screens; a row opens the message.
  Widget _messageTable(List<Message> messages) {
    final primary = Theme.of(context).primaryColor;
    return PalaTable(
      key: const ValueKey('messages_table'),
      columns: const [
        PalaColumn('Dátum', width: 116),
        PalaColumn('Feladó', flex: 3),
        PalaColumn('Tárgy', flex: 5),
        PalaColumn('Csatolmány', width: 110),
      ],
      onRowTap: (i) => _openMessage(messages[i]),
      rows: [
        for (final m in messages)
          [
            Text(_date(m.sentDate)),
            PalaStrong(m.senderName),
            Row(
              children: [
                if (!m.isRead) ...[
                  Semantics(
                    label: 'Olvasatlan',
                    child: Container(width: 8, height: 8, decoration: BoxDecoration(color: primary, shape: BoxShape.circle)),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    m.subject.isNotEmpty ? m.subject : '(Nincs tárgy)',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontWeight: m.isRead ? FontWeight.w400 : FontWeight.w700),
                  ),
                ),
              ],
            ),
            m.attachments.isEmpty
                ? const SizedBox.shrink()
                : Row(
                    children: [
                      Icon(Icons.attach_file, size: 16, color: PalaTheme.textMuted),
                      const SizedBox(width: 4),
                      Text('${m.attachments.length} db', style: TextStyle(color: PalaTheme.textMuted)),
                    ],
                  ),
          ],
      ],
    );
  }

  Widget _noteCard(Note n) {
    final color = n.isPraise ? PalaTheme.success : (n.isDisciplinary ? PalaTheme.danger : Theme.of(context).primaryColor);
    final body = htmlToText(n.content);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: PalaTheme.card,
        borderRadius: BorderRadius.circular(AppShapes.card),
        border: Border.all(color: PalaTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(AppShapes.control)),
            child: Text(n.type.isNotEmpty ? n.type : 'Feljegyzés', style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(height: 8),
          Text(n.title.isNotEmpty ? n.title : 'Feljegyzés', style: TextStyle(color: PalaTheme.text, fontWeight: FontWeight.w700, fontSize: 14)),
          const SizedBox(height: 2),
          Text('${n.senderName} • ${_date(n.date)}', style: TextStyle(color: PalaTheme.textMuted, fontSize: 12)),
          if (body.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(body, style: TextStyle(color: PalaTheme.text, fontSize: 13, height: 1.45)),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    return ListenableBuilder(
      listenable: widget.appModel,
      builder: (context, _) {
        final all = widget.appModel.messages;
        final shown = messageView(all, sender: messageSenders(all).contains(_sender) ? _sender : null, oldestFirst: _oldestFirst);
        final notes = [...widget.appModel.notes]..sort((a, b) => (b.date ?? DateTime(0)).compareTo(a.date ?? DateTime(0)));
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
                labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                tabs: [
                  Tab(text: 'Üzenetek (${all.length})'),
                  Tab(text: 'Feljegyzések (${notes.length})'),
                ],
              ),
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              RefreshIndicator(
                onRefresh: widget.appModel.refreshAll,
                color: primary,
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  children: [
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton.icon(
                        onPressed: () => ComposeMessageModal.show(context, widget.appModel),
                        icon: const Icon(Icons.edit, size: 14),
                        label: const Text('Új üzenet', style: TextStyle(fontSize: 12)),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _toolbar(all),
                    const SizedBox(height: 12),
                    if (shown.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(32),
                        child: Center(child: Text('Nincsenek beérkezett üzenetek.', style: TextStyle(color: PalaTheme.textMuted))),
                      )
                    else if (AdaptiveBreakpoints.isExpanded(context))
                      _messageTable(shown)
                    else
                      ...shown.map(_messageTile),
                    const SizedBox(height: 60),
                  ],
                ),
              ),
              RefreshIndicator(
                onRefresh: widget.appModel.refreshAll,
                color: primary,
                child: notes.isEmpty
                    ? ListView(children: [
                        Padding(
                          padding: const EdgeInsets.all(32),
                          child: Center(child: Text('Nincsenek feljegyzések.', style: TextStyle(color: PalaTheme.textMuted))),
                        ),
                      ])
                    : ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        children: [...notes.map(_noteCard), const SizedBox(height: 60)],
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// One opened message: its full text (fetched on opening, because the inbox
/// list only carries a short preview) and its attachments.
class _MessageSheet extends StatefulWidget {
  final AppModel appModel;
  final Message message;
  /// The sheet's scroll controller; null inside the desktop dialog.
  final ScrollController? scroll;
  final AttachmentPresenter presentAttachment;

  const _MessageSheet({
    required this.appModel,
    required this.message,
    this.scroll,
    required this.presentAttachment,
  });

  @override
  State<_MessageSheet> createState() => _MessageSheetState();
}

class _MessageSheetState extends State<_MessageSheet> {
  late Future<String> _text = widget.appModel.messageText(widget.message);
  int? _downloadingId;
  String _status = '';
  bool _statusIsError = false;
  File? _savedFile;

  bool get _isPhone => defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS;

  void _say(String text, {bool error = false, File? saved}) {
    if (!mounted) return;
    setState(() {
      _downloadingId = null;
      _status = text;
      _statusIsError = error;
      _savedFile = saved;
    });
  }

  Future<void> _download(MessageAttachment a) async {
    if (widget.appModel.isDemo) {
      _say('Demó módban a csatolmányok nem tölthetők le.', error: true);
      return;
    }
    setState(() {
      _downloadingId = a.id;
      _status = '${a.name} letöltése...';
      _statusIsError = false;
      _savedFile = null;
    });
    File? file;
    try {
      file = await widget.appModel.saveAttachment(a);
    } catch (_) {
      file = null;
    }
    if (file == null) {
      _say('A csatolmány most nem tölthető le. Ellenőrizd az internetkapcsolatot, és próbáld újra.', error: true);
      return;
    }
    if (!_isPhone) {
      _say('${file.uri.pathSegments.last} mentve ide: ${file.parent.path}', saved: file);
      return;
    }
    final opened = await _present(file);
    _say(
      opened ? '${a.name} megnyitva.' : 'Nincs olyan alkalmazás a készüléken, amely meg tudná nyitni ezt a fájlt.',
      error: !opened,
    );
  }

  Future<bool> _present(File file) async {
    try {
      return await widget.presentAttachment(file);
    } catch (_) {
      return false;
    }
  }

  Widget _body() {
    final style = TextStyle(color: PalaTheme.text, fontSize: 13, height: 1.5);
    return FutureBuilder<String>(
      future: _text,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator()));
        }
        if (snap.hasError) {
          final preview = htmlToText(widget.message.text);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Az üzenet teljes szövege most nem tölthető be.',
                style: TextStyle(color: PalaTheme.danger, fontSize: 13, fontWeight: FontWeight.w700),
              ),
              if (preview.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text('Csak az eleje látszik:', style: TextStyle(color: PalaTheme.textMuted, fontSize: 12)),
                const SizedBox(height: 8),
                SelectableText(preview, style: style),
              ],
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => setState(() {
                  _text = widget.appModel.messageText(widget.message);
                }),
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Újrapróbálás'),
              ),
            ],
          );
        }
        final text = snap.data ?? '';
        return SelectableText(text.isNotEmpty ? text : 'Nincs szöveges tartalom.', style: style);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final msg = widget.message;
    final sent = msg.sentDate != null ? DateFormat('yyyy.MM.dd HH:mm').format(msg.sentDate!) : '-';
    return ListView(
      controller: widget.scroll,
      shrinkWrap: widget.scroll == null,
      padding: const EdgeInsets.all(24),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                msg.subject.isNotEmpty ? msg.subject : 'Üzenet',
                style: TextStyle(color: PalaTheme.text, fontSize: 17, fontWeight: FontWeight.w700),
              ),
            ),
            IconButton(
              tooltip: 'Bezárás',
              icon: const Icon(Icons.close, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text('Feladó: ${msg.senderName} • $sent', style: TextStyle(color: PalaTheme.textMuted, fontSize: 12)),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: PalaTheme.card,
            borderRadius: BorderRadius.circular(AppShapes.card),
            border: Border.all(color: PalaTheme.border),
          ),
          child: _body(),
        ),
        if (msg.attachments.isNotEmpty) ...[
          const SizedBox(height: 14),
          Text('Csatolmányok', style: TextStyle(color: PalaTheme.textMuted, fontSize: 12, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          for (final a in msg.attachments)
            ListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              leading: const Icon(Icons.attach_file, size: 18),
              title: Text(a.name, style: TextStyle(color: PalaTheme.text, fontSize: 13)),
              trailing: _downloadingId == a.id
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : TextButton(
                      onPressed: _downloadingId == null ? () => _download(a) : null,
                      child: Text(_isPhone ? 'Megnyitás' : 'Letöltés'),
                    ),
            ),
          if (_status.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                _status,
                style: TextStyle(color: _statusIsError ? PalaTheme.danger : PalaTheme.textMuted, fontSize: 12),
              ),
            ),
          if (_savedFile != null)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () async {
                  final file = _savedFile!;
                  if (!await _present(file)) {
                    _say('A mappa nem nyitható meg. A fájl itt van: ${file.path}', error: true, saved: file);
                  }
                },
                icon: const Icon(Icons.folder_open, size: 16),
                label: const Text('Mappa megnyitása'),
              ),
            ),
        ],
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  ComposeMessageModal.show(
                    context,
                    widget.appModel,
                    initialRecipient: msg.senderName,
                    initialSubject: 'Re: ${msg.subject}',
                  );
                },
                icon: const Icon(Icons.reply, size: 16),
                label: const Text('Válasz a tanárnak'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Bezárás')),
            ),
          ],
        ),
      ],
    );
  }
}

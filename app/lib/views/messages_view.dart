import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pala/models/message.dart';
import 'package:pala/models/note.dart';
import 'package:pala/utils/html_text.dart';
import '../state/app_model.dart';
import '../theme/pala_theme.dart';
import 'compose_message_view.dart';

/// Üzenetek: the e-Ügyintézés inbox (sender filter, order, unread marks,
/// full text and attachments) and the teachers' notes (Feljegyzések), as on
/// the extension's Üzenetek page.
class MessagesView extends StatefulWidget {
  final AppModel appModel;

  const MessagesView({super.key, required this.appModel});

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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: PalaTheme.sidebar,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        final canDownload = Platform.isWindows || Platform.isMacOS || Platform.isLinux;
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.7,
          maxChildSize: 0.95,
          builder: (context, scroll) => ListView(
            controller: scroll,
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
              Text(
                'Feladó: ${msg.senderName} • ${_date(msg.sentDate, 'yyyy.MM.dd HH:mm')}',
                style: TextStyle(color: PalaTheme.textMuted, fontSize: 12),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: PalaTheme.card,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: PalaTheme.border),
                ),
                child: FutureBuilder<String>(
                  future: widget.appModel.messageText(msg),
                  builder: (context, snap) {
                    if (snap.connectionState != ConnectionState.done) {
                      return const Center(child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator()));
                    }
                    final text = snap.data ?? '';
                    return SelectableText(
                      snap.hasError ? 'Az üzenet szövege most nem tölthető be.' : (text.isNotEmpty ? text : 'Nincs szöveges tartalom.'),
                      style: TextStyle(color: PalaTheme.text, fontSize: 13, height: 1.5),
                    );
                  },
                ),
              ),
              if (msg.attachments.isNotEmpty) ...[
                const SizedBox(height: 14),
                Text('Mellékletek', style: TextStyle(color: PalaTheme.textMuted, fontSize: 12, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                for (final a in msg.attachments)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    leading: const Icon(Icons.attach_file, size: 18),
                    title: Text(a.name, style: TextStyle(color: PalaTheme.text, fontSize: 13)),
                    trailing: canDownload
                        ? TextButton(
                            onPressed: () async {
                              final messenger = ScaffoldMessenger.of(context);
                              final ok = await widget.appModel.downloadAttachment(a);
                              messenger.showSnackBar(SnackBar(
                                content: Text(ok ? '${a.name} mentve a Letöltések mappába.' : 'A melléklet nem tölthető le.'),
                              ));
                            },
                            child: const Text('Letöltés'),
                          )
                        : null,
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
          ),
        );
      },
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
          borderRadius: BorderRadius.circular(12),
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

  Widget _noteCard(Note n) {
    final color = n.isPraise ? PalaTheme.success : (n.isDisciplinary ? PalaTheme.danger : Theme.of(context).primaryColor);
    final body = htmlToText(n.content);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: PalaTheme.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: PalaTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(6)),
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

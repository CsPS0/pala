import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pala/models/message.dart';
import '../state/app_model.dart';
import '../theme/pala_theme.dart';
import 'compose_message_view.dart';

class TasksView extends StatefulWidget {
  final AppModel appModel;

  const TasksView({super.key, required this.appModel});

  @override
  State<TasksView> createState() => _TasksViewState();
}

class _TasksViewState extends State<TasksView> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _openMessageDetails(Message msg) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: PalaTheme.sidebar,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      msg.subject.isNotEmpty ? msg.subject : 'Üzenet',
                      style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Feladó: ${msg.senderName} • ${msg.sentDate != null ? DateFormat('yyyy.MM.dd HH:mm').format(msg.sentDate!) : "-"}',
                style: const TextStyle(color: PalaTheme.textMuted, fontSize: 12),
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
                child: Text(
                  msg.text.isNotEmpty ? msg.text : 'Nincs szöveges tartalom.',
                  style: const TextStyle(color: PalaTheme.text, fontSize: 13, height: 1.5),
                ),
              ),
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
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Bezárás'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.primaryColor;

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
            tabs: const [
              Tab(text: 'Házi Feladatok'),
              Tab(text: 'Dolgozatok'),
              Tab(text: 'Üzenetek'),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // 1. Homework Checklist Tab
          RefreshIndicator(
            onRefresh: widget.appModel.refreshAll,
            color: primary,
            child: widget.appModel.homework.isEmpty
                ? const Center(child: Text('Nincsenek aktív házi feladatok.', style: TextStyle(color: PalaTheme.textMuted)))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    itemCount: widget.appModel.homework.length,
                    itemBuilder: (context, idx) {
                      final h = widget.appModel.homework[idx];
                      final hwId = (h.uid != null && h.uid!.isNotEmpty) ? h.uid! : 'hw_$idx';
                      final isDone = widget.appModel.completedHomework.contains(hwId);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: Material(
                          color: PalaTheme.card,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: const BorderSide(color: PalaTheme.border),
                          ),
                          child: CheckboxListTile(
                            value: isDone,
                            activeColor: primary,
                            checkColor: Colors.black,
                            onChanged: (_) => widget.appModel.toggleHomework(hwId),
                            title: Text(
                              widget.appModel.getDisplaySubject(h.subject),
                              style: TextStyle(
                                color: isDone ? PalaTheme.textMuted : Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                decoration: isDone ? TextDecoration.lineThrough : null,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(
                                  h.text,
                                  style: TextStyle(
                                    color: isDone ? PalaTheme.textMuted.withValues(alpha: 0.6) : PalaTheme.text,
                                    fontSize: 12,
                                    decoration: isDone ? TextDecoration.lineThrough : null,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Határidő: ${h.deadline != null ? DateFormat('yyyy.MM.dd').format(h.deadline!) : "-"}',
                                  style: const TextStyle(color: PalaTheme.warning, fontSize: 11, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // 2. Exams Tab
          RefreshIndicator(
            onRefresh: widget.appModel.refreshAll,
            color: primary,
            child: widget.appModel.exams.isEmpty
                ? const Center(child: Text('Nincsenek bejelentett dolgozatok.', style: TextStyle(color: PalaTheme.textMuted)))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    itemCount: widget.appModel.exams.length,
                    itemBuilder: (context, idx) {
                      final e = widget.appModel.exams[idx];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: PalaTheme.card,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: PalaTheme.border),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: primary.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                e.mode.isNotEmpty ? e.mode : 'Dolgozat',
                                style: TextStyle(color: primary, fontSize: 11, fontWeight: FontWeight.w700),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.appModel.getDisplaySubject(e.subject),
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    e.theme != null && e.theme!.isNotEmpty ? e.theme! : 'Téma nincs megadva',
                                    style: const TextStyle(color: PalaTheme.textMuted, fontSize: 12),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Dátum: ${e.date != null ? DateFormat('yyyy.MM.dd').format(e.date!) : "-"}',
                                    style: const TextStyle(color: PalaTheme.textMuted, fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),

          // 3. Messages Tab
          RefreshIndicator(
            onRefresh: widget.appModel.refreshAll,
            color: primary,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              children: [
                // Top Composer Card
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: PalaTheme.card,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: primary.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.mail_outline, color: primary, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'Kréta Üzenetküldés',
                              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Colors.white),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Írj közvetlen üzenetet tanáraidnak',
                              style: TextStyle(fontSize: 11, color: PalaTheme.textMuted),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => ComposeMessageModal.show(context, widget.appModel),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        icon: const Icon(Icons.edit, size: 14),
                        label: const Text('Új Üzenet', style: TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                if (widget.appModel.messages.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(32),
                    alignment: Alignment.center,
                    child: const Text('Nincsenek beérkezett üzenetek.', style: TextStyle(color: PalaTheme.textMuted)),
                  )
                else
                  ...widget.appModel.messages.map((m) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Material(
                        color: PalaTheme.card,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: PalaTheme.border),
                        ),
                        child: ListTile(
                          title: Text(
                            m.subject.isNotEmpty ? m.subject : '(Nincs tárgy)',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14),
                          ),
                          subtitle: Text(
                            '${m.senderName} • ${m.sentDate != null ? DateFormat('yyyy.MM.dd').format(m.sentDate!) : "-"}',
                            style: const TextStyle(color: PalaTheme.textMuted, fontSize: 12),
                          ),
                          trailing: const Icon(Icons.chevron_right, size: 20, color: PalaTheme.textMuted),
                          onTap: () => _openMessageDetails(m),
                        ),
                      ),
                    );
                  }),
                const SizedBox(height: 60),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

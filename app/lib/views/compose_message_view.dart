import 'package:flutter/material.dart';
import '../state/app_model.dart';
import '../theme/pala_theme.dart';

class ComposeMessageModal extends StatefulWidget {
  final AppModel appModel;
  final String? initialRecipient;
  final String? initialSubject;

  const ComposeMessageModal({
    super.key,
    required this.appModel,
    this.initialRecipient,
    this.initialSubject,
  });

  static void show(
    BuildContext context,
    AppModel appModel, {
    String? initialRecipient,
    String? initialSubject,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: PalaTheme.sidebar,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => ComposeMessageModal(
        appModel: appModel,
        initialRecipient: initialRecipient,
        initialSubject: initialSubject,
      ),
    );
  }

  @override
  State<ComposeMessageModal> createState() => _ComposeMessageModalState();
}

class _ComposeMessageModalState extends State<ComposeMessageModal> {
  late final TextEditingController _recipientController;
  late final TextEditingController _subjectController;
  final _messageController = TextEditingController();
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _recipientController = TextEditingController(text: widget.initialRecipient ?? '');
    _subjectController = TextEditingController(text: widget.initialSubject ?? '');
  }

  @override
  void dispose() {
    _recipientController.dispose();
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  List<String> _getAllTeachers() {
    final Set<String> teacherNames = {};

    // 1. From API teachers list
    for (final t in widget.appModel.teachers) {
      final name = (t['Nev'] ?? t['nev'] ?? t['name'])?.toString();
      if (name != null && name.trim().isNotEmpty) {
        teacherNames.add(name.trim());
      }
    }

    // 2. From grades
    for (final g in widget.appModel.grades) {
      if (g.teacherName != null && g.teacherName!.trim().isNotEmpty) {
        teacherNames.add(g.teacherName!.trim());
      }
    }

    // 3. From timetable
    for (final t in widget.appModel.timetable) {
      if (t.teacher != null && t.teacher!.trim().isNotEmpty) {
        teacherNames.add(t.teacher!.trim());
      }
    }

    // Fallback demo teachers if empty
    if (teacherNames.isEmpty) {
      teacherNames.addAll([
        'Arany Jánosné (Magyar nyelv és irodalom)',
        'Bolyai Farkas (Matematika)',
        'Eötvös Loránd (Fizika)',
        'Neumann János (Digitális kultúra)',
        'Semmelweis Ignác (Biológia)',
        'Szent-Györgyi Albert (Kémia)',
        'Zrínyi Miklós (Történelem)',
        'Shakespeare William (Angol nyelv)',
      ]);
    }

    return teacherNames.toList()..sort();
  }

  Future<void> _send() async {
    final recipient = _recipientController.text.trim();
    final subject = _subjectController.text.trim();
    final text = _messageController.text.trim();

    if (recipient.isEmpty || subject.isEmpty || text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kérlek tölts ki minden mezőt!')),
      );
      return;
    }

    setState(() => _isSending = true);

    final success = await widget.appModel.sendMessage(
      recipientName: recipient,
      subject: subject,
      messageText: text,
    );

    if (!mounted) return;
    setState(() => _isSending = false);

    if (success) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Üzenet sikeresen elküldve a tanárnak!')),
      );
      widget.appModel.refreshAll();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.appModel.errorMessage ?? 'Nem sikerült elküldeni az üzenetet.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final allTeachers = _getAllTeachers();

    return Padding(
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Új Üzenet Küldése Tanárnak',
                style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Recipient Dropdown / Input
          const Text('Címzett Tanár kiválasztása', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: PalaTheme.textMuted)),
          const SizedBox(height: 6),
          if (allTeachers.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: PalaTheme.card,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: PalaTheme.border),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: allTeachers.contains(_recipientController.text) ? _recipientController.text : null,
                  hint: Text(
                    _recipientController.text.isNotEmpty ? _recipientController.text : 'Válassz tanárt a listából...',
                    style: const TextStyle(fontSize: 13, color: Colors.white70),
                  ),
                  isExpanded: true,
                  dropdownColor: PalaTheme.card,
                  items: allTeachers.map((name) {
                    return DropdownMenuItem<String>(
                      value: name,
                      child: Text(name, style: const TextStyle(fontSize: 13)),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _recipientController.text = val);
                  },
                ),
              ),
            ),
            const SizedBox(height: 6),
          ],
          TextField(
            controller: _recipientController,
            decoration: const InputDecoration(hintText: 'Vagy írd be a tanár nevét...'),
          ),

          const SizedBox(height: 12),

          // Subject
          const Text('Tárgy', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: PalaTheme.textMuted)),
          const SizedBox(height: 6),
          TextField(
            controller: _subjectController,
            decoration: const InputDecoration(hintText: 'Pl. Kérdés a dolgozattal kapcsolatban / Igazolás'),
          ),

          const SizedBox(height: 12),

          // Message Body
          const Text('Üzenet szövege', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: PalaTheme.textMuted)),
          const SizedBox(height: 6),
          TextField(
            controller: _messageController,
            maxLines: 4,
            decoration: const InputDecoration(hintText: 'Írd ide az üzenetet...'),
          ),

          const SizedBox(height: 20),

          ElevatedButton.icon(
            onPressed: _isSending ? null : _send,
            icon: _isSending
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                : const Icon(Icons.send, size: 16),
            label: Text(_isSending ? 'Küldés folyamatban...' : 'Üzenet Elküldése'),
          ),
        ],
      ),
    );
  }
}

class MessageAttachment {
  final int id;
  final String name;

  MessageAttachment({required this.id, required this.name});

  factory MessageAttachment.fromJson(Map<String, dynamic> json) {
    return MessageAttachment(
      id: json['azonosito'] ?? 0,
      name: json['fajlNev'] ?? 'fajl',
    );
  }
}

class Message {
  final int id;
  final String senderName;
  final String subject;
  final DateTime? sentDate;
  final bool isRead;
  final String text;
  final List<MessageAttachment> attachments;

  const Message({
    required this.id,
    required this.senderName,
    required this.subject,
    this.sentDate,
    this.isRead = false,
    this.text = '',
    this.attachments = const [],
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    final msg = json['uzenet'];
    final attachmentsRaw = msg?['csatolmanyok'];
    final List<MessageAttachment> parsedAttachments = [];
    if (attachmentsRaw is List) {
      for (var item in attachmentsRaw) {
        if (item is Map<String, dynamic>) {
          parsedAttachments.add(MessageAttachment.fromJson(item));
        }
      }
    }

    return Message(
      id: json['azonosito'] ?? 0,
      senderName: msg?['feladoNev'] ?? 'Ismeretlen feladó',
      subject: msg?['targy'] ?? 'Nincs tárgy',
      sentDate: msg?['kuldesDatum'] != null ? DateTime.tryParse(msg!['kuldesDatum'].toString())?.toLocal() : null,
      isRead: json['isElolvasva'] == true,
      text: msg?['szoveg'] ?? '',
      attachments: parsedAttachments,
    );
  }
}

/// Message lists show the newest first; messages without a date go last.
/// The extension mirrors this in `KretaApi.sortMessagesNewestFirst`.
List<Message> sortMessagesNewestFirst(Iterable<Message> messages) {
  return messages.toList()
    ..sort((a, b) {
      final da = a.sentDate, db = b.sentDate;
      if (da == null && db == null) return 0;
      if (da == null) return 1;
      if (db == null) return -1;
      return db.compareTo(da);
    });
}

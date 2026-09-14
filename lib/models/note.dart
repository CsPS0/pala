class Note {
  final String id;
  final String type;
  final String senderName;
  final String title;
  final String content;
  final DateTime? date;

  const Note({
    required this.id,
    required this.type,
    required this.senderName,
    required this.title,
    required this.content,
    this.date,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'senderName': senderName,
    'title': title,
    'content': content,
    'date': date?.toIso8601String(),
  };

  bool get isPraise {
    final t = type.toLowerCase();
    return t.contains('dicséret') || t.contains('dicseret');
  }

  bool get isDisciplinary {
    final t = type.toLowerCase();
    return t.contains('figyelmeztet') ||
        t.contains('intő') ||
        t.contains('into') ||
        t.contains('megrovás') ||
        t.contains('megrovas');
  }

  factory Note.fromJson(Map<String, dynamic> json) {
    String parsedType = 'Feljegyzés';
    final tipusRaw = json['Tipus'];
    if (tipusRaw is Map<String, dynamic>) {
      parsedType = tipusRaw['Leiras'] ?? tipusRaw['Nev'] ?? parsedType;
    } else if (tipusRaw is String) {
      parsedType = tipusRaw;
    }

    final rawDate = json['KeszitesDatuma'] ?? json['Datum'] ?? json['RogzitesDatuma'];

    return Note(
      id: (json['Uid'] ?? json['Id'] ?? '').toString(),
      type: parsedType,
      senderName: json['KeszitoTanarNeve'] ?? json['Tanar'] ?? 'Ismeretlen tanár',
      title: json['Cim'] ?? json['Tartalom'] ?? parsedType,
      content: json['Tartalom'] ?? json['Szoveg'] ?? '',
      date: rawDate != null ? DateTime.tryParse(rawDate.toString())?.toLocal() : null,
    );
  }
}

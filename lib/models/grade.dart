class Grade {
  final String subject;
  final String? subjectCategory;
  final num? numericValue;
  final String? textValue;
  final double weight;
  final DateTime? date;
  final String? type;
  final String? theme;
  final String? teacherName;

  const Grade({
    required this.subject,
    this.subjectCategory,
    this.numericValue,
    this.textValue,
    this.weight = 100.0,
    this.date,
    this.type,
    this.theme,
    this.teacherName,
  });

  Map<String, dynamic> toJson() => {
    'subject': subject,
    'subjectCategory': subjectCategory,
    'numericValue': numericValue,
    'textValue': textValue,
    'weight': weight,
    'date': date?.toIso8601String(),
    'type': type,
    'theme': theme,
    'teacherName': teacherName,
  };

  bool get isSummaryGrade {
    final t = type?.toLowerCase() ?? '';
    return t.contains('év végi') || 
           t.contains('félévi') || 
           t.contains('negyedévi') || 
           t.contains('háromnegyedévi') ||
           t.contains('vegi') ||
           t.contains('felevi') ||
           t.contains('negyedevi') ||
           t.contains('osztályozó') ||
           t.contains('osztalyozo');
  }

  factory Grade.fromJson(Map<String, dynamic> json) {
    final weightRaw = json['SulySzazalekErteke'];
    double parsedWeight = 100.0;
    if (weightRaw != null) {
      parsedWeight = weightRaw is num ? weightRaw.toDouble() : double.tryParse(weightRaw.toString()) ?? 100.0;
    }

    return Grade(
      subject: json['Tantargy']?['Nev'] ?? 'Ismeretlen tantárgy',
      subjectCategory: json['Tantargy']?['Kategoria']?['Nev'],
      numericValue: json['SzamErtek'],
      textValue: json['SzovegesErtek'],
      weight: parsedWeight,
      date: json['KeszitesDatuma'] != null ? DateTime.tryParse(json['KeszitesDatuma'])?.toLocal() : null,
      // Leiras is the readable name ("Félévi jegy"), Nev the code; read like the extension does.
      type: json['Tipus']?['Leiras'] ?? json['Tipus']?['Nev'],
      theme: json['Tema'],
      teacherName: json['ErtekeloTanarNeve'],
    );
  }
}

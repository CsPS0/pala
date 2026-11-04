/// What a Kréta evaluation holds: a 1-5 grade, a percentage, or text.
/// Kréta sends it as `ErtekFajta.Nev` (`Osztalyzat`, `Szazalekos`,
/// `Szoveges`). A percentage can carry a 1-5 `SzamErtek` ("4%"), so the
/// number alone does not make a grade.
enum GradeValueKind { grade, percent, text }

class Grade {
  final String subject;
  final String? subjectCategory;

  /// The 1-5 grade. Null for percentage and text evaluations, even when Kréta
  /// sends a number with them, so code that reads it never mistakes "4%" for a 4.
  final num? numericValue;
  final String? textValue;

  /// The percentage of a percentage evaluation ("85%"), otherwise null.
  final int? percentValue;
  final double weight;
  final DateTime? date;
  final String? type;
  final String? theme;
  final String? teacherName;
  final GradeValueKind? _valueKind;

  const Grade({
    required this.subject,
    this.subjectCategory,
    this.numericValue,
    this.textValue,
    this.percentValue,
    this.weight = 100.0,
    this.date,
    this.type,
    this.theme,
    this.teacherName,
    GradeValueKind? valueKind,
  }) : _valueKind = valueKind;

  /// The kind Kréta sent; for grades built in code it follows the values.
  GradeValueKind get valueKind {
    final known = _valueKind;
    if (known != null) return known;
    if (percentValue != null) return GradeValueKind.percent;
    final v = numericValue;
    if (v != null && v >= 1 && v <= 5) return GradeValueKind.grade;
    return GradeValueKind.text;
  }

  /// The value as shown to the user: "4", "85%" or the text evaluation.
  String get displayValue {
    final text = textValue?.trim() ?? '';
    return switch (valueKind) {
      GradeValueKind.grade => numericValue != null ? '${numericValue!.round()}' : (text.isEmpty ? '-' : text),
      GradeValueKind.percent => '${percentValue ?? '-'}%',
      GradeValueKind.text => text.isEmpty ? '-' : text,
    };
  }

  /// Kréta's `ErtekFajta.Nev`, or, when it is missing, the old guess: a
  /// trailing `%` or a number above 5 is a percentage, 1-5 a grade, else text.
  static GradeValueKind _kindOf(Map<String, dynamic> json) {
    final f = json['ErtekFajta'];
    final name = f is Map ? f['Nev']?.toString() : null;
    if (name != null && name.isNotEmpty) {
      // An Osztalyzat without a 1-5 number ("Nem írt" with 0) is shown as its text.
      if (name == 'Osztalyzat') {
        final v = json['SzamErtek'];
        return (v is num && v >= 1 && v <= 5) ? GradeValueKind.grade : GradeValueKind.text;
      }
      if (name == 'Szazalekos') return GradeValueKind.percent;
      return GradeValueKind.text;
    }
    final v = json['SzamErtek'];
    final text = json['SzovegesErtek']?.toString().trim() ?? '';
    if (text.endsWith('%') || (v is num && v > 5)) return GradeValueKind.percent;
    if (v is num && v >= 1 && v <= 5) return GradeValueKind.grade;
    return GradeValueKind.text;
  }

  Map<String, dynamic> toJson() => {
    'subject': subject,
    'subjectCategory': subjectCategory,
    'numericValue': numericValue,
    'textValue': textValue,
    'percentValue': percentValue,
    'weight': weight,
    'date': date?.toIso8601String(),
    'type': type,
    'theme': theme,
    'teacherName': teacherName,
    'valueKind': valueKind.name,
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

    final kind = _kindOf(json);
    final rawNumber = json['SzamErtek'] is num ? json['SzamErtek'] as num : null;
    final text = json['SzovegesErtek'] as String?;
    return Grade(
      subject: json['Tantargy']?['Nev'] ?? 'Ismeretlen tantárgy',
      subjectCategory: json['Tantargy']?['Kategoria']?['Nev'],
      numericValue: kind == GradeValueKind.grade ? rawNumber : null,
      textValue: text,
      percentValue: kind == GradeValueKind.percent
          ? (int.tryParse(text?.replaceAll('%', '').trim() ?? '') ?? rawNumber?.round())
          : null,
      weight: parsedWeight,
      date: json['KeszitesDatuma'] != null ? DateTime.tryParse(json['KeszitesDatuma'])?.toLocal() : null,
      // Leiras is the readable name ("Félévi jegy"), Nev the code; read like the extension does.
      type: json['Tipus']?['Leiras'] ?? json['Tipus']?['Nev'],
      theme: json['Tema'],
      teacherName: json['ErtekeloTanarNeve'],
      valueKind: kind,
    );
  }
}

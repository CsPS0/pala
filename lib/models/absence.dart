class Absence {
  final String subject;
  final DateTime? date;
  final String status;
  final String? type;
  final int? delayMinutes;

  const Absence({
    required this.subject,
    this.date,
    required this.status,
    this.type,
    this.delayMinutes,
  });

  factory Absence.fromJson(Map<String, dynamic> json) {
    return Absence(
      subject: json['Tantargy']?['Nev'] ?? 'Ismeretlen tantárgy',
      date: json['Datum'] != null ? DateTime.tryParse(json['Datum'])?.toLocal() : null,
      status: json['IgazolasAllapota'] ?? 'Ismeretlen',
      type: json['Tipus']?['Leiras'] ?? json['Tipus']?['Nev'],
      // Kréta sends KesesPercben (as the reference client rsfilc reads it).
      delayMinutes: (json['KesesPercben'] ?? json['KesesIdotartama']) as int?,
    );
  }
}

/// The one CSV format every Dart-side export uses (TUI, app): a UTF-8 BOM so
/// Excel reads the accents, semicolons because Hungarian Excel splits on ';',
/// every value quoted with inner quotes doubled, and CRLF line ends.
/// The extension writes the same format (KretaApi.toCsv).
String toCsv(List<String> header, Iterable<List<Object?>> rows) {
  String field(Object? v) => '"${(v ?? '').toString().replaceAll('"', '""')}"';
  final buffer = StringBuffer('\uFEFF');
  buffer.write('${header.join(';')}\r\n');
  for (final row in rows) {
    buffer.write('${row.map(field).join(';')}\r\n');
  }
  return buffer.toString();
}

/// Local calendar date as YYYY-MM-DD (the UTC date can be a day off).
String csvDate(DateTime? d) {
  if (d == null) return '';
  final l = d.toLocal();
  return '${l.year.toString().padLeft(4, '0')}-${l.month.toString().padLeft(2, '0')}-${l.day.toString().padLeft(2, '0')}';
}

/// Plain text from Kréta's HTML message and homework bodies: block ends and
/// <br> become line breaks, tags are dropped, entities decoded. Text without
/// tags is returned as is (trimmed). Style and script blocks are left out, a
/// link keeps its address when the label does not show it, and a tag cut in
/// half at the end (the inbox preview stops at 100 characters) is dropped.
String htmlToText(String? html) {
  var s = html ?? '';
  if (!s.contains('<') && !s.contains('&')) return s.trim();
  s = s
      .replaceAll(RegExp(r'<(style|script)\b[^>]*>.*?</\1\s*>', caseSensitive: false, dotAll: true), '')
      .replaceAllMapped(
        RegExp(r'''<a\b[^>]*\bhref\s*=\s*["']?(https?://[^"'\s>]+)["']?[^>]*>(.*?)</a\s*>''',
            caseSensitive: false, dotAll: true),
        (m) {
          final url = m.group(1)!, label = m.group(2)!;
          return label.contains(url) ? label : '$label ($url)';
        },
      )
      .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'</(p|div|li|h[1-6]|tr)>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'<(?:/?[a-zA-Z]|!)[^>]*>'), '')
      .replaceAll(RegExp(r'</?[a-zA-Z][^<>]*$'), '');
  s = s.replaceAllMapped(RegExp(r'&(#x?[0-9a-fA-F]+|[a-zA-Z]+);'), (m) {
    final code = m.group(1)!;
    if (code.startsWith('#x') || code.startsWith('#X')) {
      final v = int.tryParse(code.substring(2), radix: 16);
      return v != null ? String.fromCharCode(v) : m.group(0)!;
    }
    if (code.startsWith('#')) {
      final v = int.tryParse(code.substring(1));
      return v != null ? String.fromCharCode(v) : m.group(0)!;
    }
    return _entities[code] ?? m.group(0)!;
  });
  return s
      .split('\n')
      .map((line) => line.replaceAll(RegExp(r'[ \t ]+'), ' ').trim())
      .join('\n')
      .replaceAll(RegExp(r'\n{3,}'), '\n\n')
      .trim();
}

const _entities = {
  'nbsp': ' ',
  'amp': '&',
  'lt': '<',
  'gt': '>',
  'quot': '"',
  'apos': "'",
  'aacute': 'á', 'Aacute': 'Á',
  'eacute': 'é', 'Eacute': 'É',
  'iacute': 'í', 'Iacute': 'Í',
  'oacute': 'ó', 'Oacute': 'Ó',
  'ouml': 'ö', 'Ouml': 'Ö',
  'uacute': 'ú', 'Uacute': 'Ú',
  'uuml': 'ü', 'Uuml': 'Ü',
  'ndash': '–',
  'mdash': '—',
  'hellip': '…',
};

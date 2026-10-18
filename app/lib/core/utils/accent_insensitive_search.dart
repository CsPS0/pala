/// Hungarian diacritic and accent-insensitive string normalization and matching utility.
class AccentInsensitiveSearch {
  AccentInsensitiveSearch._();

  static const Map<String, String> _diacriticMap = {
    'á': 'a',
    'é': 'e',
    'í': 'i',
    'ó': 'o',
    'ö': 'o',
    'ő': 'o',
    'ú': 'u',
    'ü': 'u',
    'ű': 'u',
    'Á': 'a',
    'É': 'e',
    'Í': 'i',
    'Ó': 'o',
    'Ö': 'o',
    'Ő': 'o',
    'Ú': 'u',
    'Ü': 'u',
    'Ű': 'u',
  };

  /// Normalizes a string by converting to lowercase and stripping Hungarian accents/diacritics.
  static String normalize(String? input) {
    if (input == null || input.isEmpty) return '';
    final buffer = StringBuffer();
    for (int i = 0; i < input.length; i++) {
      final char = input[i];
      final replaced = _diacriticMap[char];
      if (replaced != null) {
        buffer.write(replaced);
      } else {
        buffer.write(char.toLowerCase());
      }
    }
    return buffer.toString().trim();
  }

  /// Evaluates whether [source] contains [query] under accent-insensitive and case-insensitive rules.
  static bool matches(String? source, String? query) {
    if (source == null || query == null) return false;
    final normalizedQuery = normalize(query);
    if (normalizedQuery.isEmpty) return true;
    final normalizedSource = normalize(source);
    return normalizedSource.contains(normalizedQuery);
  }

  /// Evaluates whether any element of [sources] contains [query].
  static bool matchesAny(Iterable<String?> sources, String? query) {
    final normalizedQuery = normalize(query);
    if (normalizedQuery.isEmpty) return true;
    for (final s in sources) {
      if (matches(s, normalizedQuery)) return true;
    }
    return false;
  }
}

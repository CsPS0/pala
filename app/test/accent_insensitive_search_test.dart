import 'package:flutter_test/flutter_test.dart';
import 'package:pala_app/core/utils/accent_insensitive_search.dart';

void main() {
  group('AccentInsensitiveSearch tests', () {
    test('normalizes Hungarian vowels with diacritics', () {
      expect(AccentInsensitiveSearch.normalize('áéíóöőúüű'), 'aeiooouuu');
      expect(AccentInsensitiveSearch.normalize('ÁÉÍÓÖŐÚÜŰ'), 'aeiooouuu');
    });

    test('matches queries with and without accents', () {
      expect(AccentInsensitiveSearch.matches('Történelem', 'tortenelem'), isTrue);
      expect(AccentInsensitiveSearch.matches('Történelem', 'TÖRTÉNELEM'), isTrue);
      expect(AccentInsensitiveSearch.matches('Matematika', 'mat'), isTrue);
      expect(AccentInsensitiveSearch.matches('Irodalom', 'irodalom'), isTrue);
      expect(AccentInsensitiveSearch.matches('Fizika', 'kémia'), isFalse);
    });

    test('matchesAny evaluates across multiple entity attributes', () {
      final attributes = ['Matematika', 'Kovács János', '102-es terem', 'Algebra dolgozat'];
      expect(AccentInsensitiveSearch.matchesAny(attributes, 'kovacs'), isTrue);
      expect(AccentInsensitiveSearch.matchesAny(attributes, 'algebra'), isTrue);
      expect(AccentInsensitiveSearch.matchesAny(attributes, '102'), isTrue);
      expect(AccentInsensitiveSearch.matchesAny(attributes, 'biologia'), isFalse);
    });
  });
}

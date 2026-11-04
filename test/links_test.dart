import 'package:pala/links.dart';
import 'package:test/test.dart';

void main() {
  test('settings links: website and GitHub, no entry for an empty URL', () {
    final links = PalaLinks.visible();
    expect(links.map((l) => l.url), containsAll(['https://pala-app.hu', 'https://github.com/CsPS0/pala']));
    expect(links.every((l) => l.url.isNotEmpty), isTrue);
    expect(links.any((l) => l.label == 'Instagram'), PalaLinks.instagram.isNotEmpty);
  });
}

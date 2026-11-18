import 'package:pala/utils/html_text.dart';
import 'package:test/test.dart';

void main() {
  test('htmlToText keeps line breaks, drops tags and decodes entities', () {
    expect(htmlToText('<p>Kedves Diákok!</p><p>Holnap <b>dolgozat</b>&nbsp;lesz.<br>Üdv,<br/>Kovács&amp;Tsa</p>'),
        'Kedves Diákok!\nHolnap dolgozat lesz.\nÜdv,\nKovács&Tsa');
    expect(htmlToText('&lt;3 &quot;idézet&quot; &#39;x&#39; &#337;'), '<3 "idézet" \'x\' ő');
    expect(htmlToText('sima szöveg'), 'sima szöveg');
    expect(htmlToText('<ul><li>egy</li><li>kettő</li></ul>'), 'egy\nkettő');
  });

  test('htmlToText drops a tag that the 100-character preview cut in half', () {
    expect(htmlToText('<p>A részletek a csatolt fájlban <stro'), 'A részletek a csatolt fájlban');
    expect(htmlToText('<p>Kedves Szülők!</p><p style="margin:0;font-fam'), 'Kedves Szülők!');
    expect(htmlToText('2 < 3 és 5 > 4'), '2 < 3 és 5 > 4');
  });

  test('htmlToText leaves out style and script blocks', () {
    expect(htmlToText('<style>p { color: red; }</style><p>Szöveg</p><script>alert(1)</script>'), 'Szöveg');
  });

  test('htmlToText keeps the address of a link whose label hides it', () {
    expect(htmlToText('<p>Jelentkezés <a href="https://pelda.hu/urlap">ezen az űrlapon</a>.</p>'),
        'Jelentkezés ezen az űrlapon (https://pelda.hu/urlap).');
    expect(htmlToText('<a href="https://pelda.hu">https://pelda.hu</a>'), 'https://pelda.hu');
    expect(htmlToText('<a href="javascript:alert(1)">katt</a>'), 'katt');
  });
}

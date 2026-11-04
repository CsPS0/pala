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
}

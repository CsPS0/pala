import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import '../utils/logger.dart';

class WebComposerData {
  final String subject;
  final String text;
  final List<int> recipientIds;
  final List<String> attachmentPaths;

  WebComposerData({
    required this.subject,
    required this.text,
    required this.recipientIds,
    this.attachmentPaths = const [],
  });
}

class WebComposerServer {
  static Future<WebComposerData?> start({
    required List<Map<String, dynamic>> teachers,
    int? preselectedTeacherId,
    String? preselectedSubject,
    String studentName = '',
  }) async {
    HttpServer? server;
    try {
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    } catch (e) {
      PalaLogger.debug('Failed to bind WebComposerServer: $e');
      return null;
    }

    final port = server.port;
    final sessionToken = base64Url.encode(List<int>.generate(24, (_) => Random.secure().nextInt(256)));
    final url = 'http://127.0.0.1:$port/?token=$sessionToken';
    final completer = Completer<WebComposerData?>();

    final htmlContent = _generateHtml(
      teachers: teachers,
      preselectedTeacherId: preselectedTeacherId,
      preselectedSubject: preselectedSubject ?? '',
      studentName: studentName,
      sessionToken: sessionToken,
    );

    server.listen((HttpRequest request) async {
      final path = request.uri.path;

      // Validate session token for API requests to prevent CSRF / cross-origin tampering
      final requestToken = request.headers.value('x-pala-token') ?? request.uri.queryParameters['token'];

      if (request.method == 'GET' && (path == '/' || path == '/index.html')) {
        // Enforce token check on web UI access
        if (requestToken != sessionToken) {
          request.response
            ..statusCode = HttpStatus.forbidden
            ..write('Access Forbidden: Invalid or missing session token.');
          await request.response.close();
          return;
        }

        request.response
          ..statusCode = HttpStatus.ok
          ..headers.contentType = ContentType.html
          ..headers.set('X-Frame-Options', 'DENY')
          ..headers.set('X-Content-Type-Options', 'nosniff')
          ..write(htmlContent);
        await request.response.close();
      } else if (request.method == 'POST' && path == '/api/send') {
        if (requestToken != sessionToken) {
          request.response
            ..statusCode = HttpStatus.forbidden
            ..headers.contentType = ContentType.json
            ..write(jsonEncode({'error': 'Érvénytelen munkamenet token (CSRF védelem)'}));
          await request.response.close();
          return;
        }

        try {
          final content = await utf8.decodeStream(request);
          final data = jsonDecode(content) as Map<String, dynamic>;

          final subject = (data['subject'] ?? '').toString().trim();
          final text = (data['text'] ?? '').toString().trim();
          final recipientIds = (data['recipientIds'] as List? ?? [])
              .map((e) => int.tryParse(e.toString()) ?? 0)
              .where((id) => id > 0)
              .toList();
          final attachments = (data['attachments'] as List? ?? [])
              .map((e) => e.toString())
              .toList();

          if (subject.isNotEmpty && text.isNotEmpty && recipientIds.isNotEmpty) {
            request.response
              ..statusCode = HttpStatus.ok
              ..headers.contentType = ContentType.json
              ..write(jsonEncode({'success': true}));
            await request.response.close();

            if (!completer.isCompleted) {
              completer.complete(
                WebComposerData(
                  subject: subject,
                  text: text,
                  recipientIds: recipientIds,
                  attachmentPaths: attachments,
                ),
              );
            }
          } else {
            request.response
              ..statusCode = HttpStatus.badRequest
              ..headers.contentType = ContentType.json
              ..write(jsonEncode({'error': 'Hiányzó mezők (Tárgy, Címzett vagy Szöveg)'}));
            await request.response.close();
          }
        } catch (e) {
          request.response
            ..statusCode = HttpStatus.internalServerError
            ..headers.contentType = ContentType.json
            ..write(jsonEncode({'error': e.toString()}));
          await request.response.close();
        }
      } else if (request.method == 'POST' && path == '/api/cancel') {
        if (requestToken != sessionToken) {
          request.response
            ..statusCode = HttpStatus.forbidden
            ..headers.contentType = ContentType.json
            ..write(jsonEncode({'error': 'Érvénytelen munkamenet token'}));
          await request.response.close();
          return;
        }

        request.response
          ..statusCode = HttpStatus.ok
          ..headers.contentType = ContentType.json
          ..write(jsonEncode({'canceled': true}));
        await request.response.close();

        if (!completer.isCompleted) {
          completer.complete(null);
        }
      } else {
        request.response
          ..statusCode = HttpStatus.notFound
          ..write('Not found');
        await request.response.close();
      }
    });

    _openBrowser(url);

    try {
      final result = await completer.future.timeout(const Duration(minutes: 15), onTimeout: () => null);
      return result;
    } finally {
      await Future.delayed(const Duration(milliseconds: 300));
      await server.close(force: true);
    }
  }

  static void _openBrowser(String url) {
    try {
      if (Platform.isWindows) {
        Process.run('explorer', [url]);
      } else if (Platform.isLinux) {
        Process.run('xdg-open', [url]);
      } else if (Platform.isMacOS) {
        Process.run('open', [url]);
      }
    } catch (e) {
      PalaLogger.debug('Failed to open browser automatically: $e');
    }
  }

  static String _generateHtml({
    required List<Map<String, dynamic>> teachers,
    int? preselectedTeacherId,
    required String preselectedSubject,
    required String studentName,
    required String sessionToken,
  }) {
    final teachersOptions = teachers.map((t) {
      final id = t['azonosito'] ?? t['id'] ?? 0;
      final rawName = t['nev'] ?? t['name'] ?? 'Névtelen tanár';
      final rawSubjects = t['tantargyak'] ?? t['subjects'] ?? '';
      final safeName = htmlEscape.convert(rawName.toString());
      final safeSubjects = htmlEscape.convert(rawSubjects.toString());
      final label = safeSubjects.isNotEmpty ? '$safeName ($safeSubjects)' : safeName;
      final isSelected = preselectedTeacherId != null && preselectedTeacherId == id ? 'selected' : '';
      return '<option value="$id" $isSelected>$label</option>';
    }).join('\n');

    final safeStudentName = htmlEscape.convert(studentName);
    final safeSubject = htmlEscape.convert(preselectedSubject);
    final safeSessionToken = htmlEscape.convert(sessionToken);

    return '''<!DOCTYPE html>
<html lang="hu">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Pala // Üzenetküldő</title>
  <style>
    :root {
      --bg: #121212;
      --card: #1c1c1e;
      --input-bg: #262628;
      --border: #333336;
      --primary: #ff8800;
      --primary-hover: #ffa033;
      --text: #f0f0f2;
      --text-muted: #8e8e93;
      --error: #ff453a;
      --success: #30d158;
    }
    * {
      box-sizing: border-box;
      margin: 0;
      padding: 0;
    }
    body {
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
      background-color: var(--bg);
      color: var(--text);
      min-height: 100vh;
      display: flex;
      justify-content: center;
      align-items: center;
      padding: 20px;
    }
    .composer-container {
      width: 100%;
      max-width: 820px;
      background: var(--card);
      border: 1px solid var(--border);
      border-radius: 12px;
      box-shadow: 0 12px 40px rgba(0, 0, 0, 0.6);
      overflow: hidden;
      display: flex;
      flex-direction: column;
    }
    .header {
      padding: 16px 24px;
      border-bottom: 1px solid var(--border);
      display: flex;
      align-items: center;
      justify-content: space-between;
      background: #18181a;
    }
    .logo {
      display: flex;
      align-items: center;
      gap: 10px;
      font-size: 1.15rem;
      font-weight: 700;
      color: var(--primary);
      letter-spacing: 0.5px;
    }
    .logo-badge {
      font-size: 0.75rem;
      background: rgba(255, 136, 0, 0.15);
      border: 1px solid rgba(255, 136, 0, 0.3);
      padding: 3px 8px;
      border-radius: 6px;
      color: var(--primary);
      text-transform: uppercase;
    }
    .form-body {
      padding: 24px;
      display: flex;
      flex-direction: column;
      gap: 18px;
    }
    .form-group {
      display: flex;
      flex-direction: column;
      gap: 6px;
    }
    label {
      font-size: 0.85rem;
      font-weight: 600;
      color: var(--text-muted);
      text-transform: uppercase;
      letter-spacing: 0.5px;
    }
    select, input[type="text"] {
      width: 100%;
      padding: 12px 14px;
      background: var(--input-bg);
      border: 1px solid var(--border);
      border-radius: 8px;
      color: var(--text);
      font-size: 0.95rem;
      outline: none;
      transition: border-color 0.2s, box-shadow 0.2s;
    }
    select:focus, input[type="text"]:focus {
      border-color: var(--primary);
      box-shadow: 0 0 0 3px rgba(255, 136, 0, 0.2);
    }
    .templates-bar {
      display: flex;
      align-items: center;
      gap: 8px;
      flex-wrap: wrap;
    }
    .template-btn {
      background: #242426;
      border: 1px solid #38383c;
      color: var(--text-muted);
      padding: 5px 10px;
      font-size: 0.8rem;
      border-radius: 6px;
      cursor: pointer;
      transition: all 0.2s;
    }
    .template-btn:hover {
      background: #303034;
      color: var(--primary);
      border-color: var(--primary);
    }
    .toolbar {
      display: flex;
      gap: 4px;
      background: #18181a;
      padding: 8px 12px;
      border: 1px solid var(--border);
      border-bottom: none;
      border-top-left-radius: 8px;
      border-top-right-radius: 8px;
      flex-wrap: wrap;
    }
    .tool-btn {
      background: transparent;
      border: 1px solid transparent;
      color: var(--text);
      padding: 6px 10px;
      border-radius: 4px;
      cursor: pointer;
      font-size: 0.85rem;
      font-weight: 600;
      min-width: 28px;
      transition: background 0.15s;
    }
    .tool-btn:hover {
      background: #2c2c2e;
      border-color: #444;
      color: var(--primary);
    }
    .tool-separator {
      width: 1px;
      height: 22px;
      background: var(--border);
      margin: 0 4px;
      align-self: center;
    }
    .editor-wrapper {
      display: flex;
      flex-direction: column;
    }
    .editor {
      min-height: 220px;
      max-height: 400px;
      overflow-y: auto;
      padding: 16px;
      background: var(--input-bg);
      border: 1px solid var(--border);
      border-bottom-left-radius: 8px;
      border-bottom-right-radius: 8px;
      color: var(--text);
      font-size: 1rem;
      line-height: 1.6;
      outline: none;
    }
    .editor:focus {
      border-color: var(--primary);
    }
    .editor blockquote {
      border-left: 3px solid var(--primary);
      padding-left: 12px;
      margin: 8px 0;
      color: var(--text-muted);
      font-style: italic;
    }
    .editor ul, .editor ol {
      padding-left: 24px;
      margin: 8px 0;
    }
    .footer {
      padding: 16px 24px;
      border-top: 1px solid var(--border);
      display: flex;
      align-items: center;
      justify-content: space-between;
      background: #18181a;
    }
    .footer-hints {
      font-size: 0.8rem;
      color: var(--text-muted);
    }
    .footer-actions {
      display: flex;
      gap: 12px;
    }
    .btn {
      padding: 10px 20px;
      border-radius: 8px;
      font-size: 0.95rem;
      font-weight: 600;
      cursor: pointer;
      transition: all 0.2s;
      border: none;
      outline: none;
    }
    .btn-primary {
      background: var(--primary);
      color: #000;
    }
    .btn-primary:hover {
      background: var(--primary-hover);
      box-shadow: 0 4px 14px rgba(255, 136, 0, 0.4);
    }
    .btn-secondary {
      background: #2a2a2c;
      color: var(--text-muted);
      border: 1px solid var(--border);
    }
    .btn-secondary:hover {
      background: #36363a;
      color: var(--text);
    }
    .status-toast {
      display: none;
      padding: 12px 16px;
      border-radius: 8px;
      font-size: 0.9rem;
      font-weight: 500;
      margin-bottom: 12px;
    }
    .status-toast.error {
      background: rgba(255, 69, 58, 0.15);
      border: 1px solid var(--error);
      color: var(--error);
      display: block;
    }
    .status-toast.success {
      background: rgba(48, 209, 88, 0.15);
      border: 1px solid var(--success);
      color: var(--success);
      display: block;
    }
  </style>
</head>
<body>

  <div class="composer-container">
    <div class="header">
      <div class="logo">
        <span>Pala</span>
        <span class="logo-badge">Kréta Üzenetküldő</span>
      </div>
      <div style="font-size: 0.85rem; color: var(--text-muted);">
        Feladó: <strong style="color: var(--text);">$safeStudentName</strong>
      </div>
    </div>

    <div class="form-body">
      <div id="statusToast" class="status-toast"></div>

      <div class="form-group">
        <label for="recipientSelect">Címzett tanár(ok)</label>
        <select id="recipientSelect" multiple size="4">
          $teachersOptions
        </select>
        <span style="font-size: 0.75rem; color: var(--text-muted);">Tartsd nyomva a Ctrl (vagy Cmd) billentyűt több tanár kijelöléséhez.</span>
      </div>

      <div class="form-group">
        <label for="subjectInput">Üzenet tárgya</label>
        <input type="text" id="subjectInput" placeholder="pl. Kérdés a tegnapi matematika témazáró dolgozatról" value="$safeSubject" autofocus />
      </div>

      <div class="templates-bar">
        <span style="font-size: 0.8rem; color: var(--text-muted);">Gyors sablonok:</span>
        <button type="button" class="template-btn" onclick="applyTemplate('igazolas')">Mulasztás igazolás</button>
        <button type="button" class="template-btn" onclick="applyTemplate('javitas')">Dolgozat javítás</button>
        <button type="button" class="template-btn" onclick="applyTemplate('konzultacio')">Fogadóóra / Konzultáció</button>
        <button type="button" class="template-btn" onclick="applyTemplate('hazifeladat')">Házi feladat kérdés</button>
      </div>

      <div class="editor-wrapper">
        <label>Üzenet szövege</label>
        <div class="toolbar">
          <button type="button" class="tool-btn" onclick="format('bold')" title="Félkövér (Ctrl+B)"><b>B</b></button>
          <button type="button" class="tool-btn" onclick="format('italic')" title="Dőlt (Ctrl+I)"><i>I</i></button>
          <button type="button" class="tool-btn" onclick="format('underline')" title="Aláhúzott (Ctrl+U)"><u>U</u></button>
          <button type="button" class="tool-btn" onclick="format('strikeThrough')" title="Áthúzott"><s>S</s></button>
          <div class="tool-separator"></div>
          <button type="button" class="tool-btn" onclick="format('insertUnorderedList')" title="Felsorolás">• Lista</button>
          <button type="button" class="tool-btn" onclick="format('insertOrderedList')" title="Számozott lista">1. Lista</button>
          <button type="button" class="tool-btn" onclick="formatBlock('blockquote')" title="Idézet">Idézet</button>
          <div class="tool-separator"></div>
          <button type="button" class="tool-btn" onclick="insertGreeting()" title="Megszólítás">Megszólítás</button>
          <button type="button" class="tool-btn" onclick="insertClosing()" title="Elköszönés">Elköszönés</button>
        </div>
        <div id="editor" class="editor" contenteditable="true" placeholder="Ide írd a tanárnak szánt üzenetet..."></div>
      </div>
    </div>

    <div class="footer">
      <div class="footer-hints">
        Tipp: <strong>Ctrl + Enter</strong> a küldéshez, <strong>Esc</strong> a bezáráshoz
      </div>
      <div class="footer-actions">
        <button type="button" class="btn btn-secondary" onclick="cancelComposer()">Mégse</button>
        <button type="button" class="btn btn-primary" onclick="sendMessage()">Üzenet küldése</button>
      </div>
    </div>
  </div>

  <script>
    const studentName = "$safeStudentName";
    const sessionToken = "$safeSessionToken";

    function format(cmd, val = null) {
      document.execCommand(cmd, false, val);
      document.getElementById('editor').focus();
    }

    function formatBlock(tag) {
      document.execCommand('formatBlock', false, tag);
      document.getElementById('editor').focus();
    }

    function insertGreeting() {
      const editor = document.getElementById('editor');
      editor.focus();
      document.execCommand('insertHTML', false, '<p>Tisztelt Tanárnő / Tanár Úr!</p><p><br></p>');
    }

    function insertClosing() {
      const editor = document.getElementById('editor');
      editor.focus();
      document.execCommand('insertHTML', false, '<p><br></p><p>Tisztelettel és köszönettel:<br>' + (studentName || 'Diák') + '</p>');
    }

    function applyTemplate(type) {
      const subjectInput = document.getElementById('subjectInput');
      const editor = document.getElementById('editor');
      
      if (type === 'igazolas') {
        subjectInput.value = 'Mulasztás és hiányzás igazolása';
        editor.innerHTML = '<p>Tisztelt Tanárnő / Tanár Úr!</p><p>Ezúton szeretném igazolni az elmúlt időszakban történt hiányzásomat orvosi igazolás alapján.</p><p><br></p><p>Tisztelettel és köszönettel:<br>' + (studentName || 'Diák') + '</p>';
      } else if (type === 'javitas') {
        subjectInput.value = 'Érdeklődés dolgozatjavítási lehetőségről';
        editor.innerHTML = '<p>Tisztelt Tanár Úr / Tanárnő!</p><p>Szeretnék érdeklődni, hogy van-e lehetőség a legutóbbi dolgozat javítására vagy szóbeli feleletre az átlagom javítása érdekében.</p><p><br></p><p>Tisztelettel:<br>' + (studentName || 'Diák') + '</p>';
      } else if (type === 'konzultacio') {
        subjectInput.value = 'Konzultáció / Egyéni megbeszélés egyeztetése';
        editor.innerHTML = '<p>Tisztelt Tanár Úr / Tanárnő!</p><p>Szeretnék időpontot kérni egy rövid személyes konzultációra a tananyaggal kapcsolatos kérdéseim tisztázása céljából.</p><p><br></p><p>Tisztelettel:<br>' + (studentName || 'Diák') + '</p>';
      } else if (type === 'hazifeladat') {
        subjectInput.value = 'Kérdés a feladott házi feladattal kapcsolatban';
        editor.innerHTML = '<p>Tisztelt Tanárnő / Tanár Úr!</p><p>A legutóbbi órán feladott feladat kapcsán felmerült bennem egy kérdés, amiben a segítségét szeretném kérni:</p><p><br></p><p>Köszönettel:<br>' + (studentName || 'Diák') + '</p>';
      }
      editor.focus();
    }

    async function sendMessage() {
      const subject = document.getElementById('subjectInput').value.trim();
      const editor = document.getElementById('editor');
      const text = editor.innerText.trim();
      const html = editor.innerHTML.trim();
      const select = document.getElementById('recipientSelect');
      const toast = document.getElementById('statusToast');

      const recipientIds = Array.from(select.selectedOptions).map(opt => opt.value);

      if (recipientIds.length === 0) {
        toast.className = 'status-toast error';
        toast.innerText = 'Kérlek válassz legalább egy címzett tanárt!';
        select.focus();
        return;
      }

      if (!subject) {
        toast.className = 'status-toast error';
        toast.innerText = 'Kérlek adj meg egy üzenet tárgyat!';
        document.getElementById('subjectInput').focus();
        return;
      }

      if (!text) {
        toast.className = 'status-toast error';
        toast.innerText = 'Az üzenet szövege nem lehet üres!';
        editor.focus();
        return;
      }

      toast.className = 'status-toast success';
      toast.innerText = 'Üzenet küldése folyamatban...';

      try {
        const response = await fetch('/api/send', {
          method: 'POST',
          headers: { 
            'Content-Type': 'application/json',
            'X-Pala-Token': sessionToken
          },
          body: JSON.stringify({
            subject: subject,
            text: html.length > 0 ? html : text,
            recipientIds: recipientIds,
            attachments: []
          })
        });

        if (response.ok) {
          toast.className = 'status-toast success';
          toast.innerHTML = '[OK] <strong>Üzenet sikeresen elküldve!</strong> Ez az ablak most bezárható.';
          setTimeout(() => window.close(), 1200);
        } else {
          const err = await response.json();
          toast.className = 'status-toast error';
          toast.innerText = 'Hiba a küldés során: ' + (err.error || 'Ismeretlen hiba');
        }
      } catch (e) {
        toast.className = 'status-toast error';
        toast.innerText = 'Hálózati hiba: ' + e.message;
      }
    }

    async function cancelComposer() {
      try {
        await fetch('/api/cancel', { 
          method: 'POST',
          headers: { 'X-Pala-Token': sessionToken }
        });
      } catch (_) {}
      window.close();
    }

    document.addEventListener('keydown', (e) => {
      if ((e.ctrlKey || e.metaKey) && e.key === 'Enter') {
        sendMessage();
      } else if (e.key === 'Escape') {
        cancelComposer();
      }
    });
  </script>
</body>
</html>''';
  }
}

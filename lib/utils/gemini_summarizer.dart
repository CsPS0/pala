import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:pala/utils/logger.dart';

/// Turns the alerts of one daemon run into a short Hungarian summary with the
/// Gemini API.
///
/// The API key is a secret, so it is read from `PALA_GEMINI_API_KEY` or from
/// the owner-only `gemini_key` file in the config directory, never from argv.
/// The summary is optional: when the key is missing or the call fails,
/// [summarize] returns null and the plain alerts still go out.
///
/// Privacy: the prompt only holds the alert lines (subject names, grade
/// values, dates, Moodle course titles). No student name, class or school id
/// is added. Free-tier content may be used by Google to improve its products,
/// so keep the alert lines free of personal data.
class GeminiSummarizer {
  static const defaultModel = 'gemini-2.5-flash';
  static const _host = 'generativelanguage.googleapis.com';
  static const _timeout = Duration(seconds: 20);
  static const _maxInputChars = 4000;

  final String? apiKey;
  final String model;
  final http.Client _client;

  GeminiSummarizer(this.apiKey, {String? model, http.Client? client})
      : model = (model == null || model.isEmpty) ? defaultModel : model,
        _client = client ?? http.Client();

  factory GeminiSummarizer.fromConfig(String configDir, {http.Client? client}) {
    final model = Platform.environment['PALA_GEMINI_MODEL']?.trim();
    final fromEnv = Platform.environment['PALA_GEMINI_API_KEY']?.trim();
    if (fromEnv != null && fromEnv.isNotEmpty) {
      return GeminiSummarizer(fromEnv, model: model, client: client);
    }
    final file = File('$configDir/gemini_key');
    if (file.existsSync()) {
      final value = file.readAsStringSync().trim();
      if (value.isNotEmpty) {
        return GeminiSummarizer(value, model: model, client: client);
      }
    }
    return GeminiSummarizer(null, model: model, client: client);
  }

  bool get isEnabled => apiKey != null && apiKey!.isNotEmpty;

  /// The model name ends up in the URL path, so only the characters a model
  /// id uses are allowed.
  static bool isValidModel(String model) =>
      RegExp(r'^[a-zA-Z0-9._-]+$').hasMatch(model);

  static const instruction =
      'Te egy diákasszisztens vagy. Az alábbi sorok új iskolai értesítések '
      '(Kréta és Moodle). Írj magyarul 2-4 rövid mondatos összefoglalót. '
      'Emeld ki a legsürgősebb határidőt vagy dolgozatot, és adj egy '
      'konkrét teendőt. Ne találj ki adatot, csak a megadott sorokból '
      'dolgozz. Ne használj emojit és formázást.';

  static Map<String, dynamic> buildRequest(List<String> alerts) {
    var text = alerts.join('\n');
    if (text.length > _maxInputChars) {
      text = text.substring(0, _maxInputChars);
    }
    return {
      'systemInstruction': {
        'parts': [
          {'text': instruction}
        ]
      },
      'contents': [
        {
          'role': 'user',
          'parts': [
            {'text': text}
          ]
        }
      ],
      'generationConfig': {'temperature': 0.3, 'maxOutputTokens': 300},
    };
  }

  /// Pulls the generated text out of a `generateContent` response.
  static String? parseResponse(String body) {
    try {
      final data = jsonDecode(body);
      final parts = data['candidates']?[0]?['content']?['parts'];
      if (parts is! List) return null;
      final text = parts
          .map((p) => p is Map ? (p['text'] ?? '').toString() : '')
          .join()
          .trim();
      return text.isEmpty ? null : text;
    } catch (_) {
      return null;
    }
  }

  Future<String?> summarize(List<String> alerts) async {
    if (!isEnabled || alerts.isEmpty || !isValidModel(model)) return null;
    final uri = Uri.https(_host, '/v1beta/models/$model:generateContent');
    try {
      final response = await _client
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'x-goog-api-key': apiKey!,
            },
            body: jsonEncode(buildRequest(alerts)),
          )
          .timeout(_timeout);
      if (response.statusCode != 200) {
        PalaLogger.debug('Gemini: HTTP ${response.statusCode}');
        return null;
      }
      return parseResponse(response.body);
    } catch (e) {
      // The key travels in a header, never in the URL, so the error text is
      // safe to log.
      PalaLogger.debug('Gemini: $e');
      return null;
    }
  }
}

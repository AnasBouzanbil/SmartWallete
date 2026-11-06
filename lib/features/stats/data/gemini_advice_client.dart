import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import 'advice_payload.dart';
import 'stats_repository.dart';

class AdviceResult {
  const AdviceResult.ok(this.text) : error = null;

  const AdviceResult.fail(this.error) : text = null;

  final String? text;
  final String? error;

  bool get isOk => text != null && text!.trim().isNotEmpty;
}

class GeminiAdviceClient {
  GeminiAdviceClient({http.Client? httpClient})
      : _http = httpClient ?? http.Client();

  static const String _model = 'gemini-flash-latest';
  static final Uri _uri = Uri.parse(
    'https://generativelanguage.googleapis.com/v1beta/models/'
    '$_model:generateContent',
  );

  final http.Client _http;

  String? get _apiKey {
    if (!dotenv.isInitialized) {
      return null;
    }
    final String? key = dotenv.maybeGet('GEMINI_API_KEY');
    if (key == null || key.trim().isEmpty) {
      return null;
    }
    return key.trim();
  }

  Future<AdviceResult> advise(StatsSummary summary) async {
    final String? apiKey = _apiKey;
    if (apiKey == null) {
      return const AdviceResult.fail(
        'AI is not configured. Add GEMINI_API_KEY to your .env file.',
      );
    }

    final String prompt = buildAdvicePrompt(summary);

    try {
      final http.Response response = await _http.post(
        _uri,
        headers: <String, String>{
          'Content-Type': 'application/json',
          'X-goog-api-key': apiKey,
        },
        body: jsonEncode(<String, dynamic>{
          'contents': <Map<String, dynamic>>[
            <String, dynamic>{
              'parts': <Map<String, String>>[
                <String, String>{'text': prompt},
              ],
            },
          ],
        }),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return AdviceResult.fail(
          'Could not get advice right now (${response.statusCode}).',
        );
      }

      final Object? decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        return const AdviceResult.fail('Unexpected AI response.');
      }

      final String? text = _extractText(decoded);
      if (text == null || text.trim().isEmpty) {
        return const AdviceResult.fail('AI returned an empty tip.');
      }
      return AdviceResult.ok(text.trim());
    } catch (_) {
      return const AdviceResult.fail(
        'Could not reach AI. Check your connection and try again.',
      );
    }
  }

  static String? _extractText(Map<String, dynamic> json) {
    final Object? candidates = json['candidates'];
    if (candidates is! List<dynamic> || candidates.isEmpty) {
      return null;
    }
    final Object? first = candidates.first;
    if (first is! Map<String, dynamic>) {
      return null;
    }
    final Object? content = first['content'];
    if (content is! Map<String, dynamic>) {
      return null;
    }
    final Object? parts = content['parts'];
    if (parts is! List<dynamic> || parts.isEmpty) {
      return null;
    }
    final Object? part = parts.first;
    if (part is! Map<String, dynamic>) {
      return null;
    }
    final Object? text = part['text'];
    return text is String ? text : null;
  }
}

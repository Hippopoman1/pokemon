// lib/gemini_client.dart
import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;

/// Gemini REST (non-stream) – Google AI Studio API v1 + retry/backoff
class GeminiClient {
  final String apiKey;
  final String model;
  final int maxRetries;
  final Duration timeout;

  GeminiClient({
    required this.apiKey,
    this.model = 'gemini-2.5-flash',
    this.maxRetries = 4, // รวมครั้งแรก → ยิงได้สูงสุด 4 ครั้ง
    this.timeout = const Duration(seconds: 20),
  });

  Uri _endpoint(String m) => Uri.parse(
    'https://generativelanguage.googleapis.com/v1/models/$m:generateContent',
  );

  Future<String> chat(
    String prompt, {
    List<Map<String, String>> history = const [],
  }) async {
    final contents = <Map<String, dynamic>>[
      for (final h in history)
        {
          'role': h['role'] == 'model' ? 'model' : 'user',
          'parts': [{'text': h['text'] ?? ''}],
        },
      {'role': 'user', 'parts': [{'text': prompt}]},
    ];

    final candidates = <String>{
      model,                 // gemini-2.5-flash
      '$model-001',
      '$model-latest',
    }.toList();

    Exception? lastErr;
    for (final m in candidates) {
      try {
        final text = await _postWithRetry(
          endpoint: _endpoint(m).replace(queryParameters: {'key': apiKey}),
          body: {
            'contents': contents,
            'generationConfig': {'temperature': 0.7, 'maxOutputTokens': 1024},
          },
        );
        return text;
      } catch (e) {
        lastErr = e is Exception ? e : Exception(e.toString());
      }
    }
    throw lastErr ?? Exception('Gemini request failed (unknown error)');
  }

  Future<String> _postWithRetry({
    required Uri endpoint,
    required Map<String, dynamic> body,
  }) async {
    final rand = Random();
    int attempt = 0;

    while (true) {
      attempt++;

      try {
        final res = await http
            .post(
              endpoint,
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode(body),
            )
            .timeout(timeout);

        // 404: รุ่นไม่เจอ → โยนให้ caller ไปลองรุ่นถัดไป
        if (res.statusCode == 404) {
          throw Exception('404: ${res.body}');
        }

        // 2xx → parse แล้วคืน
        if (res.statusCode >= 200 && res.statusCode < 300) {
          final data = jsonDecode(res.body) as Map<String, dynamic>;
          final cands = (data['candidates'] as List?) ?? const [];
          if (cands.isEmpty) return '';
          final content = (cands[0]['content'] as Map?) ?? {};
          final parts = (content['parts'] as List?) ?? const [];
          final buf = StringBuffer();
          for (final p in parts) {
            buf.write(((p as Map?)?['text'] ?? '').toString());
          }
          return buf.toString().trim();
        }

        // 429/5xx → เข้าสายรีทราย
        if (_isRetryableStatus(res.statusCode)) {
          if (attempt >= maxRetries) {
            throw Exception('Gemini HTTP ${res.statusCode}: ${res.body}');
          }
          final backoff = _backoff(attempt, rand);
          await Future.delayed(backoff);
          continue;
        }

        // อื่นๆ โยนทันที
        throw Exception('Gemini HTTP ${res.statusCode}: ${res.body}');
      } catch (e) {
        // timeout / เครือข่าย → รีทรายถ้าเหลือสิทธิ์
        if (attempt >= maxRetries) rethrow;
        final backoff = _backoff(attempt, rand);
        await Future.delayed(backoff);
      }
    }
  }

  bool _isRetryableStatus(int s) =>
      s == 429 || s == 500 || s == 502 || s == 503 || s == 504;

  Duration _backoff(int attempt, Random rand) {
    // exponential backoff with jitter: 0.5s, 1s, 2s, 4s (+/-20%)
    final baseMs = 500 * (1 << (attempt - 1)); // 500,1000,2000,4000
    final jitter = (baseMs * 0.2).round();     // ±20%
    final delta = rand.nextInt(jitter * 2 + 1) - jitter;
    return Duration(milliseconds: baseMs + delta);
  }
}

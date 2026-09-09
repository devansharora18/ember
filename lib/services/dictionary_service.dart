import 'dart:convert';
import 'package:http/http.dart' as http;

class DictionaryService {
  static Future<String?> lookup(String word) async {
    try {
      final clean = word.replaceAll(RegExp(r'[^\w\s]'), '').trim().toLowerCase();
      if (clean.isEmpty) return null;

      final uri = Uri.parse('https://freedictionaryapi.com/api/v1/entries/en/$clean');
      final response = await http.get(uri).timeout(const Duration(seconds: 5));

      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final entries = data['entries'] as List<dynamic>;
      if (entries.isEmpty) return null;

      // Prefer the first entry that has a definition. Fall back to the first sense
      // of the first entry otherwise.
      final buf = StringBuffer();
      for (final entry in entries) {
        final e = entry as Map<String, dynamic>;
        final pos = (e['partOfSpeech'] as String? ?? '').trim();
        final senses = e['senses'] as List<dynamic>? ?? [];
        String? definition;
        for (final sense in senses) {
          definition = (sense as Map<String, dynamic>)['definition'] as String?;
          if (definition != null && definition.isNotEmpty) break;
        }
        if (definition == null || definition.isEmpty) continue;

        buf.writeln('${pos.isNotEmpty ? '($pos) ' : ''}$definition');
        break; // just first definition
      }

      final result = buf.toString().trim();
      return result.isEmpty ? null : result;
    } catch (_) {
      return null;
    }
  }
}
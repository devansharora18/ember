import 'dart:convert';
import 'package:http/http.dart' as http;

class DictionaryService {
  static Future<String?> lookup(String word) async {
    try {
      final clean = word.replaceAll(RegExp(r'[^\w\s]'), '').trim().toLowerCase();
      if (clean.isEmpty) return null;

      final uri = Uri.parse('https://api.dictionaryapi.dev/api/v2/entries/en/$clean');
      final response = await http.get(uri).timeout(const Duration(seconds: 5));

      if (response.statusCode != 200) return null;

      final List<dynamic> data = jsonDecode(response.body);
      if (data.isEmpty) return null;

      final entry = data[0] as Map<String, dynamic>;
      final meanings = entry['meanings'] as List<dynamic>;
      if (meanings.isEmpty) return null;

      final buf = StringBuffer();
      for (final meaning in meanings) {
        final m = meaning as Map<String, dynamic>;
        final pos = m['partOfSpeech'] as String? ?? '';
        final definitions = m['definitions'] as List<dynamic>;
        if (definitions.isEmpty) continue;

        buf.writeln('${pos.isNotEmpty ? '($pos) ' : ''}${definitions[0]['definition']}');
        break; // just first definition
      }

      return buf.toString().trim();
    } catch (_) {
      return null;
    }
  }
}

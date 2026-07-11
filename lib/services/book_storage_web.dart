import 'dart:convert';
import 'dart:typed_data';
import 'package:universal_html/html.dart' as html;
import '../models/book.dart';

class BookStorage {
  static String _key(String k) => 'ember_$k';

  static String _coverFileName(String filePath) {
    final bytes = utf8.encode(filePath);
    return base64Url.encode(bytes).replaceAll('=', '');
  }

  static Future<({List<Book> books, int columns})> loadAll() async {
    try {
      final raw = html.window.localStorage[_key('books')];
      if (raw == null) return (books: <Book>[], columns: 3);
      final data = jsonDecode(raw) as Map<String, dynamic>;
      final jsonList = data['books'] as List? ?? [];
      final columns = data['columns'] as int? ?? 3;
      final books = <Book>[];
      for (final map in jsonList) {
        final b = map as Map<String, dynamic>;
        Uint8List? coverBytes;
        final coverKey = b['coverKey'] as String?;
        if (coverKey != null) {
          final coverRaw = html.window.localStorage[_key('cover_$coverKey')];
          if (coverRaw != null) {
            coverBytes = base64Decode(coverRaw);
          }
        }
        Uint8List? fileBytes;
        final fileKey = b['fileKey'] as String?;
        if (fileKey != null) {
          final fileRaw = html.window.localStorage[_key('file_$fileKey')];
          if (fileRaw != null) {
            fileBytes = base64Decode(fileRaw);
          }
        }
        books.add(Book(
          title: b['title'] as String,
          author: b['author'] as String,
          filePath: b['filePath'] as String,
          coverBytes: coverBytes,
          fileBytes: fileBytes,
          progress: (b['progress'] as num?)?.toDouble() ?? 0.0,
          lastOpened: b['lastOpened'] != null ? DateTime.tryParse(b['lastOpened'] as String) : null,
        ));
      }
      return (books: books, columns: columns);
    } catch (_) {
      return (books: <Book>[], columns: 3);
    }
  }

  static Future<void> saveAll(List<Book> books, int columns) async {
    try {
      final jsonList = <Map<String, dynamic>>[];
      for (final book in books) {
        final coverKey = book.coverBytes != null ? _coverFileName(book.filePath) : null;
        final fileKey = book.fileBytes != null ? _coverFileName(book.filePath) : null;
        jsonList.add({
          'title': book.title,
          'author': book.author,
          'filePath': book.filePath,
          'coverKey': coverKey,
          'fileKey': fileKey,
          'progress': book.progress,
          if (book.lastOpened != null) 'lastOpened': book.lastOpened!.toIso8601String(),
        });
      }
      html.window.localStorage[_key('books')] = jsonEncode({'books': jsonList, 'columns': columns});
    } catch (_) {}
    for (final book in books) {
      try {
        if (book.coverBytes != null) {
          html.window.localStorage[_key('cover_${_coverFileName(book.filePath)}')] = base64Encode(book.coverBytes!);
        }
      } catch (_) {}
      try {
        if (book.fileBytes != null) {
          html.window.localStorage[_key('file_${_coverFileName(book.filePath)}')] = base64Encode(book.fileBytes!);
        }
      } catch (_) {}
    }
  }

  static Future<String> storeBookFile(String sourcePath) async {
    return sourcePath;
  }

  static Future<String> storeBookBytes(String fileName, Uint8List bytes) async {
    try {
      final key = _coverFileName(fileName);
      html.window.localStorage[_key('file_$key')] = base64Encode(bytes);
    } catch (_) {}
    return fileName;
  }

  static Future<void> savePosition(String filePath, int position) async {
    try { html.window.localStorage[_key('pos_${_coverFileName(filePath)}')] = position.toString(); } catch (_) {}
  }

  static Future<int> loadPosition(String filePath) async {
    try { return int.tryParse(html.window.localStorage[_key('pos_${_coverFileName(filePath)}')] ?? '0') ?? 0; } catch (_) { return 0; }
  }

  static Future<void> saveFontSize(String filePath, double fontSize) async {
    try { html.window.localStorage[_key('fontsize')] = fontSize.toString(); } catch (_) {}
  }

  static Future<double?> loadFontSize(String filePath) async {
    try { final v = html.window.localStorage[_key('fontsize')]; return v != null ? double.tryParse(v) : null; } catch (_) { return null; }
  }

  static Future<void> saveFontFamily(String filePath, String family) async {
    try { html.window.localStorage[_key('fontfamily')] = family; } catch (_) {}
  }

  static Future<String?> loadFontFamily(String filePath) async {
    try { return html.window.localStorage[_key('fontfamily')]; } catch (_) { return null; }
  }

  static Future<void> saveDarkMode(String filePath, bool darkMode) async {
    try { html.window.localStorage[_key('darkmode')] = darkMode.toString(); } catch (_) {}
  }

  static Future<bool?> loadDarkMode(String filePath) async {
    try { final v = html.window.localStorage[_key('darkmode')]; return v != null ? v == 'true' : null; } catch (_) { return null; }
  }

  static Future<void> saveRsvpWpm(int wpm) async {
    try { html.window.localStorage[_key('rsvpwpm')] = wpm.toString(); } catch (_) {}
  }

  static Future<int?> loadRsvpWpm() async {
    try { final v = html.window.localStorage[_key('rsvpwpm')]; return v != null ? int.tryParse(v) : null; } catch (_) { return null; }
  }

  static Future<List<int>> loadBookmarks(String filePath) async {
    try { final raw = html.window.localStorage[_key('bm_${_coverFileName(filePath)}')]; if (raw == null) return []; return (jsonDecode(raw) as List).map((e) => (e as num).toInt()).toList(); } catch (_) { return []; }
  }

  static Future<void> saveBookmarks(String filePath, List<int> bookmarks) async {
    try { html.window.localStorage[_key('bm_${_coverFileName(filePath)}')] = jsonEncode(bookmarks); } catch (_) {}
  }

  static Future<List<Map<String, int>>> loadHighlights(String filePath) async {
    try { final raw = html.window.localStorage[_key('hl_${_coverFileName(filePath)}')]; if (raw == null) return []; return (jsonDecode(raw) as List).map((e) => Map<String, int>.from(e as Map)).toList(); } catch (_) { return []; }
  }

  static Future<void> saveHighlights(String filePath, List<Map<String, int>> highlights) async {
    try { html.window.localStorage[_key('hl_${_coverFileName(filePath)}')] = jsonEncode(highlights); } catch (_) {}
  }
}

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import '../models/book.dart';

class BookStorage {
  static Future<Directory> _dir() async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory('${base.path}/ember');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  static String _coverFileName(String filePath) {
    final bytes = utf8.encode(filePath);
    return base64Url.encode(bytes).replaceAll('=', '');
  }

  static Future<({List<Book> books, int columns})> loadAll() async {
    try {
      final dir = await _dir();
      final file = File('${dir.path}/books.json');
      if (!await file.exists()) return (books: <Book>[], columns: 3);
      final raw = jsonDecode(await file.readAsString());
      final List jsonList;
      final int columns;
      if (raw is List) {
        jsonList = raw;
        columns = 3;
      } else {
        final data = raw as Map<String, dynamic>;
        jsonList = data['books'] as List? ?? [];
        columns = data['columns'] as int? ?? 3;
      }
      final books = <Book>[];
      for (final map in jsonList) {
        final b = map as Map<String, dynamic>;
        final coverKey = b['coverKey'] as String?;
        Uint8List? coverBytes;
        if (coverKey != null) {
          final coverFile = File('${dir.path}/covers/$coverKey');
          if (await coverFile.exists()) {
            coverBytes = await coverFile.readAsBytes();
          }
        }
        books.add(Book(
          title: b['title'] as String,
          author: b['author'] as String,
          filePath: b['filePath'] as String,
          coverBytes: coverBytes,
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
    final dir = await _dir();
    final coversDir = Directory('${dir.path}/covers');
    if (!await coversDir.exists()) await coversDir.create(recursive: true);

    final jsonList = <Map<String, dynamic>>[];
    for (final book in books) {
      String? coverKey;
      if (book.coverBytes != null) {
        coverKey = _coverFileName(book.filePath);
        final coverFile = File('${coversDir.path}/$coverKey');
        if (!await coverFile.exists()) {
          await coverFile.writeAsBytes(book.coverBytes!);
        }
      }
      jsonList.add({
        'title': book.title,
        'author': book.author,
        'filePath': book.filePath,
        'coverKey': coverKey,
        'progress': book.progress,
        if (book.lastOpened != null) 'lastOpened': book.lastOpened!.toIso8601String(),
      });
    }
    final file = File('${dir.path}/books.json');
    await file.writeAsString(jsonEncode({
      'books': jsonList,
      'columns': columns,
    }));
  }

  static Future<void> savePosition(String filePath, int position) async {
    try {
      final dir = await _dir();
      final positionsDir = Directory('${dir.path}/positions');
      if (!await positionsDir.exists()) await positionsDir.create(recursive: true);
      final key = _coverFileName(filePath);
      final file = File('${positionsDir.path}/$key');
      await file.writeAsString(position.toString());
    } catch (_) {}
  }

  static Future<int> loadPosition(String filePath) async {
    try { final dir = await _dir(); final key = _coverFileName(filePath); final file = File('${dir.path}/positions/$key'); if (!await file.exists()) return 0; return int.tryParse(await file.readAsString()) ?? 0; } catch (_) { return 0; }
  }

  static Future<void> saveFontSize(String filePath, double fontSize) async {
    try { final dir = await _dir(); final file = File('${dir.path}/settings_fontsize'); await file.writeAsString(fontSize.toString()); } catch (_) {}
  }

  static Future<double?> loadFontSize(String filePath) async {
    try { final dir = await _dir(); final file = File('${dir.path}/settings_fontsize'); if (!await file.exists()) return null; return double.tryParse(await file.readAsString()); } catch (_) { return null; }
  }

  static Future<void> saveFontFamily(String filePath, String family) async {
    try { final dir = await _dir(); final file = File('${dir.path}/settings_fontfamily'); await file.writeAsString(family); } catch (_) {}
  }

  static Future<String?> loadFontFamily(String filePath) async {
    try { final dir = await _dir(); final file = File('${dir.path}/settings_fontfamily'); if (!await file.exists()) return null; return await file.readAsString(); } catch (_) { return null; }
  }

  static Future<void> saveDarkMode(String filePath, bool darkMode) async {
    try { final dir = await _dir(); final file = File('${dir.path}/settings_darkmode'); await file.writeAsString(darkMode.toString()); } catch (_) {}
  }

  static Future<bool?> loadDarkMode(String filePath) async {
    try { final dir = await _dir(); final file = File('${dir.path}/settings_darkmode'); if (!await file.exists()) return null; return await file.readAsString() == 'true'; } catch (_) { return null; }
  }

  static Future<void> saveRsvpWpm(int wpm) async {
    try { final dir = await _dir(); final file = File('${dir.path}/settings_rsvp_wpm'); await file.writeAsString(wpm.toString()); } catch (_) {}
  }

  static Future<int?> loadRsvpWpm() async {
    try { final dir = await _dir(); final file = File('${dir.path}/settings_rsvp_wpm'); if (!await file.exists()) return null; return int.tryParse(await file.readAsString()); } catch (_) { return null; }
  }

  static Future<List<int>> loadBookmarks(String filePath) async {
    try { final dir = await _dir(); final key = _coverFileName(filePath); final file = File('${dir.path}/bookmarks/$key'); if (!await file.exists()) return []; final raw = jsonDecode(await file.readAsString()) as List; return raw.map((e) => (e as num).toInt()).toList(); } catch (_) { return []; }
  }

  static Future<void> saveBookmarks(String filePath, List<int> bookmarks) async {
    try { final dir = await _dir(); final bmDir = Directory('${dir.path}/bookmarks'); if (!await bmDir.exists()) await bmDir.create(recursive: true); final key = _coverFileName(filePath); final file = File('${bmDir.path}/$key'); await file.writeAsString(jsonEncode(bookmarks)); } catch (_) {}
  }
}

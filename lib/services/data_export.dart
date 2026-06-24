import 'dart:convert';
import 'dart:typed_data';
import 'book_storage.dart';
import '../models/book.dart';

class DataExport {
  static Future<({String json, int bookCount})> exportAll() async {
    final data = await BookStorage.loadAll();
    final books = <Map<String, dynamic>>[];

    for (final book in data.books) {
      final pos = await BookStorage.loadPosition(book.filePath);
      final bms = await BookStorage.loadBookmarks(book.filePath);
      final hls = await BookStorage.loadHighlights(book.filePath);

      books.add({
        'title': book.title,
        'author': book.author,
        'filePath': book.filePath,
        'progress': book.progress,
        if (book.lastOpened != null) 'lastOpened': book.lastOpened!.toIso8601String(),
        if (book.coverBytes != null) 'coverBytes': base64Encode(book.coverBytes!),
        if (book.fileBytes != null) 'fileBytes': base64Encode(book.fileBytes!),
        'position': pos,
        'bookmarks': bms,
        'highlights': hls.map((h) => {'s': h['s']!, 'e': h['e']!}).toList(),
      });
    }

    final fontSize = await BookStorage.loadFontSize('') ?? 18.0;
    final fontFamily = await BookStorage.loadFontFamily('') ?? 'Inter';
    final darkMode = await BookStorage.loadDarkMode('') ?? true;
    final rsvpWpm = await BookStorage.loadRsvpWpm() ?? 300;

    final json = jsonEncode({
      'version': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'columns': data.columns,
      'settings': {
        'fontSize': fontSize,
        'fontFamily': fontFamily,
        'darkMode': darkMode,
        'rsvpWpm': rsvpWpm,
      },
      'books': books,
    });

    return (json: json, bookCount: books.length);
  }

  static Future<({int books, bool success, List<Book> bookList, int columns})> importAll(String jsonString) async {
    try {
      final data = jsonDecode(jsonString) as Map<String, dynamic>;
      final version = data['version'] as int? ?? 1;
      if (version != 1) return (books: 0, success: false, bookList: <Book>[], columns: 3);

      final settings = data['settings'] as Map<String, dynamic>? ?? {};
      final jsonBooks = data['books'] as List? ?? [];
      final columns = data['columns'] as int? ?? 3;

      final loaded = await BookStorage.loadAll();
      final existingBooks = Map<String, Book>.fromIterable(
        loaded.books,
        key: (b) => (b as Book).filePath,
      );

      final books = <Book>[];
      for (final b in jsonBooks) {
        final map = b as Map<String, dynamic>;
        final filePath = map['filePath'] as String;

        Uint8List? coverBytes;
        final coverB64 = map['coverBytes'] as String?;
        if (coverB64 != null) {
          coverBytes = base64Decode(coverB64);
        }

        Uint8List? fileBytes;
        final fileB64 = map['fileBytes'] as String?;
        if (fileB64 != null) {
          fileBytes = base64Decode(fileB64);
        }

        final existing = existingBooks[filePath];

        books.add(Book(
          title: map['title'] as String? ?? existing?.title ?? 'Unknown',
          author: map['author'] as String? ?? existing?.author ?? '',
          filePath: filePath,
          coverBytes: coverBytes ?? existing?.coverBytes,
          fileBytes: fileBytes ?? existing?.fileBytes,
          progress: (map['progress'] as num?)?.toDouble() ?? existing?.progress ?? 0.0,
          lastOpened: map['lastOpened'] != null
              ? DateTime.tryParse(map['lastOpened'] as String)
              : existing?.lastOpened,
        ));
      }

      if (settings['fontSize'] != null) {
        BookStorage.saveFontSize('', (settings['fontSize'] as num).toDouble());
      }
      if (settings['fontFamily'] != null) {
        BookStorage.saveFontFamily('', settings['fontFamily'] as String);
      }
      if (settings['darkMode'] != null) {
        BookStorage.saveDarkMode('', settings['darkMode'] as bool);
      }
      if (settings['rsvpWpm'] != null) {
        BookStorage.saveRsvpWpm(settings['rsvpWpm'] as int);
      }

      for (var i = 0; i < books.length && i < jsonBooks.length; i++) {
        final map = jsonBooks[i] as Map<String, dynamic>;
        final filePath = map['filePath'] as String;
        if (map['position'] != null) {
          BookStorage.savePosition(filePath, map['position'] as int);
        }
        if (map['bookmarks'] != null) {
          final bms = (map['bookmarks'] as List).map((e) => (e as num).toInt()).toList();
          BookStorage.saveBookmarks(filePath, bms);
        }
        if (map['highlights'] != null) {
          final hls = (map['highlights'] as List)
              .map((e) => Map<String, int>.from(e as Map))
              .toList();
          BookStorage.saveHighlights(filePath, hls);
        }
      }

      return (books: books.length, success: true, bookList: List<Book>.from(books), columns: columns);
    } catch (_) {
      return (books: 0, success: false, bookList: <Book>[], columns: 3);
    }
  }

  static Future<int> clearAll() async {
    final loaded = await BookStorage.loadAll();
    final count = loaded.books.length;
    BookStorage.saveAll([], 3);
    return count;
  }
}

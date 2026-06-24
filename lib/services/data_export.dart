import 'dart:convert';
import 'dart:typed_data';
import 'package:archive/archive_io.dart';
import 'book_storage.dart';
import 'file_reader.dart';
import '../models/book.dart';

class DataExport {
  static Future<({Uint8List bytes, int bookCount})> exportAll() async {
    final data = await BookStorage.loadAll();
    final archive = Archive();

    final booksMeta = <Map<String, dynamic>>[];

    for (var i = 0; i < data.books.length; i++) {
      final book = data.books[i];
      final pos = await BookStorage.loadPosition(book.filePath);
      final bms = await BookStorage.loadBookmarks(book.filePath);
      final hls = await BookStorage.loadHighlights(book.filePath);

      Uint8List? epubBytes;
      if (book.fileBytes != null) {
        epubBytes = book.fileBytes;
      } else {
        try {
          epubBytes = await readFileAsBytes(book.filePath);
        } catch (_) {}
      }

      if (epubBytes != null) {
        final ext = book.filePath.toLowerCase().endsWith('.epub') ? '.epub' : '';
        archive.addFile(ArchiveFile('books/$i$ext', epubBytes.length, epubBytes));
      }

      if (book.coverBytes != null) {
        archive.addFile(ArchiveFile('covers/$i', book.coverBytes!.length, book.coverBytes!));
      }

      final fileName = book.filePath.split('/').last.split('\\').last;
      booksMeta.add({
        'title': book.title,
        'author': book.author,
        'fileName': fileName,
        'filePath': book.filePath,
        'progress': book.progress,
        if (book.lastOpened != null) 'lastOpened': book.lastOpened!.toIso8601String(),
        'hasCover': book.coverBytes != null,
        'hasEpub': epubBytes != null,
        'position': pos,
        'bookmarks': bms,
        'highlights': hls.map((h) => {'s': h['s']!, 'e': h['e']!}).toList(),
      });
    }

    final fontSize = await BookStorage.loadFontSize('') ?? 18.0;
    final fontFamily = await BookStorage.loadFontFamily('') ?? 'Inter';
    final darkMode = await BookStorage.loadDarkMode('') ?? true;
    final rsvpWpm = await BookStorage.loadRsvpWpm() ?? 300;

    final metaJson = jsonEncode({
      'version': 2,
      'exportedAt': DateTime.now().toIso8601String(),
      'columns': data.columns,
      'settings': {
        'fontSize': fontSize,
        'fontFamily': fontFamily,
        'darkMode': darkMode,
        'rsvpWpm': rsvpWpm,
      },
      'books': booksMeta,
    });

    final metaBytes = utf8.encode(metaJson);
    archive.addFile(ArchiveFile('metadata.json', metaBytes.length, metaBytes));

    final encoder = ZipEncoder();
    final zipBytes = encoder.encode(archive);

    return (bytes: Uint8List.fromList(zipBytes), bookCount: data.books.length);
  }

  static Future<({int books, bool success, List<Book> bookList, int columns})> importAll(Uint8List fileBytes) async {
    try {
      final decoder = ZipDecoder();
      final archive = decoder.decodeBytes(fileBytes);

      final metaFile = archive.findFile('metadata.json');
      if (metaFile == null) return (books: 0, success: false, bookList: <Book>[], columns: 3);

      final metaJson = utf8.decode(metaFile.content as List<int>);
      final data = jsonDecode(metaJson) as Map<String, dynamic>;
      final version = data['version'] as int? ?? 1;
      if (version < 1) return (books: 0, success: false, bookList: <Book>[], columns: 3);

      final settings = data['settings'] as Map<String, dynamic>? ?? {};
      final jsonBooks = data['books'] as List? ?? [];
      final columns = data['columns'] as int? ?? 3;

      final books = <Book>[];
      for (var i = 0; i < jsonBooks.length; i++) {
        final map = jsonBooks[i] as Map<String, dynamic>;
        final fileName = map['fileName'] as String? ?? map['filePath'] as String? ?? 'book_$i';

        Uint8List? coverBytes;
        final coverFile = archive.findFile('covers/$i');
        if (coverFile != null) {
          coverBytes = Uint8List.fromList(coverFile.content as List<int>);
        }

        Uint8List? epubBytes;
        final epubWithExt = archive.findFile('books/$i.epub');
        final epubNoExt = archive.findFile('books/$i');
        final epubFile = epubWithExt ?? epubNoExt;
        if (epubFile != null) {
          epubBytes = Uint8List.fromList(epubFile.content as List<int>);
        }

        final storedPath = epubBytes != null
            ? await BookStorage.storeBookBytes(fileName, epubBytes)
            : fileName;

        books.add(Book(
          title: map['title'] as String? ?? 'Unknown',
          author: map['author'] as String? ?? '',
          filePath: storedPath,
          coverBytes: coverBytes,
          fileBytes: epubBytes,
          progress: (map['progress'] as num?)?.toDouble() ?? 0.0,
          lastOpened: map['lastOpened'] != null
              ? DateTime.tryParse(map['lastOpened'] as String)
              : null,
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
        final filePath = books[i].filePath;
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

      return (books: books.length, success: true, bookList: books, columns: columns);
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

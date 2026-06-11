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
    try {
      final dir = await _dir();
      final key = _coverFileName(filePath);
      final file = File('${dir.path}/positions/$key');
      if (!await file.exists()) return 0;
      return int.tryParse(await file.readAsString()) ?? 0;
    } catch (_) {
      return 0;
    }
  }

  static Future<void> saveFontSize(String filePath, double fontSize) async {
    try {
      final dir = await _dir();
      final positionsDir = Directory('${dir.path}/positions');
      if (!await positionsDir.exists()) await positionsDir.create(recursive: true);
      final key = _coverFileName(filePath);
      final file = File('${positionsDir.path}/${key}_fontsize');
      await file.writeAsString(fontSize.toString());
    } catch (_) {}
  }

  static Future<double?> loadFontSize(String filePath) async {
    try {
      final dir = await _dir();
      final key = _coverFileName(filePath);
      final file = File('${dir.path}/positions/${key}_fontsize');
      if (!await file.exists()) return null;
      return double.tryParse(await file.readAsString());
    } catch (_) {
      return null;
    }
  }
}

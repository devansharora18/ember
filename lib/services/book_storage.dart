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

  static Future<List<Book>> loadBooks() async {
    try {
      final dir = await _dir();
      final file = File('${dir.path}/books.json');
      if (!await file.exists()) return [];
      final json = jsonDecode(await file.readAsString()) as List;
      final books = <Book>[];
      for (final map in json) {
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
      return books;
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveBooks(List<Book> books) async {
    final dir = await _dir();
    final coversDir = Directory('${dir.path}/covers');
    if (!await coversDir.exists()) await coversDir.create(recursive: true);

    final json = <Map<String, dynamic>>[];
    for (final book in books) {
      String? coverKey;
      if (book.coverBytes != null) {
        coverKey = _coverFileName(book.filePath);
        final coverFile = File('${coversDir.path}/$coverKey');
        if (!await coverFile.exists()) {
          await coverFile.writeAsBytes(book.coverBytes!);
        }
      }
      json.add({
        'title': book.title,
        'author': book.author,
        'filePath': book.filePath,
        'coverKey': coverKey,
      });
    }
    final file = File('${dir.path}/books.json');
    await file.writeAsString(jsonEncode(json));
  }
}

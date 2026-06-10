import 'dart:typed_data';

class Book {
  String title;
  String author;
  final String filePath;
  Uint8List? coverBytes;

  Book({
    required this.title,
    required this.author,
    required this.filePath,
    this.coverBytes,
  });
}

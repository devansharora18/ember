import 'dart:typed_data';

class Book {
  final String title;
  final String author;
  final String filePath;
  final Uint8List? coverBytes;

  const Book({
    required this.title,
    required this.author,
    required this.filePath,
    this.coverBytes,
  });

  Book copyWith({
    String? title,
    String? author,
    Uint8List? coverBytes,
  }) {
    return Book(
      title: title ?? this.title,
      author: author ?? this.author,
      filePath: filePath,
      coverBytes: coverBytes ?? this.coverBytes,
    );
  }
}

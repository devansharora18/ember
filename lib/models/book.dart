import 'dart:typed_data';

class Book {
  final String title;
  final String author;
  final String filePath;
  final Uint8List? coverBytes;
  double progress;
  DateTime? lastOpened;
  Uint8List? fileBytes;

  Book({
    required this.title,
    required this.author,
    required this.filePath,
    this.coverBytes,
    this.progress = 0.0,
    this.lastOpened,
    this.fileBytes,
  });

  Book copyWith({
    String? title,
    String? author,
    Uint8List? coverBytes,
    double? progress,
    DateTime? lastOpened,
  }) {
    return Book(
      title: title ?? this.title,
      author: author ?? this.author,
      filePath: filePath,
      coverBytes: coverBytes ?? this.coverBytes,
      progress: progress ?? this.progress,
      lastOpened: lastOpened ?? this.lastOpened,
      fileBytes: fileBytes,
    );
  }
}

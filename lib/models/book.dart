class Book {
  final String title;
  final String author;
  final String filePath;
  final String? coverPath;

  const Book({
    required this.title,
    required this.author,
    required this.filePath,
    this.coverPath,
  });
}

import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/book.dart';
import '../services/book_storage.dart';
import '../services/epub_parser.dart';

class BookListNotifier extends Notifier<List<Book>> {
  @override
  List<Book> build() {
    _load();
    return [];
  }

  Future<void> _load() async {
    try {
      final data = await BookStorage.loadAll();
      state = data.books;
      ref.read(columnsProvider.notifier).state = data.columns;
    } catch (_) {}
  }

  Future<void> addBooks(List<String> paths) async {
    final newBooks = <Book>[];
    for (final path in paths) {
      final meta = EpubParser.parse(path);
      newBooks.add(Book(
        title: meta.title,
        author: meta.author,
        filePath: path,
        coverBytes: meta.coverBytes,
      ));
    }
    state = [...state, ...newBooks];
    _save();
  }

  void editBook(int index, {String? title, String? author, Uint8List? coverBytes, double? progress}) {
    state = [
      for (var i = 0; i < state.length; i++)
        if (i == index) state[i].copyWith(title: title, author: author, coverBytes: coverBytes, progress: progress) else state[i],
    ];
    _save();
  }

  void refreshCover(int index) {
    final book = state[index];
    if (!book.filePath.toLowerCase().endsWith('.epub')) return;
    final meta = EpubParser.parse(book.filePath);
    if (meta.coverBytes != null) {
      state = [
        for (var i = 0; i < state.length; i++)
          if (i == index) state[i].copyWith(coverBytes: meta.coverBytes) else state[i],
      ];
      _save();
    }
  }

  void deleteBook(int index) {
    state = [...state]..removeAt(index);
    _save();
  }

  void touchBook(String filePath) {
    final idx = state.indexWhere((b) => b.filePath == filePath);
    if (idx == -1) return;
    state = [
      for (var i = 0; i < state.length; i++)
        if (i == idx) state[i].copyWith(lastOpened: DateTime.now()) else state[i],
    ];
    _save();
  }

  void addBookFromBytes(String name, Uint8List bytes) {
    final meta = EpubParser.parseBytes(bytes);
    final dot = name.lastIndexOf('.');
    final title = dot > 0 ? name.substring(0, dot) : name;
    state = [...state, Book(title: meta.title.isEmpty ? title : meta.title, author: meta.author, filePath: name, coverBytes: meta.coverBytes, fileBytes: bytes)];
    _save();
  }

  void _save() {
    BookStorage.saveAll(state, ref.read(columnsProvider));
  }

  void saveLayout() {
    BookStorage.saveAll(state, ref.read(columnsProvider));
  }
}

final bookListProvider = NotifierProvider<BookListNotifier, List<Book>>(BookListNotifier.new);

final columnsProvider = StateProvider<int>((ref) => 3);
final searchQueryProvider = StateProvider<String>((ref) => '');
final searchingProvider = StateProvider<bool>((ref) => false);

final filteredBooksProvider = Provider<List<Book>>((ref) {
  final books = ref.watch(bookListProvider);
  final query = ref.watch(searchQueryProvider).toLowerCase();
  List<Book> result;
  if (query.isEmpty) {
    result = List.of(books);
  } else {
    result = books.where((b) =>
      b.title.toLowerCase().contains(query) ||
      b.author.toLowerCase().contains(query)
    ).toList();
  }
  result.sort((a, b) {
    if (a.lastOpened == null && b.lastOpened == null) return 0;
    if (a.lastOpened == null) return 1;
    if (b.lastOpened == null) return -1;
    return b.lastOpened!.compareTo(a.lastOpened!);
  });
  return result;
});

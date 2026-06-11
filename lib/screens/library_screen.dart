import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/book.dart';
import '../providers/book_list_provider.dart';
import '../widgets/book_card.dart';

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  final _searchController = TextEditingController();
  static const _columnOptions = [3, 4, 2];
  static const _columnIcons = [Icons.grid_view_rounded, Icons.apps_rounded, Icons.space_dashboard_rounded];
  static const _scaleMap = {2: 1.15, 3: 1.0, 4: 0.85};

  double _scale(int columns) => _scaleMap[columns] ?? 1.0;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _addBooks() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: ['pdf', 'epub', 'mobi', 'txt', 'cbz', 'cbr'],
    );
    if (result == null || result.files.isEmpty) return;
    final paths = result.files.map((f) => f.path).whereType<String>().toList();
    if (paths.isNotEmpty) {
      ref.read(bookListProvider.notifier).addBooks(paths);
    }
  }

  Future<void> _editBook(int index) async {
    final books = ref.read(bookListProvider);
    final book = books[index];
    final titleController = TextEditingController(text: book.title);
    final authorController = TextEditingController(text: book.author);
    Uint8List? newCover = book.coverBytes;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF0F0F0F),
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          title: Text('Edit metadata', style: GoogleFonts.inter(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
          content: SizedBox(
            width: 280,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    labelStyle: TextStyle(color: Color(0xFF666666), fontSize: 12),
                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF333333))),
                    focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: authorController,
                  style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
                  decoration: const InputDecoration(
                    labelText: 'Author',
                    labelStyle: TextStyle(color: Color(0xFF666666), fontSize: 12),
                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF333333))),
                    focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                  ),
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () async {
                    final picked = await FilePicker.platform.pickFiles(
                      type: FileType.custom,
                      allowedExtensions: ['png', 'jpg', 'jpeg'],
                      withData: true,
                    );
                    if (picked != null && picked.files.isNotEmpty && picked.files.first.bytes != null) {
                      setDialogState(() => newCover = picked.files.first.bytes);
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    height: 120,
                    color: const Color(0xFF0A0A0A),
                    child: newCover != null
                        ? Image.memory(newCover!, fit: BoxFit.contain)
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_photo_alternate, color: Colors.white.withAlpha(80), size: 28),
                              const SizedBox(height: 6),
                              Text('Tap to pick cover', style: GoogleFonts.inter(color: const Color(0xFF555555), fontSize: 11)),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('Cancel', style: GoogleFonts.inter(color: const Color(0xFF888888), fontSize: 13)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text('Save', style: GoogleFonts.inter(color: Colors.white, fontSize: 13)),
            ),
          ],
        ),
      ),
    );

    if (result == true && mounted) {
      final title = titleController.text.trim();
      final author = authorController.text.trim();
      ref.read(bookListProvider.notifier).editBook(
        index,
        title: title.isEmpty ? null : title,
        author: author.isEmpty ? null : author,
        coverBytes: newCover != book.coverBytes ? newCover : null,
      );
    }
  }

  Future<void> _deleteBook(int index) async {
    final books = ref.read(bookListProvider);
    final book = books[index];
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F0F0F),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        title: Text('Delete book?', style: GoogleFonts.inter(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
        content: Text(
          '${book.title} will be removed from your library.',
          style: GoogleFonts.inter(color: const Color(0xFF888888), fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: GoogleFonts.inter(color: const Color(0xFF888888), fontSize: 13)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Delete', style: GoogleFonts.inter(color: const Color(0xFFE05555), fontSize: 13)),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      ref.read(bookListProvider.notifier).deleteBook(index);
    }
  }

  @override
  Widget build(BuildContext context) {
    final books = ref.watch(filteredBooksProvider);
    final columns = ref.watch(columnsProvider);
    final searching = ref.watch(searchingProvider);
    final s = _scale(columns);
    const appBarScale = 1.15;

    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64 * appBarScale),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20 * appBarScale),
                child: SizedBox(
                  height: 63 * appBarScale,
                  child: searching ? _buildSearchBar(appBarScale) : _buildTitleBar(columns, appBarScale),
                ),
              ),
              Container(color: const Color(0xFF141414), height: 0.5),
            ],
          ),
        ),
      ),
      body: books.isEmpty
          ? _buildEmptyState(s)
          : _buildGrid(books, columns, s),
      floatingActionButton: FloatingActionButton(
        onPressed: _addBooks,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        child: Icon(Icons.add, size: 24 * s),
      ),
    );
  }

  Widget _buildTitleBar(int columns, double s) {
    final idx = _columnOptions.indexOf(columns);
    final icon = _columnIcons[idx.clamp(0, _columnIcons.length - 1)];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: 10 * s),
            child: Text(
              'Library',
              style: GoogleFonts.inter(color: Colors.white, fontSize: 20 * s, fontWeight: FontWeight.w600, letterSpacing: 1 * s),
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.only(bottom: 6 * s),
          child: Row(
            children: [
              IconButton(
                onPressed: () {
                  final newIdx = (idx + 1) % _columnOptions.length;
                  ref.read(columnsProvider.notifier).state = _columnOptions[newIdx];
                  ref.read(bookListProvider.notifier).saveLayout();
                },
                icon: Icon(icon, color: Colors.white.withAlpha(128), size: 20 * s),
                splashRadius: 22 * s,
                visualDensity: VisualDensity.compact,
                tooltip: '$columns columns',
              ),
              IconButton(
                onPressed: () => ref.read(searchingProvider.notifier).state = true,
                icon: Icon(Icons.search, color: Colors.white.withAlpha(128), size: 22 * s),
                splashRadius: 22 * s,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar(double s) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: TextField(
            controller: _searchController,
            autofocus: true,
            style: GoogleFonts.inter(color: Colors.white, fontSize: 16 * s),
            cursorColor: Colors.white,
            decoration: InputDecoration(
              hintText: 'Search by title or author',
              hintStyle: GoogleFonts.inter(color: const Color(0xFF555555), fontSize: 14 * s),
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.symmetric(vertical: 8 * s),
            ),
            onChanged: (v) => ref.read(searchQueryProvider.notifier).state = v,
          ),
        ),
        IconButton(
          onPressed: () {
            _searchController.clear();
            ref.read(searchQueryProvider.notifier).state = '';
            ref.read(searchingProvider.notifier).state = false;
          },
          icon: Icon(Icons.close, color: Colors.white, size: 20 * s),
          splashRadius: 20 * s,
          visualDensity: VisualDensity.compact,
        ),
      ],
    );
  }

  Widget _buildEmptyState(double s) {
    final query = ref.watch(searchQueryProvider);
    final isSearching = query.isNotEmpty;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isSearching ? Icons.search_off : Icons.menu_book_rounded, size: 48 * s, color: Colors.white.withAlpha(20)),
          SizedBox(height: 16 * s),
          Text(
            isSearching ? 'no results for "$query"' : 'no books yet',
            style: GoogleFonts.inter(color: const Color(0xFF444444), fontSize: 15 * s, fontWeight: FontWeight.w400),
          ),
          SizedBox(height: 8 * s),
          Text(
            isSearching ? 'try a different search' : 'tap + to add from your device',
            style: GoogleFonts.inter(color: const Color(0xFF333333), fontSize: 13 * s, fontWeight: FontWeight.w400),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid(List<Book> books, int columns, double s) {
    final allBooks = ref.watch(bookListProvider);
    return GridView.builder(
      padding: EdgeInsets.all(12 * s),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        mainAxisSpacing: 8 * s,
        crossAxisSpacing: 8 * s,
        childAspectRatio: 0.56,
      ),
      itemCount: books.length,
      itemBuilder: (context, index) {
        final book = books[index];
        final bookIndex = allBooks.indexOf(book);
        return BookCard(
          book: book,
          scale: s,
          onEdit: () => _editBook(bookIndex),
          onRefreshCover: () => ref.read(bookListProvider.notifier).refreshCover(bookIndex),
          onDelete: () => _deleteBook(bookIndex),
        );
      },
    );
  }
}

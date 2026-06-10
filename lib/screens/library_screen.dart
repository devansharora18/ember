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

    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SizedBox(
                  height: 63,
                  child: searching ? _buildSearchBar() : _buildTitleBar(columns),
                ),
              ),
              Container(color: const Color(0xFF141414), height: 0.5),
            ],
          ),
        ),
      ),
      body: books.isEmpty
          ? _buildEmptyState()
          : _buildGrid(books, columns),
      floatingActionButton: FloatingActionButton(
        onPressed: _addBooks,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildTitleBar(int columns) {
    final idx = _columnOptions.indexOf(columns);
    final icon = _columnIcons[idx.clamp(0, _columnIcons.length - 1)];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              'Library',
              style: GoogleFonts.inter(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600, letterSpacing: 1),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            children: [
              IconButton(
                onPressed: () {
                  final newIdx = (idx + 1) % _columnOptions.length;
                  ref.read(columnsProvider.notifier).state = _columnOptions[newIdx];
                  ref.read(bookListProvider.notifier).saveLayout();
                },
                icon: Icon(icon, color: Colors.white.withAlpha(128), size: 20),
                splashRadius: 22,
                visualDensity: VisualDensity.compact,
                tooltip: '$columns columns',
              ),
              IconButton(
                onPressed: () => ref.read(searchingProvider.notifier).state = true,
                icon: Icon(Icons.search, color: Colors.white.withAlpha(128), size: 22),
                splashRadius: 22,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: TextField(
            controller: _searchController,
            autofocus: true,
            style: GoogleFonts.inter(color: Colors.white, fontSize: 16),
            cursorColor: Colors.white,
            decoration: InputDecoration(
              hintText: 'Search by title or author',
              hintStyle: GoogleFonts.inter(color: const Color(0xFF555555), fontSize: 14),
              border: InputBorder.none,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
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
          icon: const Icon(Icons.close, color: Colors.white, size: 20),
          splashRadius: 20,
          visualDensity: VisualDensity.compact,
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    final query = ref.watch(searchQueryProvider);
    final isSearching = query.isNotEmpty;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isSearching ? Icons.search_off : Icons.menu_book_rounded, size: 48, color: Colors.white.withAlpha(20)),
          const SizedBox(height: 16),
          Text(
            isSearching ? 'no results for "$query"' : 'no books yet',
            style: GoogleFonts.inter(color: const Color(0xFF444444), fontSize: 15, fontWeight: FontWeight.w400),
          ),
          const SizedBox(height: 8),
          Text(
            isSearching ? 'try a different search' : 'tap + to add from your device',
            style: GoogleFonts.inter(color: const Color(0xFF333333), fontSize: 13, fontWeight: FontWeight.w400),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid(List<Book> books, int columns) {
    final allBooks = ref.watch(bookListProvider);
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 0.56,
      ),
      itemCount: books.length,
      itemBuilder: (context, index) {
        final book = books[index];
        final bookIndex = allBooks.indexOf(book);
        return BookCard(
          book: book,
          onEdit: () => _editBook(bookIndex),
          onRefreshCover: () => ref.read(bookListProvider.notifier).refreshCover(bookIndex),
          onDelete: () => _deleteBook(bookIndex),
        );
      },
    );
  }
}

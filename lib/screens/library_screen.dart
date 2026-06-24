import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/book.dart';
import '../providers/book_list_provider.dart';
import '../widgets/book_card.dart';
import 'reader_screen.dart';
import 'library/library_dialogs.dart';
import 'settings_screen.dart';

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  final _searchController = TextEditingController();
  double _pinchAccum = 0.0;
  bool _isPinching = false;

  static const _columnOptions = [3, 4, 2];
  static const _columnIcons = [Icons.grid_view_rounded, Icons.apps_rounded, Icons.space_dashboard_rounded];
  static const _scaleMap = {2: 1.15, 3: 1.0, 4: 0.85};

  double _scale(int columns) => _scaleMap[columns] ?? 1.0;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // --------------- Pinch-to-layout ---------------

  void _onPinchStart(ScaleStartDetails d) { _isPinching = d.pointerCount >= 2; _pinchAccum = 0.0; }
  void _onPinchEnd(ScaleEndDetails _) { _isPinching = false; _pinchAccum = 0.0; }

  void _onPinchUpdate(ScaleUpdateDetails d) {
    if (!_isPinching) return;
    _pinchAccum += d.scale - 1.0;
    if (_pinchAccum > 0.5) {
      _pinchAccum = 0.0; final cols = ref.read(columnsProvider);
      final idx = _columnOptions.indexOf(cols);
      if (cols > 2) { ref.read(columnsProvider.notifier).set(_columnOptions[(idx - 1).clamp(0, _columnOptions.length - 1)]); ref.read(bookListProvider.notifier).saveLayout(); }
    } else if (_pinchAccum < -0.5) {
      _pinchAccum = 0.0; final cols = ref.read(columnsProvider);
      final idx = _columnOptions.indexOf(cols);
      if (cols < 4) { ref.read(columnsProvider.notifier).set(_columnOptions[(idx + 1).clamp(0, _columnOptions.length - 1)]); ref.read(bookListProvider.notifier).saveLayout(); }
    }
  }

  // --------------- Book actions ---------------

  Future<void> _addBooks() async {
    final result = await FilePicker.pickFiles(allowMultiple: true, type: FileType.custom, allowedExtensions: ['epub']);
    if (result == null || result.files.isEmpty) return;
    final paths = <String>[];
    for (final f in result.files) {
      if (kIsWeb) {
        if (f.bytes != null) {
          ref.read(bookListProvider.notifier).addBookFromBytes(f.name, f.bytes!);
        }
      } else if (f.path != null) {
        paths.add(f.path!);
      }
    }
    if (paths.isNotEmpty) ref.read(bookListProvider.notifier).addBooks(paths);
  }

  void _openBook(Book book) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => ReaderScreen(book: book)));
  }

  Future<void> _editBook(int index) async {
    final books = ref.read(bookListProvider);
    final book = books[index];
    final result = await EditBookDialog.show(context, book);
    if (result == null || !mounted) return;
    ref.read(bookListProvider.notifier).editBook(
      index,
      title: result.title.isNotEmpty ? result.title : null,
      author: result.author.isNotEmpty ? result.author : null,
      coverBytes: result.cover != book.coverBytes ? result.cover : null,
    );
  }

  Future<void> _deleteBook(int index) async {
    final books = ref.read(bookListProvider);
    final confirmed = await DeleteBookDialog.show(context, books[index].title);
    if (confirmed == true && mounted) ref.read(bookListProvider.notifier).deleteBook(index);
  }

  // --------------- Build ---------------

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
        child: SafeArea(bottom: false, child: Column(children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20 * appBarScale),
            child: SizedBox(height: 63 * appBarScale, child: searching ? _buildSearchBar(appBarScale) : _buildTitleBar(columns, appBarScale)),
          ),
          Container(color: const Color(0xFF141414), height: 0.5),
        ])),
      ),
      body: GestureDetector(
        onScaleStart: _onPinchStart, onScaleUpdate: _onPinchUpdate, onScaleEnd: _onPinchEnd,
        child: books.isEmpty ? _buildEmptyState(s) : _buildGrid(books, columns, s),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addBooks, backgroundColor: Colors.white, foregroundColor: Colors.black,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        child: Icon(Icons.add, size: 24 * s),
      ),
    );
  }

  Widget _buildTitleBar(int columns, double s) {
    final idx = _columnOptions.indexOf(columns);
    final icon = _columnIcons[idx.clamp(0, _columnIcons.length - 1)];

    return Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
      Expanded(child: Padding(padding: EdgeInsets.only(bottom: 10 * s), child: Text('Library', style: GoogleFonts.inter(color: Colors.white, fontSize: 20 * s, fontWeight: FontWeight.w600, letterSpacing: 1 * s)))),
      Padding(
        padding: EdgeInsets.only(bottom: 6 * s),
        child: Row(children: [
          IconButton(
            onPressed: () {
              final newIdx = (idx + 1) % _columnOptions.length;
              ref.read(columnsProvider.notifier).set(_columnOptions[newIdx]);
              ref.read(bookListProvider.notifier).saveLayout();
            },
            icon: Icon(icon, color: Colors.white.withAlpha(128), size: 20 * s), splashRadius: 22 * s, visualDensity: VisualDensity.compact, tooltip: '$columns columns',
          ),
          IconButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
            icon: Icon(Icons.settings, color: Colors.white.withAlpha(128), size: 20 * s), splashRadius: 22 * s, visualDensity: VisualDensity.compact, tooltip: 'Settings',
          ),
          IconButton(
            onPressed: () => ref.read(searchingProvider.notifier).set(true),
            icon: Icon(Icons.search, color: Colors.white.withAlpha(128), size: 22 * s), splashRadius: 22 * s, visualDensity: VisualDensity.compact,
          ),
        ]),
      ),
    ]);
  }

  Widget _buildSearchBar(double s) {
    return Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
      Expanded(child: TextField(
        controller: _searchController, autofocus: true,
        style: GoogleFonts.inter(color: Colors.white, fontSize: 16 * s), cursorColor: Colors.white,
        decoration: InputDecoration(hintText: 'Search by title or author', hintStyle: GoogleFonts.inter(color: const Color(0xFF555555), fontSize: 14 * s), border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.symmetric(vertical: 8 * s)),
        onChanged: (v) => ref.read(searchQueryProvider.notifier).set(v),
      )),
      IconButton(
        onPressed: () { _searchController.clear(); ref.read(searchQueryProvider.notifier).set(''); ref.read(searchingProvider.notifier).set(false); },
        icon: const Icon(Icons.close, color: Colors.white, size: 20), splashRadius: 20, visualDensity: VisualDensity.compact,
      ),
    ]);
  }

  Widget _buildEmptyState(double s) {
    final query = ref.watch(searchQueryProvider);
    final isSearching = query.isNotEmpty;
    return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(isSearching ? Icons.search_off : Icons.menu_book_rounded, size: 48 * s, color: Colors.white.withAlpha(20)),
      SizedBox(height: 16 * s),
      Text(isSearching ? 'no results for "$query"' : 'no books yet', style: GoogleFonts.inter(color: const Color(0xFF444444), fontSize: 15 * s, fontWeight: FontWeight.w400)),
      SizedBox(height: 8 * s),
      Text(isSearching ? 'try a different search' : 'tap + to add from your device', style: GoogleFonts.inter(color: const Color(0xFF333333), fontSize: 13 * s, fontWeight: FontWeight.w400)),
    ]));
  }

  Widget _buildGrid(List<Book> books, int columns, double s) {
    final allBooks = ref.watch(bookListProvider);
    return GridView.builder(
      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      padding: EdgeInsets.all(12 * s),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: columns, mainAxisSpacing: 8 * s, crossAxisSpacing: 8 * s, childAspectRatio: 0.56),
      itemCount: books.length,
      itemBuilder: (context, index) {
        final book = books[index];
        final bookIndex = allBooks.indexOf(book);
        return BookCard(
          book: book, scale: s,
          onTap: () => _openBook(book),
          onEdit: () => _editBook(bookIndex),
          onRefreshCover: () => ref.read(bookListProvider.notifier).refreshCover(bookIndex),
          onDelete: () => _deleteBook(bookIndex),
        );
      },
    );
  }
}

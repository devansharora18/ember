import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/book.dart';
import '../services/book_storage.dart';
import '../services/epub_parser.dart';
import '../widgets/book_card.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final List<Book> _books = [];
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadBooks();
  }

  Future<void> _loadBooks() async {
    final books = await BookStorage.loadBooks();
    if (!mounted) return;
    setState(() {
      _books.addAll(books);
      _loaded = true;
    });
  }

  Future<void> _addBooks() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: ['pdf', 'epub', 'mobi', 'txt', 'cbz', 'cbr'],
    );

    if (result == null || result.files.isEmpty) return;

    setState(() {
      for (final file in result.files) {
        final path = file.path;
        if (path == null) continue;

        final meta = EpubParser.parse(path);

        _books.add(Book(
          title: meta.title,
          author: meta.author,
          filePath: path,
          coverBytes: meta.coverBytes,
        ));
      }
    });

    BookStorage.saveBooks(_books);
  }

  Future<void> _editBook(int index) async {
    final book = _books[index];
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
      setState(() {
        book.title = titleController.text.trim().isEmpty ? book.title : titleController.text.trim();
        book.author = authorController.text.trim().isEmpty ? book.author : authorController.text.trim();
        if (newCover != book.coverBytes) {
          book.coverBytes = newCover;
        }
      });
      BookStorage.saveBooks(_books);
    }
  }

  Future<void> _refreshCover(int index) async {
    final book = _books[index];
    if (!book.filePath.toLowerCase().endsWith('.epub')) return;

    final meta = EpubParser.parse(book.filePath);
    if (meta.coverBytes != null && mounted) {
      setState(() {
        book.coverBytes = meta.coverBytes;
      });
      BookStorage.saveBooks(_books);
    }
  }

  Future<void> _deleteBook(int index) async {
    final book = _books[index];
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
      setState(() => _books.removeAt(index));
      BookStorage.saveBooks(_books);
    }
  }

  @override
  Widget build(BuildContext context) {
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
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Text(
                            'Library',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: IconButton(
                          onPressed: () {},
                          icon: Icon(Icons.search, color: Colors.white.withAlpha(128), size: 22),
                          splashRadius: 22,
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Container(color: const Color(0xFF141414), height: 0.5),
            ],
          ),
        ),
      ),
      body: _loaded
          ? (_books.isEmpty ? _buildEmptyState() : _buildGrid())
          : const Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(Color(0xFF333333)),
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addBooks,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.menu_book_rounded, size: 48, color: Colors.white.withAlpha(20)),
          const SizedBox(height: 16),
          Text(
            'no books yet',
            style: GoogleFonts.inter(
              color: const Color(0xFF444444),
              fontSize: 15,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'tap + to add from your device',
            style: GoogleFonts.inter(
              color: const Color(0xFF333333),
              fontSize: 13,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 0.56,
      ),
      itemCount: _books.length,
      itemBuilder: (context, index) {
        return BookCard(
          book: _books[index],
          onEdit: () => _editBook(index),
          onRefreshCover: () => _refreshCover(index),
          onDelete: () => _deleteBook(index),
        );
      },
    );
  }
}

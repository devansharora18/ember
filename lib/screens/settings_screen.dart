import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/book.dart';
import '../providers/book_list_provider.dart';
import '../services/book_storage.dart';
import '../services/data_export.dart';
import '../services/file_reader.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  String? _status;

  Future<void> _export() async {
    setState(() => _status = 'Preparing export...');
    try {
      final result = await DataExport.exportAll();
      final path = await FilePicker.saveFile(
        dialogTitle: 'Export library',
        fileName: 'ember_backup.ember',
        type: FileType.custom,
        allowedExtensions: ['ember'],
        bytes: result.bytes,
      );
      if (path != null) {
        setState(() => _status = 'Exported ${result.bookCount} books');
      } else {
        setState(() => _status = null);
      }
    } catch (e) {
      setState(() => _status = 'Export failed: $e');
    }
  }

  Future<void> _import() async {
    setState(() => _status = 'Selecting file...');
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['ember', 'json'],
        withData: true,
      );
      if (result == null || result.files.isEmpty) {
        setState(() => _status = null);
        return;
      }

      Uint8List bytes;
      if (result.files.first.bytes != null) {
        bytes = result.files.first.bytes!;
      } else if (!kIsWeb && result.files.first.path != null) {
        bytes = await readFileAsBytes(result.files.first.path!);
      } else {
        setState(() => _status = 'Could not read file');
        return;
      }

      setState(() => _status = 'Importing...');

      var importResult = await DataExport.importAll(bytes);
      if (!importResult.success) {
        final content = utf8.decode(bytes);
        try {
          final data = jsonDecode(content);
          if (data is Map<String, dynamic> && data['version'] != null) {
            final legacy = await _importLegacy(content);
            importResult = legacy;
          }
        } catch (_) {}
      }

      if (importResult.success) {
        ref.read(bookListProvider.notifier).replaceAll(importResult.bookList, importResult.columns);
        setState(() => _status = 'Imported ${importResult.books} books');
      } else {
        setState(() => _status = 'Invalid backup file');
      }
    } catch (e) {
      setState(() => _status = 'Import failed: $e');
    }
  }

  Future<({int books, bool success, List<Book> bookList, int columns})> _importLegacy(String content) async {
    final data = jsonDecode(content) as Map<String, dynamic>;
    final version = data['version'] as int? ?? 1;
    if (version != 1) return (books: 0, success: false, bookList: <Book>[], columns: 3);

    final settings = data['settings'] as Map<String, dynamic>? ?? {};
    final jsonBooks = data['books'] as List? ?? [];
    final columns = data['columns'] as int? ?? 3;

    final books = <Book>[];
    for (final b in jsonBooks) {
      final map = b as Map<String, dynamic>;
      final filePath = map['filePath'] as String;

      Uint8List? coverBytes;
      final coverB64 = map['coverBytes'] as String?;
      if (coverB64 != null) coverBytes = base64Decode(coverB64);

      Uint8List? fileBytes;
      final fileB64 = map['fileBytes'] as String?;
      if (fileB64 != null) fileBytes = base64Decode(fileB64);

      books.add(Book(
        title: map['title'] as String? ?? 'Unknown',
        author: map['author'] as String? ?? '',
        filePath: filePath,
        coverBytes: coverBytes,
        fileBytes: fileBytes,
        progress: (map['progress'] as num?)?.toDouble() ?? 0.0,
        lastOpened: map['lastOpened'] != null ? DateTime.tryParse(map['lastOpened'] as String) : null,
      ));
    }

    if (settings['fontSize'] != null) BookStorage.saveFontSize('', (settings['fontSize'] as num).toDouble());
    if (settings['fontFamily'] != null) BookStorage.saveFontFamily('', settings['fontFamily'] as String);
    if (settings['darkMode'] != null) BookStorage.saveDarkMode('', settings['darkMode'] as bool);
    if (settings['rsvpWpm'] != null) BookStorage.saveRsvpWpm(settings['rsvpWpm'] as int);

    for (var i = 0; i < books.length && i < jsonBooks.length; i++) {
      final map = jsonBooks[i] as Map<String, dynamic>;
      final filePath = map['filePath'] as String;
      if (map['position'] != null) BookStorage.savePosition(filePath, map['position'] as int);
      if (map['bookmarks'] != null) {
        final bms = (map['bookmarks'] as List).map((e) => (e as num).toInt()).toList();
        BookStorage.saveBookmarks(filePath, bms);
      }
      if (map['highlights'] != null) {
        final hls = (map['highlights'] as List).map((e) => Map<String, int>.from(e as Map)).toList();
        BookStorage.saveHighlights(filePath, hls);
      }
    }

    return (books: books.length, success: true, bookList: books, columns: columns);
  }

  @override
  Widget build(BuildContext context) {
    final s = MediaQuery.textScalerOf(context).scale(1.0).clamp(1.0, 1.5);

    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.arrow_back, color: Colors.white.withAlpha(128), size: 20),
                  splashRadius: 22,
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.only(bottom: 22),
                ),
                Padding(
                  padding: EdgeInsets.only(bottom: 10 * s),
                  child: Text('Settings', style: GoogleFonts.inter(color: Colors.white, fontSize: 20 * s, fontWeight: FontWeight.w600, letterSpacing: 1 * s)),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(20 * s),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Data', style: GoogleFonts.inter(color: const Color(0xFF888888), fontSize: 12 * s, fontWeight: FontWeight.w500, letterSpacing: 0.5 * s)),
            const SizedBox(height: 12),
            _buildButton(
              icon: Icons.upload_file,
              label: 'Export library',
              subtitle: 'Save all books, progress & settings to a file',
              onTap: _export,
              s: s,
            ),
            const SizedBox(height: 8),
            _buildButton(
              icon: Icons.download,
              label: 'Import library',
              subtitle: 'Restore books, progress & settings from a file',
              onTap: _import,
              s: s,
            ),
            if (_status != null) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: 16 * s, vertical: 12 * s),
                color: const Color(0xFF0A0A0A),
                child: Text(
                  _status!,
                  style: GoogleFonts.inter(
                    color: _status!.contains('failed') || _status!.contains('Invalid')
                        ? const Color(0xFFE05555)
                        : const Color(0xFF888888),
                    fontSize: 12 * s,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildButton({
    required IconData icon,
    required String label,
    required String subtitle,
    required VoidCallback onTap,
    required double s,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(16 * s),
        decoration: BoxDecoration(
          color: const Color(0xFF0A0A0A),
          border: Border.all(color: const Color(0xFF1A1A1A)),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white.withAlpha(128), size: 22 * s),
            SizedBox(width: 14 * s),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: GoogleFonts.inter(color: Colors.white, fontSize: 14 * s, fontWeight: FontWeight.w500)),
                  SizedBox(height: 2),
                  Text(subtitle, style: GoogleFonts.inter(color: const Color(0xFF555555), fontSize: 11 * s)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.white.withAlpha(40), size: 20 * s),
          ],
        ),
      ),
    );
  }
}

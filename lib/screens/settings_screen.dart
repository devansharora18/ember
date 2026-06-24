import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/book_list_provider.dart';
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
      final bytes = utf8.encode(result.json);
      final path = await FilePicker.saveFile(
        dialogTitle: 'Export library',
        fileName: 'ember_backup.json',
        type: FileType.custom,
        allowedExtensions: ['json'],
        bytes: bytes,
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
        allowedExtensions: ['json'],
        withData: true,
      );
      if (result == null || result.files.isEmpty) {
        setState(() => _status = null);
        return;
      }

      String content;
      if (result.files.first.bytes != null) {
        content = utf8.decode(result.files.first.bytes!);
      } else       if (!kIsWeb && result.files.first.path != null) {
        content = await readFileAsString(result.files.first.path!);
      } else {
        setState(() => _status = 'Could not read file');
        return;
      }

      setState(() => _status = 'Importing...');
      final importResult = await DataExport.importAll(content);
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

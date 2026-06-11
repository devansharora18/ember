import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/book.dart';

class EditBookDialog extends StatelessWidget {
  final Book book;

  const EditBookDialog({super.key, required this.book});

  static Future<({String title, String author, Uint8List? cover})?> show(BuildContext context, Book book) async {
    final result = await showDialog<({String title, String author, Uint8List? cover})?>(
      context: context,
      builder: (_) => EditBookDialog(book: book),
    );
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final titleCtrl = TextEditingController(text: book.title);
    final authorCtrl = TextEditingController(text: book.author);
    Uint8List? newCover = book.coverBytes;

    return StatefulBuilder(
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
                controller: titleCtrl,
                style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
                decoration: const InputDecoration(labelText: 'Title', labelStyle: TextStyle(color: Color(0xFF666666), fontSize: 12), enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF333333))), focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white))),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: authorCtrl,
                style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
                decoration: const InputDecoration(labelText: 'Author', labelStyle: TextStyle(color: Color(0xFF666666), fontSize: 12), enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF333333))), focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white))),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () async {
                  final picked = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['png', 'jpg', 'jpeg'], withData: true);
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
                      : Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.add_photo_alternate, color: Colors.white.withAlpha(80), size: 28), const SizedBox(height: 6), Text('Tap to pick cover', style: GoogleFonts.inter(color: const Color(0xFF555555), fontSize: 11))]),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, null), child: Text('Cancel', style: GoogleFonts.inter(color: const Color(0xFF888888), fontSize: 13))),
          TextButton(
            onPressed: () {
              final title = titleCtrl.text.trim();
              final author = authorCtrl.text.trim();
              Navigator.pop(ctx, (title: title.isNotEmpty ? title : book.title, author: author.isNotEmpty ? author : book.author, cover: newCover));
            },
            child: Text('Save', style: GoogleFonts.inter(color: Colors.white, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

class DeleteBookDialog extends StatelessWidget {
  final String bookTitle;

  const DeleteBookDialog({super.key, required this.bookTitle});

  static Future<bool?> show(BuildContext context, String bookTitle) {
    return showDialog<bool>(context: context, builder: (_) => DeleteBookDialog(bookTitle: bookTitle));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF0F0F0F),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      title: Text('Delete book?', style: GoogleFonts.inter(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
      content: Text('$bookTitle will be removed from your library.', style: GoogleFonts.inter(color: const Color(0xFF888888), fontSize: 13)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Cancel', style: GoogleFonts.inter(color: const Color(0xFF888888), fontSize: 13))),
        TextButton(onPressed: () => Navigator.pop(context, true), child: Text('Delete', style: GoogleFonts.inter(color: const Color(0xFFE05555), fontSize: 13))),
      ],
    );
  }
}

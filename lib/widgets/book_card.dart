import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/book.dart';

class BookCard extends StatelessWidget {
  final Book book;
  final VoidCallback? onTap;

  const BookCard({super.key, required this.book, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0A0A0A),
          border: Border.all(color: const Color(0xFF1A1A1A)),
          borderRadius: BorderRadius.zero,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                color: const Color(0xFF111111),
                child: book.coverBytes != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.zero,
                        child: Image.memory(
                          book.coverBytes!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          errorBuilder: (_, _, _) => _placeholderIcon(),
                        ),
                      )
                    : _placeholderIcon(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book.title,
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    book.author,
                    style: GoogleFonts.inter(
                      color: const Color(0xFF666666),
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholderIcon() {
    return Center(
      child: Icon(
        Icons.menu_book_rounded,
        size: 32,
        color: Colors.white.withAlpha(40),
      ),
    );
  }
}

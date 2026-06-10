import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/book.dart';

class BookCard extends StatelessWidget {
  final Book book;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onRefreshCover;

  const BookCard({
    super.key,
    required this.book,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.onRefreshCover,
  });

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
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    height: double.infinity,
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
                  Positioned(
                    top: 2,
                    right: 2,
                    child: Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: const Color(0xBB000000),
                        borderRadius: BorderRadius.zero,
                      ),
                      child: PopupMenuButton<String>(
                        onSelected: (value) {
                          switch (value) {
                            case 'edit':
                              onEdit?.call();
                            case 'refresh':
                              onRefreshCover?.call();
                            case 'delete':
                              onDelete?.call();
                          }
                        },
                        icon: const Icon(Icons.more_vert, color: Colors.white, size: 18),
                        iconSize: 18,
                        padding: EdgeInsets.zero,
                        splashRadius: 16,
                        constraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                        color: const Color(0xFF141414),
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero,
                          side: BorderSide(color: Color(0xFF222222)),
                        ),
                        offset: const Offset(0, 2),
                        itemBuilder: (_) => [
                          PopupMenuItem<String>(
                            value: 'edit',
                            height: 40,
                            child: Row(
                              children: [
                                Icon(Icons.edit, size: 16, color: Colors.white.withAlpha(200)),
                                const SizedBox(width: 10),
                                Text('Edit metadata', style: GoogleFonts.inter(fontSize: 13, color: Colors.white)),
                              ],
                            ),
                          ),
                          PopupMenuItem<String>(
                            value: 'refresh',
                            height: 40,
                            child: Row(
                              children: [
                                Icon(Icons.refresh, size: 16, color: Colors.white.withAlpha(200)),
                                const SizedBox(width: 10),
                                Text('Refresh cover', style: GoogleFonts.inter(fontSize: 13, color: Colors.white)),
                              ],
                            ),
                          ),
                          const PopupMenuDivider(height: 1),
                          PopupMenuItem<String>(
                            value: 'delete',
                            height: 40,
                            child: Row(
                              children: [
                                const Icon(Icons.delete_outline, size: 16, color: Color(0xFFE05555)),
                                const SizedBox(width: 10),
                                Text('Delete', style: GoogleFonts.inter(fontSize: 13, color: Color(0xFFE05555))),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
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

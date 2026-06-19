import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class BookmarksSheet extends StatefulWidget {
  final bool darkMode;
  final List<int> bookmarks;
  final int currentPage;
  final int coverCount;
  final void Function(int page) onNavigate;
  final void Function(int index) onRemove;

  const BookmarksSheet({
    super.key,
    required this.darkMode,
    required this.bookmarks,
    required this.currentPage,
    required this.coverCount,
    required this.onNavigate,
    required this.onRemove,
  });

  @override
  State<BookmarksSheet> createState() => _BookmarksSheetState();
}

class _BookmarksSheetState extends State<BookmarksSheet> {
  @override
  Widget build(BuildContext context) {
    final dm = widget.darkMode;
    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Text('Bookmarks', style: GoogleFonts.inter(color: dm ? Colors.white : Colors.black87, fontSize: 16, fontWeight: FontWeight.w600)),
          ),
          Container(color: dm ? const Color(0xFF141414) : const Color(0xFFDDDDD8), height: 0.5),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: widget.bookmarks.length,
              itemBuilder: (_, i) {
                final pg = widget.bookmarks[i];
                final isCurrent = pg == widget.currentPage;
                return ListTile(
                  dense: true,
                  leading: Icon(Icons.bookmark, size: 16, color: isCurrent ? (dm ? Colors.white : Colors.black87) : (dm ? const Color(0xFF555555) : const Color(0xFF999999))),
                  title: Text('Page ${pg + 1}', style: GoogleFonts.inter(color: isCurrent ? (dm ? Colors.white : Colors.black87) : (dm ? const Color(0xFFAAAAAA) : const Color(0xFF666666)), fontSize: 14)),
                  trailing: IconButton(
                    icon: Icon(Icons.close, size: 16, color: dm ? const Color(0xFF555555) : const Color(0xFF999999)),
                    onPressed: () {
                      widget.onRemove(i);
                      if (widget.bookmarks.length <= 1) Navigator.pop(context);
                    },
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    widget.onNavigate(pg);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class HighlightsSheet extends StatefulWidget {
  final bool darkMode;
  final List<Map<String, int>> highlights;
  final int coverCount;
  final void Function(int page) onNavigate;
  final void Function(int index) onRemove;
  final String Function() getFullText;
  final int Function(int) pageFinder;

  const HighlightsSheet({
    super.key,
    required this.darkMode,
    required this.highlights,
    required this.coverCount,
    required this.onNavigate,
    required this.onRemove,
    required this.getFullText,
    required this.pageFinder,
  });

  @override
  State<HighlightsSheet> createState() => _HighlightsSheetState();
}

class _HighlightsSheetState extends State<HighlightsSheet> {
  @override
  Widget build(BuildContext context) {
    final dm = widget.darkMode;
    final fullText = widget.getFullText();
    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Text('Highlights', style: GoogleFonts.inter(color: dm ? Colors.white : Colors.black87, fontSize: 16, fontWeight: FontWeight.w600)),
          ),
          Container(color: dm ? const Color(0xFF141414) : const Color(0xFFDDDDD8), height: 0.5),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: widget.highlights.length,
              itemBuilder: (_, i) {
                final hl = widget.highlights[i];
                final hlStart = hl['s']!;
                final hlEnd = hl['e']!;
                final text = fullText.substring(hlStart.clamp(0, fullText.length), hlEnd.clamp(0, fullText.length));
                final pg = widget.pageFinder(hlStart);
                return ListTile(
                  dense: true,
                  leading: const Icon(Icons.format_quote, size: 16, color: Color(0xFF888888)),
                  title: Text(
                    text.length > 60 ? '${text.substring(0, 60)}...' : text,
                    style: GoogleFonts.inter(color: dm ? const Color(0xFFAAAAAA) : const Color(0xFF666666), fontSize: 13),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    'Page ${pg + 1}',
                    style: GoogleFonts.inter(color: dm ? const Color(0xFF555555) : const Color(0xFF999999), fontSize: 11),
                  ),
                  trailing: IconButton(
                    icon: Icon(Icons.close, size: 16, color: dm ? const Color(0xFF555555) : const Color(0xFF999999)),
                    onPressed: () {
                      widget.onRemove(i);
                      if (widget.highlights.length <= 1) Navigator.pop(context);
                    },
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    widget.onNavigate(pg);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

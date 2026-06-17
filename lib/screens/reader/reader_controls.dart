import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ReaderAppBar extends StatelessWidget {
  final String title;
  final bool darkMode;
  final EdgeInsets padding;
  final VoidCallback onBack;
  final VoidCallback onDecreaseFont;
  final VoidCallback onIncreaseFont;
  final VoidCallback onShowToc;
  final VoidCallback? onBookmarkToggle;
  final bool isBookmarked;
  final ValueChanged<String> onMenuAction;
  final List<PopupMenuEntry<String>> menuItems;

  const ReaderAppBar({
    super.key,
    required this.title,
    required this.darkMode,
    required this.padding,
    required this.onBack,
    required this.onDecreaseFont,
    required this.onIncreaseFont,
    required this.onShowToc,
    this.onBookmarkToggle,
    this.isBookmarked = false,
    required this.onMenuAction,
    required this.menuItems,
  });

  @override
  Widget build(BuildContext context) {
    final fg = darkMode ? Colors.white : Colors.black87;
    final bg = darkMode ? const Color(0xDD000000) : const Color(0xDDF5F5F0);

    return Container(
      padding: EdgeInsets.only(top: padding.top),
      color: bg,
      child: SizedBox(
        height: 52,
        child: Row(
          children: [
            IconButton(icon: Icon(Icons.arrow_back, color: fg, size: 22), onPressed: onBack),
            Expanded(
              child: Text(title, style: GoogleFonts.inter(color: fg, fontSize: 14, fontWeight: FontWeight.w500, letterSpacing: 0.5), maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
            IconButton(icon: Icon(Icons.text_decrease, color: fg, size: 20), onPressed: onDecreaseFont),
            IconButton(icon: Icon(Icons.text_increase, color: fg, size: 20), onPressed: onIncreaseFont),
            if (onBookmarkToggle != null) IconButton(icon: Icon(isBookmarked ? Icons.bookmark : Icons.bookmark_border, color: isBookmarked ? const Color(0xFFE05555) : fg, size: 20), onPressed: onBookmarkToggle),
            IconButton(icon: Icon(Icons.list, color: fg, size: 20), onPressed: onShowToc),
            PopupMenuButton<String>(
              onSelected: onMenuAction,
              icon: Icon(Icons.more_vert, color: fg, size: 20),
              iconSize: 20,
              splashRadius: 20,
              color: darkMode ? const Color(0xFF141414) : const Color(0xFFF0F0EB),
              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero, side: BorderSide(color: Color(0xFF222222))),
              itemBuilder: (_) => menuItems,
            ),
          ],
        ),
      ),
    );
  }
}

class ReaderBottomBar extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final int totalChars;
  final int position;
  final bool darkMode;
  final int coverCount;
  final PageController pageController;

  const ReaderBottomBar({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.totalChars,
    required this.position,
    required this.darkMode,
    required this.coverCount,
    required this.pageController,
  });

  @override
  Widget build(BuildContext context) {
    final pad = MediaQuery.of(context).padding;
    final bg = darkMode ? const Color(0xDD000000) : const Color(0xDDF5F5F0);
    final fg = darkMode ? const Color(0xFF888888) : const Color(0xFF666666);

    final remainingChars = (totalChars - position).clamp(0, totalChars);
    final remainingWords = remainingChars / 6;
    final remainingMin = remainingWords / 250;
    final timeStr = remainingMin < 1
        ? '<1 min'
        : remainingMin < 60
            ? '${remainingMin.round()} min'
            : '${remainingMin ~/ 60}h ${(remainingMin.round() % 60)}m';

    return Container(
      padding: EdgeInsets.only(bottom: pad.bottom),
      color: bg,
      child: SizedBox(
        height: 36,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              if (coverCount > 0 && pageController.hasClients && pageController.page?.round() == 0)
                Text('Cover', style: GoogleFonts.inter(color: fg, fontSize: 11))
              else ...[
                Text('$currentPage / $totalPages', style: GoogleFonts.inter(color: fg, fontSize: 11)),
                const SizedBox(width: 12),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.zero,
                    child: LinearProgressIndicator(
                      value: totalPages > 1 ? (currentPage / (totalPages - 1)).clamp(0.0, 1.0) : 0,
                      backgroundColor: darkMode ? const Color(0xFF1A1A1A) : const Color(0xFFE0E0DB),
                      valueColor: AlwaysStoppedAnimation(darkMode ? const Color(0xFF444444) : const Color(0xFFAAAAAA)),
                      minHeight: 2,
                    ),
                  ),
                ),
              ],
              const SizedBox(width: 12),
              Text('${totalChars > 0 ? (position * 100 ~/ totalChars) : 0}% · $timeStr', style: GoogleFonts.inter(color: fg, fontSize: 11)),
            ],
          ),
        ),
      ),
    );
  }
}

PopupMenuItem<String> readerMenuPopItem(String label, String value, bool darkMode) {
  return PopupMenuItem<String>(
    value: value,
    height: 38,
    child: Text(label, style: GoogleFonts.inter(color: darkMode ? const Color(0xFFAAAAAA) : const Color(0xFF666666), fontSize: 13)),
  );
}

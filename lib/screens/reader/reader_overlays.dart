import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class GoToPageOverlay extends StatelessWidget {
  final int currentPage;
  final int originalPage;
  final int totalPages;
  final bool darkMode;
  final EdgeInsets padding;
  final List<int> bookmarks;
  final VoidCallback onReturn;
  final VoidCallback onExit;
  final ValueChanged<double> onSliderChanged;

  const GoToPageOverlay({
    super.key,
    required this.currentPage,
    required this.originalPage,
    required this.totalPages,
    required this.darkMode,
    required this.padding,
    required this.bookmarks,
    required this.onReturn,
    required this.onExit,
    required this.onSliderChanged,
  });

  @override
  Widget build(BuildContext context) {
    final bg = darkMode ? const Color(0xEE000000) : const Color(0xEEF5F5F0);
    final fg = darkMode ? Colors.white : Colors.black87;
    final dim = darkMode ? const Color(0xFF888888) : const Color(0xFF666666);

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Expanded(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: onExit,
          ),
        ),
        Container(
          padding: EdgeInsets.only(bottom: padding.bottom),
          color: bg,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: onReturn,
                      child: Container(
                        width: 48,
                        height: 64,
                        decoration: BoxDecoration(
                          color: darkMode ? const Color(0xFF111111) : const Color(0xFFDDDDD8),
                          border: Border.all(color: originalPage == currentPage ? fg : dim),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.history, size: 16, color: dim),
                              const SizedBox(height: 2),
                              Text('${originalPage + 1}', style: GoogleFonts.inter(color: dim, fontSize: 9)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text('Page ${currentPage + 1}', style: GoogleFonts.inter(color: fg, fontSize: 14, fontWeight: FontWeight.w600)),
                              const Spacer(),
                              GestureDetector(
                                onTap: onExit,
                                child: Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: darkMode ? const Color(0xFF333333) : const Color(0xFFCCCCCC),
                                  ),
                                  child: const Icon(Icons.close, size: 16, color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          if (bookmarks.isNotEmpty)
                            SizedBox(
                              height: 8,
                              child: LayoutBuilder(
                                builder: (_, ctr) {
                                  final w = ctr.maxWidth;
                                  return Stack(
                                    children: bookmarks.map((bm) {
                                      final frac = (bm + 1) / totalPages;
                                      final left = (frac * w).clamp(4.0, w - 4.0) - 3;
                                      return Positioned(
                                        left: left,
                                        child: Icon(
                                          Icons.bookmark,
                                          size: 8,
                                          color: currentPage == bm ? fg : dim,
                                        ),
                                      );
                                    }).toList(),
                                  );
                                },
                              ),
                            ),
                          const SizedBox(height: 4),
                          Slider(
                            value: (currentPage + 1).toDouble().clamp(1, totalPages.toDouble()),
                            min: 1,
                            max: totalPages.toDouble().clamp(1, 99999),
                            divisions: (totalPages - 1).clamp(0, 999),
                            activeColor: fg,
                            inactiveColor: darkMode ? const Color(0xFF333333) : const Color(0xFFCCCCCC),
                            onChanged: onSliderChanged,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ],
    );
  }
}

class SearchOverlay extends StatelessWidget {
  final bool darkMode;
  final EdgeInsets padding;
  final String fullText;
  final String query;
  final List<Map<String, int>> results;
  final int Function(int) pageFinder;
  final TextEditingController controller;
  final VoidCallback onExit;
  final ValueChanged<String> onSearch;
  final ValueChanged<int> onNavigate;

  const SearchOverlay({
    super.key,
    required this.darkMode,
    required this.padding,
    required this.fullText,
    required this.query,
    required this.results,
    required this.pageFinder,
    required this.controller,
    required this.onExit,
    required this.onSearch,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    final bg = darkMode ? const Color(0xEE000000) : const Color(0xEEF5F5F0);
    final fg = darkMode ? Colors.white : Colors.black87;
    final dim = darkMode ? const Color(0xFF888888) : const Color(0xFF666666);
    const accent = Color(0xFFE05555);

    return Column(
      children: [
        Container(
          padding: EdgeInsets.only(top: padding.top),
          color: bg,
          child: SizedBox(
            height: 56,
            child: Row(
              children: [
                IconButton(icon: Icon(Icons.arrow_back, color: fg, size: 22), onPressed: onExit),
                Expanded(
                  child: TextField(
                    controller: controller,
                    autofocus: true,
                    onChanged: onSearch,
                    style: GoogleFonts.inter(color: fg, fontSize: 14),
                    cursorColor: accent,
                    decoration: InputDecoration(
                      hintText: 'Search…',
                      hintStyle: GoogleFonts.inter(color: dim, fontSize: 14),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
                if (query.isNotEmpty)
                  Text('${results.length}', style: GoogleFonts.inter(color: dim, fontSize: 12)),
                const SizedBox(width: 8),
              ],
            ),
          ),
        ),
        if (query.isNotEmpty)
          Expanded(
            child: Container(
              color: bg,
              child: results.isEmpty
                  ? Center(child: Text('No results', style: GoogleFonts.inter(color: dim, fontSize: 13)))
                  : ListView.builder(
                      padding: EdgeInsets.only(bottom: padding.bottom),
                      itemCount: results.length.clamp(0, 100),
                      itemBuilder: (_, i) => _buildResultItem(i, dim, accent),
                    ),
            ),
          ),
      ],
    );
  }

  Widget _buildResultItem(int i, Color dim, Color accent) {
    final m = results[i];
    final pos = m['pos']!;
    final len = m['len']!;
    final start = (pos - 40).clamp(0, fullText.length);
    final end = (pos + len + 40).clamp(0, fullText.length);
    final before = fullText.substring(start, pos);
    final match = fullText.substring(pos, pos + len);
    final after = fullText.substring(pos + len, end);
    final pg = pageFinder(pos);

    return ListTile(
      dense: true,
      leading: Icon(Icons.search, size: 14, color: dim),
      title: RichText(
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        text: TextSpan(children: [
          if (start < pos) TextSpan(text: '…${before.trimLeft()}', style: GoogleFonts.inter(color: dim, fontSize: 13)),
          TextSpan(text: match, style: GoogleFonts.inter(color: accent, fontSize: 13, fontWeight: FontWeight.w600)),
          if (pos + len < end) TextSpan(text: '${after.trimRight()}…', style: GoogleFonts.inter(color: dim, fontSize: 13)),
        ]),
      ),
      subtitle: Text('Page ${pg + 1}', style: GoogleFonts.inter(color: darkMode ? const Color(0xFF555555) : const Color(0xFF999999), fontSize: 11)),
      onTap: () => onNavigate(pos),
    );
  }
}

class HighlightBanner extends StatelessWidget {
  final bool darkMode;
  final bool hasStartPosition;
  final VoidCallback onCancel;

  const HighlightBanner({
    super.key,
    required this.darkMode,
    required this.hasStartPosition,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 56,
      left: 20,
      right: 20,
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: darkMode ? const Color(0xEE000000) : const Color(0xEEF5F5F0),
            border: Border.all(color: const Color(0xFFE05555)),
            borderRadius: BorderRadius.zero,
          ),
          child: Row(
            children: [
              const Icon(Icons.highlight, size: 16, color: Color(0xFFE05555)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  hasStartPosition ? 'Tap end of text to highlight' : 'Tap start of text to highlight',
                  style: GoogleFonts.inter(color: darkMode ? Colors.white : Colors.black87, fontSize: 13),
                ),
              ),
              GestureDetector(
                onTap: onCancel,
                child: const Icon(Icons.close, size: 18, color: Color(0xFF888888)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

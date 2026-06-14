import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/book_storage.dart';
import '../../services/epub_parser.dart';

void showReaderFontDialog(
  BuildContext context,
  String currentFont,
  bool darkMode,
  String filePath,
  ValueChanged<String> onFontChanged,
) {
  final fonts = ['Inter', 'Lora', 'Merriweather', 'Space Mono'];

  showDialog(
    context: context,
    builder: (ctx) => Dialog(
      backgroundColor: darkMode ? const Color(0xFF0F0F0F) : const Color(0xFFF0F0EB),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 16, bottom: 8),
              child: Text('Select font', style: GoogleFonts.inter(color: darkMode ? Colors.white : Colors.black87, fontSize: 15, fontWeight: FontWeight.w600)),
            ),
            ...fonts.map((f) => ListTile(
              dense: true,
              title: Text(f, style: GoogleFonts.getFont(f, fontSize: 16, color: darkMode ? Colors.white : Colors.black87)),
              trailing: currentFont == f ? Icon(Icons.check, size: 18, color: darkMode ? Colors.white : Colors.black87) : null,
              onTap: () {
                onFontChanged(f);
                BookStorage.saveFontFamily(filePath, f);
                Navigator.pop(ctx);
              },
            )),
          ],
        ),
      ),
    ),
  );
}

void showReaderGoToPageDialog(
  BuildContext context,
  int currentPage,
  int totalPages,
  bool darkMode,
  bool hasCover,
  List<int> pageStarts,
  String filePath,
  PageController pageController,
) {
  final coverOff = hasCover ? 1 : 0;
  var target = currentPage + 1;
  final originalPage = currentPage;

  showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setD) => Dialog(
        backgroundColor: darkMode ? const Color(0xFF0F0F0F) : const Color(0xFFF0F0EB),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Go to page', style: GoogleFonts.inter(color: darkMode ? Colors.white : Colors.black87, fontSize: 15, fontWeight: FontWeight.w600)),
              const SizedBox(height: 20),
              Row(
                children: [
                  Text('1', style: GoogleFonts.inter(color: darkMode ? const Color(0xFF555555) : const Color(0xFF999999), fontSize: 12)),
                  Expanded(
                    child: Slider(
                      value: target.toDouble().clamp(1, totalPages.toDouble()),
                      min: 1,
                      max: totalPages.toDouble().clamp(1, 99999),
                      divisions: (totalPages - 1).clamp(0, 999),
                      activeColor: darkMode ? Colors.white : Colors.black87,
                      inactiveColor: darkMode ? const Color(0xFF333333) : const Color(0xFFCCCCCC),
                      onChanged: (v) {
                        setD(() => target = v.round());
                        final tp = v.round() - 1;
                        if (tp >= 0 && tp < totalPages) {
                          pageController.jumpToPage(tp + coverOff);
                        }
                      },
                    ),
                  ),
                  Text('$totalPages', style: GoogleFonts.inter(color: darkMode ? const Color(0xFF555555) : const Color(0xFF999999), fontSize: 12)),
                ],
              ),
              const SizedBox(height: 4),
              Text('Page $target', style: GoogleFonts.inter(color: darkMode ? Colors.white : Colors.black87, fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      final tp = originalPage;
                      if (tp >= 0 && tp < totalPages) {
                        pageController.jumpToPage(tp + coverOff);
                      }
                      Navigator.pop(ctx);
                    },
                    child: Text('Cancel', style: GoogleFonts.inter(color: darkMode ? const Color(0xFF888888) : const Color(0xFF999999), fontSize: 13)),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      final tp = target - 1;
                      if (tp >= 0 && tp < totalPages) {
                        BookStorage.savePosition(filePath, pageStarts[tp]);
                      }
                    },
                    child: Text('Go', style: GoogleFonts.inter(color: darkMode ? Colors.white : Colors.black87, fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

void showReaderToc(
  BuildContext context,
  List<EpubChapter> chapters,
  List<int> chapterStarts,
  int totalChars,
  int position,
  bool darkMode,
  bool hasCover,
  PageController pageController,
  List<int> pageStarts,
  VoidCallback onScheduleHide,
) {
  showModalBottomSheet(
    context: context,
    backgroundColor: darkMode ? const Color(0xFF0F0F0F) : const Color(0xFFF0F0EB),
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
    builder: (ctx) => Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Text('Contents', style: GoogleFonts.inter(color: darkMode ? Colors.white : Colors.black87, fontSize: 16, fontWeight: FontWeight.w600)),
          ),
          Container(color: darkMode ? const Color(0xFF141414) : const Color(0xFFDDDDD8), height: 0.5),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: chapters.length,
              itemBuilder: (_, i) {
                final next = i < chapterStarts.length - 1 ? chapterStarts[i + 1] : totalChars;
                final cur = position >= chapterStarts[i] && position < next;
                return ListTile(
                  dense: true,
                  leading: Text('${i + 1}', style: GoogleFonts.inter(color: darkMode ? const Color(0xFF555555) : const Color(0xFF999999), fontSize: 13)),
                  title: Text(
                    chapters[i].title,
                    style: GoogleFonts.inter(color: cur ? (darkMode ? Colors.white : Colors.black87) : (darkMode ? const Color(0xFFAAAAAA) : const Color(0xFF666666)), fontSize: 14, fontWeight: cur ? FontWeight.w600 : FontWeight.w400),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  selected: cur,
                  selectedTileColor: darkMode ? const Color(0xFF1A1A1A) : const Color(0xFFE8E8E3),
                  onTap: () {
                    Navigator.pop(ctx);
                    final pos = chapterStarts[i];
                    final page = _findPage(pos, pageStarts);
                    final coverOff = hasCover ? 1 : 0;
                    pageController.jumpToPage(page + coverOff);
                  },
                );
              },
            ),
          ),
        ],
      ),
    ),
  ).then((_) => onScheduleHide());
}

int _findPage(int pos, List<int> pageStarts) {
  for (var i = pageStarts.length - 1; i >= 0; i--) {
    if (pageStarts[i] <= pos) return i;
  }
  return 0;
}

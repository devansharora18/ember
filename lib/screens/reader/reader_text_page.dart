import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../services/epub_parser.dart';

class ReaderTextPage extends StatelessWidget {
  final String text;
  final EdgeInsets padding;
  final int pageStart;
  final double fontSize;
  final String fontFamily;
  final bool darkMode;
  final List<EpubChapter> chapters;
  final List<Map<String, int>> highlights;
  final bool highlightModeActive;
  final bool rsvpPickActive;
  final void Function(TapDownDetails, String, GlobalKey) onTapWord;

  const ReaderTextPage({
    super.key,
    required this.text,
    required this.padding,
    required this.pageStart,
    required this.fontSize,
    required this.fontFamily,
    required this.darkMode,
    required this.chapters,
    required this.highlights,
    this.highlightModeActive = false,
    this.rsvpPickActive = false,
    required this.onTapWord,
  });

  TextStyle _style({double? fontSize, Color? color, FontWeight? fontWeight, double? height, double? letterSpacing}) {
    final base = GoogleFonts.getFont(
      fontFamily,
      fontSize: fontSize ?? this.fontSize,
      fontWeight: fontWeight ?? FontWeight.w400,
      color: color ?? (darkMode ? const Color(0xFFCCCCCC) : const Color(0xFF1A1A1A)),
      letterSpacing: letterSpacing,
    );
    return height != null ? base.copyWith(height: height) : base;
  }

  @override
  Widget build(BuildContext context) {
    final key = GlobalKey();
    final isChapter = _isChapterStart();
    final normStyle = _style(height: 1.7);
    final pageEnd = pageStart + text.length;

    final pageHighlights = highlights
        .where((h) => h['s']! < pageEnd && h['e']! > pageStart)
        .toList();

    final content = pageHighlights.isEmpty
        ? Text(text, key: key, style: normStyle)
        : _buildHighlightedText(key, normStyle, pageHighlights);

    final gestureDetector = GestureDetector(
      onDoubleTapDown: highlightModeActive ? null : (d) => onTapWord(d, text, key),
      onTapDown: (rsvpPickActive || highlightModeActive) ? (d) => onTapWord(d, text, key) : null,
      child: content,
    );

    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(24, padding.top + 48, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isChapter) ...[
            _chapterHeader(),
            const SizedBox(height: 12),
          ],
          gestureDetector,
        ],
      ),
    );
  }

  Widget _buildHighlightedText(GlobalKey key, TextStyle normStyle, List<Map<String, int>> pageHighlights) {
    final hlStyle = _style(
      height: 1.7,
      color: darkMode ? const Color(0xFF000000) : const Color(0xFFFFFFFF),
    );
    final hlBg = darkMode ? const Color(0xAAFFFFFF) : const Color(0xAA000000);
    final spans = <TextSpan>[];
    var pos = 0;

    for (final hl in pageHighlights) {
      final localStart = (hl['s']! - pageStart).clamp(0, text.length);
      final localEnd = (hl['e']! - pageStart).clamp(0, text.length);
      if (localStart > pos) {
        spans.add(TextSpan(text: text.substring(pos, localStart), style: normStyle));
      }
      if (localEnd > localStart) {
        spans.add(TextSpan(
          text: text.substring(localStart, localEnd),
          style: hlStyle.copyWith(backgroundColor: hlBg),
        ));
      }
      pos = localEnd;
    }
    if (pos < text.length) {
      spans.add(TextSpan(text: text.substring(pos), style: normStyle));
    }
    return RichText(key: key, text: TextSpan(children: spans));
  }

  bool _isChapterStart() {
    for (final ch in chapters) {
      if (text.startsWith('${ch.title}\n')) return true;
    }
    return false;
  }

  Widget _chapterHeader() {
    for (final ch in chapters) {
      if (text.startsWith('${ch.title}\n')) {
        return Text(
          ch.title,
          style: _style(
            fontSize: fontSize * 0.7,
            fontWeight: FontWeight.w500,
            letterSpacing: 2,
          ),
        );
      }
    }
    return const SizedBox.shrink();
  }
}

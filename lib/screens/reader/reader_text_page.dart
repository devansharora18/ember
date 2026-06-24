import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/format_range.dart';

class ReaderTextPage extends StatelessWidget {
  final String text;
  final EdgeInsets padding;
  final int pageStart;
  final double fontSize;
  final String fontFamily;
  final bool darkMode;
  final List<Map<String, int>> highlights;
  final List<FormatRange> formatRanges;
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
    required this.highlights,
    this.formatRanges = const [],
    this.highlightModeActive = false,
    this.rsvpPickActive = false,
    required this.onTapWord,
  });

  TextStyle _style({
    double? fontSize,
    Color? color,
    FontWeight? fontWeight,
    FontStyle? fontStyle,
    double? height,
    double? letterSpacing,
  }) {
    final base = GoogleFonts.getFont(
      fontFamily,
      fontSize: fontSize ?? this.fontSize,
      fontWeight: fontWeight ?? FontWeight.w400,
      fontStyle: fontStyle ?? FontStyle.normal,
      color:
          color ??
          (darkMode ? const Color(0xFFCCCCCC) : const Color(0xFF1A1A1A)),
      letterSpacing: letterSpacing,
    );
    return height != null ? base.copyWith(height: height) : base;
  }

  @override
  Widget build(BuildContext context) {
    final key = GlobalKey();
    final pageEnd = pageStart + text.length;

    final pageHighlights = highlights
        .where((h) => h['s']! < pageEnd && h['e']! > pageStart)
        .toList();

    final pageFormats = formatRanges
        .where((r) => r.start < pageEnd && r.end > pageStart)
        .toList();

    final content = (pageFormats.isEmpty && pageHighlights.isEmpty)
        ? Text(text, key: key, style: _style(height: 1.7))
        : _buildRichText(key, pageHighlights, pageFormats);

    final gestureDetector = GestureDetector(
      onDoubleTapDown: highlightModeActive
          ? null
          : (d) => onTapWord(d, text, key),
      onTapDown: (rsvpPickActive || highlightModeActive)
          ? (d) => onTapWord(d, text, key)
          : null,
      child: content,
    );

    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(24, padding.top + 48, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [gestureDetector],
      ),
    );
  }

  Widget _buildRichText(
    GlobalKey key,
    List<Map<String, int>> pageHighlights,
    List<FormatRange> pageFormats,
  ) {
    final hlStyle = _style(
      height: 1.7,
      color: darkMode ? const Color(0xFF000000) : const Color(0xFFFFFFFF),
    );
    final hlBg = darkMode ? const Color(0xAAFFFFFF) : const Color(0xAA000000);

    final breakPoints = <int>{0, text.length};
    for (final h in pageHighlights) {
      breakPoints.add((h['s']! - pageStart).clamp(0, text.length));
      breakPoints.add((h['e']! - pageStart).clamp(0, text.length));
    }
    for (final r in pageFormats) {
      breakPoints.add((r.start - pageStart).clamp(0, text.length));
      breakPoints.add((r.end - pageStart).clamp(0, text.length));
    }
    final sorted = breakPoints.toList()..sort();

    final spans = <TextSpan>[];
    for (var i = 0; i < sorted.length - 1; i++) {
      final s = sorted[i];
      final e = sorted[i + 1];
      if (s >= e) continue;
      final mid = (s + e) ~/ 2;
      final globalMid = pageStart + mid;

      final isHighlighted = pageHighlights.any(
        (h) => h['s']! <= globalMid && h['e']! > globalMid,
      );

      var isBold = false;
      var isItalic = false;
      for (final r in pageFormats) {
        if (r.start <= globalMid && r.end > globalMid) {
          if (r.bold) isBold = true;
          if (r.italic) isItalic = true;
        }
      }

      TextStyle spanStyle;
      if (isHighlighted) {
        spanStyle = hlStyle.copyWith(
          backgroundColor: hlBg,
          fontWeight: isBold ? FontWeight.w700 : FontWeight.w400,
          fontStyle: isItalic ? FontStyle.italic : FontStyle.normal,
        );
      } else {
        spanStyle = _style(
          height: 1.7,
          fontWeight: isBold ? FontWeight.w700 : FontWeight.w400,
          fontStyle: isItalic ? FontStyle.italic : FontStyle.normal,
        );
      }

      spans.add(TextSpan(text: text.substring(s, e), style: spanStyle));
    }

    return RichText(key: key, text: TextSpan(children: spans));
  }
}

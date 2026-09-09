import 'package:flutter/material.dart';

class ReaderPageLayout {
  final String fullText;
  final List<int> chapterStarts;
  final double fontSize;
  final String fontFamily;

  ReaderPageLayout({
    required this.fullText,
    required this.chapterStarts,
    required this.fontSize,
    required this.fontFamily,
  });

  TextStyle _applyStyle(TextStyle Function(double?) styleBuilder) =>
      styleBuilder(fontSize).copyWith(height: 1.7);

  // Measures the real average chars-per-line and line height by laying out a
  // representative slice of the document, accounting for word-wrapping. This
  // is cheap (single small layout) and accurate, unlike a fixed-character
  // heuristic which under- or over-fills the page.
  double _lineHeight(BuildContext context, TextStyle Function(double?) styleBuilder) {
    final painter = TextPainter(
      text: TextSpan(text: 'X', style: _applyStyle(styleBuilder)),
      textDirection: TextDirection.ltr,
    )..layout();
    final h = (painter.height as double?) ?? 1.0;
    painter.dispose();
    return h > 0 ? h : 1.0;
  }

  double _avgCharsPerLine(double width, TextStyle Function(double?) styleBuilder) {
    final sampleLength = fullText.length < 4000 ? fullText.length : 4000;
    if (sampleLength == 0) return 1;
    final sample = fullText.substring(0, sampleLength);
    final painter = TextPainter(
      text: TextSpan(text: sample, style: _applyStyle(styleBuilder)),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: width);
    final lines = painter.computeLineMetrics().length;
    painter.dispose();
    return lines > 0 ? sampleLength / lines : 1;
  }

  int charsPerPage(BuildContext context, TextStyle Function(double?) styleBuilder) {
    final s = MediaQuery.of(context).size;
    final p = MediaQuery.of(context).padding;
    const tp = EdgeInsets.fromLTRB(24, 48, 24, 0);
    final w = s.width - tp.left - tp.right;
    final h = s.height - p.top - p.bottom - tp.top - tp.bottom;
    if (w <= 0 || h <= 0) return 1000;
    final lineHeight = _lineHeight(context, styleBuilder);
    final linesPerPage = (h / lineHeight).floor().clamp(1, 9999);
    final avgCpl = _avgCharsPerLine(w, styleBuilder);
    return (avgCpl * linesPerPage).floor().clamp(1, 1000000);
  }

  int colsPerLine(BuildContext context, TextStyle Function(double?) styleBuilder) {
    final s = MediaQuery.of(context).size;
    const tp = EdgeInsets.fromLTRB(24, 48, 24, 0);
    final w = s.width - tp.left - tp.right;
    if (w <= 0) return 80;
    return _avgCharsPerLine(w, styleBuilder).ceil().clamp(1, 9999);
  }

  List<int> computePageBreaks(int cpp, int cols) {
    if (cpp <= 0) return [0];
    final breaks = <int>[0];
    while (breaks.last < fullText.length) {
      var end = (breaks.last + cpp).clamp(0, fullText.length);
      var chapterTruncated = false;

      final nextChapter = chapterStarts.cast<int?>().firstWhere(
        (cs) => cs! > breaks.last,
        orElse: () => null,
      );
      if (nextChapter != null && nextChapter < end) {
        end = nextChapter;
        chapterTruncated = true;
      }

      if (!chapterTruncated) {
        final segment = fullText.substring(breaks.last, end);
        final newlineCount = '\n'.allMatches(segment).length;
        final penalty = newlineCount * (cols ~/ 2);
        final minEnd = (breaks.last + 1).clamp(0, end);
        end = (end - penalty).clamp(minEnd, end);
      }

      if (end < fullText.length) {
        var back = end;
        while (back > breaks.last && back > end - 80 &&
            fullText[back] != ' ' && fullText[back] != '\n') {
          back--;
        }
        if (back > breaks.last &&
            (fullText[back] == ' ' || fullText[back] == '\n')) {
          end = back + 1;
        }
      }
      breaks.add(end);
    }
    return breaks;
  }

  int findPageForPosition(int pos, List<int> pageStarts) {
    for (var i = pageStarts.length - 1; i >= 0; i--) {
      if (pageStarts[i] <= pos) return i;
    }
    return 0;
  }
}
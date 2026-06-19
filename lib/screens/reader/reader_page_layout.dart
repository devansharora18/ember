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

  int charsPerPage(BuildContext context, TextStyle Function(double?) styleBuilder) {
    final s = MediaQuery.of(context).size;
    final p = MediaQuery.of(context).padding;
    const tp = EdgeInsets.fromLTRB(24, 48, 24, 0);
    final w = s.width - tp.left - tp.right;
    final h = s.height - p.top - p.bottom - tp.top - tp.bottom;
    if (w <= 0 || h <= 0) return 1000;
    final painter = TextPainter(
      text: TextSpan(text: 'X', style: styleBuilder(fontSize).copyWith(height: 1.7)),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: w);
    final cols = (w / painter.width).ceil().clamp(1, 999);
    final rows = (h / painter.height).ceil().clamp(1, 999);
    return cols * rows;
  }

  int colsPerLine(BuildContext context, TextStyle Function(double?) styleBuilder) {
    final s = MediaQuery.of(context).size;
    final p = MediaQuery.of(context).padding;
    const tp = EdgeInsets.fromLTRB(24, 48, 24, 0);
    final w = s.width - tp.left - tp.right;
    if (w <= 0) return 80;
    final painter = TextPainter(
      text: TextSpan(text: 'X', style: styleBuilder(fontSize).copyWith(height: 1.7)),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: w);
    return (w / painter.width).ceil().clamp(1, 999);
  }

  List<int> computePageBreaks(int cpp, int cols) {
    if (cpp <= 0) return [0];
    final breaks = <int>[0];
    while (breaks.last < fullText.length) {
      var end = (breaks.last + cpp).clamp(0, fullText.length);

      final nextChapter = chapterStarts.cast<int?>().firstWhere(
        (cs) => cs! > breaks.last,
        orElse: () => null,
      );
      if (nextChapter != null && nextChapter < end) {
        end = nextChapter;
      }

      final segment = fullText.substring(breaks.last, end);
      final newlineCount = '\n'.allMatches(segment).length;
      final penalty = newlineCount * (cols ~/ 2);
      final minEnd = (breaks.last + 1).clamp(0, end);
      end = (end - penalty).clamp(minEnd, end);

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

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/book.dart';
import '../services/book_storage.dart';
import '../services/epub_parser.dart';

class ReaderScreen extends StatefulWidget {
  final Book book;

  const ReaderScreen({super.key, required this.book});

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  List<EpubChapter> _chapters = [];
  bool _loading = true;
  double _fontSize = 16;
  final _pageController = PageController();

  String _fullText = '';
  int _totalChars = 0;
  int _position = 0;
  int _currentPage = 0;
  int _totalPages = 1;
  List<int> _pageStarts = [0];
  final List<int> _chapterStarts = [];

  bool _controlsVisible = true;
  Timer? _hideTimer;

  static const _minFontSize = 12.0;
  static const _maxFontSize = 24.0;
  static const _autoHideDelay = Duration(seconds: 3);

  @override
  void initState() {
    super.initState();
    _pageController.addListener(_onPageScrolling);
    _loadContent();
  }

  void _onPageScrolling() {
    if (!_pageController.hasClients || !mounted) return;
    final page = _pageController.page;
    if (page == null) return;
    final coverPageCount = widget.book.coverBytes != null ? 1 : 0;
    final rounded = page.round();
    final textPage = (rounded - coverPageCount).clamp(0, _pageStarts.length - 1);
    if (textPage != _currentPage && textPage >= 0 && textPage < _pageStarts.length) {
      setState(() => _currentPage = textPage);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _hideTimer?.cancel();
    super.dispose();
  }

  void _scheduleHide() {
    _hideTimer?.cancel();
    _hideTimer = Timer(_autoHideDelay, () {
      if (mounted) setState(() => _controlsVisible = false);
    });
  }

  void _toggleControls() {
    setState(() {
      _controlsVisible = !_controlsVisible;
    });
    if (_controlsVisible) {
      _scheduleHide();
    } else {
      _hideTimer?.cancel();
    }
  }

  Future<void> _loadContent() async {
    final chapters = await Future(() => EpubParser.extractChapters(widget.book.filePath));
    final savedPos = await BookStorage.loadPosition(widget.book.filePath);
    final savedFontSize = await BookStorage.loadFontSize(widget.book.filePath);
    if (!mounted) return;

    final buf = StringBuffer();
    final chapterStarts = <int>[];
    for (final ch in chapters) {
      chapterStarts.add(buf.length);
      buf.writeln(ch.title);
      buf.writeln();
      buf.writeln(ch.content);
      buf.writeln();
    }
    final text = buf.toString();
    final totalChars = text.length;

    setState(() {
      _chapters = chapters;
      _fullText = text;
      _totalChars = totalChars;
      _position = savedPos.clamp(0, totalChars);
      _chapterStarts
        ..clear()
        ..addAll(chapterStarts);
      if (savedFontSize != null) {
        _fontSize = savedFontSize.clamp(_minFontSize, _maxFontSize);
      }
      _loading = false;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final page = _findPageForPosition(_position);
      final coverOffset = widget.book.coverBytes != null ? 1 : 0;
      _pageController.jumpToPage(page + coverOffset);
    });

    _scheduleHide();
  }

  int _charsPerPage(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final padding = MediaQuery.of(context).padding;
    final textPadding = const EdgeInsets.fromLTRB(24, 48, 24, 8);
    final width = size.width - textPadding.left - textPadding.right;
    final height = size.height - padding.top - padding.bottom - textPadding.top - textPadding.bottom;
    if (width <= 0 || height <= 0) return 1000;

    final tp = TextPainter(
      text: TextSpan(text: 'X', style: GoogleFonts.inter(fontSize: _fontSize, height: 1.7)),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: width);

    final charsPerLine = (width / tp.width).floor().clamp(1, 999);
    final lineHeight = tp.height;
    final linesPerPage = (height / lineHeight).floor().clamp(1, 999);
    return charsPerLine * linesPerPage;
  }

  int _findPageForPosition(int position) {
    for (var i = _pageStarts.length - 1; i >= 0; i--) {
      if (_pageStarts[i] <= position) return i;
    }
    return 0;
  }

  List<int> _computePageBreaks(int cpp) {
    if (cpp <= 0) return [0];
    final breaks = <int>[0];
    while (breaks.last < _fullText.length) {
      var end = (breaks.last + cpp).clamp(0, _fullText.length);
      if (end < _fullText.length) {
        var adjusted = end;
        while (adjusted > breaks.last && adjusted > end - 80 && _fullText[adjusted] != ' ' && _fullText[adjusted] != '\n') {
          adjusted--;
        }
        if (adjusted > breaks.last && (_fullText[adjusted] == ' ' || _fullText[adjusted] == '\n')) {
          end = adjusted + 1;
        }
      }
      breaks.add(end);
    }
    return breaks;
  }

  void _onPageChanged(int page) {
    if (_chapters.isEmpty || page >= _pageStarts.length) return;
    _currentPage = page;
    _position = _pageStarts[page];
    BookStorage.savePosition(widget.book.filePath, _position);
  }

  void _setFontSize(double delta) {
    final oldPosition = _position;
    final coverOffset = widget.book.coverBytes != null ? 1 : 0;

    setState(() {
      _fontSize = (_fontSize + delta).clamp(_minFontSize, _maxFontSize);
    });

    BookStorage.saveFontSize(widget.book.filePath, _fontSize);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      setState(() {
        _currentPage = _findPageForPosition(oldPosition);
        _totalPages = _pageStarts.length - 1;
      });

      _pageController.jumpToPage(_currentPage + coverOffset);
    });
  }

  void _jumpToChapter(int index) {
    if (_chapters.isEmpty) return;
    final pos = _chapterPosition(index);
    final page = _findPageForPosition(pos);
    final coverOffset = widget.book.coverBytes != null ? 1 : 0;
    setState(() => _position = pos);
    _pageController.jumpToPage(page + coverOffset);
  }

  void _showToc() {
    _hideTimer?.cancel();
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F0F0F),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      builder: (ctx) => Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Text('Contents', style: GoogleFonts.inter(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
            ),
            Container(color: const Color(0xFF141414), height: 0.5),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: _chapters.length,
                itemBuilder: (_, i) {
                  final nextPos = i < _chapterStarts.length - 1 ? _chapterStarts[i + 1] : _totalChars;
                  final isCurrent = _position >= _chapterStarts[i] && _position < nextPos;
                  return ListTile(
                    dense: true,
                    leading: Text('${i + 1}', style: GoogleFonts.inter(color: const Color(0xFF555555), fontSize: 13)),
                    title: Text(
                      _chapters[i].title,
                      style: GoogleFonts.inter(color: isCurrent ? Colors.white : const Color(0xFFAAAAAA), fontSize: 14, fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w400),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    selected: isCurrent,
                    selectedTileColor: const Color(0xFF1A1A1A),
                    onTap: () {
                      Navigator.pop(ctx);
                      _jumpToChapter(i);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    ).then((_) => _scheduleHide());
  }

  int _chapterPosition(int chapterIndex) {
    if (chapterIndex < _chapterStarts.length) return _chapterStarts[chapterIndex];
    return _totalChars;
  }

  @override
  Widget build(BuildContext context) {
    final book = widget.book;

    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      body: _loading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Color(0xFF333333))))
          : _chapters.isEmpty
              ? Center(child: Text('No readable content', style: GoogleFonts.inter(color: const Color(0xFF555555), fontSize: 14)))
              : _buildReader(book),
    );
  }

  Widget _buildReader(Book book) {
    final cpp = _charsPerPage(context);
    _pageStarts = _computePageBreaks(cpp);
    _totalPages = _pageStarts.length - 1;
    final coverPageCount = book.coverBytes != null ? 1 : 0;
    final padding = MediaQuery.of(context).padding;

    return GestureDetector(
      onTap: _toggleControls,
      behavior: HitTestBehavior.translucent,
      child: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            onPageChanged: (page) {
              if (page == 0 && coverPageCount > 0) {
                _currentPage = 0;
                return;
              }
              final textPage = page - coverPageCount;
              _onPageChanged(textPage);
            },
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: _totalPages + coverPageCount,
            itemBuilder: (context, pageIndex) {
              if (coverPageCount > 0 && pageIndex == 0) {
                return _buildCoverPage(book);
              }
              final textPageIndex = pageIndex - coverPageCount;
              final start = _pageStarts[textPageIndex];
              final end = textPageIndex + 1 < _pageStarts.length ? _pageStarts[textPageIndex + 1] : _fullText.length;
              final pageText = _fullText.substring(start, end);
              return _buildTextPage(pageText, padding);
            },
          ),
          AnimatedOpacity(
            opacity: _controlsVisible ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 250),
            child: IgnorePointer(
              ignoring: !_controlsVisible,
              child: _buildAppBar(book, padding),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildBottomBar(book, coverPageCount),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(Book book, EdgeInsets padding) {
    return Container(
      padding: EdgeInsets.only(top: padding.top),
      color: const Color(0xDD000000),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 22),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Text(
              book.title,
              style: GoogleFonts.inter(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500, letterSpacing: 0.5),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(icon: const Icon(Icons.text_decrease, color: Colors.white, size: 20), onPressed: () { _hideTimer?.cancel(); _setFontSize(-1); _scheduleHide(); }),
          IconButton(icon: const Icon(Icons.text_increase, color: Colors.white, size: 20), onPressed: () { _hideTimer?.cancel(); _setFontSize(1); _scheduleHide(); }),
          IconButton(icon: const Icon(Icons.list, color: Colors.white, size: 20), onPressed: _showToc),
        ],
      ),
    );
  }

  Widget _buildBottomBar(Book book, int coverPageCount) {
    final padding = MediaQuery.of(context).padding;
    return Container(
      padding: EdgeInsets.only(bottom: padding.bottom),
      color: const Color(0xDD000000),
      child: SizedBox(
        height: 36,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              if (coverPageCount > 0 && _pageController.hasClients && _pageController.page?.round() == 0)
                Text('Cover', style: GoogleFonts.inter(color: const Color(0xFF888888), fontSize: 11))
              else ...[
                Text('${_currentPage + 1} / $_totalPages', style: GoogleFonts.inter(color: const Color(0xFF888888), fontSize: 11)),
                const SizedBox(width: 12),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.zero,
                    child: LinearProgressIndicator(
                      value: _totalPages > 1 ? (_currentPage / (_totalPages - 1)).clamp(0.0, 1.0) : 0,
                      backgroundColor: const Color(0xFF1A1A1A),
                      valueColor: const AlwaysStoppedAnimation(Color(0xFF444444)),
                      minHeight: 2,
                    ),
                  ),
                ),
              ],
              const Spacer(),
              Text('${_fontSize.round()}', style: GoogleFonts.inter(color: const Color(0xFF888888), fontSize: 11)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCoverPage(Book book) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ClipRRect(
          borderRadius: BorderRadius.zero,
          child: Image.memory(book.coverBytes!, fit: BoxFit.contain),
        ),
      ),
    );
  }

  Widget _buildTextPage(String text, EdgeInsets padding) {
    final isChapterStart = _isChapterStart(text);
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(24, padding.top + 48, 24, padding.bottom + 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isChapterStart) ...[
            _buildChapterHeader(text),
            const SizedBox(height: 12),
          ],
          Text(
            text,
            style: GoogleFonts.inter(color: const Color(0xFFCCCCCC), fontSize: _fontSize, fontWeight: FontWeight.w400, height: 1.7),
          ),
        ],
      ),
    );
  }

  bool _isChapterStart(String text) {
    for (final ch in _chapters) {
      if (text.startsWith('${ch.title}\n')) return true;
    }
    return false;
  }

  Widget _buildChapterHeader(String text) {
    for (final ch in _chapters) {
      if (text.startsWith('${ch.title}\n')) {
        return Text(
          ch.title,
          style: GoogleFonts.inter(color: Colors.white, fontSize: _fontSize * 0.7, fontWeight: FontWeight.w500, letterSpacing: 2),
        );
      }
    }
    return const SizedBox.shrink();
  }
}

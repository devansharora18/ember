import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/book.dart';
import '../../providers/book_list_provider.dart';
import '../../services/book_storage.dart';
import '../../services/epub_parser.dart';
import 'reader/reader_controls.dart';
import 'reader/reader_dialogs.dart';
import 'reader/reader_dictionary_dialog.dart';
import 'reader/reader_rsvp_screen.dart';

class ReaderScreen extends ConsumerStatefulWidget {
  final Book book;

  const ReaderScreen({super.key, required this.book});

  @override
  ConsumerState<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends ConsumerState<ReaderScreen> {
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
  bool _darkMode = true;
  String _fontFamily = 'Inter';
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

  @override
  void dispose() {
    _saveProgress();
    _pageController.dispose();
    _hideTimer?.cancel();
    super.dispose();
  }

  void _onPageScrolling() {
    if (!_pageController.hasClients || !mounted) return;
    final page = _pageController.page;
    if (page == null) return;
    final coverCount = widget.book.coverBytes != null ? 1 : 0;
    final rounded = page.round();
    final textPage = (rounded - coverCount).clamp(0, _pageStarts.length - 1);
    if (textPage != _currentPage && textPage >= 0 && textPage < _pageStarts.length) {
      setState(() => _currentPage = textPage);
    }
  }

  void _scheduleHide() {
    _hideTimer?.cancel();
    _hideTimer = Timer(_autoHideDelay, () {
      if (mounted) setState(() => _controlsVisible = false);
    });
  }

  void _toggleControls() {
    setState(() => _controlsVisible = !_controlsVisible);
    if (_controlsVisible) { _scheduleHide(); } else { _hideTimer?.cancel(); }
  }

  // --------------- Content loading ---------------

  Future<void> _loadContent() async {
    final chapters = await Future(() => EpubParser.extractChapters(widget.book.filePath));
    final savedPos = await BookStorage.loadPosition(widget.book.filePath);
    final savedFontSize = await BookStorage.loadFontSize(widget.book.filePath);
    final savedFontFamily = await BookStorage.loadFontFamily(widget.book.filePath);
    final savedDarkMode = await BookStorage.loadDarkMode(widget.book.filePath);
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
      _chapterStarts..clear()..addAll(chapterStarts);
      if (savedFontSize != null) _fontSize = savedFontSize.clamp(_minFontSize, _maxFontSize);
      if (savedFontFamily != null) _fontFamily = savedFontFamily;
      if (savedDarkMode != null) _darkMode = savedDarkMode;
      _loading = false;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final page = _findPageForPosition(_position);
      final coverOff = widget.book.coverBytes != null ? 1 : 0;
      _pageController.jumpToPage(page + coverOff);
    });

    ref.read(bookListProvider.notifier).touchBook(widget.book.filePath);
    _scheduleHide();
  }

  // --------------- Page layout ---------------

  int _charsPerPage(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final pad = MediaQuery.of(context).padding;
    final tp = const EdgeInsets.fromLTRB(24, 48, 24, 4);
    final w = size.width - tp.left - tp.right;
    final h = size.height - pad.top - pad.bottom - tp.top - tp.bottom;
    if (w <= 0 || h <= 0) return 1000;
    final painter = TextPainter(text: TextSpan(text: 'X', style: _textStyle(height: 1.7)), textDirection: TextDirection.ltr)..layout(maxWidth: w);
    return (w / painter.width).floor().clamp(1, 999) * (h / painter.height).floor().clamp(1, 999);
  }

  int _findPageForPosition(int position) {
    for (var i = _pageStarts.length - 1; i >= 0; i--) { if (_pageStarts[i] <= position) return i; }
    return 0;
  }

  List<int> _computePageBreaks(int cpp) {
    if (cpp <= 0) return [0];
    final breaks = <int>[0];
    while (breaks.last < _fullText.length) {
      var end = (breaks.last + cpp).clamp(0, _fullText.length);
      if (end < _fullText.length) {
        var adj = end;
        while (adj > breaks.last && adj > end - 80 && _fullText[adj] != ' ' && _fullText[adj] != '\n') { adj--; }
        if (adj > breaks.last && (_fullText[adj] == ' ' || _fullText[adj] == '\n')) end = adj + 1;
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

  // --------------- Font & mode ---------------

  TextStyle _textStyle({double? fontSize, Color? color, FontWeight? fontWeight, double? height, double? letterSpacing}) {
    return GoogleFonts.getFont(_fontFamily, fontSize: fontSize ?? _fontSize, fontWeight: fontWeight ?? FontWeight.w400, color: color ?? (_darkMode ? const Color(0xFFCCCCCC) : const Color(0xFF1A1A1A)), height: height, letterSpacing: letterSpacing);
  }

  void _setFontSize(double delta) {
    final oldPos = _position;
    final coverOff = widget.book.coverBytes != null ? 1 : 0;
    setState(() => _fontSize = (_fontSize + delta).clamp(_minFontSize, _maxFontSize));
    BookStorage.saveFontSize(widget.book.filePath, _fontSize);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() { _currentPage = _findPageForPosition(oldPos); _totalPages = _pageStarts.length - 1; });
      _pageController.jumpToPage(_currentPage + coverOff);
    });
  }

  void _handleMenuAction(String value) {
    _hideTimer?.cancel();
    switch (value) {
      case 'select_font':
        showReaderFontDialog(context, _fontFamily, _darkMode, widget.book.filePath, (f) => setState(() => _fontFamily = f));
        _scheduleHide();
        return;
      case 'go_to_page':
        showReaderGoToPageDialog(context, _currentPage, _totalPages, _darkMode, widget.book.coverBytes != null, _pageStarts, widget.book.filePath, _pageController);
        _scheduleHide();
        return;
      case 'rsvp':
        _openRsvp();
        return;
      case 'toggle_mode':
        setState(() => _darkMode = !_darkMode);
        BookStorage.saveDarkMode(widget.book.filePath, _darkMode);
        break;
    }
    _scheduleHide();
  }

  void _openRsvp() async {
    _hideTimer?.cancel();
    final newPos = await Navigator.push<int>(
      context,
      MaterialPageRoute(
        builder: (_) => RsvpScreen(
          fullText: _fullText,
          startPosition: _position,
          totalChars: _totalChars,
          fontFamily: _fontFamily,
          darkMode: _darkMode,
        ),
      ),
    );
    if (newPos != null && mounted) {
      _position = newPos.clamp(0, _totalChars);
      _currentPage = _findPageForPosition(_position);
      final coverOff = widget.book.coverBytes != null ? 1 : 0;
      _pageController.jumpToPage(_currentPage + coverOff);
      BookStorage.savePosition(widget.book.filePath, _position);
      _saveProgress();
    }
    _scheduleHide();
  }

  // --------------- Progress ---------------

  void _saveProgress() {
    if (_totalChars <= 0) return;
    final p = _position / _totalChars;
    final idx = ref.read(bookListProvider).indexWhere((b) => b.filePath == widget.book.filePath);
    if (idx != -1) ref.read(bookListProvider.notifier).editBook(idx, progress: p);
  }

  // --------------- Dictionary ---------------

  void _handleDoubleTap(TapDownDetails details, String text, GlobalKey textKey) {
    final rb = textKey.currentContext?.findRenderObject() as RenderBox?;
    if (rb == null || text.isEmpty) return;
    final lp = rb.globalToLocal(details.globalPosition);
    final tp = TextPainter(text: TextSpan(text: text, style: _textStyle(height: 1.7)), textDirection: TextDirection.ltr)..layout(maxWidth: rb.size.width);
    final pos = tp.getPositionForOffset(lp);
    if (pos.offset < 0 || pos.offset >= text.length) return;
    _lookupWord(text, pos.offset);
  }

  void _lookupWord(String text, int index) {
    var s = index, e = index;
    final wc = RegExp(r'[\w]');
    while (s > 0 && wc.hasMatch(text[s - 1])) { s--; }
    while (e < text.length && wc.hasMatch(text[e])) { e++; }
    final word = text.substring(s, e).trim().toLowerCase();
    if (word.length < 2 || word.length > 30) return;
    _hideTimer?.cancel();
    setState(() => _controlsVisible = true);
    showDialog(context: context, builder: (ctx) => DictionaryDialog(word: word)).then((_) => _scheduleHide());
  }

  // --------------- Build ---------------

  @override
  Widget build(BuildContext context) {
    final book = widget.book;
    final bg = _darkMode ? const Color(0xFF000000) : const Color(0xFFF5F5F0);
    return Scaffold(
      backgroundColor: bg,
      body: _loading
          ? Center(child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(_darkMode ? const Color(0xFF333333) : const Color(0xFFCCCCCC))))
          : _chapters.isEmpty
              ? Center(child: Text('No readable content', style: _textStyle(color: _darkMode ? const Color(0xFF555555) : const Color(0xFF999999), fontSize: 14)))
              : _buildReader(book, bg),
    );
  }

  Widget _buildReader(Book book, Color bg) {
    final cpp = _charsPerPage(context);
    _pageStarts = _computePageBreaks(cpp);
    _totalPages = _pageStarts.length - 1;
    final coverCount = book.coverBytes != null ? 1 : 0;
    final pad = MediaQuery.of(context).padding;
    final hasCover = book.coverBytes != null;

    return GestureDetector(
      onTap: _toggleControls,
      behavior: HitTestBehavior.translucent,
      child: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            onPageChanged: (page) { if (page == 0 && coverCount > 0) { _currentPage = 0; return; } _onPageChanged(page - coverCount); },
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: _totalPages + coverCount,
            itemBuilder: (context, pageIndex) {
              if (coverCount > 0 && pageIndex == 0) return _buildCoverPage(book, bg);
              final tp = pageIndex - coverCount;
              final start = _pageStarts[tp];
              final end = tp + 1 < _pageStarts.length ? _pageStarts[tp + 1] : _fullText.length;
              return _buildTextPage(_fullText.substring(start, end), pad);
            },
          ),
          AnimatedOpacity(
            opacity: _controlsVisible ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 250),
            child: IgnorePointer(
              ignoring: !_controlsVisible,
              child: ReaderAppBar(
                title: book.title,
                darkMode: _darkMode,
                padding: pad,
                onBack: () { _saveProgress(); Navigator.pop(context); },
                onDecreaseFont: () { _hideTimer?.cancel(); _setFontSize(-1); _scheduleHide(); },
                onIncreaseFont: () { _hideTimer?.cancel(); _setFontSize(1); _scheduleHide(); },
                onShowToc: () {
                  _hideTimer?.cancel();
                  showReaderToc(context, _chapters, _chapterStarts, _totalChars, _position, _darkMode, hasCover, _pageController, _pageStarts, _scheduleHide);
                },
                onMenuAction: _handleMenuAction,
                menuItems: [
                  readerMenuPopItem('RSVP speed read', 'rsvp', _darkMode),
                  readerMenuPopItem('Select font…', 'select_font', _darkMode),
                  readerMenuPopItem('Go to page…', 'go_to_page', _darkMode),
                  readerMenuPopItem(_darkMode ? 'Light mode' : 'Dark mode', 'toggle_mode', _darkMode),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: ReaderBottomBar(
              currentPage: _currentPage + 1,
              totalPages: _totalPages,
              totalChars: _totalChars,
              position: _position,
              darkMode: _darkMode,
              coverCount: coverCount,
              pageController: _pageController,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoverPage(Book book, Color bg) {
    return Container(color: bg, child: Center(child: Padding(padding: const EdgeInsets.all(24), child: ClipRRect(borderRadius: BorderRadius.zero, child: Image.memory(book.coverBytes!, fit: BoxFit.contain)))));
  }

  Widget _buildTextPage(String text, EdgeInsets pad) {
    final isCh = _isChapterStart(text);
    final textKey = GlobalKey();
    return GestureDetector(
      onDoubleTapDown: (d) => _handleDoubleTap(d, text, textKey),
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(24, pad.top + 48, 24, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isCh) ...[_buildChapterHeader(text), const SizedBox(height: 12)],
            Text(text, key: textKey, style: _textStyle(height: 1.7)),
          ],
        ),
      ),
    );
  }

  bool _isChapterStart(String text) {
    for (final ch in _chapters) { if (text.startsWith('${ch.title}\n')) return true; }
    return false;
  }

  Widget _buildChapterHeader(String text) {
    for (final ch in _chapters) { if (text.startsWith('${ch.title}\n')) { return Text(ch.title, style: _textStyle(fontSize: _fontSize * 0.7, fontWeight: FontWeight.w500, letterSpacing: 2)); } }
    return const SizedBox.shrink();
  }
}

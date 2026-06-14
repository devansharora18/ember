import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  bool _goToPageMode = false;
  int _goToOriginalPage = 0;
  Timer? _hideTimer;
  Completer<int?>? _rsvpPickCompleter;
  OverlayEntry? _rsvpOverlay;
  Offset? _tapPosition;

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
    if (_goToPageMode) return;
    _hideTimer?.cancel();
    _hideTimer = Timer(_autoHideDelay, () {
      if (mounted) setState(() => _controlsVisible = false);
    });
  }

  void _toggleControls() {
    if (_goToPageMode) return;
    setState(() => _controlsVisible = !_controlsVisible);
    if (_controlsVisible) { _scheduleHide(); } else { _hideTimer?.cancel(); }
  }

  Future<void> _loadContent() async {
    final chapters = await Future(() {
      if (widget.book.fileBytes != null) return EpubParser.extractChaptersFromBytes(widget.book.fileBytes!);
      return EpubParser.extractChapters(widget.book.filePath);
    });
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
      case 'select_font': showReaderFontDialog(context, _fontFamily, _darkMode, widget.book.filePath, (f) => setState(() => _fontFamily = f)); _scheduleHide(); return;
      case 'go_to_page':
        setState(() { _goToPageMode = true; _goToOriginalPage = _currentPage; _controlsVisible = true; });
        return;
      case 'rsvp': _openRsvp(); return;
      case 'toggle_mode': setState(() => _darkMode = !_darkMode); BookStorage.saveDarkMode(widget.book.filePath, _darkMode); break;
    }
    _scheduleHide();
  }

  void _goToPageSliderChanged(double value) {
    final tp = value.round() - 1;
    if (tp >= 0 && tp < _totalPages) {
      final coverOff = widget.book.coverBytes != null ? 1 : 0;
      _pageController.jumpToPage(tp + coverOff);
      setState(() => _currentPage = tp);
    }
  }

  void _exitGoToPageMode() {
    setState(() => _goToPageMode = false);
    _onPageChanged(_currentPage);
    _scheduleHide();
  }

  void _returnToOriginalPage() {
    final coverOff = widget.book.coverBytes != null ? 1 : 0;
    _pageController.jumpToPage(_goToOriginalPage + coverOff);
    _onPageChanged(_goToOriginalPage);
    setState(() { _goToPageMode = false; _currentPage = _goToOriginalPage; });
    _scheduleHide();
  }

  void _openRsvp() async {
    _hideTimer?.cancel();
    setState(() => _controlsVisible = true);
    final startPos = await _pickRsvpStartWord();
    if (startPos == null || !mounted) { _scheduleHide(); return; }
    final pauseSentences = await _askRsvpPauseSentences();
    if (pauseSentences == null || !mounted) { _scheduleHide(); return; }
    final newPos = await Navigator.push<int>(context, MaterialPageRoute(builder: (_) => RsvpScreen(fullText: _fullText, startPosition: startPos, totalChars: _totalChars, fontFamily: _fontFamily, darkMode: _darkMode, pauseAfterWords: pauseSentences)));
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

  Future<int?> _pickRsvpStartWord() async {
    final completer = Completer<int?>();
    late final OverlayEntry overlay;
    overlay = OverlayEntry(builder: (ctx) => Positioned(top: MediaQuery.of(context).padding.top + 56, left: 20, right: 20, child: Material(color: Colors.transparent, child: Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), decoration: BoxDecoration(color: _darkMode ? const Color(0xEE000000) : const Color(0xEEF5F5F0), border: Border.all(color: _darkMode ? const Color(0xFF444444) : const Color(0xFFAAAAAA)), borderRadius: BorderRadius.zero), child: Row(children: [const Icon(Icons.touch_app, size: 16, color: Color(0xFF888888)), const SizedBox(width: 10), Expanded(child: Text('Tap a word to start RSVP from here', style: GoogleFonts.inter(color: _darkMode ? Colors.white : Colors.black87, fontSize: 13))), GestureDetector(onTap: () { completer.complete(null); overlay.remove(); }, child: const Icon(Icons.close, size: 18, color: Color(0xFF888888)))])))));
    Overlay.of(context).insert(overlay);
    _rsvpPickCompleter = completer;
    _rsvpOverlay = overlay;
    return completer.future;
  }

  Future<int?> _askRsvpPauseSentences() async {
    var count = 1;
    return showDialog<int>(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setD) => Dialog(backgroundColor: _darkMode ? const Color(0xFF0F0F0F) : const Color(0xFFF0F0EB), shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero), child: Padding(padding: const EdgeInsets.fromLTRB(24, 20, 24, 12), child: Column(mainAxisSize: MainAxisSize.min, children: [Text('Auto-pause', style: GoogleFonts.inter(color: _darkMode ? Colors.white : Colors.black87, fontSize: 15, fontWeight: FontWeight.w600)), const SizedBox(height: 16), Text('Pause every N sentences', style: GoogleFonts.inter(color: _darkMode ? const Color(0xFF888888) : const Color(0xFF999999), fontSize: 12)), const SizedBox(height: 8), Row(children: [Text('Off', style: GoogleFonts.inter(color: _darkMode ? const Color(0xFF555555) : const Color(0xFF999999), fontSize: 11)), Expanded(child: Slider(value: count.toDouble(), min: 0, max: 20, divisions: 20, activeColor: _darkMode ? Colors.white : Colors.black87, inactiveColor: _darkMode ? const Color(0xFF333333) : const Color(0xFFCCCCCC), onChanged: (v) => setD(() => count = v.round()))), Text('20', style: GoogleFonts.inter(color: _darkMode ? const Color(0xFF555555) : const Color(0xFF999999), fontSize: 11))]), Text(count == 0 ? 'No auto-pause' : 'Every $count sentences', style: GoogleFonts.inter(color: _darkMode ? Colors.white : Colors.black87, fontSize: 13, fontWeight: FontWeight.w500)), const SizedBox(height: 16), Row(mainAxisAlignment: MainAxisAlignment.end, children: [TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel', style: GoogleFonts.inter(color: _darkMode ? const Color(0xFF888888) : const Color(0xFF999999), fontSize: 13))), const SizedBox(width: 8), TextButton(onPressed: () => Navigator.pop(ctx, count), child: Text('Start', style: GoogleFonts.inter(color: _darkMode ? Colors.white : Colors.black87, fontSize: 13, fontWeight: FontWeight.w600)))])])))));
  }

  void _saveProgress() {
    if (_totalChars <= 0) return;
    final p = _position / _totalChars;
    final idx = ref.read(bookListProvider).indexWhere((b) => b.filePath == widget.book.filePath);
    if (idx != -1) ref.read(bookListProvider.notifier).editBook(idx, progress: p);
  }

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
    if (_rsvpPickCompleter != null) {
      _rsvpOverlay?.remove(); _rsvpOverlay = null;
      final coverCount = widget.book.coverBytes != null ? 1 : 0;
      final page = _pageController.hasClients ? _pageController.page?.round() ?? 0 : 0;
      final textPage = page - coverCount;
      final pageStart = textPage >= 0 && textPage < _pageStarts.length - 1 ? _pageStarts[textPage] : 0;
      _rsvpPickCompleter!.complete(pageStart + s);
      _rsvpPickCompleter = null;
      return;
    }
    final word = text.substring(s, e).trim().toLowerCase();
    if (word.length < 2 || word.length > 30) return;
    _hideTimer?.cancel();
    setState(() => _controlsVisible = true);
    showDialog(context: context, builder: (ctx) => DictionaryDialog(word: word)).then((_) => _scheduleHide());
  }

  @override
  Widget build(BuildContext context) {
    final book = widget.book;
    final bg = _darkMode ? const Color(0xFF000000) : const Color(0xFFF5F5F0);
    return Scaffold(backgroundColor: bg, body: _loading ? Center(child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(_darkMode ? const Color(0xFF333333) : const Color(0xFFCCCCCC)))) : _chapters.isEmpty ? Center(child: Text('No readable content', style: _textStyle(color: _darkMode ? const Color(0xFF555555) : const Color(0xFF999999), fontSize: 14))) : _buildReader(book, bg));
  }

  Widget _buildReader(Book book, Color bg) {
    final cpp = _charsPerPage(context);
    _pageStarts = _computePageBreaks(cpp);
    _totalPages = _pageStarts.length - 1;
    final coverCount = book.coverBytes != null ? 1 : 0;
    final pad = MediaQuery.of(context).padding;
    final hasCover = book.coverBytes != null;
    final scale = _goToPageMode ? 0.85 : 1.0;

    return Focus(
      autofocus: true,
      onKeyEvent: (_, event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.arrowLeft) { _pageController.previousPage(duration: const Duration(milliseconds: 200), curve: Curves.easeInOut); return KeyEventResult.handled; }
          if (event.logicalKey == LogicalKeyboardKey.arrowRight) { _pageController.nextPage(duration: const Duration(milliseconds: 200), curve: Curves.easeInOut); return KeyEventResult.handled; }
        }
        return KeyEventResult.ignored;
      },
      child: Stack(children: [
        Transform.scale(
          scale: scale,
          child: PageView.builder(
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
        ),
        if (!_goToPageMode) Positioned.fill(child: Listener(behavior: HitTestBehavior.translucent, onPointerDown: (e) => _tapPosition = e.localPosition, onPointerUp: (e) { if (_tapPosition != null && (e.localPosition - _tapPosition!).distance < 10 && _rsvpPickCompleter == null) _toggleControls(); _tapPosition = null; })),
        if (!_goToPageMode) AnimatedOpacity(opacity: _controlsVisible ? 1.0 : 0.0, duration: const Duration(milliseconds: 250), child: IgnorePointer(ignoring: !_controlsVisible, child: ReaderAppBar(title: book.title, darkMode: _darkMode, padding: pad, onBack: () { _saveProgress(); Navigator.pop(context); }, onDecreaseFont: () { _hideTimer?.cancel(); _setFontSize(-1); _scheduleHide(); }, onIncreaseFont: () { _hideTimer?.cancel(); _setFontSize(1); _scheduleHide(); }, onShowToc: () { _hideTimer?.cancel(); showReaderToc(context, _chapters, _chapterStarts, _totalChars, _position, _darkMode, hasCover, _pageController, _pageStarts, _scheduleHide); }, onMenuAction: _handleMenuAction, menuItems: [readerMenuPopItem('RSVP speed read', 'rsvp', _darkMode), readerMenuPopItem('Select font…', 'select_font', _darkMode), readerMenuPopItem('Go to page…', 'go_to_page', _darkMode), readerMenuPopItem(_darkMode ? 'Light mode' : 'Dark mode', 'toggle_mode', _darkMode)]))),
        if (!_goToPageMode) Positioned(bottom: 0, left: 0, right: 0, child: ReaderBottomBar(currentPage: _currentPage + 1, totalPages: _totalPages, totalChars: _totalChars, position: _position, darkMode: _darkMode, coverCount: coverCount, pageController: _pageController)),
        if (_goToPageMode) _buildGoToPageOverlay(pad),
      ]),
    );
  }

  Widget _buildGoToPageOverlay(EdgeInsets pad) {
    final bgColor = _darkMode ? const Color(0xEE000000) : const Color(0xEEF5F5F0);
    final fg = _darkMode ? Colors.white : Colors.black87;
    final dim = _darkMode ? const Color(0xFF888888) : const Color(0xFF666666);

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Expanded(
          child: Listener(
            behavior: HitTestBehavior.translucent,
            onPointerDown: (e) => _tapPosition = e.localPosition,
            onPointerUp: (e) {
              if (_tapPosition != null && (e.localPosition - _tapPosition!).distance < 10) _exitGoToPageMode();
              _tapPosition = null;
            },
          ),
        ),
        Container(
          padding: EdgeInsets.only(bottom: pad.bottom),
          color: bgColor,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Row(children: [
                  GestureDetector(
                    onTap: _returnToOriginalPage,
                    child: Container(
                      width: 48, height: 64,
                      decoration: BoxDecoration(color: _darkMode ? const Color(0xFF111111) : const Color(0xFFDDDDD8), border: Border.all(color: _goToOriginalPage == _currentPage ? fg : dim)),
                      child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.history, size: 16, color: dim), const SizedBox(height: 2), Text('${_goToOriginalPage + 1}', style: GoogleFonts.inter(color: dim, fontSize: 9))])),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Text('Page ${_currentPage + 1}', style: GoogleFonts.inter(color: fg, fontSize: 14, fontWeight: FontWeight.w600)),
                          const Spacer(),
                          GestureDetector(
                            onTap: _exitGoToPageMode,
                            child: Container(width: 28, height: 28, decoration: BoxDecoration(shape: BoxShape.circle, color: _darkMode ? const Color(0xFF333333) : const Color(0xFFCCCCCC)), child: const Icon(Icons.close, size: 16, color: Colors.white)),
                          ),
                        ]),
                        const SizedBox(height: 4),
                        Slider(
                          value: (_currentPage + 1).toDouble().clamp(1, _totalPages.toDouble()),
                          min: 1,
                          max: _totalPages.toDouble().clamp(1, 99999),
                          divisions: (_totalPages - 1).clamp(0, 999),
                          activeColor: fg,
                          inactiveColor: _darkMode ? const Color(0xFF333333) : const Color(0xFFCCCCCC),
                          onChanged: _goToPageSliderChanged,
                        ),
                      ],
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCoverPage(Book book, Color bg) => Container(color: bg, child: Center(child: Padding(padding: const EdgeInsets.all(24), child: ClipRRect(borderRadius: BorderRadius.zero, child: Image.memory(book.coverBytes!, fit: BoxFit.contain)))));

  Widget _buildTextPage(String text, EdgeInsets pad) {
    final isCh = _isChapterStart(text);
    final textKey = GlobalKey();
    return GestureDetector(
      onDoubleTapDown: (d) => _handleDoubleTap(d, text, textKey),
      onTapDown: _rsvpPickCompleter != null ? (d) => _handleDoubleTap(d, text, textKey) : null,
      child: SingleChildScrollView(physics: const NeverScrollableScrollPhysics(), padding: EdgeInsets.fromLTRB(24, pad.top + 48, 24, 0), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [if (isCh) ...[_buildChapterHeader(text), const SizedBox(height: 12)], Text(text, key: textKey, style: _textStyle(height: 1.7))])),
    );
  }

  bool _isChapterStart(String text) { for (final ch in _chapters) { if (text.startsWith('${ch.title}\n')) return true; } return false; }

  Widget _buildChapterHeader(String text) { for (final ch in _chapters) { if (text.startsWith('${ch.title}\n')) return Text(ch.title, style: _textStyle(fontSize: _fontSize * 0.7, fontWeight: FontWeight.w500, letterSpacing: 2)); } return const SizedBox.shrink(); }
}

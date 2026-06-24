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
import 'reader/reader_overlays.dart';
import 'reader/reader_page_layout.dart';
import 'reader/reader_rsvp_screen.dart';
import 'reader/reader_sheets.dart';
import 'reader/reader_text_page.dart';

class ReaderScreen extends ConsumerStatefulWidget {
  final Book book;
  const ReaderScreen({super.key, required this.book});
  @override
  ConsumerState<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends ConsumerState<ReaderScreen> {
  // ── content ──
  List<EpubChapter> _chapters = [];
  String _fullText = '';
  int _totalChars = 0;
  int _position = 0;
  late ReaderPageLayout _layout;

  // ── pagination ──
  final _pageController = PageController();
  int _currentPage = 0;
  int _totalPages = 1;
  List<int> _pageStarts = [0];

  // ── display settings ──
  double _fontSize = 16;
  bool _darkMode = true;
  String _fontFamily = 'Inter';

  // ── UI state ──
  bool _loading = true;
  bool _controlsVisible = true;
  Timer? _hideTimer;

  // ── overlays ──
  bool _goToPageMode = false;
  int _goToOriginalPage = 0;
  bool _searchMode = false;
  final _searchController = TextEditingController();
  String _searchQuery = '';
  List<Map<String, int>> _searchResults = [];

  // ── bookmarks ──
  List<int> _bookmarks = [];
  bool _isBookmarked = false;

  // ── highlights ──
  List<Map<String, int>> _highlights = [];
  bool _highlightMode = false;
  int? _highlightStartPos;

  // ── RSVP ──
  Completer<int?>? _rsvpPickCompleter;
  OverlayEntry? _rsvpOverlay;

  // ── constants ──
  static const _minFontSize = 12.0;
  static const _maxFontSize = 24.0;
  static const _autoHideDelay = Duration(seconds: 3);

  // ─────────────────── lifecycle ───────────────────

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
    _searchController.dispose();
    super.dispose();
  }

  // ─────────────────── content loading ───────────────────

  Future<void> _loadContent() async {
    final chapters = await Future(() {
      if (widget.book.fileBytes != null) {
        return EpubParser.extractChaptersFromBytes(widget.book.fileBytes!);
      }
      return EpubParser.extractChapters(widget.book.filePath);
    });

    final savedPos = await BookStorage.loadPosition(widget.book.filePath);
    final savedFontSize = await BookStorage.loadFontSize(widget.book.filePath);
    final savedFontFamily = await BookStorage.loadFontFamily(widget.book.filePath);
    final savedDarkMode = await BookStorage.loadDarkMode(widget.book.filePath);
    final bms = await BookStorage.loadBookmarks(widget.book.filePath);
    final hls = await BookStorage.loadHighlights(widget.book.filePath);

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
    final tc = text.length;

    setState(() {
      _chapters = chapters;
      _fullText = text;
      _totalChars = tc;
      _position = savedPos.clamp(0, tc);
      if (savedFontSize != null) _fontSize = savedFontSize.clamp(_minFontSize, _maxFontSize);
      if (savedFontFamily != null) _fontFamily = savedFontFamily;
      if (savedDarkMode != null) _darkMode = savedDarkMode;
      _layout = ReaderPageLayout(
        fullText: text,
        chapterStarts: chapterStarts,
        fontSize: _fontSize,
        fontFamily: _fontFamily,
      );
      _bookmarks = bms;
      _isBookmarked = bms.contains(_currentPage);
      _highlights = hls;
      _loading = false;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final co = _coverCount;
      final p = _layout.findPageForPosition(_position, _pageStarts);
      _pageController.jumpToPage(p + co);
    });

    ref.read(bookListProvider.notifier).touchBook(widget.book.filePath);
    _scheduleHide();
  }

  // ─────────────────── text style ───────────────────

  TextStyle _textStyle({double? fontSize, Color? color, FontWeight? fontWeight, double? height, double? letterSpacing}) {
    final base = GoogleFonts.getFont(
      _fontFamily,
      fontSize: fontSize ?? _fontSize,
      fontWeight: fontWeight ?? FontWeight.w400,
      color: color ?? (_darkMode ? const Color(0xFFCCCCCC) : const Color(0xFF1A1A1A)),
      letterSpacing: letterSpacing,
    );
    return height != null ? base.copyWith(height: height) : base;
  }

  // ─────────────────── page management ───────────────────

  int get _coverCount => widget.book.coverBytes != null ? 1 : 0;

  void _updatePagination() {
    final cpp = _layout.charsPerPage(context, (fs) => _textStyle(fontSize: fs));
    final cols = _layout.colsPerLine(context, (fs) => _textStyle(fontSize: fs));
    _pageStarts = _layout.computePageBreaks(cpp, cols);
    _totalPages = _pageStarts.length - 1;
  }

  void _onPageScrolling() {
    if (!_pageController.hasClients || !mounted) return;
    final p = _pageController.page;
    if (p == null) return;
    final tp = (p.round() - _coverCount).clamp(0, _pageStarts.length - 1);
    if (tp != _currentPage && tp >= 0 && tp < _pageStarts.length) {
      setState(() {
        _currentPage = tp;
        _isBookmarked = _bookmarks.contains(tp);
      });
    }
  }

  void _onPageChanged(int pg) {
    if (_chapters.isEmpty || pg >= _pageStarts.length) return;
    _currentPage = pg;
    _position = _pageStarts[pg];
    _isBookmarked = _bookmarks.contains(pg);
    BookStorage.savePosition(widget.book.filePath, _position);
  }

  // ─────────────────── controls visibility ───────────────────

  void _scheduleHide() {
    if (_goToPageMode || _highlightMode || _searchMode) return;
    _hideTimer?.cancel();
    _hideTimer = Timer(_autoHideDelay, () {
      if (mounted) setState(() => _controlsVisible = false);
    });
  }

  void _toggleControls() {
    if (_goToPageMode || _highlightMode || _searchMode) return;
    setState(() => _controlsVisible = !_controlsVisible);
    if (_controlsVisible) {
      _scheduleHide();
    } else {
      _hideTimer?.cancel();
    }
  }

  // ─────────────────── font size ───────────────────

  void _setFontSize(double delta) {
    final old = _position;
    setState(() => _fontSize = (_fontSize + delta).clamp(_minFontSize, _maxFontSize));
    _layout = ReaderPageLayout(
      fullText: _fullText,
      chapterStarts: _layout.chapterStarts,
      fontSize: _fontSize,
      fontFamily: _fontFamily,
    );
    BookStorage.saveFontSize(widget.book.filePath, _fontSize);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _currentPage = _layout.findPageForPosition(old, _pageStarts);
        _totalPages = _pageStarts.length - 1;
      });
      _pageController.jumpToPage(_currentPage + _coverCount);
    });
  }

  // ─────────────────── bookmarks ───────────────────

  void _toggleBookmark() {
    setState(() {
      if (_bookmarks.contains(_currentPage)) {
        _bookmarks.remove(_currentPage);
        _isBookmarked = false;
      } else {
        _bookmarks.add(_currentPage);
        _bookmarks.sort();
        _isBookmarked = true;
      }
    });
    BookStorage.saveBookmarks(widget.book.filePath, _bookmarks);
    _controlsVisible = true;
    _scheduleHide();
  }

  void _showBookmarksSheet() {
    _hideTimer?.cancel();
    if (_bookmarks.isEmpty) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: _darkMode ? const Color(0xFF0F0F0F) : const Color(0xFFF0F0EB),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      builder: (_) => BookmarksSheet(
        darkMode: _darkMode,
        bookmarks: _bookmarks,
        currentPage: _currentPage,
        coverCount: _coverCount,
        onNavigate: (pg) {
          _pageController.jumpToPage(pg + _coverCount);
          _onPageChanged(pg);
        },
        onRemove: (i) {
          setState(() {
            _bookmarks.removeAt(i);
            _isBookmarked = _bookmarks.contains(_currentPage);
          });
          BookStorage.saveBookmarks(widget.book.filePath, _bookmarks);
        },
      ),
    ).then((_) => _scheduleHide());
  }

  // ─────────────────── highlights ───────────────────

  void _enterHighlightMode() {
    setState(() {
      _highlightMode = true;
      _highlightStartPos = null;
      _controlsVisible = true;
    });
    _hideTimer?.cancel();
  }

  void _handleHighlightTap(int wordStart, int wordEnd) {
    if (!_highlightMode) return;
    if (_highlightStartPos == null) {
      setState(() => _highlightStartPos = wordStart);
      return;
    }
    if (_highlightStartPos! <= wordStart) {
      setState(() {
        _highlights.add({'s': _highlightStartPos!, 'e': wordEnd});
        _highlightMode = false;
        _highlightStartPos = null;
      });
    } else {
      setState(() {
        _highlights.add({'s': wordStart, 'e': _highlightStartPos!});
        _highlightMode = false;
        _highlightStartPos = null;
      });
    }
    BookStorage.saveHighlights(widget.book.filePath, _highlights);
    _scheduleHide();
  }

  void _showHighlightsSheet() {
    _hideTimer?.cancel();
    if (_highlights.isEmpty) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: _darkMode ? const Color(0xFF0F0F0F) : const Color(0xFFF0F0EB),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      builder: (_) => HighlightsSheet(
        darkMode: _darkMode,
        highlights: _highlights,
        coverCount: _coverCount,
        onNavigate: (pg) {
          _pageController.jumpToPage(pg + _coverCount);
          _onPageChanged(pg);
        },
        onRemove: (i) {
          setState(() => _highlights.removeAt(i));
          BookStorage.saveHighlights(widget.book.filePath, _highlights);
        },
        getFullText: () => _fullText,
        pageFinder: (pos) => _layout.findPageForPosition(pos, _pageStarts),
      ),
    ).then((_) => _scheduleHide());
  }

  // ─────────────────── menu ───────────────────

  void _handleMenuAction(String v) {
    _hideTimer?.cancel();
    switch (v) {
      case 'select_font':
        showReaderFontDialog(context, _fontFamily, _darkMode, widget.book.filePath,
            (f) => setState(() => _fontFamily = f));
        _scheduleHide();
        return;
      case 'go_to_page':
        setState(() {
          _goToPageMode = true;
          _goToOriginalPage = _currentPage;
          _controlsVisible = true;
        });
        return;
      case 'bookmarks':
        _showBookmarksSheet();
        return;
      case 'highlights':
        _showHighlightsSheet();
        return;
      case 'highlight':
        _enterHighlightMode();
        return;
      case 'rsvp':
        _openRsvp();
        return;
      case 'search':
        _enterSearchMode();
        return;
      case 'toggle_mode':
        setState(() => _darkMode = !_darkMode);
        BookStorage.saveDarkMode(widget.book.filePath, _darkMode);
        break;
    }
    _scheduleHide();
  }

  // ─────────────────── go-to-page ───────────────────

  void _onGoToSliderChanged(double val) {
    var tp = val.round() - 1;
    for (final bm in _bookmarks) {
      if ((bm - tp).abs() <= 2) { tp = bm; break; }
    }
    if (tp >= 0 && tp < _totalPages) {
      _pageController.jumpToPage(tp + _coverCount);
      setState(() => _currentPage = tp);
    }
  }

  void _exitGoToPageMode() {
    setState(() => _goToPageMode = false);
    _onPageChanged(_currentPage);
    _scheduleHide();
  }

  void _returnToOriginalPage() {
    _pageController.jumpToPage(_goToOriginalPage + _coverCount);
    _onPageChanged(_goToOriginalPage);
    setState(() {
      _goToPageMode = false;
      _currentPage = _goToOriginalPage;
    });
    _scheduleHide();
  }

  // ─────────────────── search ───────────────────

  void _enterSearchMode() {
    _hideTimer?.cancel();
    _searchQuery = '';
    _searchResults = [];
    _searchController.clear();
    setState(() {
      _searchMode = true;
      _controlsVisible = true;
    });
  }

  void _exitSearchMode() {
    setState(() => _searchMode = false);
    _searchController.clear();
    _scheduleHide();
  }

  void _performSearch(String query) {
    if (query.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }
    final lower = _fullText.toLowerCase();
    final q = query.toLowerCase();
    final results = <Map<String, int>>[];
    var start = 0;
    while (start < _fullText.length) {
      final idx = lower.indexOf(q, start);
      if (idx == -1) break;
      results.add({'pos': idx, 'len': q.length});
      start = idx + 1;
    }
    setState(() => _searchResults = results);
  }

  void _navigateToSearchResult(int pos) {
    _exitSearchMode();
    _position = pos.clamp(0, _totalChars);
    _currentPage = _layout.findPageForPosition(_position, _pageStarts);
    _pageController.jumpToPage(_currentPage + _coverCount);
    BookStorage.savePosition(widget.book.filePath, _position);
  }

  // ─────────────────── RSVP ───────────────────

  void _openRsvp() async {
    _hideTimer?.cancel();
    setState(() => _controlsVisible = true);

    final sp = await _pickRsvpStartWord();
    if (sp == null || !mounted) { _scheduleHide(); return; }

    final ps = await _askRsvpPauseSentences();
    if (ps == null || !mounted) { _scheduleHide(); return; }

    final np = await Navigator.push<int>(
      context,
      MaterialPageRoute(
        builder: (_) => RsvpScreen(
          fullText: _fullText,
          startPosition: sp,
          totalChars: _totalChars,
          fontFamily: _fontFamily,
          darkMode: _darkMode,
          pauseAfterWords: ps,
        ),
      ),
    );

    if (np != null && mounted) {
      _position = np.clamp(0, _totalChars);
      _currentPage = _layout.findPageForPosition(_position, _pageStarts);
      _pageController.jumpToPage(_currentPage + _coverCount);
      BookStorage.savePosition(widget.book.filePath, _position);
      _saveProgress();
    }
    _scheduleHide();
  }

  Future<int?> _pickRsvpStartWord() async {
    final c = Completer<int?>();
    late final OverlayEntry o;
    o = OverlayEntry(
      builder: (_) => Positioned(
        top: MediaQuery.of(context).padding.top + 56,
        left: 20,
        right: 20,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: _darkMode ? const Color(0xEE000000) : const Color(0xEEF5F5F0),
              border: Border.all(color: _darkMode ? const Color(0xFF444444) : const Color(0xFFAAAAAA)),
              borderRadius: BorderRadius.zero,
            ),
            child: Row(
              children: [
                const Icon(Icons.touch_app, size: 16, color: Color(0xFF888888)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Tap a word to start RSVP from here',
                    style: GoogleFonts.inter(color: _darkMode ? Colors.white : Colors.black87, fontSize: 13),
                  ),
                ),
                GestureDetector(
                  onTap: () { c.complete(null); o.remove(); },
                  child: const Icon(Icons.close, size: 18, color: Color(0xFF888888)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    Overlay.of(context).insert(o);
    _rsvpPickCompleter = c;
    _rsvpOverlay = o;
    return c.future;
  }

  Future<int?> _askRsvpPauseSentences() async {
    var ct = 1;
    return showDialog<int>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => Dialog(
          backgroundColor: _darkMode ? const Color(0xFF0F0F0F) : const Color(0xFFF0F0EB),
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Auto-pause', style: GoogleFonts.inter(color: _darkMode ? Colors.white : Colors.black87, fontSize: 15, fontWeight: FontWeight.w600)),
                const SizedBox(height: 16),
                Text('Pause every N sentences', style: GoogleFonts.inter(color: _darkMode ? const Color(0xFF888888) : const Color(0xFF999999), fontSize: 12)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text('Off', style: GoogleFonts.inter(color: _darkMode ? const Color(0xFF555555) : const Color(0xFF999999), fontSize: 11)),
                    Expanded(
                      child: Slider(
                        value: ct.toDouble(), min: 0, max: 20, divisions: 20,
                        activeColor: _darkMode ? Colors.white : Colors.black87,
                        inactiveColor: _darkMode ? const Color(0xFF333333) : const Color(0xFFCCCCCC),
                        onChanged: (v) => setD(() => ct = v.round()),
                      ),
                    ),
                    Text('20', style: GoogleFonts.inter(color: _darkMode ? const Color(0xFF555555) : const Color(0xFF999999), fontSize: 11)),
                  ],
                ),
                Text(ct == 0 ? 'No auto-pause' : 'Every $ct sentences', style: GoogleFonts.inter(color: _darkMode ? Colors.white : Colors.black87, fontSize: 13, fontWeight: FontWeight.w500)),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel', style: GoogleFonts.inter(color: _darkMode ? const Color(0xFF888888) : const Color(0xFF999999), fontSize: 13))),
                    const SizedBox(width: 8),
                    TextButton(onPressed: () => Navigator.pop(ctx, ct), child: Text('Start', style: GoogleFonts.inter(color: _darkMode ? Colors.white : Colors.black87, fontSize: 13, fontWeight: FontWeight.w600))),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────── double-tap / dictionary ───────────────────

  void _handleDoubleTap(TapDownDetails d, String text, GlobalKey tk) {
    final rb = tk.currentContext?.findRenderObject() as RenderBox?;
    if (rb == null || text.isEmpty) return;
    final lp = rb.globalToLocal(d.globalPosition);
    final tp = TextPainter(
      text: TextSpan(text: text, style: _textStyle(height: 1.7)),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: rb.size.width);
    final po = tp.getPositionForOffset(lp);
    if (po.offset < 0 || po.offset >= text.length) return;
    _lookupWord(text, po.offset);
  }

  void _lookupWord(String text, int idx) {
    var s = idx, e = idx;
    final wc = RegExp(r'[\w]');
    while (s > 0 && wc.hasMatch(text[s - 1])) { s--; }
    while (e < text.length && wc.hasMatch(text[e])) { e++; }

    if (_highlightMode) {
      while (s > 0 && RegExp(r'[^\w\s]').hasMatch(text[s - 1])) { s--; }
      while (e < text.length && RegExp(r'[^\w\s]').hasMatch(text[e])) { e++; }
      final pg = _pageController.hasClients ? _pageController.page?.round() ?? 0 : 0;
      final tp = pg - _coverCount;
      final ps = tp >= 0 && tp < _pageStarts.length - 1 ? _pageStarts[tp] : 0;
      _handleHighlightTap(ps + s, ps + e);
      return;
    }

    if (_rsvpPickCompleter != null) {
      _rsvpOverlay?.remove();
      _rsvpOverlay = null;
      final pg = _pageController.hasClients ? _pageController.page?.round() ?? 0 : 0;
      final tp = pg - _coverCount;
      final ps = tp >= 0 && tp < _pageStarts.length - 1 ? _pageStarts[tp] : 0;
      _rsvpPickCompleter!.complete(ps + s);
      _rsvpPickCompleter = null;
      return;
    }

    final word = text.substring(s, e).trim().toLowerCase();
    if (word.length < 2 || word.length > 30) return;
    _hideTimer?.cancel();
    setState(() => _controlsVisible = true);
    showDialog(context: context, builder: (_) => DictionaryDialog(word: word))
        .then((_) => _scheduleHide());
  }

  // ─────────────────── progress ───────────────────

  void _saveProgress() {
    if (_totalChars <= 0) return;
    final p = _position / _totalChars;
    final idx = ref.read(bookListProvider).indexWhere((b) => b.filePath == widget.book.filePath);
    if (idx != -1) ref.read(bookListProvider.notifier).editBook(idx, progress: p);
  }

  // ─────────────────── build ───────────────────

  @override
  Widget build(BuildContext ctx) {
    final b = widget.book;
    final bg = _darkMode ? const Color(0xFF000000) : const Color(0xFFF5F5F0);

    if (_loading) {
      return Scaffold(
        backgroundColor: bg,
        body: Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation(_darkMode ? const Color(0xFF333333) : const Color(0xFFCCCCCC)),
          ),
        ),
      );
    }

    if (_chapters.isEmpty) {
      return Scaffold(
        backgroundColor: bg,
        body: Center(
          child: Text('No readable content', style: _textStyle(color: _darkMode ? const Color(0xFF555555) : const Color(0xFF999999), fontSize: 14)),
        ),
      );
    }

    return _buildReader(b, bg);
  }

  Widget _buildReader(Book b, Color bg) {
    _updatePagination();

    final pad = MediaQuery.of(context).padding;
    final sc = (_goToPageMode || _highlightMode || _searchMode) ? 0.85 : 1.0;
    final cc = _coverCount;

    final menuItems = <PopupMenuEntry<String>>[
      readerMenuPopItem('Search…', 'search', _darkMode),
      readerMenuPopItem('RSVP speed read', 'rsvp', _darkMode),
      readerMenuPopItem('Highlight', 'highlight', _darkMode),
      readerMenuPopItem('Highlights', 'highlights', _darkMode),
      readerMenuPopItem('Bookmarks', 'bookmarks', _darkMode),
      readerMenuPopItem('Select font…', 'select_font', _darkMode),
      readerMenuPopItem('Go to page…', 'go_to_page', _darkMode),
      readerMenuPopItem(_darkMode ? 'Light mode' : 'Dark mode', 'toggle_mode', _darkMode),
    ];

    return Scaffold(
      backgroundColor: bg,
      body: Focus(
        autofocus: true,
        onKeyEvent: (_, e) {
          if (e is KeyDownEvent) {
            if (e.logicalKey == LogicalKeyboardKey.arrowLeft) {
              _pageController.previousPage(duration: const Duration(milliseconds: 200), curve: Curves.easeInOut);
              return KeyEventResult.handled;
            }
            if (e.logicalKey == LogicalKeyboardKey.arrowRight) {
              _pageController.nextPage(duration: const Duration(milliseconds: 200), curve: Curves.easeInOut);
              return KeyEventResult.handled;
            }
          }
          return KeyEventResult.ignored;
        },
        child: Stack(
          children: [
            // ── page content ──
            Transform.scale(
              scale: sc,
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (pg) {
                  if (pg == 0 && cc > 0) { _currentPage = 0; return; }
                  _onPageChanged(pg - cc);
                },
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: _totalPages + cc,
                itemBuilder: (_, pi) {
                  if (cc > 0 && pi == 0) return _buildCoverPage(b, bg);
                  final tp = pi - cc;
                  final st = _pageStarts[tp];
                  final en = tp + 1 < _pageStarts.length ? _pageStarts[tp + 1] : _fullText.length;
                  return ReaderTextPage(
                    text: _fullText.substring(st, en),
                    padding: pad,
                    pageStart: st,
                    fontSize: _fontSize,
                    fontFamily: _fontFamily,
                    darkMode: _darkMode,
                    highlights: _highlights,
                    highlightModeActive: _highlightMode,
                    rsvpPickActive: _rsvpPickCompleter != null,
                    onTapWord: _handleDoubleTap,
                  );
                },
              ),
            ),

            // ── highlight banner ──
            if (_highlightMode)
              HighlightBanner(
                darkMode: _darkMode,
                hasStartPosition: _highlightStartPos != null,
                onCancel: () {
                  setState(() { _highlightMode = false; _highlightStartPos = null; });
                  _scheduleHide();
                },
              ),

            // ── tap-to-toggle-controls ──
            if (!_goToPageMode && !_highlightMode && !_searchMode)
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: () {
                    if (_rsvpPickCompleter == null) _toggleControls();
                  },
                ),
              ),

            // ── app bar ──
            if (!_goToPageMode && !_highlightMode && !_searchMode)
              AnimatedOpacity(
                opacity: _controlsVisible ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 250),
                child: IgnorePointer(
                  ignoring: !_controlsVisible,
                  child: ReaderAppBar(
                    title: b.title,
                    darkMode: _darkMode,
                    padding: pad,
                    onBack: () { _saveProgress(); Navigator.pop(context); },
                    onDecreaseFont: () { _hideTimer?.cancel(); _setFontSize(-1); _scheduleHide(); },
                    onIncreaseFont: () { _hideTimer?.cancel(); _setFontSize(1); _scheduleHide(); },
                    onShowToc: () {
                      _hideTimer?.cancel();
                      showReaderToc(context, _chapters, _layout.chapterStarts, _totalChars, _position,
                          _darkMode, _coverCount > 0, _pageController, _pageStarts, _scheduleHide);
                    },
                    onBookmarkToggle: _toggleBookmark,
                    isBookmarked: _isBookmarked,
                    onMenuAction: _handleMenuAction,
                    menuItems: menuItems,
                  ),
                ),
              ),

            // ── bottom bar ──
            if (!_goToPageMode && !_highlightMode && !_searchMode)
              Positioned(
                bottom: 0, left: 0, right: 0,
                child: ReaderBottomBar(
                  currentPage: _currentPage + 1,
                  totalPages: _totalPages,
                  totalChars: _totalChars,
                  position: _position,
                  darkMode: _darkMode,
                  coverCount: cc,
                  pageController: _pageController,
                ),
              ),

            // ── overlays ──
            if (_goToPageMode)
              GoToPageOverlay(
                currentPage: _currentPage,
                originalPage: _goToOriginalPage,
                totalPages: _totalPages,
                darkMode: _darkMode,
                padding: pad,
                bookmarks: _bookmarks,
                onReturn: _returnToOriginalPage,
                onExit: _exitGoToPageMode,
                onSliderChanged: _onGoToSliderChanged,
              ),

            if (_searchMode)
              SearchOverlay(
                darkMode: _darkMode,
                padding: pad,
                fullText: _fullText,
                query: _searchQuery,
                results: _searchResults,
                pageFinder: (pos) => _layout.findPageForPosition(pos, _pageStarts),
                controller: _searchController,
                onExit: _exitSearchMode,
                onSearch: _performSearch,
                onNavigate: _navigateToSearchResult,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoverPage(Book b, Color bg) {
    return Container(
      color: bg,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ClipRRect(
            borderRadius: BorderRadius.zero,
            child: Image.memory(b.coverBytes!, fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }
}

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
  List<int> _bookmarks = [];
  bool _isBookmarked = false;
  List<Map<String, int>> _highlights = [];
  bool _highlightMode = false;
  int? _highlightStartPos;
  Timer? _hideTimer;
  Completer<int?>? _rsvpPickCompleter;
  OverlayEntry? _rsvpOverlay;
  Offset? _tapPosition;

  bool _searchMode = false;
  String _searchQuery = '';
  List<Map<String, int>> _searchResults = [];
  final _searchController = TextEditingController();

  static const _minFontSize = 12.0;
  static const _maxFontSize = 24.0;
  static const _autoHideDelay = Duration(seconds: 3);

  @override
  void initState() { super.initState(); _pageController.addListener(_onPageScrolling); _loadContent(); }

  @override
  void dispose() { _saveProgress(); _pageController.dispose(); _hideTimer?.cancel(); _searchController.dispose(); super.dispose(); }

  void _onPageScrolling() {
    if (!_pageController.hasClients || !mounted) return;
    final p = _pageController.page; if (p == null) return;
    final cc = widget.book.coverBytes != null ? 1 : 0;
    final tp = (p.round() - cc).clamp(0, _pageStarts.length - 1);
    if (tp != _currentPage && tp >= 0 && tp < _pageStarts.length) {
      setState(() { _currentPage = tp; _isBookmarked = _bookmarks.contains(tp); });
    }
  }

  void _scheduleHide() { if (_goToPageMode || _highlightMode || _searchMode) return; _hideTimer?.cancel(); _hideTimer = Timer(_autoHideDelay, () { if (mounted) setState(() => _controlsVisible = false); }); }
  void _toggleControls() { if (_goToPageMode || _highlightMode || _searchMode) return; setState(() => _controlsVisible = !_controlsVisible); if (_controlsVisible) { _scheduleHide(); } else { _hideTimer?.cancel(); } }

  Future<void> _loadContent() async {
    final chapters = await Future(() { if (widget.book.fileBytes != null) return EpubParser.extractChaptersFromBytes(widget.book.fileBytes!); return EpubParser.extractChapters(widget.book.filePath); });
    final savedPos = await BookStorage.loadPosition(widget.book.filePath);
    final savedFontSize = await BookStorage.loadFontSize(widget.book.filePath);
    final savedFontFamily = await BookStorage.loadFontFamily(widget.book.filePath);
    final savedDarkMode = await BookStorage.loadDarkMode(widget.book.filePath);
    final bms = await BookStorage.loadBookmarks(widget.book.filePath);
    final hls = await BookStorage.loadHighlights(widget.book.filePath);
    if (!mounted) return;
    final buf = StringBuffer(); final css = <int>[];
    for (final ch in chapters) { css.add(buf.length); buf.writeln(ch.title); buf.writeln(); buf.writeln(ch.content); buf.writeln(); }
    final text = buf.toString(); final tc = text.length;
    setState(() {
      _chapters = chapters; _fullText = text; _totalChars = tc; _position = savedPos.clamp(0, tc);
      _chapterStarts..clear()..addAll(css);
      if (savedFontSize != null) _fontSize = savedFontSize.clamp(_minFontSize, _maxFontSize);
      if (savedFontFamily != null) _fontFamily = savedFontFamily;
      if (savedDarkMode != null) _darkMode = savedDarkMode;
      _bookmarks = bms; _isBookmarked = bms.contains(_currentPage);
      _highlights = hls; _loading = false;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) { if (!mounted) return; final p = _findPageForPosition(_position); final co = widget.book.coverBytes != null ? 1 : 0; _pageController.jumpToPage(p + co); });
    ref.read(bookListProvider.notifier).touchBook(widget.book.filePath);
    _scheduleHide();
  }

  int _charsPerPage(BuildContext context) {
    final s = MediaQuery.of(context).size; final p = MediaQuery.of(context).padding;
    final tp = const EdgeInsets.fromLTRB(24, 0, 24, 0);
    final w = s.width - tp.left - tp.right; final h = s.height - p.top - p.bottom - tp.top - tp.bottom;
    if (w <= 0 || h <= 0) return 1000;
    final painter = TextPainter(text: TextSpan(text: 'X', style: _textStyle(height: 1.7)), textDirection: TextDirection.ltr)..layout(maxWidth: w);
    return (w / painter.width).floor().clamp(1, 999) * (h / painter.height).floor().clamp(1, 999);
  }

  int _findPageForPosition(int pos) { for (var i = _pageStarts.length - 1; i >= 0; i--) { if (_pageStarts[i] <= pos) return i; } return 0; }

  List<int> _computePageBreaks(int cpp) {
    if (cpp <= 0) return [0];
    final b = <int>[0];
    while (b.last < _fullText.length) {
      var e = (b.last + cpp).clamp(0, _fullText.length);
      final nextChapterStart = _chapterStarts.cast<int?>().firstWhere((cs) => cs! > b.last, orElse: () => null);
      if (nextChapterStart != null && nextChapterStart < e) {
        e = nextChapterStart;
      }
      if (e < _fullText.length) {
        var a = e;
        while (a > b.last && a > e - 80 && _fullText[a] != ' ' && _fullText[a] != '\n') { a--; }
        if (a > b.last && (_fullText[a] == ' ' || _fullText[a] == '\n')) e = a + 1;
      }
      b.add(e);
    }
    return b;
  }

  void _onPageChanged(int pg) { if (_chapters.isEmpty || pg >= _pageStarts.length) return; _currentPage = pg; _position = _pageStarts[pg]; _isBookmarked = _bookmarks.contains(pg); BookStorage.savePosition(widget.book.filePath, _position); }

  TextStyle _textStyle({double? fontSize, Color? color, FontWeight? fontWeight, double? height, double? letterSpacing}) {
    final base = GoogleFonts.getFont(_fontFamily, fontSize: fontSize ?? _fontSize, fontWeight: fontWeight ?? FontWeight.w400, color: color ?? (_darkMode ? const Color(0xFFCCCCCC) : const Color(0xFF1A1A1A)), letterSpacing: letterSpacing);
    if (height != null) return base.copyWith(height: height);
    return base;
  }

  void _setFontSize(double delta) {
    final old = _position; final co = widget.book.coverBytes != null ? 1 : 0;
    setState(() => _fontSize = (_fontSize + delta).clamp(_minFontSize, _maxFontSize));
    BookStorage.saveFontSize(widget.book.filePath, _fontSize);
    WidgetsBinding.instance.addPostFrameCallback((_) { if (!mounted) return; setState(() { _currentPage = _findPageForPosition(old); _totalPages = _pageStarts.length - 1; }); _pageController.jumpToPage(_currentPage + co); });
  }

  void _toggleBookmark() {
    setState(() { if (_bookmarks.contains(_currentPage)) { _bookmarks.remove(_currentPage); _isBookmarked = false; } else { _bookmarks.add(_currentPage); _bookmarks.sort(); _isBookmarked = true; } });
    BookStorage.saveBookmarks(widget.book.filePath, _bookmarks); _controlsVisible = true; _scheduleHide();
  }

  void _showBookmarks() {
    _hideTimer?.cancel(); if (_bookmarks.isEmpty) return;
    final co = widget.book.coverBytes != null ? 1 : 0;
    showModalBottomSheet(context: context, backgroundColor: _darkMode ? const Color(0xFF0F0F0F) : const Color(0xFFF0F0EB), shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero), builder: (ctx) => Container(constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.5), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Padding(padding: const EdgeInsets.fromLTRB(20, 16, 20, 12), child: Text('Bookmarks', style: GoogleFonts.inter(color: _darkMode ? Colors.white : Colors.black87, fontSize: 16, fontWeight: FontWeight.w600))), Container(color: _darkMode ? const Color(0xFF141414) : const Color(0xFFDDDDD8), height: 0.5), Expanded(child: ListView.builder(padding: const EdgeInsets.symmetric(vertical: 8), itemCount: _bookmarks.length, itemBuilder: (_, i) { final pg = _bookmarks[i]; return ListTile(dense: true, leading: Icon(Icons.bookmark, size: 16, color: pg == _currentPage ? (_darkMode ? Colors.white : Colors.black87) : (_darkMode ? const Color(0xFF555555) : const Color(0xFF999999))), title: Text('Page ${pg + 1}', style: GoogleFonts.inter(color: pg == _currentPage ? (_darkMode ? Colors.white : Colors.black87) : (_darkMode ? const Color(0xFFAAAAAA) : const Color(0xFF666666)), fontSize: 14)), trailing: IconButton(icon: Icon(Icons.close, size: 16, color: _darkMode ? const Color(0xFF555555) : const Color(0xFF999999)), onPressed: () { setState(() { _bookmarks.removeAt(i); _isBookmarked = _bookmarks.contains(_currentPage); }); BookStorage.saveBookmarks(widget.book.filePath, _bookmarks); if (_bookmarks.isEmpty) Navigator.pop(ctx); }), onTap: () { Navigator.pop(ctx); _pageController.jumpToPage(pg + co); _onPageChanged(pg); }); }))]))).then((_) => _scheduleHide());
  }

  void _enterHighlightMode() {
    setState(() { _highlightMode = true; _highlightStartPos = null; _controlsVisible = true; });
    _hideTimer?.cancel();
  }

  void _handleHighlightTap(int wordStart, int wordEnd) {
    if (!_highlightMode) return;
    if (_highlightStartPos == null) {
      setState(() => _highlightStartPos = wordStart);
      return;
    }
    if (_highlightStartPos! <= wordStart) {
      // first tap came first in text order
      setState(() { _highlights.add({'s': _highlightStartPos!, 'e': wordEnd}); _highlightMode = false; _highlightStartPos = null; });
    } else {
      // second tap is before first in text order
      setState(() { _highlights.add({'s': wordStart, 'e': _highlightStartPos!}); _highlightMode = false; _highlightStartPos = null; });
    }
    BookStorage.saveHighlights(widget.book.filePath, _highlights);
    _scheduleHide();
  }

  void _showHighlights() {
    _hideTimer?.cancel(); if (_highlights.isEmpty) return;
    showModalBottomSheet(context: context, backgroundColor: _darkMode ? const Color(0xFF0F0F0F) : const Color(0xFFF0F0EB), shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero), builder: (ctx) => StatefulBuilder(builder: (ctx, setSheetState) => Container(constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.5), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Padding(padding: const EdgeInsets.fromLTRB(20, 16, 20, 12), child: Text('Highlights', style: GoogleFonts.inter(color: _darkMode ? Colors.white : Colors.black87, fontSize: 16, fontWeight: FontWeight.w600))), Container(color: _darkMode ? const Color(0xFF141414) : const Color(0xFFDDDDD8), height: 0.5), Expanded(child: ListView.builder(padding: const EdgeInsets.symmetric(vertical: 8), itemCount: _highlights.length, itemBuilder: (_, i) { final hl = _highlights[i]; final hlStart = hl['s']!; final hlEnd = hl['e']!;
      final text = _fullText.substring(hlStart.clamp(0, _fullText.length), hlEnd.clamp(0, _fullText.length));
      final pg = _findPageForPosition(hlStart); return ListTile(dense: true, leading: const Icon(Icons.format_quote, size: 16, color: Color(0xFF888888)), title: Text(text.length > 60 ? '${text.substring(0, 60)}...' : text, style: GoogleFonts.inter(color: _darkMode ? const Color(0xFFAAAAAA) : const Color(0xFF666666), fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis), subtitle: Text('Page ${pg + 1}', style: GoogleFonts.inter(color: _darkMode ? const Color(0xFF555555) : const Color(0xFF999999), fontSize: 11)), trailing: IconButton(icon: Icon(Icons.close, size: 16, color: _darkMode ? const Color(0xFF555555) : const Color(0xFF999999)), onPressed: () { setState(() => _highlights.removeAt(i)); setSheetState(() {}); BookStorage.saveHighlights(widget.book.filePath, _highlights); if (_highlights.isEmpty) Navigator.pop(ctx); }), onTap: () { Navigator.pop(ctx); final co = widget.book.coverBytes != null ? 1 : 0; _pageController.jumpToPage(pg + co); _onPageChanged(pg); }); }))])))).then((_) => _scheduleHide());
  }

  void _handleMenuAction(String v) {
    _hideTimer?.cancel();
    switch (v) {
      case 'select_font': showReaderFontDialog(context, _fontFamily, _darkMode, widget.book.filePath, (f) => setState(() => _fontFamily = f)); _scheduleHide(); return;
      case 'go_to_page': setState(() { _goToPageMode = true; _goToOriginalPage = _currentPage; _controlsVisible = true; }); return;
      case 'bookmarks': _showBookmarks(); return;
      case 'highlights': _showHighlights(); return;
      case 'highlight': _enterHighlightMode(); return;
      case 'rsvp': _openRsvp(); return;
      case 'search': _enterSearchMode(); return;
      case 'toggle_mode': setState(() => _darkMode = !_darkMode); BookStorage.saveDarkMode(widget.book.filePath, _darkMode); break;
    }
    _scheduleHide();
  }

  void _goToPageSliderChanged(double val) { final tp = val.round() - 1; var s = tp; for (final bm in _bookmarks) { if ((bm - tp).abs() <= 2) { s = bm; break; } } if (s >= 0 && s < _totalPages) { final co = widget.book.coverBytes != null ? 1 : 0; _pageController.jumpToPage(s + co); setState(() => _currentPage = s); } }
  void _exitGoToPageMode() { setState(() => _goToPageMode = false); _onPageChanged(_currentPage); _scheduleHide(); }
  void _returnToOriginalPage() { final co = widget.book.coverBytes != null ? 1 : 0; _pageController.jumpToPage(_goToOriginalPage + co); _onPageChanged(_goToOriginalPage); setState(() { _goToPageMode = false; _currentPage = _goToOriginalPage; }); _scheduleHide(); }

  void _enterSearchMode() {
    _hideTimer?.cancel();
    _searchQuery = '';
    _searchResults = [];
    _searchController.clear();
    setState(() { _searchMode = true; _controlsVisible = true; });
  }

  void _exitSearchMode() {
    setState(() => _searchMode = false);
    _searchController.clear();
    _scheduleHide();
  }

  void _performSearch(String query) {
    if (query.isEmpty) { setState(() => _searchResults = []); return; }
    final results = <Map<String, int>>[];
    final lower = _fullText.toLowerCase();
    final q = query.toLowerCase();
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
    _currentPage = _findPageForPosition(_position);
    final co = widget.book.coverBytes != null ? 1 : 0;
    _pageController.jumpToPage(_currentPage + co);
    BookStorage.savePosition(widget.book.filePath, _position);
  }

  void _openRsvp() async {
    _hideTimer?.cancel(); setState(() => _controlsVisible = true);
    final sp = await _pickRsvpStartWord(); if (sp == null || !mounted) { _scheduleHide(); return; }
    final ps = await _askRsvpPauseSentences(); if (ps == null || !mounted) { _scheduleHide(); return; }
    final np = await Navigator.push<int>(context, MaterialPageRoute(builder: (_) => RsvpScreen(fullText: _fullText, startPosition: sp, totalChars: _totalChars, fontFamily: _fontFamily, darkMode: _darkMode, pauseAfterWords: ps)));
    if (np != null && mounted) { _position = np.clamp(0, _totalChars); _currentPage = _findPageForPosition(_position); final co = widget.book.coverBytes != null ? 1 : 0; _pageController.jumpToPage(_currentPage + co); BookStorage.savePosition(widget.book.filePath, _position); _saveProgress(); }
    _scheduleHide();
  }

  Future<int?> _pickRsvpStartWord() async {
    final c = Completer<int?>(); late final OverlayEntry o;
    o = OverlayEntry(builder: (_) => Positioned(top: MediaQuery.of(context).padding.top + 56, left: 20, right: 20, child: Material(color: Colors.transparent, child: Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), decoration: BoxDecoration(color: _darkMode ? const Color(0xEE000000) : const Color(0xEEF5F5F0), border: Border.all(color: _darkMode ? const Color(0xFF444444) : const Color(0xFFAAAAAA)), borderRadius: BorderRadius.zero), child: Row(children: [const Icon(Icons.touch_app, size: 16, color: Color(0xFF888888)), const SizedBox(width: 10), Expanded(child: Text('Tap a word to start RSVP from here', style: GoogleFonts.inter(color: _darkMode ? Colors.white : Colors.black87, fontSize: 13))), GestureDetector(onTap: () { c.complete(null); o.remove(); }, child: const Icon(Icons.close, size: 18, color: Color(0xFF888888)))])))));
    Overlay.of(context).insert(o); _rsvpPickCompleter = c; _rsvpOverlay = o; return c.future;
  }

  Future<int?> _askRsvpPauseSentences() async { var ct = 1; return showDialog<int>(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setD) => Dialog(backgroundColor: _darkMode ? const Color(0xFF0F0F0F) : const Color(0xFFF0F0EB), shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero), child: Padding(padding: const EdgeInsets.fromLTRB(24, 20, 24, 12), child: Column(mainAxisSize: MainAxisSize.min, children: [Text('Auto-pause', style: GoogleFonts.inter(color: _darkMode ? Colors.white : Colors.black87, fontSize: 15, fontWeight: FontWeight.w600)), const SizedBox(height: 16), Text('Pause every N sentences', style: GoogleFonts.inter(color: _darkMode ? const Color(0xFF888888) : const Color(0xFF999999), fontSize: 12)), const SizedBox(height: 8), Row(children: [Text('Off', style: GoogleFonts.inter(color: _darkMode ? const Color(0xFF555555) : const Color(0xFF999999), fontSize: 11)), Expanded(child: Slider(value: ct.toDouble(), min: 0, max: 20, divisions: 20, activeColor: _darkMode ? Colors.white : Colors.black87, inactiveColor: _darkMode ? const Color(0xFF333333) : const Color(0xFFCCCCCC), onChanged: (v) => setD(() => ct = v.round()))), Text('20', style: GoogleFonts.inter(color: _darkMode ? const Color(0xFF555555) : const Color(0xFF999999), fontSize: 11))]), Text(ct == 0 ? 'No auto-pause' : 'Every $ct sentences', style: GoogleFonts.inter(color: _darkMode ? Colors.white : Colors.black87, fontSize: 13, fontWeight: FontWeight.w500)), const SizedBox(height: 16), Row(mainAxisAlignment: MainAxisAlignment.end, children: [TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel', style: GoogleFonts.inter(color: _darkMode ? const Color(0xFF888888) : const Color(0xFF999999), fontSize: 13))), const SizedBox(width: 8), TextButton(onPressed: () => Navigator.pop(ctx, ct), child: Text('Start', style: GoogleFonts.inter(color: _darkMode ? Colors.white : Colors.black87, fontSize: 13, fontWeight: FontWeight.w600)))])]))))); }

  void _saveProgress() { if (_totalChars <= 0) return; final p = _position / _totalChars; final idx = ref.read(bookListProvider).indexWhere((b) => b.filePath == widget.book.filePath); if (idx != -1) ref.read(bookListProvider.notifier).editBook(idx, progress: p); }

  void _handleDoubleTap(TapDownDetails d, String text, GlobalKey tk) { final rb = tk.currentContext?.findRenderObject() as RenderBox?; if (rb == null || text.isEmpty) return; final lp = rb.globalToLocal(d.globalPosition); final tp = TextPainter(text: TextSpan(text: text, style: _textStyle(height: 1.7)), textDirection: TextDirection.ltr)..layout(maxWidth: rb.size.width); final po = tp.getPositionForOffset(lp); if (po.offset < 0 || po.offset >= text.length) return; _lookupWord(text, po.offset); }

  void _lookupWord(String text, int idx) {
    var s = idx, e = idx; final wc = RegExp(r'[\w]');
    while (s > 0 && wc.hasMatch(text[s - 1])) { s--; } while (e < text.length && wc.hasMatch(text[e])) { e++; }

    if (_highlightMode) {
      // Extend to include adjacent punctuation touching the word
      while (s > 0 && RegExp(r'[^\w\s]').hasMatch(text[s - 1])) { s--; }
      while (e < text.length && RegExp(r'[^\w\s]').hasMatch(text[e])) { e++; }
      final cc = widget.book.coverBytes != null ? 1 : 0;
      final pg = _pageController.hasClients ? _pageController.page?.round() ?? 0 : 0;
      final tp = pg - cc; final ps = tp >= 0 && tp < _pageStarts.length - 1 ? _pageStarts[tp] : 0;
      _handleHighlightTap(ps + s, ps + e); return;
    }

    if (_rsvpPickCompleter != null) { _rsvpOverlay?.remove(); _rsvpOverlay = null; final cc = widget.book.coverBytes != null ? 1 : 0; final pg = _pageController.hasClients ? _pageController.page?.round() ?? 0 : 0; final tp = pg - cc; final ps = tp >= 0 && tp < _pageStarts.length - 1 ? _pageStarts[tp] : 0; _rsvpPickCompleter!.complete(ps + s); _rsvpPickCompleter = null; return; }
    final word = text.substring(s, e).trim().toLowerCase(); if (word.length < 2 || word.length > 30) return;
    _hideTimer?.cancel(); setState(() => _controlsVisible = true);
    showDialog(context: context, builder: (_) => DictionaryDialog(word: word)).then((_) => _scheduleHide());
  }

  @override
  Widget build(BuildContext ctx) { final b = widget.book; final bg = _darkMode ? const Color(0xFF000000) : const Color(0xFFF5F5F0); return Scaffold(backgroundColor: bg, body: _loading ? Center(child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(_darkMode ? const Color(0xFF333333) : const Color(0xFFCCCCCC)))) : _chapters.isEmpty ? Center(child: Text('No readable content', style: _textStyle(color: _darkMode ? const Color(0xFF555555) : const Color(0xFF999999), fontSize: 14))) : _buildReader(b, bg)); }

  Widget _buildReader(Book b, Color bg) {
    final cpp = _charsPerPage(context); _pageStarts = _computePageBreaks(cpp); _totalPages = _pageStarts.length - 1;
    final cc = b.coverBytes != null ? 1 : 0; final pad = MediaQuery.of(context).padding; final hc = b.coverBytes != null;
    final sc = (_goToPageMode || _highlightMode || _searchMode) ? 0.85 : 1.0;

    return Focus(autofocus: true, onKeyEvent: (_, e) { if (e is KeyDownEvent) { if (e.logicalKey == LogicalKeyboardKey.arrowLeft) { _pageController.previousPage(duration: const Duration(milliseconds: 200), curve: Curves.easeInOut); return KeyEventResult.handled; } if (e.logicalKey == LogicalKeyboardKey.arrowRight) { _pageController.nextPage(duration: const Duration(milliseconds: 200), curve: Curves.easeInOut); return KeyEventResult.handled; } } return KeyEventResult.ignored; }, child: Stack(children: [
      Transform.scale(scale: sc, child: PageView.builder(controller: _pageController, onPageChanged: (pg) { if (pg == 0 && cc > 0) { _currentPage = 0; return; } _onPageChanged(pg - cc); }, scrollDirection: Axis.horizontal, physics: const BouncingScrollPhysics(), itemCount: _totalPages + cc, itemBuilder: (_, pi) { if (cc > 0 && pi == 0) return _buildCoverPage(b, bg); final tp = pi - cc; final st = _pageStarts[tp]; final en = tp + 1 < _pageStarts.length ? _pageStarts[tp + 1] : _fullText.length; return _buildTextPage(_fullText.substring(st, en), pad, st); })),
      if (_highlightMode) Positioned(top: MediaQuery.of(context).padding.top + 56, left: 20, right: 20, child: Material(color: Colors.transparent, child: Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), decoration: BoxDecoration(color: _darkMode ? const Color(0xEE000000) : const Color(0xEEF5F5F0), border: Border.all(color: const Color(0xFFE05555)), borderRadius: BorderRadius.zero), child: Row(children: [const Icon(Icons.highlight, size: 16, color: Color(0xFFE05555)), const SizedBox(width: 10), Expanded(child: Text(_highlightStartPos == null ? 'Tap start of text to highlight' : 'Tap end of text to highlight', style: GoogleFonts.inter(color: _darkMode ? Colors.white : Colors.black87, fontSize: 13))), GestureDetector(onTap: () { setState(() { _highlightMode = false; _highlightStartPos = null; }); _scheduleHide(); }, child: const Icon(Icons.close, size: 18, color: Color(0xFF888888)))])))),
      if (!_goToPageMode && !_highlightMode && !_searchMode) Positioned.fill(child: Listener(behavior: HitTestBehavior.translucent, onPointerDown: (e) => _tapPosition = e.localPosition, onPointerUp: (e) { if (_tapPosition != null && (e.localPosition - _tapPosition!).distance < 10 && _rsvpPickCompleter == null) _toggleControls(); _tapPosition = null; })),
      if (!_goToPageMode && !_highlightMode && !_searchMode) AnimatedOpacity(opacity: _controlsVisible ? 1.0 : 0.0, duration: const Duration(milliseconds: 250), child: IgnorePointer(ignoring: !_controlsVisible, child: ReaderAppBar(title: b.title, darkMode: _darkMode, padding: pad, onBack: () { _saveProgress(); Navigator.pop(context); }, onDecreaseFont: () { _hideTimer?.cancel(); _setFontSize(-1); _scheduleHide(); }, onIncreaseFont: () { _hideTimer?.cancel(); _setFontSize(1); _scheduleHide(); }, onShowToc: () { _hideTimer?.cancel(); showReaderToc(context, _chapters, _chapterStarts, _totalChars, _position, _darkMode, hc, _pageController, _pageStarts, _scheduleHide); }, onBookmarkToggle: _toggleBookmark, isBookmarked: _isBookmarked,                     onMenuAction: _handleMenuAction, menuItems: [readerMenuPopItem('Search…', 'search', _darkMode), readerMenuPopItem('RSVP speed read', 'rsvp', _darkMode), readerMenuPopItem('Highlight', 'highlight', _darkMode), readerMenuPopItem('Highlights', 'highlights', _darkMode), readerMenuPopItem('Bookmarks', 'bookmarks', _darkMode), readerMenuPopItem('Select font…', 'select_font', _darkMode), readerMenuPopItem('Go to page…', 'go_to_page', _darkMode), readerMenuPopItem(_darkMode ? 'Light mode' : 'Dark mode', 'toggle_mode', _darkMode)]))),
      if (!_goToPageMode && !_highlightMode && !_searchMode) Positioned(bottom: 0, left: 0, right: 0, child: ReaderBottomBar(currentPage: _currentPage + 1, totalPages: _totalPages, totalChars: _totalChars, position: _position, darkMode: _darkMode, coverCount: cc, pageController: _pageController)),
      if (_goToPageMode) _buildGoToPageOverlay(pad),
      if (_searchMode) _buildSearchOverlay(pad),
    ]));
  }

  Widget _buildGoToPageOverlay(EdgeInsets pad) {
    final bgColor = _darkMode ? const Color(0xEE000000) : const Color(0xEEF5F5F0);
    final fg = _darkMode ? Colors.white : Colors.black87;
    final dim = _darkMode ? const Color(0xFF888888) : const Color(0xFF666666);
    return Column(mainAxisAlignment: MainAxisAlignment.end, children: [
      Expanded(child: Listener(behavior: HitTestBehavior.translucent, onPointerDown: (e) => _tapPosition = e.localPosition, onPointerUp: (e) { if (_tapPosition != null && (e.localPosition - _tapPosition!).distance < 10) _exitGoToPageMode(); _tapPosition = null; })),
      Container(padding: EdgeInsets.only(bottom: pad.bottom), color: bgColor, child: Column(mainAxisSize: MainAxisSize.min, children: [
        Padding(padding: const EdgeInsets.fromLTRB(20, 12, 20, 0), child: Row(children: [
          GestureDetector(onTap: _returnToOriginalPage, child: Container(width: 48, height: 64, decoration: BoxDecoration(color: _darkMode ? const Color(0xFF111111) : const Color(0xFFDDDDD8), border: Border.all(color: _goToOriginalPage == _currentPage ? fg : dim)), child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.history, size: 16, color: dim), const SizedBox(height: 2), Text('${_goToOriginalPage + 1}', style: GoogleFonts.inter(color: dim, fontSize: 9))])))),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [Text('Page ${_currentPage + 1}', style: GoogleFonts.inter(color: fg, fontSize: 14, fontWeight: FontWeight.w600)), const Spacer(), GestureDetector(onTap: _exitGoToPageMode, child: Container(width: 28, height: 28, decoration: BoxDecoration(shape: BoxShape.circle, color: _darkMode ? const Color(0xFF333333) : const Color(0xFFCCCCCC)), child: const Icon(Icons.close, size: 16, color: Colors.white)))]),
            const SizedBox(height: 4),
            if (_bookmarks.isNotEmpty) SizedBox(height: 8, child: LayoutBuilder(builder: (_, ctr) { final w = ctr.maxWidth; return Stack(children: _bookmarks.map((bm) { final frac = (bm + 1) / _totalPages; return Positioned(left: (frac * w).clamp(4.0, w - 4.0) - 3, child: Icon(Icons.bookmark, size: 8, color: _currentPage == bm ? (_darkMode ? Colors.white : Colors.black87) : dim)); }).toList()); })),
            const SizedBox(height: 4),
            Slider(value: (_currentPage + 1).toDouble().clamp(1, _totalPages.toDouble()), min: 1, max: _totalPages.toDouble().clamp(1, 99999), divisions: (_totalPages - 1).clamp(0, 999), activeColor: fg, inactiveColor: _darkMode ? const Color(0xFF333333) : const Color(0xFFCCCCCC), onChanged: _goToPageSliderChanged),
          ])),
        ])),
        const SizedBox(height: 8),
      ])),
    ]);
  }

  Widget _buildSearchOverlay(EdgeInsets pad) {
    final bgColor = _darkMode ? const Color(0xEE000000) : const Color(0xEEF5F5F0);
    final fg = _darkMode ? Colors.white : Colors.black87;
    final dim = _darkMode ? const Color(0xFF888888) : const Color(0xFF666666);
    final accent = const Color(0xFFE05555);

    return Column(children: [
      Container(padding: EdgeInsets.only(top: pad.top), color: bgColor, child: SizedBox(height: 56, child: Row(children: [
        IconButton(icon: Icon(Icons.arrow_back, color: fg, size: 22), onPressed: _exitSearchMode),
        Expanded(child: TextField(
          controller: _searchController,
          autofocus: true,
          onChanged: (v) { _searchQuery = v; _performSearch(v); },
          style: GoogleFonts.inter(color: fg, fontSize: 14),
          cursorColor: accent,
          decoration: InputDecoration(
            hintText: 'Search…',
            hintStyle: GoogleFonts.inter(color: dim, fontSize: 14),
            border: InputBorder.none,
            contentPadding: EdgeInsets.zero,
          ),
        )),
        if (_searchQuery.isNotEmpty)
          Text('${_searchResults.length}', style: GoogleFonts.inter(color: dim, fontSize: 12)),
        const SizedBox(width: 8),
      ]))),
      if (_searchQuery.isNotEmpty)
        Expanded(child: Container(color: bgColor, child: _searchResults.isEmpty
            ? Center(child: Text('No results', style: GoogleFonts.inter(color: dim, fontSize: 13)))
            : ListView.builder(
                padding: EdgeInsets.only(bottom: pad.bottom),
                itemCount: _searchResults.length.clamp(0, 100),
                itemBuilder: (_, i) {
                  final m = _searchResults[i];
                  final pos = m['pos']!;
                  final len = m['len']!;
                  final start = (pos - 40).clamp(0, _fullText.length);
                  final end = (pos + len + 40).clamp(0, _fullText.length);
                  final before = _fullText.substring(start, pos);
                  final match = _fullText.substring(pos, pos + len);
                  final after = _fullText.substring(pos + len, end);
                  final pg = _findPageForPosition(pos);
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
                    subtitle: Text('Page ${pg + 1}', style: GoogleFonts.inter(color: _darkMode ? const Color(0xFF555555) : const Color(0xFF999999), fontSize: 11)),
                    onTap: () => _navigateToSearchResult(pos),
                  );
                },
              ),
        )),
    ]);
  }

  Widget _buildCoverPage(Book b, Color bg) => Container(color: bg, child: Center(child: Padding(padding: const EdgeInsets.all(24), child: ClipRRect(borderRadius: BorderRadius.zero, child: Image.memory(b.coverBytes!, fit: BoxFit.contain)))));

  Widget _buildTextPage(String text, EdgeInsets pad, int pageStart) {
    final isCh = _isChapterStart(text); final tk = GlobalKey();

    // Build highlighted text spans
    final normStyle = _textStyle(height: 1.7);
    final hlStyle = _textStyle(height: 1.7, color: _darkMode ? const Color(0xFF000000) : const Color(0xFFFFFFFF));
    final hlBg = _darkMode ? const Color(0xAAFFFFFF) : const Color(0xAA000000);
    final pageEnd = pageStart + text.length;

    Widget content;
    final pageHighlights = _highlights.where((h) => h['s']! < pageEnd && h['e']! > pageStart).toList();
    if (pageHighlights.isEmpty) {
      content = Text(text, key: tk, style: normStyle);
    } else {
      final spans = <TextSpan>[];
      var pos = 0;
      for (final hl in pageHighlights) {
        final localStart = (hl['s']! - pageStart).clamp(0, text.length);
        final localEnd = (hl['e']! - pageStart).clamp(0, text.length);
        if (localStart > pos) spans.add(TextSpan(text: text.substring(pos, localStart), style: normStyle));
        if (localEnd > localStart) {
          spans.add(TextSpan(text: text.substring(localStart, localEnd), style: hlStyle.copyWith(backgroundColor: hlBg)));
          // Apply highlight background via a WidgetSpan or just use backgroundColor on the span
        }
        pos = localEnd;
      }
      if (pos < text.length) spans.add(TextSpan(text: text.substring(pos), style: normStyle));
      content = RichText(key: tk, text: TextSpan(children: spans));
    }

    return GestureDetector(
      onDoubleTapDown: _highlightMode ? null : (d) => _handleDoubleTap(d, text, tk),
      onTapDown: (_rsvpPickCompleter != null || _highlightMode) ? (d) => _handleDoubleTap(d, text, tk) : null,
      child: SingleChildScrollView(physics: const NeverScrollableScrollPhysics(), padding: EdgeInsets.fromLTRB(24, pad.top + 48, 24, 0), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [if (isCh) ...[_buildChapterHeader(text), const SizedBox(height: 12)], content])),
    );
  }

  bool _isChapterStart(String text) { for (final ch in _chapters) { if (text.startsWith('${ch.title}\n')) return true; } return false; }
  Widget _buildChapterHeader(String text) { for (final ch in _chapters) { if (text.startsWith('${ch.title}\n')) return Text(ch.title, style: _textStyle(fontSize: _fontSize * 0.7, fontWeight: FontWeight.w500, letterSpacing: 2)); } return const SizedBox.shrink(); }
}

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/book.dart';
import '../providers/book_list_provider.dart';
import '../services/book_storage.dart';
import '../services/dictionary_service.dart';
import '../services/epub_parser.dart';

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

  void _jumpToChapter(int index) {
    if (_chapters.isEmpty) return;
    final pos = _chapterPosition(index);
    final page = _findPageForPosition(pos);
    final coverOff = widget.book.coverBytes != null ? 1 : 0;
    setState(() => _position = pos);
    _pageController.jumpToPage(page + coverOff);
  }

  void _showToc() {
    _hideTimer?.cancel();
    showModalBottomSheet(
      context: context,
      backgroundColor: _darkMode ? const Color(0xFF0F0F0F) : const Color(0xFFF0F0EB),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      builder: (ctx) => Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.6),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(padding: const EdgeInsets.fromLTRB(20, 16, 20, 12), child: Text('Contents', style: GoogleFonts.inter(color: _darkMode ? Colors.white : Colors.black87, fontSize: 16, fontWeight: FontWeight.w600))),
          Container(color: _darkMode ? const Color(0xFF141414) : const Color(0xFFDDDDD8), height: 0.5),
          Expanded(child: ListView.builder(padding: const EdgeInsets.symmetric(vertical: 8), itemCount: _chapters.length, itemBuilder: (_, i) {
            final next = i < _chapterStarts.length - 1 ? _chapterStarts[i + 1] : _totalChars;
            final cur = _position >= _chapterStarts[i] && _position < next;
            return ListTile(
              dense: true,
              leading: Text('${i + 1}', style: GoogleFonts.inter(color: _darkMode ? const Color(0xFF555555) : const Color(0xFF999999), fontSize: 13)),
              title: Text(_chapters[i].title, style: GoogleFonts.inter(color: cur ? (_darkMode ? Colors.white : Colors.black87) : (_darkMode ? const Color(0xFFAAAAAA) : const Color(0xFF666666)), fontSize: 14, fontWeight: cur ? FontWeight.w600 : FontWeight.w400), maxLines: 2, overflow: TextOverflow.ellipsis),
              selected: cur,
              selectedTileColor: _darkMode ? const Color(0xFF1A1A1A) : const Color(0xFFE8E8E3),
              onTap: () { Navigator.pop(ctx); _jumpToChapter(i); },
            );
          })),
        ]),
      ),
    ).then((_) => _scheduleHide());
  }

  int _chapterPosition(int chapterIndex) {
    if (chapterIndex < _chapterStarts.length) return _chapterStarts[chapterIndex];
    return _totalChars;
  }

  void _saveProgress() {
    if (_totalChars <= 0) return;
    final p = _position / _totalChars;
    final idx = ref.read(bookListProvider).indexWhere((b) => b.filePath == widget.book.filePath);
    if (idx != -1) ref.read(bookListProvider.notifier).editBook(idx, progress: p);
  }

  TextStyle _textStyle({double? fontSize, Color? color, FontWeight? fontWeight, double? height, double? letterSpacing}) {
    return GoogleFonts.getFont(_fontFamily, fontSize: fontSize ?? _fontSize, fontWeight: fontWeight ?? FontWeight.w400, color: color ?? (_darkMode ? const Color(0xFFCCCCCC) : const Color(0xFF1A1A1A)), height: height, letterSpacing: letterSpacing);
  }

  void _handleMenuAction(String value) {
    _hideTimer?.cancel();
    switch (value) {
      case 'select_font': _showFontDialog(); return;
      case 'go_to_page': _showGoToPage(); return;
      case 'toggle_mode':
        setState(() => _darkMode = !_darkMode);
        BookStorage.saveDarkMode(widget.book.filePath, _darkMode);
        break;
    }
    _scheduleHide();
  }

  void _showFontDialog() {
    final fonts = ['Inter', 'Lora', 'Merriweather', 'Space Mono'];
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: _darkMode ? const Color(0xFF0F0F0F) : const Color(0xFFF0F0EB),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        child: Padding(padding: const EdgeInsets.fromLTRB(8, 16, 8, 8), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(padding: const EdgeInsets.only(left: 16, bottom: 8), child: Text('Select font', style: GoogleFonts.inter(color: _darkMode ? Colors.white : Colors.black87, fontSize: 15, fontWeight: FontWeight.w600))),
          ...fonts.map((f) => ListTile(
            dense: true,
            title: Text(f, style: GoogleFonts.getFont(f, fontSize: 16, color: _darkMode ? Colors.white : Colors.black87)),
            trailing: _fontFamily == f ? Icon(Icons.check, size: 18, color: _darkMode ? Colors.white : Colors.black87) : null,
            onTap: () { setState(() => _fontFamily = f); BookStorage.saveFontFamily(widget.book.filePath, f); Navigator.pop(ctx); },
          )),
        ])),
      ),
    ).then((_) => _scheduleHide());
  }

  void _showGoToPage() {
    final coverOff = widget.book.coverBytes != null ? 1 : 0;
    var target = _currentPage + 1;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setD) => Dialog(
        backgroundColor: _darkMode ? const Color(0xFF0F0F0F) : const Color(0xFFF0F0EB),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        child: Padding(padding: const EdgeInsets.fromLTRB(24, 20, 24, 12), child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Go to page', style: GoogleFonts.inter(color: _darkMode ? Colors.white : Colors.black87, fontSize: 15, fontWeight: FontWeight.w600)),
          const SizedBox(height: 20),
          Row(children: [
            Text('1', style: GoogleFonts.inter(color: _darkMode ? const Color(0xFF555555) : const Color(0xFF999999), fontSize: 12)),
            Expanded(child: Slider(value: target.toDouble().clamp(1, _totalPages.toDouble()), min: 1, max: _totalPages.toDouble().clamp(1, 99999), divisions: (_totalPages - 1).clamp(0, 999), activeColor: _darkMode ? Colors.white : Colors.black87, inactiveColor: _darkMode ? const Color(0xFF333333) : const Color(0xFFCCCCCC), onChanged: (v) => setD(() => target = v.round()))),
            Text('$_totalPages', style: GoogleFonts.inter(color: _darkMode ? const Color(0xFF555555) : const Color(0xFF999999), fontSize: 12)),
          ]),
          const SizedBox(height: 4),
          Text('Page $target', style: GoogleFonts.inter(color: _darkMode ? Colors.white : Colors.black87, fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel', style: GoogleFonts.inter(color: _darkMode ? const Color(0xFF888888) : const Color(0xFF999999), fontSize: 13))),
            const SizedBox(width: 8),
            TextButton(onPressed: () { Navigator.pop(ctx); final tp = target - 1; if (tp >= 0 && tp < _totalPages) { _pageController.jumpToPage(tp + coverOff); _position = _pageStarts[tp]; BookStorage.savePosition(widget.book.filePath, _position); } }, child: Text('Go', style: GoogleFonts.inter(color: _darkMode ? Colors.white : Colors.black87, fontSize: 13, fontWeight: FontWeight.w600))),
          ]),
        ])),
      )),
    ).then((_) => _scheduleHide());
  }

  @override
  void dispose() {
    _saveProgress();
    _pageController.dispose();
    _hideTimer?.cancel();
    super.dispose();
  }

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
    return GestureDetector(
      onTap: _toggleControls,
      behavior: HitTestBehavior.translucent,
      child: Stack(children: [
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
        AnimatedOpacity(opacity: _controlsVisible ? 1.0 : 0.0, duration: const Duration(milliseconds: 250), child: IgnorePointer(ignoring: !_controlsVisible, child: _buildAppBar(book, pad))),
        Positioned(bottom: 0, left: 0, right: 0, child: _buildBottomBar(coverCount)),
      ]),
    );
  }

  Widget _buildAppBar(Book book, EdgeInsets pad) {
    final fg = _darkMode ? Colors.white : Colors.black87;
    final abg = _darkMode ? const Color(0xDD000000) : const Color(0xDDF5F5F0);
    return Container(padding: EdgeInsets.only(top: pad.top), color: abg, child: SizedBox(height: 52, child: Row(children: [
      IconButton(icon: Icon(Icons.arrow_back, color: fg, size: 22), onPressed: () { _saveProgress(); Navigator.pop(context); }),
      Expanded(child: Text(book.title, style: GoogleFonts.inter(color: fg, fontSize: 14, fontWeight: FontWeight.w500, letterSpacing: 0.5), maxLines: 1, overflow: TextOverflow.ellipsis)),
      IconButton(icon: Icon(Icons.text_decrease, color: fg, size: 20), onPressed: () { _hideTimer?.cancel(); _setFontSize(-1); _scheduleHide(); }),
      IconButton(icon: Icon(Icons.text_increase, color: fg, size: 20), onPressed: () { _hideTimer?.cancel(); _setFontSize(1); _scheduleHide(); }),
      IconButton(icon: Icon(Icons.list, color: fg, size: 20), onPressed: _showToc),
      PopupMenuButton<String>(
        onSelected: _handleMenuAction,
        icon: Icon(Icons.more_vert, color: fg, size: 20), iconSize: 20, splashRadius: 20,
        color: _darkMode ? const Color(0xFF141414) : const Color(0xFFF0F0EB),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero, side: BorderSide(color: Color(0xFF222222))),
        itemBuilder: (_) => [
          _menuPopItem('Select font…', 'select_font'),
          _menuPopItem('Go to page…', 'go_to_page'),
          _menuPopItem(_darkMode ? 'Light mode' : 'Dark mode', 'toggle_mode'),
        ],
      ),
    ])));
  }

  PopupMenuItem<String> _menuPopItem(String label, String value) {
    return PopupMenuItem<String>(value: value, height: 38, child: Text(label, style: GoogleFonts.inter(color: _darkMode ? const Color(0xFFAAAAAA) : const Color(0xFF666666), fontSize: 13)));
  }

  Widget _buildBottomBar(int coverCount) {
    final pad = MediaQuery.of(context).padding;
    final bbg = _darkMode ? const Color(0xDD000000) : const Color(0xDDF5F5F0);
    final fg = _darkMode ? const Color(0xFF888888) : const Color(0xFF666666);
    return Container(
      padding: EdgeInsets.only(bottom: pad.bottom), color: bbg,
      child: SizedBox(height: 36, child: Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: Row(children: [
        if (coverCount > 0 && _pageController.hasClients && _pageController.page?.round() == 0)
          Text('Cover', style: GoogleFonts.inter(color: fg, fontSize: 11))
        else ...[
          Text('${_currentPage + 1} / $_totalPages', style: GoogleFonts.inter(color: fg, fontSize: 11)),
          const SizedBox(width: 12),
          Expanded(child: ClipRRect(borderRadius: BorderRadius.zero, child: LinearProgressIndicator(value: _totalPages > 1 ? (_currentPage / (_totalPages - 1)).clamp(0.0, 1.0) : 0, backgroundColor: _darkMode ? const Color(0xFF1A1A1A) : const Color(0xFFE0E0DB), valueColor: AlwaysStoppedAnimation(_darkMode ? const Color(0xFF444444) : const Color(0xFFAAAAAA)), minHeight: 2))),
        ],
        const SizedBox(width: 12),
        Text('${_totalChars > 0 ? (_position * 100 ~/ _totalChars) : 0}%', style: GoogleFonts.inter(color: fg, fontSize: 11)),
      ]))),
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
      child: SingleChildScrollView(physics: const NeverScrollableScrollPhysics(), padding: EdgeInsets.fromLTRB(24, pad.top + 48, 24, 0), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (isCh) ...[_buildChapterHeader(text), const SizedBox(height: 12)],
        Text(text, key: textKey, style: _textStyle(height: 1.7)),
      ])),
    );
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
    final word = text.substring(s, e).trim().toLowerCase();
    if (word.length < 2 || word.length > 30) return;
    _hideTimer?.cancel();
    setState(() => _controlsVisible = true);
    showDialog(context: context, builder: (ctx) => _DictionaryDialog(word: word)).then((_) => _scheduleHide());
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

class _DictionaryDialog extends StatefulWidget {
  final String word;
  const _DictionaryDialog({required this.word});
  @override
  State<_DictionaryDialog> createState() => _DictionaryDialogState();
}

class _DictionaryDialogState extends State<_DictionaryDialog> {
  String? _definition;
  bool _loading = true;

  @override
  void initState() { super.initState(); _lookup(); }

  Future<void> _lookup() async {
    final def = await DictionaryService.lookup(widget.word);
    if (mounted) setState(() { _definition = def; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(backgroundColor: const Color(0xFF0F0F0F), shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero), child: Padding(padding: const EdgeInsets.all(20), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(widget.word, style: GoogleFonts.inter(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
      const SizedBox(height: 12),
      if (_loading) const SizedBox(height: 40, child: Center(child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Color(0xFF333333)))))
      else if (_definition != null) Text(_definition!, style: GoogleFonts.inter(color: const Color(0xFFBBBBBB), fontSize: 14, height: 1.5))
      else Text('No definition found.', style: GoogleFonts.inter(color: const Color(0xFF666666), fontSize: 14)),
      const SizedBox(height: 16),
      Align(alignment: Alignment.centerRight, child: TextButton(onPressed: () => Navigator.pop(context), child: Text('Close', style: GoogleFonts.inter(color: const Color(0xFF888888), fontSize: 13)))),
    ])));
  }
}

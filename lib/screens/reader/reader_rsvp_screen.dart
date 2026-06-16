import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/book_storage.dart';

class RsvpScreen extends StatefulWidget {
  final String fullText;
  final int startPosition;
  final int totalChars;
  final String fontFamily;
  final bool darkMode;
  final int pauseAfterWords;

  const RsvpScreen({
    super.key,
    required this.fullText,
    required this.startPosition,
    required this.totalChars,
    required this.fontFamily,
    required this.darkMode,
    this.pauseAfterWords = 0,
  });

  @override
  State<RsvpScreen> createState() => _RsvpScreenState();
}

class _RsvpScreenState extends State<RsvpScreen> {
  int _index = 0;
  int _wpm = 180;
  bool _playing = false;
  Timer? _timer;
  bool _controlsVisible = true;
  Timer? _hideTimer;
  int _sentencesSincePause = 0;
  bool _isFirstWordOfSentence = true;
  bool _showBlank = false;
  late final List<_Word> _words;
  late final TextStyle _measuredStyle;
  final TextPainter _measurer = TextPainter(textDirection: TextDirection.ltr);

  static const _minWpm = 50;
  static const _maxWpm = 400;
  static const _autoHideDelay = Duration(seconds: 3);
  static const double _wordSpacing = 10.0;

  @override
  void initState() {
    super.initState();
    _words = _tokenize(widget.fullText);
    _measuredStyle = GoogleFonts.getFont(widget.fontFamily, fontSize: 32, fontWeight: FontWeight.w400);
    _index = _findWordIndex(widget.startPosition);
    _isFirstWordOfSentence = _index == 0 || _isWordSentenceEnd(_words[_index - 1].text);
    _loadWpm();
    _scheduleHide();
  }

  Future<void> _loadWpm() async {
    final saved = await BookStorage.loadRsvpWpm();
    if (saved != null && mounted) {
      setState(() => _wpm = ((saved.clamp(_minWpm, _maxWpm)) / 5).round() * 5);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _hideTimer?.cancel();
    super.dispose();
  }

  List<_Word> _tokenize(String text) {
    final words = <_Word>[];
    final re = RegExp(r'\S+');
    for (final match in re.allMatches(text)) {
      words.add(_Word(match.group(0)!, match.start));
    }
    return words;
  }

  int _findWordIndex(int charPos) {
    var result = 0;
    for (var i = 0; i < _words.length; i++) {
      if (_words[i].startPos <= charPos) { result = i; } else { break; }
    }
    return result.clamp(0, _words.length - 1);
  }

  int get _currentCharPos {
    if (_words.isEmpty) return 0;
    return _words[_index.clamp(0, _words.length - 1)].startPos;
  }

  void _scheduleHide() {
    _hideTimer?.cancel();
    _hideTimer = Timer(_autoHideDelay, () {
      if (mounted) setState(() => _controlsVisible = false);
    });
  }

  void _togglePlaying() {
    _timer?.cancel();
    if (_playing) {
      setState(() { _playing = false; _sentencesSincePause = 0; _showBlank = false; });
      return;
    }
    setState(() => _playing = true);
    _tick();
  }

  void _tick() {
    if (!_playing || _index >= _words.length - 1) {
      setState(() => _playing = false);
      return;
    }
    final word = _words[_index].text;
    final ms = _getWordDuration(word);
    _timer = Timer(Duration(milliseconds: ms.round()), () {
      if (!mounted || !_playing) return;

      final breathMs = _punctuationBreath(word);
      if (breathMs > 0) {
        _index++;
        setState(() {
          _showBlank = true;
          if (_isWordSentenceEnd(word)) { _sentencesSincePause++; _isFirstWordOfSentence = true; }
        });
        _timer = Timer(Duration(milliseconds: breathMs), () {
          if (!mounted || !_playing) return;
          setState(() => _showBlank = false);
          if (widget.pauseAfterWords > 0 && _sentencesSincePause >= widget.pauseAfterWords) {
            setState(() { _playing = false; _sentencesSincePause = 0; _isFirstWordOfSentence = true; _showBlank = false; });
            return;
          }
          _tick();
        });
        return;
      }

      setState(() {
        if (_index < _words.length - 1) {
          _index++;
          final nextWord = _words[_index].text;
          final isSentenceEnd = _isWordSentenceEnd(nextWord);
          _isFirstWordOfSentence = isSentenceEnd;
          if (isSentenceEnd) { _sentencesSincePause++; }
        }
      });
      if (widget.pauseAfterWords > 0 && _sentencesSincePause >= widget.pauseAfterWords) {
        setState(() { _playing = false; _sentencesSincePause = 0; _isFirstWordOfSentence = true; _showBlank = false; });
        return;
      }
      _tick();
    });
  }

  int _punctuationBreath(String word) {
    if (word.endsWith('.') || word.endsWith('!') || word.endsWith('?')) return 300;
    if (word.endsWith(';')) return 180;
    if (word.endsWith(',')) return 100;
    return 0;
  }

  double _getWordDuration(String word) {
    final baseMs = 60000 / _wpm;
    var multiplier = 1.0;

    final len = word.replaceAll(RegExp(r'[^a-zA-Z]'), '').length;
    if (len > 5) { multiplier += (len - 5) * 0.1; }

    final syllables = _countSyllables(word);
    if (syllables > 2) { multiplier += (syllables - 2) * 0.15; }

    if (_isWordSentenceEnd(word)) {
      multiplier += 0.8;
    } else if (word.endsWith(',') || word.endsWith(';')) {
      multiplier += 0.3;
    } else if (word.endsWith(':')) {
      multiplier += 0.4;
    }

    if (RegExp(r'\d').hasMatch(word)) { multiplier += 0.5; }

    if (word.contains('-')) {
      final parts = word.split('-');
      double hyphenPenalty = 0;
      for (final part in parts) {
        final partLen = part.length;
        hyphenPenalty += partLen > 5 ? (partLen - 5) * 0.1 : 0.05;
      }
      multiplier += hyphenPenalty + 0.3;
    }

    if (_isFirstWordOfSentence) { multiplier += 0.2; }

    return baseMs * multiplier.clamp(1.0, 4.0);
  }

  int _countSyllables(String word) {
    final w = word.toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');
    if (w.isEmpty) return 1;
    final vowelGroups = RegExp(r'[aeiouy]+').allMatches(w).length;
    var count = vowelGroups;
    if (w.endsWith('e') && w.length > 2) count--;
    return count < 1 ? 1 : count;
  }

  void _skip(int count) {
    _timer?.cancel();
    _scheduleHide();
    final wasPlaying = _playing;
    setState(() {
      _playing = false;
      _showBlank = false;
      _index = (_index + count).clamp(0, _words.length - 1);
      _isFirstWordOfSentence = _index == 0 || _isWordSentenceEnd(_words[_index - 1].text);
    });
    if (wasPlaying) {
      setState(() => _playing = true);
      _tick();
    }
  }

  bool _isWordSentenceEnd(String word) {
    return word.endsWith('.') || word.endsWith('!') || word.endsWith('?');
  }

  void _adjustWpm(int delta) {
    final newWpm = ((_wpm + delta) / 5).round() * 5;
    setState(() => _wpm = newWpm.clamp(_minWpm, _maxWpm));
    BookStorage.saveRsvpWpm(_wpm);
    if (_playing) { _timer?.cancel(); _tick(); }
  }

  Widget _buildWord() {
    if (_words.isEmpty) return const SizedBox.shrink();
    if (_showBlank) return Container(color: widget.darkMode ? const Color(0xFF000000) : const Color(0xFFF5F5F0));

    final isFinished = _words.length > 1 && _index >= _words.length - 1;
    final isPaused = !_playing && !isFinished;
    final bg = widget.darkMode ? const Color(0xFF000000) : const Color(0xFFF5F5F0);
    final fg = widget.darkMode ? Colors.white : Colors.black87;

    return GestureDetector(
      onTap: () { setState(() => _controlsVisible = !_controlsVisible); if (_controlsVisible) { _scheduleHide(); } else { _hideTimer?.cancel(); } },
      child: Container(
        color: bg,
        child: Center(
          child: isFinished
              ? Column(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.check_circle, size: 48, color: Color(0xFF444444)),
                  const SizedBox(height: 16),
                  Text('Finished', style: GoogleFonts.getFont(widget.fontFamily, fontSize: 18, color: const Color(0xFF555555))),
                ])
              : Column(mainAxisSize: MainAxisSize.min, children: [
                  _buildWordStrip(fg),
                  if (isPaused) ...[
                    const SizedBox(height: 20),
                    Text('Paused', style: GoogleFonts.inter(color: const Color(0xFF555555), fontSize: 13)),
                    const SizedBox(height: 8),
                    TextButton.icon(onPressed: _togglePlaying, icon: const Icon(Icons.play_arrow, size: 16, color: Color(0xFF888888)), label: Text('Resume', style: GoogleFonts.inter(color: const Color(0xFF888888), fontSize: 13))),
                  ],
                ]),
        ),
      ),
    );
  }

  Widget _buildWordStrip(Color fg) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const int windowRadius = 8;
        final startIdx = (_index - windowRadius).clamp(0, _words.length);
        final endIdx = (_index + windowRadius + 1).clamp(0, _words.length);

        var leadingWidth = 0.0;
        for (int i = startIdx; i < _index; i++) {
          _measurer.text = TextSpan(text: _words[i].text, style: _measuredStyle);
          _measurer.layout();
          leadingWidth += _measurer.width + _wordSpacing;
        }
        _measurer.text = TextSpan(text: _words[_index].text, style: _measuredStyle);
        _measurer.layout();
        final currentWidth = _measurer.width;
        final stripOffset = constraints.maxWidth / 2 - leadingWidth - currentWidth / 2;

        return SizedBox(
          height: 56,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 100),
                curve: Curves.easeOut,
                left: stripOffset,
                top: 0,
                bottom: 0,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [for (int i = startIdx; i < endIdx; i++) _buildWordWidget(i, fg)],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWordWidget(int i, Color fg) {
    final word = _words[i].text;
    final distance = (i - _index).abs();
    final opacity = i == _index ? 1.0 : (distance == 1 ? 0.7 : (distance == 2 ? 0.45 : 0.25));
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _wordSpacing / 2),
      child: AnimatedOpacity(
        opacity: opacity,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Text(
          word,
          style: GoogleFonts.getFont(
            widget.fontFamily,
            fontSize: 32,
            fontWeight: i == _index ? FontWeight.w600 : FontWeight.w400,
            color: fg,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pad = MediaQuery.of(context).padding;
    final bg = widget.darkMode ? const Color(0xDD000000) : const Color(0xDDF5F5F0);
    final fg = widget.darkMode ? Colors.white : Colors.black87;
    final dim = widget.darkMode ? const Color(0xFF888888) : const Color(0xFF666666);

    return Scaffold(
      backgroundColor: widget.darkMode ? const Color(0xFF000000) : const Color(0xFFF5F5F0),
      body: Stack(children: [
        _buildWord(),
        _buildBottomControls(pad, bg, fg, dim),
        _buildTopBar(pad, bg),
      ]),
    );
  }

  Widget _buildBottomControls(EdgeInsets pad, Color bg, Color fg, Color dim) {
    final progress = widget.totalChars > 0 ? _currentCharPos / widget.totalChars : 0.0;
    return Positioned(
      bottom: 0, left: 0, right: 0,
      child: AnimatedOpacity(
        opacity: _controlsVisible ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 250),
        child: IgnorePointer(
          ignoring: !_controlsVisible,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(color: bg, padding: const EdgeInsets.fromLTRB(20, 12, 20, 0), child: Column(children: [
                Row(children: [
                  Text('$_wpm WPM', style: GoogleFonts.inter(color: fg, fontSize: 13, fontWeight: FontWeight.w600)),
                  const Spacer(),
                  Text('${(progress * 100).round()}%', style: GoogleFonts.inter(color: dim, fontSize: 11)),
                ]),
                Row(children: [
                  IconButton(icon: Icon(Icons.remove, color: fg, size: 18), onPressed: () => _adjustWpm(-5), visualDensity: VisualDensity.compact),
                  Expanded(child: Slider(value: _wpm.toDouble(), min: _minWpm.toDouble(), max: _maxWpm.toDouble(), divisions: ((_maxWpm - _minWpm) / 5).round(), activeColor: fg, inactiveColor: widget.darkMode ? const Color(0xFF333333) : const Color(0xFFCCCCCC), onChangeStart: (_) => _hideTimer?.cancel(), onChangeEnd: (_) => _scheduleHide(), onChanged: (v) => _adjustWpm(v.round() - _wpm))),
                  IconButton(icon: Icon(Icons.add, color: fg, size: 18), onPressed: () => _adjustWpm(5), visualDensity: VisualDensity.compact),
                ]),
              ])),
              Container(padding: EdgeInsets.only(bottom: pad.bottom), color: bg, child: SizedBox(height: 56, child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                IconButton(icon: Icon(Icons.skip_previous, color: fg, size: 28), onPressed: () => _skip(-50)),
                IconButton(icon: Icon(Icons.fast_rewind, color: fg, size: 24), onPressed: () => _skip(-5)),
                SizedBox(width: 56, height: 56, child: IconButton(icon: Icon(_playing ? Icons.pause : Icons.play_arrow, color: fg, size: 32), onPressed: _togglePlaying)),
                IconButton(icon: Icon(Icons.fast_forward, color: fg, size: 24), onPressed: () => _skip(5)),
                IconButton(icon: Icon(Icons.skip_next, color: fg, size: 28), onPressed: () => _skip(50)),
              ]))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(EdgeInsets pad, Color bg) {
    return Positioned(
      top: 0, left: 0, right: 0,
      child: AnimatedOpacity(
        opacity: _controlsVisible ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 250),
        child: IgnorePointer(
          ignoring: !_controlsVisible,
          child: Container(padding: EdgeInsets.only(top: pad.top), color: bg, child: SizedBox(height: 52, child: Row(children: [
            IconButton(icon: const Icon(Icons.close, color: Colors.white, size: 22), onPressed: () => Navigator.pop(context, _currentCharPos)),
            const Spacer(),
          ]))),
        ),
      ),
    );
  }
}

class _Word {
  final String text;
  final int startPos;
  const _Word(this.text, this.startPos);
}

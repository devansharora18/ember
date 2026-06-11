import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
  int _wpm = 300;
  bool _playing = false;
  Timer? _timer;
  bool _controlsVisible = true;
  Timer? _hideTimer;
  int _sentencesSincePause = 0;

  late final List<_Word> _words;

  static const _minWpm = 50;
  static const _maxWpm = 1000;
  static const _autoHideDelay = Duration(seconds: 3);

  @override
  void initState() {
    super.initState();
    _words = _tokenize(widget.fullText);
    _index = _findWordIndex(widget.startPosition);
    _scheduleHide();
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
    for (var i = 0; i < _words.length; i++) {
      if (_words[i].startPos >= charPos) return i.clamp(0, _words.length - 1);
    }
    return _words.length - 1;
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
      setState(() { _playing = false; _sentencesSincePause = 0; });
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
    final delay = Duration(milliseconds: (60000 / _wpm).round());
    _timer = Timer(delay, () {
      if (!mounted || !_playing) return;
      setState(() {
        if (_index < _words.length - 1) {
          _index++;
          final word = _words[_index].text;
          if (word.endsWith('.') || word.endsWith('!') || word.endsWith('?')) {
            _sentencesSincePause++;
          }
        }
      });
      if (widget.pauseAfterWords > 0 && _sentencesSincePause >= widget.pauseAfterWords) {
        setState(() { _playing = false; _sentencesSincePause = 0; });
        return;
      }
      _tick();
    });
  }

  void _skip(int count) {
    _timer?.cancel();
    final wasPlaying = _playing;
    setState(() {
      _playing = false;
      _index = (_index + count).clamp(0, _words.length - 1);
    });
    if (wasPlaying) {
      setState(() => _playing = true);
      _tick();
    }
  }

  void _adjustWpm(int delta) {
    setState(() => _wpm = (_wpm + delta).clamp(_minWpm, _maxWpm));
    if (_playing) {
      _timer?.cancel();
      _tick();
    }
  }

  Widget _buildWord() {
    if (_words.isEmpty) return const SizedBox.shrink();
    final w = _words[_index.clamp(0, _words.length - 1)].text;
    final isFinished = _words.length > 1 && _index >= _words.length - 1;
    final isPaused = !_playing && !isFinished;
    final bg = widget.darkMode ? const Color(0xFF000000) : const Color(0xFFF5F5F0);
    final fg = widget.darkMode ? Colors.white : Colors.black87;
    final dim = widget.darkMode ? const Color(0xFF888888) : const Color(0xFF999999);
    final accent = const Color(0xFFE05555);

    return GestureDetector(
      onTap: () { setState(() => _controlsVisible = !_controlsVisible); if (_controlsVisible) { _scheduleHide(); } else { _hideTimer?.cancel(); } },
      child: Container(
        color: bg,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: isFinished
                ? Column(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.check_circle, size: 48, color: Color(0xFF444444)),
                    const SizedBox(height: 16),
                    Text('Finished', style: GoogleFonts.getFont(widget.fontFamily, fontSize: 18, color: const Color(0xFF555555))),
                  ])
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildOrpWord(w, fg, dim, accent),
                      if (isPaused) ...[
                        const SizedBox(height: 20),
                        Text('Paused', style: GoogleFonts.inter(color: const Color(0xFF555555), fontSize: 13)),
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: _togglePlaying,
                          icon: const Icon(Icons.play_arrow, size: 16, color: Color(0xFF888888)),
                          label: Text('Resume', style: GoogleFonts.inter(color: const Color(0xFF888888), fontSize: 13)),
                        ),
                      ],
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  int _orpIndex(int length) {
    if (length <= 1) return 0;
    return ((length - 1) / 3).floor().clamp(0, 4);
  }

  Widget _buildOrpWord(String word, Color fg, Color dim, Color accent) {
    if (word.length <= 1) {
      return Text(word, textAlign: TextAlign.center, style: GoogleFonts.getFont(widget.fontFamily, fontSize: 36, fontWeight: FontWeight.w500, color: fg));
    }

    final orp = _orpIndex(word.length);
    final left = word.substring(0, orp);
    final focal = word[orp];
    final right = word.substring(orp + 1);

    final baseStyle = TextStyle(fontFamily: GoogleFonts.getFont(widget.fontFamily).fontFamily, fontSize: 36, fontWeight: FontWeight.w500);

    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(children: [
        if (left.isNotEmpty) TextSpan(text: left, style: baseStyle.copyWith(color: fg)),
        TextSpan(text: focal, style: baseStyle.copyWith(color: accent)),
        if (right.isNotEmpty) TextSpan(text: right, style: baseStyle.copyWith(color: dim)),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pad = MediaQuery.of(context).padding;
    final bg = widget.darkMode ? const Color(0xDD000000) : const Color(0xDDF5F5F0);
    final fg = widget.darkMode ? Colors.white : Colors.black87;
    final dim = widget.darkMode ? const Color(0xFF888888) : const Color(0xFF666666);
    final progress = widget.totalChars > 0 ? _currentCharPos / widget.totalChars : 0.0;

    return Scaffold(
      backgroundColor: widget.darkMode ? const Color(0xFF000000) : const Color(0xFFF5F5F0),
      body: Stack(
        children: [
          _buildWord(),
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: AnimatedOpacity(
              opacity: _controlsVisible ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 250),
              child: IgnorePointer(
                ignoring: !_controlsVisible,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Speed slider
                    Container(
                      color: bg,
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                      child: Column(children: [
                        Row(children: [
                          Text('${_wpm}WPM', style: GoogleFonts.inter(color: fg, fontSize: 13, fontWeight: FontWeight.w600)),
                          const Spacer(),
                          Text('${(progress * 100).round()}%', style: GoogleFonts.inter(color: dim, fontSize: 11)),
                        ]),
                        Row(children: [
                          IconButton(icon: Icon(Icons.remove, color: fg, size: 18), onPressed: () => _adjustWpm(-50), visualDensity: VisualDensity.compact),
                          Expanded(child: Slider(value: _wpm.toDouble(), min: _minWpm.toDouble(), max: _maxWpm.toDouble(), activeColor: fg, inactiveColor: widget.darkMode ? const Color(0xFF333333) : const Color(0xFFCCCCCC), onChanged: (v) => _adjustWpm(v.round() - _wpm))),
                          IconButton(icon: Icon(Icons.add, color: fg, size: 18), onPressed: () => _adjustWpm(50), visualDensity: VisualDensity.compact),
                        ]),
                      ]),
                    ),
                    // Bottom bar
                    Container(
                      padding: EdgeInsets.only(bottom: pad.bottom),
                      color: bg,
                      child: SizedBox(
                        height: 56,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            IconButton(icon: Icon(Icons.skip_previous, color: fg, size: 28), onPressed: () => _skip(-50)),
                            IconButton(icon: Icon(Icons.fast_rewind, color: fg, size: 24), onPressed: () => _skip(-5)),
                            SizedBox(
                              width: 56, height: 56,
                              child: IconButton(
                                icon: Icon(_playing ? Icons.pause : Icons.play_arrow, color: fg, size: 32),
                                onPressed: _togglePlaying,
                              ),
                            ),
                            IconButton(icon: Icon(Icons.fast_forward, color: fg, size: 24), onPressed: () => _skip(5)),
                            IconButton(icon: Icon(Icons.skip_next, color: fg, size: 28), onPressed: () => _skip(50)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Top app bar
          Positioned(
            top: 0, left: 0, right: 0,
            child: AnimatedOpacity(
              opacity: _controlsVisible ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 250),
              child: IgnorePointer(
                ignoring: !_controlsVisible,
                child: Container(
                  padding: EdgeInsets.only(top: pad.top),
                  color: bg,
                  child: SizedBox(
                    height: 52,
                    child: Row(children: [
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white, size: 22),
                        onPressed: () => Navigator.pop(context, _currentCharPos),
                      ),
                      const Spacer(),
                    ]),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Word {
  final String text;
  final int startPos;
  const _Word(this.text, this.startPos);
}

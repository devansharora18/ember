import 'dart:async';
import '../models/reading_stats.dart';
import 'stats_storage.dart';

/// A shared, app-wide session tracker for reading stats.
///
/// The Reader and RSVP screens call [addWords] and [addSeconds] as the user
/// reads. Flush points (periodically and on app/route teardown) aggregate the
/// in-memory buffers into the current day and update the streak. This keeps the
/// data path simple: nothing is persisted until a flush, and flushes are cheap.
class ReadingStatsTracker {
  ReadingStatsTracker._();
  static final instance = ReadingStatsTracker._();

  final _listeners = <void Function()>[];
  void addListener(void Function() fn) => _listeners.add(fn);
  void removeListener(void Function() fn) => _listeners.remove(fn);
  void _notify() {
    for (final fn in List.of(_listeners)) {
      fn();
    }
  }

  Map<String, DailyReading> _daily = {};
  ReadingStreak _streak = ReadingStreak();
  bool _loaded = false;

  // In-memory session buffers (accumulated until the next flush).
  int _pendingWords = 0;
  int _pendingSeconds = 0;
  bool _currentDayIsRead = false;

  Timer? _flushTimer;

  /// Returns today's aggregate.
  DailyReading get today {
    _ensureLoaded();
    final key = formatDateKey(DateTime.now());
    return _daily.putIfAbsent(key, () => DailyReading(dateKey: key));
  }

  ReadingStreak get streak => _streak;

  bool get anyWordsToday => today.words > 0 || _pendingWords > 0;

  /// Call from the reader/RSVP screen's initState to start tracking this
  /// reading session. Spins up a periodic auto-flush timer.
  void begin() {
    _ensureLoaded();
    _flushTimer ??= Timer.periodic(const Duration(seconds: 20), (_) => flush());
  }

  /// Call from the screen's dispose to stop tracking and flush pending data.
  void end() {
    _flushTimer?.cancel();
    _flushTimer = null;
    flush();
  }

  /// Register freshly-read words (counted from real text/WPM, not estimated).
  void addWords(int words) {
    _ensureLoaded();
    if (words <= 0) return;
    _pendingWords += words;
  }

  /// Register seconds spent actively reading.
  void addSeconds(int seconds) {
    _ensureLoaded();
    if (seconds <= 0) return;
    _pendingSeconds += seconds;
  }

  void _ensureLoaded() {
    if (_loaded) return;
    _loaded = true;
    unawaited(_load());
  }

  Future<void> _load() async {
    _daily = await StatsStorage.loadDaily();
    _streak = await StatsStorage.loadStreak();
    _currentDayIsRead = _streak.lastDay == formatDateKey(DateTime.now());
  }

  /// Persists pending words/seconds into today and advances the streak.
  Future<void> flush() async {
    await _ensureLoadedSafe();
    if (_pendingWords <= 0 && _pendingSeconds <= 0) return;

    final key = formatDateKey(DateTime.now());
    final day = _daily.putIfAbsent(key, () => DailyReading(dateKey: key));
    day.words += _pendingWords;
    day.seconds += _pendingSeconds;
    _streak.totalWords += _pendingWords;

    // Advance the streak only on the first reading day in a run; otherwise keep
    // the current count intact for repeat sessions on the same day.
    if (!_currentDayIsRead) {
      final todayKey = formatDateKey(DateTime.now());
      if (_streak.lastDay == null) {
        _streak.current = 1;
      } else {
        final yesterday = formatDateKey(DateTime.now().subtract(const Duration(days: 1)));
        _streak.current = _streak.lastDay == yesterday ? _streak.current + 1 : 1;
      }
      if (_streak.current > _streak.best) _streak.best = _streak.current;
      _streak.lastDay = todayKey;
      _currentDayIsRead = true;
    }

    _pendingWords = 0;
    _pendingSeconds = 0;

    await Future.wait([
      StatsStorage.saveDaily(_daily),
      StatsStorage.saveStreak(_streak),
    ]);
    _notify();
  }

  Future<void> _ensureLoadedSafe() async {
    if (!_loaded) {
      _loaded = true;
      await _load();
    }
  }
}
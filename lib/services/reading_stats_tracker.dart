import 'dart:async';
import '../models/badges.dart';
import '../models/reading_stats.dart';
import 'stats_storage.dart';

/// A shared, app-wide session tracker for reading stats.
///
/// Reader and RSVP screens call [begin]/[end] (refcounted) and report progress
/// via [addWords]/[addSeconds]. Words/seconds update the live "today" record
/// immediately and notify listeners, so the Stats screen stays current while
/// reading. A debounced [flush] persists to storage. The tracker owns a single
/// heartbeat timer so time is never double-counted by two open screens.
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

  final Map<String, DailyReading> _daily = {};
  ReadingStreak _streak = ReadingStreak();
  bool _loaded = false;
  bool _dirty = false;

  int _activeSessions = 0;
  Timer? _heartbeat;
  Timer? _flushTimer;

  /// Returns today's aggregate, creating the entry lazily.
  DailyReading get today {
    _ensureLoaded();
    final key = formatDateKey(DateTime.now());
    return _daily.putIfAbsent(key, () => DailyReading(dateKey: key));
  }

  ReadingStreak get streak => _streak;

  /// All recorded days (for heatmaps). Keys are "yyyy-MM-dd".
  Map<String, DailyReading> get daily => _daily;

  bool get anyWordsToday => today.words > 0;

  /// Sets the user's daily goal and persists it immediately.
  Future<void> setDailyGoal(int words) async {
    _ensureLoaded();
    _streak.dailyGoal = words < 100 ? 100 : words;
    await StatsStorage.saveStreak(_streak);
    _notify();
  }

  /// Starts a reading session (call from initState). Refcounted so opening
  /// RSVP on top of the reader doesn't double-count time.
  void begin() {
    _ensureLoaded();
    _activeSessions++;
    _heartbeat ??= Timer.periodic(const Duration(seconds: 1), (_) {
      if (_activeSessions > 0) addSeconds(1);
    });
    _flushTimer ??= Timer.periodic(const Duration(seconds: 15), (_) => flush());
  }

  /// Ends a reading session (call from dispose). Flushes when the last session
  /// closes.
  void end() {
    if (_activeSessions > 0) _activeSessions--;
    if (_activeSessions == 0) {
      _heartbeat?.cancel();
      _heartbeat = null;
      _flushTimer?.cancel();
      _flushTimer = null;
      flush();
    }
  }

  /// Register freshly-read words. Updates today's live record and notifies.
  void addWords(int words) {
    _ensureLoaded();
    if (words <= 0) return;
    today.words += words;
    _streak.totalWords += words;
    _dirty = true;
    _advanceStreak();
    _evaluateBadges();
    _notify();
  }

  /// Register seconds spent actively reading. Updates today's live record.
  void addSeconds(int seconds) {
    _ensureLoaded();
    if (seconds <= 0) return;
    today.seconds += seconds;
    _dirty = true;
    _notify();
  }

  /// Record a finished book.
  void completeBook() {
    _ensureLoaded();
    _streak.booksFinished++;
    today.booksFinished++;
    _dirty = true;
    _evaluateBadges();
    _notify();
  }

  /// Earns any badges whose conditions are now met.
  void _evaluateBadges() {
    final ctx = BadgeContext(
      currentStreak: _streak.current,
      bestStreak: _streak.best,
      totalWords: _streak.totalWords,
      daysRead: _daily.values.where((d) => d.words > 0).length,
    );
    var changed = false;
    for (final b in badges) {
      if (b.earned(ctx) && !_streak.badges.contains(b.id)) {
        _streak.badges = {..._streak.badges, b.id};
        changed = true;
      }
    }
    if (changed) _dirty = true;
  }

  void _ensureLoaded() {
    if (_loaded) return;
    _loaded = true;
    unawaited(_load());
  }

  Future<void> _load() async {
    final storedDaily = await StatsStorage.loadDaily();
    final storedStreak = await StatsStorage.loadStreak();
    // Stored data wins. The `today` getter may have created an empty entry in
    // `_daily` before this async load finished (e.g. the provider building the
    // first snapshot) — that empty entry must NOT overwrite real stored data.
    _daily.addAll(storedDaily);
    _streak = storedStreak;
    _evaluateBadges();
    _notify();
  }

  /// Advances the streak on the first time words are added for a day.
  void _advanceStreak() {
    final todayKey = formatDateKey(DateTime.now());
    if (_streak.lastDay == todayKey) return;
    if (_streak.lastDay == null) {
      _streak.current = 1;
    } else {
      final yesterday = formatDateKey(DateTime.now().subtract(const Duration(days: 1)));
      _streak.current = _streak.lastDay == yesterday ? _streak.current + 1 : 1;
    }
    if (_streak.current > _streak.best) _streak.best = _streak.current;
    _streak.lastDay = todayKey;
  }

  /// Persists the current in-memory state. Cheap no-op unless data changed.
  Future<void> flush() async {
    await _ensureLoadedSafe();
    if (!_dirty) return;
    _dirty = false;
    await Future.wait([
      StatsStorage.saveDaily(_daily),
      StatsStorage.saveStreak(_streak),
    ]);
  }

  Future<void> _ensureLoadedSafe() async {
    if (!_loaded) {
      _loaded = true;
      await _load();
    }
  }
}
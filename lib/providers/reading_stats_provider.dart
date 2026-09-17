import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/reading_stats.dart';
import '../services/reading_stats_tracker.dart';

/// Exposes the current day's reading aggregate and the streak. Rebuilds
/// whenever the in-memory tracker flushes, so the stats UI (Phase 2) and the
/// library can show live "today" numbers.
final readingStatsProvider = NotifierProvider<ReadingStatsController, ReadingStatsSnapshot>(
  ReadingStatsController.new,
);

class ReadingStatsSnapshot {
  final DailyReading today;
  final ReadingStreak streak;
  final Map<String, DailyReading> daily;
  final bool loaded;

  const ReadingStatsSnapshot({
    required this.today,
    required this.streak,
    this.daily = const {},
    this.loaded = true,
  });
}

class ReadingStatsController extends Notifier<ReadingStatsSnapshot> {
  void Function()? _listener;

  @override
  ReadingStatsSnapshot build() {
    final tracker = ReadingStatsTracker.instance;
    _listener = _notify;
    tracker.addListener(_listener!);
    ref.onDispose(() {
      if (_listener != null) tracker.removeListener(_listener!);
    });
    return ReadingStatsSnapshot(
      today: tracker.today,
      streak: tracker.streak,
      daily: tracker.daily,
    );
  }

  void _notify() => state = ReadingStatsSnapshot(
        today: ReadingStatsTracker.instance.today,
        streak: ReadingStatsTracker.instance.streak,
        daily: ReadingStatsTracker.instance.daily,
      );
}
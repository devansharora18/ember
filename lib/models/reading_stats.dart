/// Reading stats data model. Phase 1 tracks words + time per day.
class DailyReading {
  final String dateKey; // ISO "yyyy-MM-dd" in local time
  int seconds;
  int words;
  int chars;
  int booksFinished;

  DailyReading({
    required this.dateKey,
    this.seconds = 0,
    this.words = 0,
    this.chars = 0,
    this.booksFinished = 0,
  });

  Map<String, dynamic> toJson() => {
        'dateKey': dateKey,
        'seconds': seconds,
        'words': words,
        'chars': chars,
        'booksFinished': booksFinished,
      };

  factory DailyReading.fromJson(Map<String, dynamic> json) => DailyReading(
        dateKey: json['dateKey'] as String,
        seconds: (json['seconds'] as num?)?.toInt() ?? 0,
        words: (json['words'] as num?)?.toInt() ?? 0,
        chars: (json['chars'] as num?)?.toInt() ?? 0,
        booksFinished: (json['booksFinished'] as num?)?.toInt() ?? 0,
      );
}

/// Streak + lifetime totals. `current`/`best` are consecutive-day counts based
/// on words read. `totalWords` is the lifetime cumulative count ("XP").
class ReadingStreak {
  int current;
  int best;
  String? lastDay; // last day that counted toward the streak (yyyy-MM-dd)
  int totalWords;
  int dailyGoal; // target words per day, user-configurable
  int booksFinished;
  Set<String> badges; // earned badge ids

  ReadingStreak({
    this.current = 0,
    this.best = 0,
    this.lastDay,
    this.totalWords = 0,
    this.dailyGoal = 1000,
    this.booksFinished = 0,
    this.badges = const {},
  });

  Map<String, dynamic> toJson() => {
        'current': current,
        'best': best,
        if (lastDay != null) 'lastDay': lastDay,
        'totalWords': totalWords,
        'dailyGoal': dailyGoal,
        'booksFinished': booksFinished,
        'badges': badges.toList(),
      };

  factory ReadingStreak.fromJson(Map<String, dynamic> json) => ReadingStreak(
        current: (json['current'] as num?)?.toInt() ?? 0,
        best: (json['best'] as num?)?.toInt() ?? 0,
        lastDay: json['lastDay'] as String?,
        totalWords: (json['totalWords'] as num?)?.toInt() ?? 0,
        dailyGoal: (json['dailyGoal'] as num?)?.toInt() ?? 1000,
        booksFinished: (json['booksFinished'] as num?)?.toInt() ?? 0,
        badges: ((json['badges'] as List?) ?? []).map((e) => e.toString()).toSet(),
      );
}

String formatDateKey(DateTime d) {
  final m = d.month.toString().padLeft(2, '0');
  final day = d.day.toString().padLeft(2, '0');
  return '${d.year}-$m-$day';
}
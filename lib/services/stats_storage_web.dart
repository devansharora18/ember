import 'dart:convert';
import 'package:universal_html/html.dart' as html;
import '../models/reading_stats.dart';

/// LocalStorage-backed stats persistence for the web build.
class StatsStorage {
  static String _key(String k) => 'ember_stats_$k';

  static Map<String, DailyReading> _decode(String raw) {
    final map = <String, DailyReading>{};
    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      for (final e in data.entries) {
        map[e.key] = DailyReading.fromJson(e.value as Map<String, dynamic>);
      }
    } catch (_) {}
    return map;
  }

  static Future<Map<String, DailyReading>> loadDaily() async {
    try {
      final raw = html.window.localStorage[_key('daily')];
      if (raw == null) return {};
      return _decode(raw);
    } catch (_) {
      return {};
    }
  }

  static Future<void> saveDaily(Map<String, DailyReading> daily) async {
    try {
      final json = <String, dynamic>{
        for (final e in daily.entries) e.key: e.value.toJson(),
      };
      html.window.localStorage[_key('daily')] = jsonEncode(json);
    } catch (_) {}
  }

  static Future<ReadingStreak> loadStreak() async {
    try {
      final raw = html.window.localStorage[_key('streak')];
      if (raw == null) return ReadingStreak();
      return ReadingStreak.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return ReadingStreak();
    }
  }

  static Future<void> saveStreak(ReadingStreak streak) async {
    try {
      html.window.localStorage[_key('streak')] = jsonEncode(streak.toJson());
    } catch (_) {}
  }
}
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/reading_stats.dart';

/// Persists reading stats. Mirrors the per-platform pattern of `BookStorage`
/// (io vs web), but lives in its own namespace so the two implementations stay
/// small. Stats are global (not per-book), so no file-path hashing is needed.
class StatsStorage {
  static Future<Directory> _dir() async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory('${base.path}/ember');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  static Future<Map<String, DailyReading>> loadDaily() async {
    try {
      final dir = await _dir();
      final file = File('${dir.path}/daily.json');
      if (!await file.exists()) return {};
      final raw = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      final map = <String, DailyReading>{};
      for (final e in raw.entries) {
        map[e.key] = DailyReading.fromJson(e.value as Map<String, dynamic>);
      }
      return map;
    } catch (_) {
      return {};
    }
  }

  static Future<void> saveDaily(Map<String, DailyReading> daily) async {
    try {
      final dir = await _dir();
      final file = File('${dir.path}/daily.json');
      final json = <String, dynamic>{
        for (final e in daily.entries) e.key: e.value.toJson(),
      };
      await file.writeAsString(jsonEncode(json));
    } catch (_) {}
  }

  static Future<ReadingStreak> loadStreak() async {
    try {
      final dir = await _dir();
      final file = File('${dir.path}/streak.json');
      if (!await file.exists()) return ReadingStreak();
      return ReadingStreak.fromJson(
        jsonDecode(await file.readAsString()) as Map<String, dynamic>,
      );
    } catch (_) {
      return ReadingStreak();
    }
  }

  static Future<void> saveStreak(ReadingStreak streak) async {
    try {
      final dir = await _dir();
      final file = File('${dir.path}/streak.json');
      await file.writeAsString(jsonEncode(streak.toJson()));
    } catch (_) {}
  }
}
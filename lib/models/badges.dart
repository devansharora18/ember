import 'package:flutter/material.dart';

/// A badge a reader can earn. Conditions are evaluated against the tracker's
/// live state (streak, lifetime words, days read).
class BadgeDef {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final bool Function(BadgeContext ctx) earned;

  BadgeDef({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.earned,
  });
}

/// Snapshot of the numbers used to evaluate badges.
class BadgeContext {
  final int currentStreak;
  final int bestStreak;
  final int totalWords;
  final int daysRead;

  const BadgeContext({
    required this.currentStreak,
    required this.bestStreak,
    required this.totalWords,
    required this.daysRead,
  });
}

List<BadgeDef> badges = [
  BadgeDef(
    id: 'first_words',
    name: 'First Steps',
    description: 'Read your first 100 words',
    icon: Icons.auto_stories,
    earned: (c) => c.totalWords >= 100,
  ),
  BadgeDef(
    id: 'words_10k',
    name: 'Bookworm',
    description: 'Read 10,000 words',
    icon: Icons.menu_book,
    earned: (c) => c.totalWords >= 10000,
  ),
  BadgeDef(
    id: 'words_100k',
    name: 'Scholar',
    description: 'Read 100,000 words',
    icon: Icons.school,
    earned: (c) => c.totalWords >= 100000,
  ),
  BadgeDef(
    id: 'streak_3',
    name: 'Warm Up',
    description: '3-day reading streak',
    icon: Icons.local_fire_department,
    earned: (c) => c.bestStreak >= 3,
  ),
  BadgeDef(
    id: 'streak_7',
    name: 'Consistent',
    description: '7-day reading streak',
    icon: Icons.local_fire_department,
    earned: (c) => c.bestStreak >= 7,
  ),
  BadgeDef(
    id: 'streak_30',
    name: 'On Fire',
    description: '30-day reading streak',
    icon: Icons.local_fire_department,
    earned: (c) => c.bestStreak >= 30,
  ),
  BadgeDef(
    id: 'streak_100',
    name: 'Unstoppable',
    description: '100-day reading streak',
    icon: Icons.whatshot,
    earned: (c) => c.bestStreak >= 100,
  ),
  BadgeDef(
    id: 'days_7',
    name: 'Daily Reader',
    description: 'Read on 7 different days',
    icon: Icons.calendar_month,
    earned: (c) => c.daysRead >= 7,
  ),
  BadgeDef(
    id: 'days_30',
    name: 'Habit',
    description: 'Read on 30 different days',
    icon: Icons.calendar_month,
    earned: (c) => c.daysRead >= 30,
  ),
  BadgeDef(
    id: 'days_100',
    name: 'Devoted',
    description: 'Read on 100 different days',
    icon: Icons.workspace_premium,
    earned: (c) => c.daysRead >= 100,
  ),
];
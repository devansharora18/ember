import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/reading_stats.dart';
import '../providers/reading_stats_provider.dart';
import '../services/reading_stats_tracker.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snap = ref.watch(readingStatsProvider);
    final s = MediaQuery.textScalerOf(context).scale(1.0).clamp(1.0, 1.5);
    final today = snap.today;
    final streak = snap.streak;
    final goal = streak.dailyGoal;
    final pct = goal > 0 ? (today.words / goal).clamp(0.0, 1.0) : 0.0;

    final totalSeconds = snap.daily.values.fold<int>(0, (a, d) => a + d.seconds);
    final daysRead = snap.daily.values.where((d) => d.words > 0).length;

    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.arrow_back, color: Colors.white.withAlpha(128), size: 20),
                  splashRadius: 22,
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.only(bottom: 22),
                ),
                Padding(
                  padding: EdgeInsets.only(bottom: 10 * s),
                  child: Text('Stats', style: GoogleFonts.inter(color: Colors.white, fontSize: 20 * s, fontWeight: FontWeight.w600, letterSpacing: 1 * s)),
                ),
              ],
            ),
          ),
        ),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        padding: EdgeInsets.fromLTRB(20 * s, 8 * s, 20 * s, 32 * s),
        children: [
          _buildStreakCard(streak.current, streak.best, s),
          SizedBox(height: 14 * s),
          _buildTodayCard(today.words, goal, pct, s),
          SizedBox(height: 24 * s),
          _sectionLabel('Daily goal', s),
          SizedBox(height: 10 * s),
          _buildGoalRow(goal, s),
          SizedBox(height: 24 * s),
          _sectionLabel('All time', s),
          SizedBox(height: 10 * s),
          Row(children: [
            Expanded(child: _buildStat(Icons.text_fields, 'Words read', _formatCount(streak.totalWords), s)),
            SizedBox(width: 12 * s),
            Expanded(child: _buildStat(Icons.schedule, 'Time read', _formatDuration(totalSeconds), s)),
          ]),
          SizedBox(height: 12 * s),
          Row(children: [
            Expanded(child: _buildStat(Icons.emoji_events_outlined, 'Best streak', '${streak.best} days', s)),
            SizedBox(width: 12 * s),
            Expanded(child: _buildStat(Icons.calendar_today, 'Days read', '$daysRead', s)),
          ]),
          SizedBox(height: 24 * s),
          _sectionLabel('Activity', s),
          SizedBox(height: 12 * s),
          _buildHeatmap(ref, s),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text, double s) => Text(
        text.toUpperCase(),
        style: GoogleFonts.inter(color: const Color(0xFF666666), fontSize: 11 * s, fontWeight: FontWeight.w600, letterSpacing: 1.2 * s),
      );

  Widget _buildStreakCard(int current, int best, double s) {
    return Container(
      padding: EdgeInsets.all(22 * s),
      decoration: BoxDecoration(
        color: const Color(0xFF0E0E0E),
        border: Border.all(color: const Color(0xFF1C1C1C)),
      ),
      child: Row(children: [
        Container(
          width: 52 * s,
          height: 52 * s,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFF1A0F0C),
            border: Border.all(color: const Color(0xFF3A1C14)),
          ),
          child: Icon(Icons.local_fire_department, color: const Color(0xFFE05555), size: 28 * s),
        ),
        SizedBox(width: 18 * s),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
            Text('$current', style: GoogleFonts.inter(color: Colors.white, fontSize: 30 * s, fontWeight: FontWeight.w700, letterSpacing: 0.5 * s, height: 1)),
            SizedBox(width: 6 * s),
            Text('day${current == 1 ? '' : 's'}', style: GoogleFonts.inter(color: const Color(0xFF888888), fontSize: 14 * s, fontWeight: FontWeight.w500)),
          ]),
          SizedBox(height: 6 * s),
          Text('Current streak', style: GoogleFonts.inter(color: const Color(0xFF666666), fontSize: 12 * s)),
        ])),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('BEST', style: GoogleFonts.inter(color: const Color(0xFF555555), fontSize: 10 * s, fontWeight: FontWeight.w600, letterSpacing: 1 * s)),
          SizedBox(height: 4 * s),
          Text('$best', style: GoogleFonts.inter(color: Colors.white, fontSize: 18 * s, fontWeight: FontWeight.w700)),
        ]),
      ]),
    );
  }

  Widget _buildTodayCard(int words, int goal, double pct, double s) {
    final reached = words >= goal;
    return Container(
      padding: EdgeInsets.all(20 * s),
      decoration: BoxDecoration(
        color: const Color(0xFF0E0E0E),
        border: Border.all(color: const Color(0xFF1C1C1C)),
      ),
      child: Row(children: [
        SizedBox(
          width: 76 * s,
          height: 76 * s,
          child: Stack(alignment: Alignment.center, children: [
            SizedBox(
              width: 76 * s,
              height: 76 * s,
              child: CircularProgressIndicator(
                value: pct,
                strokeWidth: 5 * s,
                backgroundColor: const Color(0xFF1C1C1C),
                valueColor: AlwaysStoppedAnimation(reached ? const Color(0xFF4CAF50) : const Color(0xFFE05555)),
                strokeCap: StrokeCap.round,
              ),
            ),
            Text('${(pct * 100).round()}%', style: GoogleFonts.inter(color: Colors.white, fontSize: 15 * s, fontWeight: FontWeight.w600)),
          ]),
        ),
        SizedBox(width: 20 * s),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('TODAY', style: GoogleFonts.inter(color: const Color(0xFF666666), fontSize: 11 * s, fontWeight: FontWeight.w600, letterSpacing: 1 * s)),
          SizedBox(height: 8 * s),
          Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
            Text('$words', style: GoogleFonts.inter(color: Colors.white, fontSize: 22 * s, fontWeight: FontWeight.w700, height: 1)),
            Text(' / $goal words', style: GoogleFonts.inter(color: const Color(0xFF666666), fontSize: 13 * s)),
          ]),
          SizedBox(height: 6 * s),
          Row(children: [
            Icon(reached ? Icons.check_circle : Icons.trending_up,
                size: 14 * s, color: reached ? const Color(0xFF4CAF50) : const Color(0xFF888888)),
            SizedBox(width: 6 * s),
            Text(
              reached ? 'Goal reached' : '${(goal - words).clamp(0, 9999999)} words to go',
              style: GoogleFonts.inter(color: reached ? const Color(0xFF4CAF50) : const Color(0xFF888888), fontSize: 12 * s),
            ),
          ]),
        ])),
      ]),
    );
  }

  Widget _buildGoalRow(int goal, double s) {
    return Row(
      children: [
        for (final g in _goalOptions)
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: g == _goalOptions.last ? 0 : 8 * s),
              child: GestureDetector(
                onTap: () => ReadingStatsTracker.instance.setDailyGoal(g),
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 12 * s),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: g == goal ? const Color(0xFFE05555) : const Color(0xFF121212),
                    border: Border.all(color: g == goal ? const Color(0xFFE05555) : const Color(0xFF222222)),
                  ),
                  child: Text('$g', style: GoogleFonts.inter(color: g == goal ? Colors.white : const Color(0xFF888888), fontSize: 13 * s, fontWeight: FontWeight.w600)),
                ),
              ),
            ),
          ),
      ],
    );
  }

  static const _goalOptions = [250, 500, 1000, 2000];

  Widget _buildStat(IconData icon, String label, String value, double s) {
    return Container(
      padding: EdgeInsets.all(16 * s),
      decoration: BoxDecoration(
        color: const Color(0xFF0E0E0E),
        border: Border.all(color: const Color(0xFF1C1C1C)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: 16 * s, color: const Color(0xFF555555)),
        SizedBox(height: 12 * s),
        Text(value, style: GoogleFonts.inter(color: Colors.white, fontSize: 19 * s, fontWeight: FontWeight.w700)),
        SizedBox(height: 2 * s),
        Text(label, style: GoogleFonts.inter(color: const Color(0xFF666666), fontSize: 11 * s)),
      ]),
    );
  }

  Widget _buildHeatmap(WidgetRef ref, double s) {
    final snap = ref.watch(readingStatsProvider);
    final daily = snap.daily;
    final goal = snap.streak.dailyGoal;

    const weeks = 16;
    const gap = 3.0;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    // Align columns to weeks starting on Sunday, like GitHub.
    final thisSunday = today.subtract(Duration(days: today.weekday % 7));
    final start = thisSunday.subtract(const Duration(days: (weeks - 1) * 7));

    int level(String key) {
      final words = daily[key]?.words ?? 0;
      if (words <= 0) return 0;
      if (words >= goal) return 4;
      return (words / goal * 4).ceil().clamp(1, 3);
    }

    const colors = [
      Color(0xFF1A1A1A),
      Color(0xFF3A1C14),
      Color(0xFF7A3020),
      Color(0xFFB04028),
      Color(0xFFE05555),
    ];

    // Column c is a week; row r is a weekday (0 = Sunday).
    final columns = <List<DateTime?>>[];
    for (var c = 0; c < weeks; c++) {
      final col = <DateTime?>[];
      for (var r = 0; r < 7; r++) {
        final d = start.add(Duration(days: c * 7 + r));
        col.add(d.isAfter(today) ? null : d);
      }
      columns.add(col);
    }

    // Month labels span the columns that begin in each month.
    final labels = <({String text, int span})>[];
    for (var c = 0; c < weeks; c++) {
      final first = start.add(Duration(days: c * 7));
      final name = _monthAbbr(first.month);
      if (labels.isNotEmpty && labels.last.text == name) {
        labels[labels.length - 1] = (text: name, span: labels.last.span + 1);
      } else {
        labels.add((text: name, span: 1));
      }
    }

    return LayoutBuilder(builder: (context, constraints) {
      final cell = ((constraints.maxWidth - (weeks - 1) * gap - 22 * s) / weeks).floorToDouble().clamp(6.0, 18.0);
      final gridWidth = weeks * cell + (weeks - 1) * gap;
      final rowHeight = cell + gap;

      return Align(
        alignment: Alignment.centerLeft,
        child: SizedBox(
          width: gridWidth + 22 * s,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Month labels. Each label's width matches its columns so the row
              // never exceeds the grid; labels too narrow to fit are skipped
              // (their space is still reserved) to avoid overlapping text.
              SizedBox(
                height: 14 * s,
                child: Padding(
                  padding: EdgeInsets.only(left: 22 * s),
                  child: Row(children: [
                    for (var i = 0; i < labels.length; i++) ...[
                      SizedBox(
                        width: labels[i].span * cell + (labels[i].span - 1) * gap,
                        child: labels[i].span >= 2
                            ? Text(
                                labels[i].text,
                                style: GoogleFonts.inter(color: const Color(0xFF555555), fontSize: 10 * s),
                                softWrap: false,
                                overflow: TextOverflow.clip,
                              )
                            : const SizedBox.shrink(),
                      ),
                      if (i < labels.length - 1) SizedBox(width: gap),
                    ],
                  ]),
                ),
              ),
              SizedBox(height: 4 * s),
              // Weekday labels + grid, rows aligned (row 0 = Sunday).
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 22 * s,
                    child: Column(children: [
                      for (var r = 0; r < 7; r++)
                        SizedBox(
                          height: rowHeight,
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: _weekdayLabel(r, s),
                          ),
                        ),
                    ]),
                  ),
                  Row(
                    children: [
                      for (var c = 0; c < weeks; c++) ...[
                        Column(
                          children: [
                            for (var r = 0; r < 7; r++)
                              Container(
                                width: cell,
                                height: cell,
                                margin: EdgeInsets.only(bottom: gap),
                                decoration: BoxDecoration(
                                  color: columns[c][r] == null
                                      ? Colors.transparent
                                      : colors[level(formatDateKey(columns[c][r]!))],
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                          ],
                        ),
                        if (c < weeks - 1) SizedBox(width: gap),
                      ],
                    ],
                  ),
                ],
              ),
              SizedBox(height: 12 * s),
              // Legend + date range
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${_formatShortDate(start)} — ${_formatShortDate(today)}',
                      style: GoogleFonts.inter(color: const Color(0xFF444444), fontSize: 10 * s),
                    ),
                  ),
                  Text('Less', style: GoogleFonts.inter(color: const Color(0xFF555555), fontSize: 10 * s)),
                  SizedBox(width: 6 * s),
                  for (final c in colors) ...[
                    Container(
                      width: cell,
                      height: cell,
                      margin: EdgeInsets.symmetric(horizontal: 1.5 * s),
                      decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(2)),
                    ),
                  ],
                  SizedBox(width: 6 * s),
                  Text('More', style: GoogleFonts.inter(color: const Color(0xFF555555), fontSize: 10 * s)),
                ],
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _weekdayLabel(int row, double s) {
    // Row 0 = Sunday, 1 = Mon, 2 = Tue ... label every weekday.
    const names = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    final label = names[row];
    if (label.isEmpty) return const SizedBox.shrink();
    return Text(
      label,
      style: GoogleFonts.inter(color: const Color(0xFF555555), fontSize: 9 * s),
    );
  }

  static String _formatShortDate(DateTime d) =>
      '${d.day} ${_monthAbbr(d.month)}';

  static String _monthAbbr(int month) => const [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ][month - 1];

  static String _formatCount(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return '$n';
  }

  static String _formatDuration(int seconds) {
    if (seconds <= 0) return '0m';
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    if (h > 0) return m > 0 ? '${h}h ${m}m' : '${h}h';
    return '${m}m';
  }
}
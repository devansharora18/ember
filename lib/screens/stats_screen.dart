import 'dart:io' show File;
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/badges.dart';
import '../models/reading_stats.dart';
import '../providers/reading_stats_provider.dart';
import '../services/reading_stats_tracker.dart';

/// Black + orange palette used across the stats UI.
const _orange = Color(0xFFF97316);
const _orangeSoft = Color(0xFF7C4A1E);
const _cardBg = Color(0xFF0D0D0D);
const _cardBorder = Color(0xFF1E1E1E);
const _textDim = Color(0xFF888888);
const _textFaint = Color(0xFF555555);

class StatsScreen extends ConsumerStatefulWidget {
  const StatsScreen({super.key});

  @override
  ConsumerState<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends ConsumerState<StatsScreen> {
  @override
  Widget build(BuildContext context) {
    final snap = ref.watch(readingStatsProvider);
    final s = MediaQuery.textScalerOf(context).scale(1.0).clamp(1.0, 1.5);
    final today = snap.today;
    final streak = snap.streak;
    final goal = streak.dailyGoal;
    final pct = goal > 0 ? (today.words / goal).clamp(0.0, 1.0) : 0.0;

    final totalSeconds = snap.daily.values.fold<int>(0, (a, d) => a + d.seconds);
    final daysRead = snap.daily.values.where((d) => d.words > 0).length;

    return Scaffold(
      backgroundColor: Colors.black,
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
                  child: Row(children: [
                    Icon(Icons.insights, color: _orange, size: 18 * s),
                    SizedBox(width: 8 * s),
                    Text('Stats', style: GoogleFonts.inter(color: Colors.white, fontSize: 20 * s, fontWeight: FontWeight.w600, letterSpacing: 1 * s)),
                  ]),
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
          _sectionLabel('Badges', s),
          SizedBox(height: 10 * s),
          _buildBadges(streak.badges, s),
          SizedBox(height: 24 * s),
          _sectionLabel('Activity', s),
          SizedBox(height: 12 * s),
          _buildHeatmap(s),
          SizedBox(height: 24 * s),
          _buildShareButton(streak, s),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text, double s) => Row(children: [
        Container(width: 3 * s, height: 12 * s, color: _orange),
        SizedBox(width: 8 * s),
        Text(
          text.toUpperCase(),
          style: GoogleFonts.inter(color: _textFaint, fontSize: 11 * s, fontWeight: FontWeight.w600, letterSpacing: 1.4 * s),
        ),
      ]);

  Widget _buildStreakCard(int current, int best, double s) {
    final hasStreak = current > 0;
    return Container(
      padding: EdgeInsets.all(22 * s),
      decoration: BoxDecoration(
        color: _cardBg,
        border: Border.all(color: _cardBorder),
        gradient: hasStreak
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF140A04), Color(0xFF0D0D0D)],
              )
            : null,
      ),
      child: Row(children: [
        Container(
          width: 52 * s,
          height: 52 * s,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: hasStreak ? const Color(0xFF1F140C) : const Color(0xFF141414),
            border: Border.all(color: hasStreak ? _orangeSoft : _cardBorder),
          ),
          child: Icon(
            hasStreak ? Icons.local_fire_department : Icons.local_fire_department_outlined,
            color: hasStreak ? _orange : _textFaint,
            size: 28 * s,
          ),
        ),
        SizedBox(width: 18 * s),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
            Text('$current', style: GoogleFonts.inter(color: Colors.white, fontSize: 30 * s, fontWeight: FontWeight.w700, letterSpacing: 0.5 * s, height: 1)),
            SizedBox(width: 6 * s),
            Text('day${current == 1 ? '' : 's'}', style: GoogleFonts.inter(color: _textDim, fontSize: 14 * s, fontWeight: FontWeight.w500)),
          ]),
          SizedBox(height: 6 * s),
          Text('Current streak', style: GoogleFonts.inter(color: _textFaint, fontSize: 12 * s)),
        ])),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('BEST', style: GoogleFonts.inter(color: _textFaint, fontSize: 10 * s, fontWeight: FontWeight.w600, letterSpacing: 1 * s)),
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
        color: _cardBg,
        border: Border.all(color: _cardBorder),
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
                valueColor: AlwaysStoppedAnimation(_orange),
                strokeCap: StrokeCap.round,
              ),
            ),
            Text('${(pct * 100).round()}%', style: GoogleFonts.inter(color: Colors.white, fontSize: 15 * s, fontWeight: FontWeight.w600)),
          ]),
        ),
        SizedBox(width: 20 * s),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('TODAY', style: GoogleFonts.inter(color: _textFaint, fontSize: 11 * s, fontWeight: FontWeight.w600, letterSpacing: 1.2 * s)),
          SizedBox(height: 8 * s),
          Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
            Text('$words', style: GoogleFonts.inter(color: Colors.white, fontSize: 22 * s, fontWeight: FontWeight.w700, height: 1)),
            Text(' / $goal words', style: GoogleFonts.inter(color: _textDim, fontSize: 13 * s)),
          ]),
          SizedBox(height: 6 * s),
          Row(children: [
            Icon(reached ? Icons.check_circle : Icons.trending_up, size: 14 * s, color: reached ? _orange : _textDim),
            SizedBox(width: 6 * s),
            Text(
              reached ? 'Goal reached' : '${(goal - words).clamp(0, 9999999)} words to go',
              style: GoogleFonts.inter(color: reached ? _orange : _textDim, fontSize: 12 * s),
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
                    color: g == goal ? _orange : const Color(0xFF121212),
                    border: Border.all(color: g == goal ? _orange : const Color(0xFF222222)),
                  ),
                  child: Text('$g', style: GoogleFonts.inter(color: g == goal ? Colors.white : _textDim, fontSize: 13 * s, fontWeight: FontWeight.w700)),
                ),
              ),
            ),
          ),
      ],
    );
  }

  static const _goalOptions = [500, 1000, 2000, 4000];

  Widget _buildStat(IconData icon, String label, String value, double s) {
    return Container(
      padding: EdgeInsets.all(16 * s),
      decoration: BoxDecoration(
        color: _cardBg,
        border: Border.all(color: _cardBorder),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, size: 15 * s, color: _orange),
          const Spacer(),
        ]),
        SizedBox(height: 14 * s),
        Text(value, style: GoogleFonts.inter(color: Colors.white, fontSize: 19 * s, fontWeight: FontWeight.w700)),
        SizedBox(height: 2 * s),
        Text(label, style: GoogleFonts.inter(color: _textDim, fontSize: 11 * s)),
      ]),
    );
  }

  Widget _buildBadges(Set<String> earned, double s) {
    return Container(
      padding: EdgeInsets.all(16 * s),
      decoration: BoxDecoration(
        color: _cardBg,
        border: Border.all(color: _cardBorder),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text('${earned.length} / ${badges.length} earned', style: GoogleFonts.inter(color: _textDim, fontSize: 12 * s)),
          const Spacer(),
          Icon(Icons.workspace_premium, size: 16 * s, color: _orange),
        ]),
        SizedBox(height: 14 * s),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12 * s,
          crossAxisSpacing: 12 * s,
          childAspectRatio: 1.1,
          children: [
            for (final b in badges) _buildBadgeTile(b, earned.contains(b.id), s),
          ],
        ),
      ]),
    );
  }

  Widget _buildBadgeTile(BadgeDef badge, bool isEarned, double s) {
    final dim = !isEarned;
    return Column(mainAxisSize: MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(
        width: 44 * s,
        height: 44 * s,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isEarned ? const Color(0xFF1F140C) : const Color(0xFF121212),
          border: Border.all(color: isEarned ? _orangeSoft : _cardBorder),
          shape: BoxShape.circle,
        ),
        child: Icon(
          badge.icon,
          size: 22 * s,
          color: isEarned ? _orange : _textFaint,
        ),
      ),
      SizedBox(height: 6 * s),
      Text(badge.name, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis,
          style: GoogleFonts.inter(color: isEarned ? Colors.white : _textFaint, fontSize: 10 * s, fontWeight: FontWeight.w600)),
      SizedBox(height: 2 * s),
      Text(badge.description, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis,
          style: GoogleFonts.inter(color: dim ? const Color(0xFF333333) : _textDim, fontSize: 9 * s, height: 1.2)),
    ]);
  }

  Widget _buildShareButton(ReadingStreak streak, double s) {
    return Center(
      child: TextButton.icon(
        onPressed: () => _shareStreak(streak),
        icon: Icon(Icons.ios_share, size: 16 * s, color: _orange),
        label: Text('Share your streak', style: GoogleFonts.inter(color: _orange, fontSize: 13 * s, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Future<void> _shareStreak(ReadingStreak streak) async {
    final overlay = Overlay.maybeOf(context);
    if (overlay == null) return;
    final key = GlobalKey();
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => Positioned(
        left: -800,
        top: 0,
        child: RepaintBoundary(
          key: key,
          child: ShareStreakCard(streak: streak, recentDays: ReadingStatsTracker.instance.daily.values.toList()),
        ),
      ),
    );
    overlay.insert(entry);
    try {
      await WidgetsBinding.instance.endOfFrame;
      final boundary = key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData?.buffer.asUint8List();
      if (bytes == null) return;
      XFile file;
      if (kIsWeb) {
        file = XFile.fromData(bytes, mimeType: 'image/png', name: 'ember_streak.png');
      } else {
        final dir = await getTemporaryDirectory();
        final f = File('${dir.path}/ember_streak.png');
        await f.writeAsBytes(bytes);
        file = XFile(f.path);
      }
      final text = streak.current > 0
          ? "I've read ${streak.current} day${streak.current == 1 ? '' : 's'} in a row on Ember. ${streak.totalWords} words so far."
          : 'Reading ${streak.totalWords} words on Ember so far.';
      await SharePlus.instance.share(ShareParams(files: [file], text: text));
    } catch (_) {
    } finally {
      entry.remove();
    }
  }

  Widget _buildHeatmap(double s) {
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

    // Dark → orange intensity scale.
    const colors = [
      Color(0xFF1A1A1A),
      Color(0xFF3A2110),
      Color(0xFF7A4118),
      Color(0xFFC15F16),
      _orange,
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
                                style: GoogleFonts.inter(color: _textFaint, fontSize: 10 * s),
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
                      style: GoogleFonts.inter(color: _textFaint, fontSize: 10 * s),
                    ),
                  ),
                  Text('Less', style: GoogleFonts.inter(color: _textFaint, fontSize: 10 * s)),
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
                  Text('More', style: GoogleFonts.inter(color: _textFaint, fontSize: 10 * s)),
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
      style: GoogleFonts.inter(color: _textFaint, fontSize: 9 * s),
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

/// A stylized, self-contained card rendered offscreen and captured to PNG for
/// sharing. Fixed dimensions so capture is predictable.
class ShareStreakCard extends StatelessWidget {
  final ReadingStreak streak;
  final List<DailyReading> recentDays;

  const ShareStreakCard({super.key, required this.streak, this.recentDays = const []});

  @override
  Widget build(BuildContext context) {
    const width = 400.0;
    const height = 520.0;
    // The card is captured from an off-screen overlay entry that has no
    // Material/DefaultTextStyle ancestor, so Text would inherit Flutter's
    // yellow double-underline fallback. Reset it explicitly.
    return DefaultTextStyle(
      style: const TextStyle(
        decoration: TextDecoration.none,
        color: Colors.white,
        fontSize: 14,
      ),
      child: Container(
        width: width,
        height: height,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0A0A0A), Color(0xFF120904)],
          ),
        ),
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const Spacer(),
            Center(child: _buildStreakCenter()),
            const Spacer(),
            _buildStatsRow(),
            const SizedBox(height: 20),
          _buildWeekStrip(),
          const Spacer(),
          _buildFooter(),
        ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(children: [
      Container(
        width: 36,
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFF1F140C),
          border: Border.all(color: _orangeSoft),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(Icons.auto_stories, color: _orange, size: 20),
      ),
      const SizedBox(width: 12),
      Text('EMBER', style: GoogleFonts.inter(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800, letterSpacing: 4)),
      const Spacer(),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFF1F140C),
          border: Border.all(color: _orangeSoft),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.local_fire_department, color: _orange, size: 14),
          const SizedBox(width: 4),
          Text('${streak.current}', style: GoogleFonts.inter(color: _orange, fontSize: 13, fontWeight: FontWeight.w800)),
        ]),
      ),
    ]);
  }

  Widget _buildStreakCenter() {
    return Column(children: [
      // Glowing flame ring
      Container(
        width: 132,
        height: 132,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const RadialGradient(
            center: Alignment.center,
            radius: 0.8,
            colors: [Color(0xFF3A2110), Color(0xFF1A1008)],
          ),
          border: Border.all(color: _orangeSoft, width: 1.5),
          boxShadow: const [
            BoxShadow(color: Color(0x66F97316), blurRadius: 40, spreadRadius: 4),
          ],
        ),
        child: Icon(Icons.local_fire_department, color: _orange, size: 56),
      ),
      const SizedBox(height: 18),
      Text('${streak.current}', style: GoogleFonts.inter(color: Colors.white, fontSize: 76, fontWeight: FontWeight.w800, height: 1)),
      const SizedBox(height: 6),
      Text('DAY${streak.current == 1 ? '' : 'S'} IN A ROW', style: GoogleFonts.inter(color: _textDim, fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 3)),
    ]);
  }

  Widget _buildStatsRow() {
    return Row(children: [
      _buildStatChip('WORDS', _formatShareCount(streak.totalWords)),
      const SizedBox(width: 10),
      _buildStatChip('BEST', '${streak.best}d'),
      const SizedBox(width: 10),
      _buildStatChip('GOAL', '${streak.dailyGoal}'),
    ]);
  }

  Widget _buildStatChip(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF0D0D0D),
          border: Border.all(color: _cardBorder),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(children: [
          Text(value, style: GoogleFonts.inter(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 3),
          Text(label, style: GoogleFonts.inter(color: _textFaint, fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
        ]),
      ),
    );
  }

  Widget _buildWeekStrip() {
    // Last 7 days (including today), most recent on the right.
    final days = <DateTime>[];
    final now = DateTime.now();
    for (var i = 6; i >= 0; i--) {
      days.add(now.subtract(Duration(days: i)));
    }
    final dayMap = {for (final d in recentDays) d.dateKey: d};

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (final d in days) ...[
          Builder(builder: (_) {
            final read = (dayMap[formatDateKey(d)]?.words ?? 0) > 0;
            return Container(
              width: 32,
              height: 40,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                color: read ? _orange : const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: read ? _orange : _cardBorder,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    read ? Icons.check : Icons.remove,
                    size: 14,
                    color: read ? Colors.black : _textFaint,
                  ),
                ],
              ),
            );
          }),
        ],
      ],
    );
  }

  Widget _buildFooter() {
    return Row(children: [
      Text('Keep the flame alive', style: GoogleFonts.inter(color: _textDim, fontSize: 13, fontWeight: FontWeight.w500)),
      const Spacer(),
      Icon(Icons.local_fire_department, color: _orange, size: 16),
      const SizedBox(width: 5),
      Text('ember.devansharora.in', style: GoogleFonts.inter(color: _orange, fontSize: 12, fontWeight: FontWeight.w700)),
    ]);
  }

  static String _formatShareCount(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return '$n';
  }
}
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

import '../../../design/index.dart';
import '../../../core/models/models.dart';
import '../../../state/providers/theme_provider.dart';
import '../widgets/fixture_tile.dart';

enum _FixtureFilter { upcoming, completed, all }

/// Fixtures Screen
/// Apple-style large title, segmented control filters, and glass list items.
class FixturesScreen extends StatefulWidget {
  final List<Match> matches;
  final Map<int, Team> teams; // teamId -> Team

  const FixturesScreen({super.key, required this.matches, required this.teams});

  @override
  State<FixturesScreen> createState() => _FixturesScreenState();
}

class _FixturesScreenState extends State<FixturesScreen> {
  _FixtureFilter _filter = _FixtureFilter.upcoming;

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;

    final filtered = _applyFilter(widget.matches, _filter);
    final grouped = _groupByDay(filtered);

    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Fixtures'),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: AppGradients.backgroundGradient(context, isDark: isDark),
        ),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(Spacing.lg, Spacing.lg, Spacing.lg, Spacing.md),
                  child: _buildHeader(),
                ),
              ),

              // Segmented control
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
                  child: _FilterSegmentedControl(
                    value: _filter,
                    onChanged: (f) => setState(() => _filter = f),
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: Spacing.lg)),

              // Grouped sections by day
              ...grouped.entries.expand((entry) => [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(Spacing.lg, 0, Spacing.lg, Spacing.sm),
                        child: _SectionHeader(label: _friendlyDateLabel(entry.key)),
                      ),
                    ),
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final m = entry.value[index];
                          return Padding(
                            padding: const EdgeInsets.fromLTRB(Spacing.lg, 0, Spacing.lg, Spacing.md),
                            child: FixtureTile(match: m, teams: widget.teams),
                          );
                        },
                        childCount: entry.value.length,
                      ),
                    ),
                  ]),

              // Bottom spacer
              const SliverToBoxAdapter(child: SizedBox(height: Spacing.xxl)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return AppGlassContainer(
      padding: const EdgeInsets.all(Spacing.lg),
      borderRadius: 24,
      blur: 20,
      color: CupertinoColors.white.withValues(alpha: 0.25),
      borderColor: CupertinoColors.white.withValues(alpha: 0.3),
      child: Row(
        children: [
          AppIcons.match(fontSize: 28, color: CupertinoColors.activeBlue),
          const SizedBox(width: Spacing.md),
          const Expanded(
            child: AppText(
              'View upcoming and past fixtures',
              style: AppTypography.subhead,
            ),
          ),
        ],
      ),
    );
  }

  static List<Match> _applyFilter(List<Match> input, _FixtureFilter filter) {
    final now = DateTime.now();
    switch (filter) {
      case _FixtureFilter.upcoming:
        return input.where((m) {
          if (m.matchDatetime == null) return false;
          return (m.status == GameState.scheduled || m.status == GameState.unscheduled) && m.matchDatetime!.isAfter(now);
        }).toList()
          ..sort((a, b) => (a.matchDatetime ?? now).compareTo(b.matchDatetime ?? now));
      case _FixtureFilter.completed:
        return input.where((m) => m.status == GameState.finished || m.status == GameState.processed).toList()
          ..sort((a, b) => (b.matchDatetime ?? now).compareTo(a.matchDatetime ?? now));
      case _FixtureFilter.all:
        return List<Match>.from(input)
          ..sort((a, b) => (a.matchDatetime ?? now).compareTo(b.matchDatetime ?? now));
    }
  }

  static Map<DateTime, List<Match>> _groupByDay(List<Match> matches) {
    final map = <DateTime, List<Match>>{};
    for (final m in matches) {
      final dt = m.matchDatetime;
      if (dt == null) continue;
      final key = DateTime(dt.year, dt.month, dt.day);
      map.putIfAbsent(key, () => []).add(m);
    }
    // Ensure stable order by date
    final sortedKeys = map.keys.toList()..sort();
    return {for (final k in sortedKeys) k: map[k]!};
  }
}

class _FilterSegmentedControl extends StatelessWidget {
  final _FixtureFilter value;
  final ValueChanged<_FixtureFilter> onChanged;
  const _FilterSegmentedControl({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return AppSegmentedControl<_FixtureFilter>(
      selectedValue: value,
      onChanged: onChanged,
      segments: const {
        _FixtureFilter.upcoming: 'Upcoming',
        _FixtureFilter.completed: 'Completed',
        _FixtureFilter.all: 'All',
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return AppText(
      label,
      style: AppTypography.subhead.copyWith(
        fontWeight: FontWeight.w600,
        color: CupertinoColors.systemGrey,
      ),
    );
  }
}

String _friendlyDateLabel(DateTime date) {
  final today = DateTime.now();
  final d0 = DateTime(today.year, today.month, today.day);
  final d1 = DateTime(date.year, date.month, date.day);
  final diff = d1.difference(d0).inDays;
  if (diff == 0) return 'Today';
  if (diff == 1) return 'Tomorrow';
  if (diff == -1) return 'Yesterday';
  // e.g., Mon, 12 Nov
  final weekday = const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][date.weekday - 1];
  final month = const ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][date.month - 1];
  return '$weekday, ${date.day} $month';
}

// Removed inline _LiquidGlassSegmentedControl - now using AppSegmentedControl from design system

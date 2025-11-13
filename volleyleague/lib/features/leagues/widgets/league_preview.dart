import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';

import '../../../design/index.dart';
import '../../../core/models/models.dart';

/// A compact, phone-friendly glass card preview of league standings.
/// Designed to embed on a home screen or dashboard.
class LeaguePreview extends StatelessWidget {
  final Season season;
  final League league;
  final List<LeagueStanding> standings;
  final Map<int, Team> teams;
  final int maxRows;
  final double? width;

  const LeaguePreview({
    super.key,
    required this.season,
    required this.league,
    required this.standings,
    required this.teams,
    this.maxRows = 5,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final sorted = List<LeagueStanding>.from(standings)
      ..sort((a, b) {
        if (a.leaguePoints != b.leaguePoints) {
          return b.leaguePoints.compareTo(a.leaguePoints);
        }
        return b.setDifference.compareTo(a.setDifference);
      });
    final top = sorted.take(maxRows);

    return AppGlassContainer(
      width: width,
      padding: const EdgeInsets.all(Spacing.lg),
      borderRadius: 24,
      blur: 20,
      color: CupertinoColors.white.withValues(alpha: 0.25),
      borderColor: CupertinoColors.white.withValues(alpha: 0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title row
          Row(
            children: [
              AppIcons.league(
                fontSize: Spacing.xl,
                color: CupertinoColors.activeBlue,
              ),
              const SizedBox(width: Spacing.sm),
              Expanded(
                child: AppText(
                  'League Standings',
                  style: AppTypography.subhead.copyWith(
                    fontWeight: FontWeight.w700,
                    color: CupertinoColors.systemGrey,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: Spacing.md),

          // Table directly on glass to keep single-container design
          _PreviewHeaderRow(),
          const SizedBox(height: Spacing.xs),
          ...top.toList().asMap().entries.map((entry) {
            final index = entry.key;
            final s = entry.value;
            final team = teams[s.teamId];
            return _PreviewRow(
              position: index + 1,
              teamName: team?.name ?? 'Unknown Team',
              matchesPlayed: s.matchesPlayed,
              wins: s.wins,
              losses: s.losses,
              points: s.leaguePoints,
            );
          }),

          const SizedBox(height: Spacing.md),

          // CTA within the card (placeholder only)
          AppTextButtonX(
            onPressed: () {
              if (kDebugMode) {
                debugPrint('LeaguePreview: View full table (not linked).');
              }
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('View full table', style: AppTextStyles.activeBlueSemibold),
                const SizedBox(width: Spacing.xs),
                const Icon(CupertinoIcons.arrow_right, size: 18, color: CupertinoColors.activeBlue),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Header row for the compact preview table
class _PreviewHeaderRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 26,
          child: AppText(
            '#',
            style: AppTypography.caption.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(width: Spacing.sm),
        Expanded(
          child: AppText(
            'Team',
            style: AppTypography.caption.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        const _HeaderCell('MP'),
        const _HeaderCell('W'),
        const _HeaderCell('L'),
        const _HeaderCell('Pts'),
      ],
    );
  }
}

class _HeaderCell extends StatelessWidget {
  final String label;
  const _HeaderCell(this.label);
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 34,
      child: AppText(
        label,
        style: AppTypography.caption.copyWith(fontWeight: FontWeight.bold),
        textAlign: TextAlign.center,
      ),
    );
  }
}

/// Compact row for the preview list.
/// Kept private to this file as it is small and specific.
class _PreviewRow extends StatelessWidget {
  final int position;
  final String teamName;
  final int matchesPlayed;
  final int wins;
  final int losses;
  final int points;

  const _PreviewRow({
    required this.position,
    required this.teamName,
    required this.matchesPlayed,
    required this.wins,
    required this.losses,
    required this.points,
  });

  @override
  Widget build(BuildContext context) {
    final isTopThree = position <= 3;
    final isFirst = position == 1;
    final isSecond = position == 2;
    final isThird = position == 3;

    return Container(
      margin: const EdgeInsets.only(bottom: Spacing.xs),
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.sm,
        vertical: Spacing.sm,
      ),
      decoration: BoxDecoration(
        color: isFirst
            ? const Color(0xFFD4AF37).withAlpha(30)
            : isSecond
                ? const Color(0xFF525252).withAlpha(30)
                : isThird
                    ? const Color(0xFFCD7F32).withAlpha(30)
                    : null,
        borderRadius: BorderRadius.circular(Radii.sm),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 30,
            child: AppText(
              '$position',
              textAlign: TextAlign.center,
              style: AppTypography.body.copyWith(
                fontWeight: isTopThree ? FontWeight.bold : FontWeight.w500,
                color: isFirst
                    ? const Color(0xFFD4AF37)
                    : isSecond
                        ? const Color(0xFFABABAB)
                        : isThird
                            ? const Color(0xFFCD7F32)
                            : null,
              ),
            ),
          ),
          const SizedBox(width: Spacing.sm),
          Expanded(
            child: AppText(
              teamName,
              style: AppTypography.body.copyWith(
                fontWeight: isTopThree ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          _DataCell('$matchesPlayed'),
          _DataCell('$wins'),
          _DataCell('$losses'),
          SizedBox(
            width: 34,
            child: AppText(
              '$points',
              textAlign: TextAlign.center,
              style: AppTypography.footnote.copyWith(
                color: CupertinoColors.activeBlue,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DataCell extends StatelessWidget {
  final String text;
  const _DataCell(this.text);
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 34,
      child: AppText(
        text,
        textAlign: TextAlign.center,
        style: AppTypography.footnote,
      ),
    );
  }
}



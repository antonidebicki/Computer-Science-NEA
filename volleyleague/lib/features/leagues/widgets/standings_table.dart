import 'package:flutter/cupertino.dart';
import '../../../design/index.dart';
import '../../../core/models/models.dart';

/// Standings table displaying team rankings and statistics
class StandingsTable extends StatelessWidget {
  final List<LeagueStanding> standings;
  final Map<int, Team> teams;

  const StandingsTable({
    super.key,
    required this.standings,
    required this.teams,
  });

  @override
  Widget build(BuildContext context) {
    return AppGlassContainer(
      padding: const EdgeInsets.all(Spacing.lg),
      borderRadius: 24,
      blur: 20,
      color: CupertinoColors.white.withValues(alpha: 0.25),
      borderColor: CupertinoColors.white.withValues(alpha: 0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText(
            'Standings',
            style: AppTypography.title3.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: Spacing.lg),
          // Horizontal scroll for narrow screens
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Table Header
                _buildTableHeader(),
                const SizedBox(height: Spacing.sm),
                // Table Rows
                ...standings.asMap().entries.map((entry) {
                  final index = entry.key;
                  final standing = entry.value;
                  return _StandingRow(
                    position: index + 1,
                    standing: standing,
                    team: teams[standing.teamId],
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.md,
        vertical: Spacing.md,
      ),
      decoration: BoxDecoration(
        color: CupertinoColors.activeBlue.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(Radii.md),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 36,
            child: AppText(
              '#',
              style: AppTypography.subhead.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: Spacing.md),
          SizedBox(
            width: 140,
            child: AppText(
              'Team',
              style: AppTypography.subhead.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          _buildHeaderCell('P'),
          _buildHeaderCell('W'),
          _buildHeaderCell('L'),
          _buildHeaderCell('SW'),
          _buildHeaderCell('SL'),
          _buildHeaderCell('SD'),
          _buildHeaderCell('PTS'),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(String label) {
    return SizedBox(
      width: 42,
      child: AppText(
        label,
        style: AppTypography.subhead.copyWith(
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

/// Individual row in the standings table
class _StandingRow extends StatelessWidget {
  final int position;
  final LeagueStanding standing;
  final Team? team;

  const _StandingRow({
    required this.position,
    required this.standing,
    required this.team,
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
        width: 36,
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
        const SizedBox(width: Spacing.md),
        SizedBox(
        width: 140,
        child: AppText(
          team?.name ?? 'Unknown Team',
          style: AppTypography.body.copyWith(
          fontWeight: isTopThree ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        ),
        _buildDataCell('${standing.matchesPlayed}'),
        _buildDataCell('${standing.wins}'),
        _buildDataCell('${standing.losses}'),
        _buildDataCell('${standing.setsWon}'),
        _buildDataCell('${standing.setsLost}'),
        _buildDataCell(
        '${standing.setDifference > 0 ? '+' : ''}${standing.setDifference}',
        color: standing.setDifference > 0
          ? CupertinoColors.systemGreen
          : standing.setDifference < 0
            ? CupertinoColors.systemRed
            : null,
        ),
        _buildDataCell(
        '${standing.leaguePoints}',
        color: CupertinoColors.activeBlue,
        bold: true,
        ),
      ],
      ),
    );
    }

  Widget _buildDataCell(String text, {Color? color, bool bold = false}) {
    return SizedBox(
      width: 42,
      child: AppText(
        text,
        style: AppTypography.subhead.copyWith(
          fontSize: 14,
          color: color,
          fontWeight: bold ? FontWeight.bold : FontWeight.normal,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

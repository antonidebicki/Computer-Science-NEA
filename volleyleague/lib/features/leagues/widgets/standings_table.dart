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
          // Split table: fixed left (name/position) + scrollable right (stats)
          LayoutBuilder(
            builder: (context, constraints) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Fixed left section: Position & Team Name
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFixedHeader(),
                      const SizedBox(height: Spacing.sm),
                      ...standings.asMap().entries.map((entry) {
                        final index = entry.key;
                        final standing = entry.value;
                        return _buildFixedRow(
                          position: index + 1,
                          team: teams[standing.teamId],
                        );
                      }),
                    ],
                  ),
                  // Scrollable right section: All stats
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildScrollableHeader(),
                          const SizedBox(height: Spacing.sm),
                          ...standings.asMap().entries.map((entry) {
                            final index = entry.key;
                            final standing = entry.value;
                            return _buildScrollableRow(
                              position: index + 1,
                              standing: standing,
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  // Fixed left section header (Position & Team)
  Widget _buildFixedHeader() {
    return Container(
      height: 48, // Fixed height for alignment
      padding: const EdgeInsets.only(
        left: Spacing.md,
        right: Spacing.xs,
      ),
      decoration: BoxDecoration(
        color: CupertinoColors.activeBlue.withValues(alpha: 0.15),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(Radii.md),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 36,
            child: Text(
              '#',
              style: AppTypography.subhead.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: Spacing.md),
          SizedBox(
            width: 140,
            child: Text(
              'Team',
              style: AppTypography.subhead.copyWith(
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // Scrollable right section header (Stats)
  Widget _buildScrollableHeader() {
    const statColumnWidth = 50.0;
    
    return Container(
      height: 48, // Fixed height for alignment
      padding: const EdgeInsets.only(
        left: Spacing.xs,
        right: Spacing.md,
      ),
      decoration: BoxDecoration(
        color: CupertinoColors.activeBlue.withValues(alpha: 0.15),
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(Radii.md),
        ),
      ),
      child: Row(
        children: [
          _buildHeaderCell('P', statColumnWidth),
          _buildHeaderCell('W', statColumnWidth),
          _buildHeaderCell('L', statColumnWidth),
          _buildHeaderCell('SW', statColumnWidth),
          _buildHeaderCell('SL', statColumnWidth),
          _buildHeaderCell('SD', statColumnWidth),
          _buildHeaderCell('PTS', statColumnWidth),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(String label, double width) {
    return SizedBox(
      width: width,
      child: Text(
        label,
        style: AppTypography.subhead.copyWith(
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  // Fixed left section row (Position & Team)
  Widget _buildFixedRow({
    required int position,
    required Team? team,
  }) {
    final isTopThree = position <= 3;
    final isFirst = position == 1;
    final isSecond = position == 2;
    final isThird = position == 3;

    return Container(
      height: 40, // Fixed height for alignment
      margin: const EdgeInsets.only(bottom: Spacing.xs),
      padding: const EdgeInsets.only(
        left: Spacing.sm,
        right: Spacing.sm,
      ),
      decoration: BoxDecoration(
        color: isFirst
            ? const Color(0xFFD4AF37).withAlpha(30)
            : isSecond
              ? const Color(0xFF525252).withAlpha(30)
              : isThird
                ? const Color(0xFFCD7F32).withAlpha(30)
                : null,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(Radii.sm),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 36,
            child: Text(
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
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: Spacing.md),
          SizedBox(
            width: 140,
            child: Text(
              team?.name ?? 'Unknown Team',
              style: AppTypography.body.copyWith(
                fontWeight: isTopThree ? FontWeight.bold : FontWeight.normal,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // Scrollable right section row (Stats)
  Widget _buildScrollableRow({
    required int position,
    required LeagueStanding standing,
  }) {
    final isFirst = position == 1;
    final isSecond = position == 2;
    final isThird = position == 3;

    const statColumnWidth = 50.0;

    return Container(
      height: 40, // Fixed height for alignment
      margin: const EdgeInsets.only(bottom: Spacing.xs),
      padding: const EdgeInsets.only(
        left: 0,
        right: Spacing.sm,
      ),
      decoration: BoxDecoration(
        color: isFirst
            ? const Color(0xFFD4AF37).withAlpha(30)
            : isSecond
              ? const Color(0xFF525252).withAlpha(30)
              : isThird
                ? const Color(0xFFCD7F32).withAlpha(30)
                : null,
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(Radii.sm),
        ),
      ),
      child: Row(
        children: [
          _buildDataCell('${standing.matchesPlayed}', statColumnWidth),
          _buildDataCell('${standing.wins}', statColumnWidth),
          _buildDataCell('${standing.losses}', statColumnWidth),
          _buildDataCell('${standing.setsWon}', statColumnWidth),
          _buildDataCell('${standing.setsLost}', statColumnWidth),
          _buildDataCell(
            '${standing.setDifference > 0 ? '+' : ''}${standing.setDifference}',
            statColumnWidth,
            color: standing.setDifference > 0
              ? CupertinoColors.systemGreen
              : standing.setDifference < 0
                ? CupertinoColors.systemRed
                : null,
          ),
          _buildDataCell(
            '${standing.leaguePoints}',
            statColumnWidth,
            color: CupertinoColors.activeBlue,
            bold: true,
          ),
        ],
      ),
    );
  }

  Widget _buildDataCell(String text, double width, {Color? color, bool bold = false}) {
    return SizedBox(
      width: width,
      child: Text(
        text,
        style: AppTypography.subhead.copyWith(
          fontSize: 14,
          color: color,
          fontWeight: bold ? FontWeight.bold : FontWeight.normal,
        ),
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}


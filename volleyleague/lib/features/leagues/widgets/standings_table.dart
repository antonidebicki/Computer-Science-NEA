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
          // Use LayoutBuilder to get available width
          LayoutBuilder(
            builder: (context, constraints) {
              // Minimum width needed for table (adjust this value as needed)
              const minTableWidth = 500.0;
              final needsScroll = constraints.maxWidth < minTableWidth;
              final tableWidth = needsScroll ? minTableWidth : constraints.maxWidth;

              final tableContent = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Table Header
                  _buildTableHeader(tableWidth),
                  const SizedBox(height: Spacing.sm),
                  // Table Rows
                  ...standings.asMap().entries.map((entry) {
                    final index = entry.key;
                    final standing = entry.value;
                    return _StandingRow(
                      position: index + 1,
                      standing: standing,
                      team: teams[standing.teamId],
                      availableWidth: tableWidth,
                    );
                  }),
                ],
              );

              // Wrap in horizontal scroll if needed
              return needsScroll
                  ? SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SizedBox(
                        width: tableWidth,
                        child: tableContent,
                      ),
                    )
                  : tableContent;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader(double availableWidth) {
    // Calculate responsive column widths
    final statColumnWidth = _calculateStatColumnWidth(availableWidth);
    final positionWidth = _calculatePositionWidth(availableWidth);

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
            width: positionWidth,
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
          Expanded(
            child: Text(
              'Team',
              style: AppTypography.subhead.copyWith(
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
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

  // Calculate responsive column widths based on available space
  double _calculatePositionWidth(double availableWidth) {
    return availableWidth < 400 ? 30 : 36;
  }

  double _calculateStatColumnWidth(double availableWidth) {
    if (availableWidth < 400) {
      return 32;
    } else if (availableWidth < 600) {
      return 38;
    } else {
      return 42;
    }
  }
}

/// Individual row in the standings table
class _StandingRow extends StatelessWidget {
  final int position;
  final LeagueStanding standing;
  final Team? team;
  final double availableWidth;

  const _StandingRow({
    required this.position,
    required this.standing,
    required this.team,
    required this.availableWidth,
  });

  @override
  Widget build(BuildContext context) {
    final isTopThree = position <= 3;
    final isFirst = position == 1;
    final isSecond = position == 2;
    final isThird = position == 3;

    // Calculate responsive widths to match header
    final statColumnWidth = _calculateStatColumnWidth(availableWidth);
    final positionWidth = _calculatePositionWidth(availableWidth);

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
            width: positionWidth,
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
          Expanded(
            child: Text(
              team?.name ?? 'Unknown Team',
              style: AppTypography.body.copyWith(
                fontWeight: isTopThree ? FontWeight.bold : FontWeight.normal,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
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

  // Calculate responsive column widths to match header
  double _calculatePositionWidth(double availableWidth) {
    return availableWidth < 400 ? 30 : 36;
  }

  double _calculateStatColumnWidth(double availableWidth) {
    if (availableWidth < 400) {
      return 32;
    } else if (availableWidth < 600) {
      return 38;
    } else {
      return 42;
    }
  }
}

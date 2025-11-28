import 'package:flutter/cupertino.dart';
import '../../../design/index.dart';
import '../../../state/cubits/player/player_data_state.dart';
import 'standings_table_header.dart';
import 'standing_row.dart' as widgets;

/// Widget displaying league standings in a table format
/// Shows team rankings with matches played, wins, losses, and points
class LeagueStandingsWidget extends StatelessWidget {
  final String leagueName;
  final List<StandingData> standings;
  final VoidCallback? onViewFullTable;

  const LeagueStandingsWidget({
    super.key,
    required this.leagueName,
    required this.standings,
    this.onViewFullTable,
  });

  @override
  Widget build(BuildContext context) {
    return AppGlassContainer(
      padding: const EdgeInsets.all(Spacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            leagueName,
            style: AppTypography.headline.copyWith(
              color: CupertinoColors.label,
            ),
          ),
          const SizedBox(height: Spacing.lg),
          
          // Table header
          const StandingsTableHeader(),
          const SizedBox(height: Spacing.sm),
          
          // Standings rows
          ...standings.asMap().entries.map((entry) {
            final index = entry.key;
            final standing = entry.value;
            return Padding(
              padding: EdgeInsets.only(
                bottom: index < standings.length - 1 ? Spacing.sm : 0,
              ),
              child: widgets.StandingRow(
                position: index + 1,
                teamName: standing.teamName,
                matchesPlayed: standing.matchesPlayed,
                wins: standing.wins,
                losses: standing.losses,
                points: standing.points,
              ),
            );
          }),
          
          // View full table button
          if (onViewFullTable != null) ...[
            const SizedBox(height: Spacing.lg),
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: onViewFullTable,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'View full table',
                    style: AppTypography.callout.copyWith(
                      color: CupertinoColors.activeBlue,
                    ),
                  ),
                  const SizedBox(width: Spacing.xs),
                  const Icon(
                    CupertinoIcons.arrow_right,
                    size: 16,
                    color: CupertinoColors.activeBlue,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Widget shown when user doesn't belong to any league
class NoLeagueWidget extends StatelessWidget {
  const NoLeagueWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return AppGlassContainer(
      padding: const EdgeInsets.all(Spacing.xl),
      child: Column(
        children: [
          AppIcons.league(
            fontSize: 48,
            color: CupertinoColors.systemGrey,
          ),
          const SizedBox(height: Spacing.lg),
          Text(
            'No League',
            style: AppTypography.headline.copyWith(
              color: CupertinoColors.label,
            ),
          ),
          const SizedBox(height: Spacing.sm),
          Text(
            'You are not part of any league yet',
            style: AppTypography.callout.copyWith(
              color: CupertinoColors.secondaryLabel,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

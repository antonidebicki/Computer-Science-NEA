import 'package:flutter/cupertino.dart';
import '../../design/index.dart';
import '../../state/cubits/player/player_data_state.dart';
import 'standings_table_header.dart';
import 'standing_row.dart' as widgets;

// the mini version of the big page for the home screen
class MiniStandingsWidget extends StatelessWidget {
  final String leagueName;
  final List<StandingData> standings;
  final VoidCallback? onViewFullTable;

  const MiniStandingsWidget({
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

          const StandingsTableHeader(),
          const SizedBox(height: Spacing.sm),

          ...standings.take(5).toList().asMap().entries.map((entry) {
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

          // tried to use a fade to make it obvious this isnt a full table but looked bad so this is solution
          /*           if (standings.length > 5) ...[
            Row(
              children: [
                SizedBox(width: Spacing.sm,),
                Text(
                  '+ ${standings.length - 5} more teams',
                  style: AppTypography.callout.copyWith(
                    color: CupertinoColors.darkBackgroundGray.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ], */
          if (onViewFullTable != null) ...[
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: onViewFullTable,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '+ ${standings.length - 5} more teams',
                    style: AppTypography.callout.copyWith(
                      color: CupertinoColors.activeBlue,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: Spacing.xs),
                  Transform.translate(
                    offset: const Offset(0, -1.5),
                    child: Text(
                      '›',
                      style: AppTypography.callout.copyWith(
                        fontSize: AppTypography.callout.fontSize! * 1.5,
                        color: CupertinoColors.activeBlue,
                      ),
                    ),
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
          AppIcons.league(fontSize: 48, color: CupertinoColors.systemGrey),
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

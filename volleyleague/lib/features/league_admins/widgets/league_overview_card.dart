import 'package:flutter/cupertino.dart';
import '../../../core/models/league.dart';
import '../../../core/models/season.dart';
import '../../../design/index.dart';
import 'season_info.dart';

class LeagueOverviewCard extends StatelessWidget {
  final League league;
  final String? description;
  final String? rules;
  final bool isLoadingSeason;
  final Season? currentSeason;
  final Widget seasonStatus;

  const LeagueOverviewCard({
    super.key,
    required this.league,
    required this.description,
    required this.rules,
    required this.isLoadingSeason,
    required this.currentSeason,
    required this.seasonStatus,
  });

  @override
  Widget build(BuildContext context) {
    return AppGlassContainer(
      padding: const EdgeInsets.all(Spacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'League Overview',
            style: AppTypography.headline.copyWith(
              color: CupertinoColors.label,
            ),
          ),
          const SizedBox(height: Spacing.sm),
          Text(
            league.name,
            style: AppTypography.body.copyWith(
              color: CupertinoColors.secondaryLabel,
            ),
          ),
          if (description != null && description!.isNotEmpty) ...[
            const SizedBox(height: Spacing.md),
            Text(
              'Description',
              style: AppTypography.caption.copyWith(
                color: CupertinoColors.secondaryLabel,
              ),
            ),
            const SizedBox(height: Spacing.xs),
            Text(
              description!,
              style: AppTypography.body.copyWith(
                color: CupertinoColors.label,
              ),
            ),
          ],
          if (rules != null && rules!.isNotEmpty) ...[
            const SizedBox(height: Spacing.md),
            Text(
              'Rules',
              style: AppTypography.caption.copyWith(
                color: CupertinoColors.secondaryLabel,
              ),
            ),
            const SizedBox(height: Spacing.xs),
            Text(
              rules!,
              style: AppTypography.body.copyWith(
                color: CupertinoColors.label,
              ),
            ),
          ],
          const SizedBox(height: Spacing.md),
          if (isLoadingSeason)
            const CupertinoActivityIndicator(radius: 10)
          else
            SeasonInfo(season: currentSeason),
          const SizedBox(height: Spacing.md),
          seasonStatus,
        ],
      ),
    );
  }
}

import 'package:flutter/cupertino.dart';
import '../../design/index.dart';
import '../../core/models/match_data.dart';
import 'fixture_card.dart';

// the mini widgets for the home page
class MiniFixturesWidget extends StatelessWidget {
  final List<MatchData> fixtures;
  final VoidCallback? onMoreFixtures;

  const MiniFixturesWidget({
    super.key,
    required this.fixtures,
    this.onMoreFixtures,
  });

  @override
  Widget build(BuildContext context) {
    return AppGlassContainer(
      padding: const EdgeInsets.all(Spacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Next Fixtures',
            style: AppTypography.headline.copyWith(
              color: CupertinoColors.label,
            ),
          ),
          const SizedBox(height: Spacing.lg),
          
          if (fixtures.isEmpty)
            _buildNoFixtures()
          else
            ...fixtures.take(3).toList().asMap().entries.map((entry) {
              final index = entry.key;
              final fixture = entry.value;
              return Padding(
                padding: EdgeInsets.only(
                  bottom: index < fixtures.length - 1 ? Spacing.lg : 0,
                ),
                child: FixtureCard(
                  homeTeam: fixture.homeTeamName,
                  awayTeam: fixture.awayTeamName,
                  date: fixture.match.matchDatetime ?? DateTime.now(),
                  venue: fixture.match.venue,
                ),
              );
            }),
          
          if (onMoreFixtures != null && fixtures.isNotEmpty) ...[
            const SizedBox(height: Spacing.lg),
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: onMoreFixtures,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'More Fixtures',
                    style: AppTypography.callout.copyWith(
                      color: CupertinoColors.activeBlue,
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

  Widget _buildNoFixtures() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: Spacing.xl),
        child: Column(
          children: [
            AppIcons.match(
              fontSize: 40,
              color: CupertinoColors.systemGrey,
            ),
            const SizedBox(height: Spacing.md),
            Text(
              'No upcoming fixtures',
              style: AppTypography.callout.copyWith(
                color: CupertinoColors.secondaryLabel,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

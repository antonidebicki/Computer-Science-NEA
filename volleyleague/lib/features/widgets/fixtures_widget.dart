import 'package:flutter/cupertino.dart';
import '../../design/index.dart';
import '../../core/models/match_data.dart';
import 'fixture_card.dart';

class FixturesWidget extends StatelessWidget {
  final List<MatchData> fixtures;

  const FixturesWidget({
    super.key,
    required this.fixtures,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (fixtures.isEmpty)
            _buildNoFixtures()
          else
            ...fixtures.asMap().entries.map((entry) {
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

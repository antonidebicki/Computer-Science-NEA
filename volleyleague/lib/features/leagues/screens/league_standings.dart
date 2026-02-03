import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../../../design/index.dart';
import '../../../core/models/models.dart';
import '../../../state/providers/theme_provider.dart';
import '../widgets/league_header_card.dart';
import '../widgets/standings_table.dart';
import '../widgets/standings_legend.dart';

/// League Standings Screen
class LeagueStandingsScreen extends StatelessWidget {
  final Season season;
  final League league;
  final List<LeagueStanding> standings;
  final Map<int, Team> teams;
  final Future<void> Function()? onRefresh;

  const LeagueStandingsScreen({
    super.key,
    required this.season,
    required this.league,
    required this.standings,
    required this.teams,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;
    
    // Sort standings by league points (desc), then by set difference
    final sortedStandings = List<LeagueStanding>.from(standings)
      ..sort((a, b) {
        if (a.leaguePoints != b.leaguePoints) {
          return b.leaguePoints.compareTo(a.leaguePoints);
        }
        return b.setDifference.compareTo(a.setDifference);
      });

    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('League Standings'),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: AppGradients.backgroundGradient(context, isDark: isDark),
        ),
        child: CustomScrollView(
          slivers: [
            if (onRefresh != null)
              CupertinoSliverRefreshControl(
                onRefresh: onRefresh,
              ),
            SliverSafeArea(
              sliver: SliverPadding(
                padding: const EdgeInsets.all(Spacing.lg),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Header
                    LeagueHeaderCard(
                      league: league,
                      season: season,
                    ),
                    
                    const SizedBox(height: Spacing.lg),
                    
                    // Standings Table
                    StandingsTable(
                      standings: sortedStandings,
                      teams: teams,
                    ),
                    
                    const SizedBox(height: Spacing.lg),
                    
                    // Legend
                    const StandingsLegend(),
                  ]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

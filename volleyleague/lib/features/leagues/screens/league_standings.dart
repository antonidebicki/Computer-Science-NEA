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

  const LeagueStandingsScreen({
    super.key,
    required this.season,
    required this.league,
    required this.standings,
    required this.teams,
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
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(Spacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}

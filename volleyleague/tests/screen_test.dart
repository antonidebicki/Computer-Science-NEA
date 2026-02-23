import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:volleyleague/features/auth/screens/login_screen.dart';
import 'package:volleyleague/features/auth/screens/register_screen.dart';
import 'package:volleyleague/features/leagues/widgets/league_preview.dart';
import 'package:volleyleague/features/matches/screens/fixtures_screen.dart';
import 'package:volleyleague/core/models/models.dart';
import 'package:volleyleague/design/index.dart';
import 'package:volleyleague/state/providers/theme_provider.dart';

/// Screen selector for testing individual screens
class ScreenTestApp extends StatelessWidget {
  const ScreenTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return CupertinoApp(
            title: 'Screen Test',
            theme: CupertinoThemeData(
              brightness: themeProvider.brightness,
            ),
            home: const ScreenSelector(),
          );
        },
      ),
    );
  }
}

class ScreenSelector extends StatelessWidget {
  const ScreenSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDark;
    
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Select Screen to Test'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: themeProvider.toggleBrightness,
          child: Icon(
            isDark ? CupertinoIcons.sun_max : CupertinoIcons.moon,
            size: 28,
          ),
        ),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(Spacing.lg),
          children: [
            _buildScreenButton(
              context,
              'Fixtures Screen',
              _buildFixturesWithTestData(),
            ),
            const SizedBox(height: Spacing.md),
            _buildScreenButton(
              context,
              'Login Screen',
              const LoginScreen(),
            ),
            const SizedBox(height: Spacing.md),
            _buildScreenButton(
              context,
              'Register Screen',
              const RegisterScreen(),
            ),
              const SizedBox(height: Spacing.md),
              _buildScreenButton(
                context,
                'League Preview',
                _buildLeaguePreviewWithTestData(),
              ),

          ],
        ),
      ),
    );
  }

  Widget _buildScreenButton(BuildContext context, String title, Widget screen) {
    return CupertinoButton.filled(
      onPressed: () {
        Navigator.of(context).push(
          CupertinoPageRoute(builder: (_) => screen),
        );
      },
      child: Text(title),
    );
  }

  /// Create test data for the Fixtures screen
  Widget _buildFixturesWithTestData() {
    final teams = {
      1: Team(teamId: 1, name: 'South Bucks', createdByUserId: 1, logoUrl: null, createdAt: DateTime(2024, 1, 20)),
      2: Team(teamId: 2, name: 'Richmond VC', createdByUserId: 2, logoUrl: null, createdAt: DateTime(2024, 1, 21)),
      3: Team(teamId: 3, name: 'MK City', createdByUserId: 3, logoUrl: null, createdAt: DateTime(2024, 1, 22)),
      4: Team(teamId: 4, name: 'Leeds Gorse', createdByUserId: 4, logoUrl: null, createdAt: DateTime(2024, 1, 23)),
    };

    final now = DateTime.now();
    final matches = <Match>[
      Match(
        matchId: 101,
        seasonId: 1,
        homeTeamId: 1,
        awayTeamId: 2,
        matchDatetime: DateTime(now.year, now.month, now.day, 18, 30).add(const Duration(days: 0)),
        venue: 'Main Arena',
        status: GameState.scheduled,
      ),
      Match(
        matchId: 102,
        seasonId: 1,
        homeTeamId: 3,
        awayTeamId: 4,
        matchDatetime: DateTime(now.year, now.month, now.day, 20, 0).add(const Duration(days: 0)),
        venue: 'Court 2',
        status: GameState.scheduled,
      ),
      Match(
        matchId: 103,
        seasonId: 1,
        homeTeamId: 2,
        awayTeamId: 3,
        matchDatetime: DateTime(now.year, now.month, now.day, 19, 0).add(const Duration(days: 1)),
        venue: 'Community Hall',
        status: GameState.scheduled,
      ),
      Match(
        matchId: 104,
        seasonId: 1,
        homeTeamId: 4,
        awayTeamId: 1,
        matchDatetime: DateTime(now.year, now.month, now.day, 17, 0).add(const Duration(days: -2)),
        venue: 'Leeds Sports Centre',
        status: GameState.finished,
        homeSetsWon: 1,
        awaySetsWon: 3,
        winnerTeamId: 1,
      ),
      Match(
        matchId: 105,
        seasonId: 1,
        homeTeamId: 1,
        awayTeamId: 3,
        matchDatetime: DateTime(now.year, now.month, now.day, 16, 0).add(const Duration(days: 7)),
        venue: 'Main Arena',
        status: GameState.scheduled,
      ),
      Match(
        matchId: 106,
        seasonId: 1,
        homeTeamId: 2,
        awayTeamId: 4,
        matchDatetime: DateTime(now.year, now.month, now.day, 15, 0).add(const Duration(days: -7)),
        venue: 'Richmond Court',
        status: GameState.processed,
        homeSetsWon: 3,
        awaySetsWon: 0,
        winnerTeamId: 2,
      ),
    ];

    return FixturesScreen(matches: matches, teams: teams);
  }

  /// Create test data for the League Preview widget
  Widget _buildLeaguePreviewWithTestData() {
    final league = League(
      leagueId: 1,
      name: 'U18 National Volleyball League',
      adminUserId: 1,
      description: 'The highest tier of the U18 National Volleyball competition',
      rules: 'FIVB Official Rules',
      createdAt: DateTime(2024, 1, 15),
    );

    final season = Season(
      seasonId: 1,
      leagueId: 1,
      name: '2024-2025 Season',
      startDate: DateTime(2024, 9, 1),
      endDate: DateTime(2025, 5, 31),
      isArchived: false,
    );

    final teams = {
      1: Team(teamId: 1, name: 'South Bucks', createdByUserId: 1, logoUrl: null, createdAt: DateTime(2024, 1, 20)),
      2: Team(teamId: 2, name: 'Richmond VC', createdByUserId: 2, logoUrl: null, createdAt: DateTime(2024, 1, 21)),
      3: Team(teamId: 3, name: 'MK City', createdByUserId: 3, logoUrl: null, createdAt: DateTime(2024, 1, 22)),
      4: Team(teamId: 4, name: 'Leeds Gorse', createdByUserId: 4, logoUrl: null, createdAt: DateTime(2024, 1, 23)),
      5: Team(teamId: 5, name: 'Newcastle Knights', createdByUserId: 5, logoUrl: null, createdAt: DateTime(2024, 1, 24)),
      6: Team(teamId: 6, name: 'Liverpool VC', createdByUserId: 6, logoUrl: null, createdAt: DateTime(2024, 1, 25)),
      7: Team(teamId: 7, name: 'Essex Rebels', createdByUserId: 7, logoUrl: null, createdAt: DateTime(2024, 1, 26)),
      8: Team(teamId: 8, name: 'Willesden Titans', createdByUserId: 8, logoUrl: null, createdAt: DateTime(2024, 1, 27)),
    };

    final standings = [
      LeagueStanding(standingId: 1, seasonId: 1, teamId: 1, matchesPlayed: 14, wins: 12, losses: 2, setsWon: 38, setsLost: 12, pointsWon: 1056, pointsLost: 856, leaguePoints: 36),
      LeagueStanding(standingId: 2, seasonId: 1, teamId: 3, matchesPlayed: 14, wins: 11, losses: 3, setsWon: 35, setsLost: 15, pointsWon: 1023, pointsLost: 889, leaguePoints: 33),
      LeagueStanding(standingId: 3, seasonId: 1, teamId: 2, matchesPlayed: 14, wins: 10, losses: 4, setsWon: 33, setsLost: 18, pointsWon: 998, pointsLost: 912, leaguePoints: 30),
      LeagueStanding(standingId: 4, seasonId: 1, teamId: 4, matchesPlayed: 14, wins: 8, losses: 6, setsWon: 28, setsLost: 22, pointsWon: 945, pointsLost: 923, leaguePoints: 24),
      LeagueStanding(standingId: 5, seasonId: 1, teamId: 8, matchesPlayed: 14, wins: 6, losses: 8, setsWon: 22, setsLost: 28, pointsWon: 887, pointsLost: 956, leaguePoints: 18),
      LeagueStanding(standingId: 6, seasonId: 1, teamId: 5, matchesPlayed: 14, wins: 4, losses: 10, setsWon: 18, setsLost: 33, pointsWon: 834, pointsLost: 1012, leaguePoints: 12),
      LeagueStanding(standingId: 7, seasonId: 1, teamId: 7, matchesPlayed: 14, wins: 3, losses: 11, setsWon: 14, setsLost: 35, pointsWon: 789, pointsLost: 1067, leaguePoints: 9),
      LeagueStanding(standingId: 8, seasonId: 1, teamId: 6, matchesPlayed: 14, wins: 2, losses: 12, setsWon: 10, setsLost: 38, pointsWon: 756, pointsLost: 1123, leaguePoints: 6),
    ];

    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(middle: Text('League Preview (Test)')),
      child: Builder(
        builder: (ctx) => Container(
          constraints: const BoxConstraints.expand(),
          decoration: BoxDecoration(
            gradient: AppGradients.backgroundGradient(
              ctx,
              isDark: Provider.of<ThemeProvider>(ctx, listen: false).isDark,
            ),
          ),
          child: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(Spacing.lg),
              children: [
                Align(
                  alignment: Alignment.topCenter,
                  child: LeaguePreview(
                    season: season,
                    league: league,
                    standings: standings,
                    teams: teams,
                    maxRows: 6,
                    width: 330,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

void main() {
  runApp(const ScreenTestApp());
}

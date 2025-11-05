import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:volleyleague/features/auth/screens/login_screen.dart';
import 'package:volleyleague/features/auth/screens/register_screen.dart';
import 'package:volleyleague/features/leagues/screens/league_standings.dart';
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
              'League Standings',
              _buildLeagueStandingsWithTestData(),
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

  /// Create test data for the League Standings screen
  Widget _buildLeagueStandingsWithTestData() {
    // Create test league
    final league = League(
      leagueId: 1,
      name: 'U18 National Volleyball League',
      adminUserId: 1,
      description: 'The highest tier of the U18 National Volleyball competition',
      rules: 'FIVB Official Rules',
      createdAt: DateTime(2024, 1, 15),
    );

    // Create test season
    final season = Season(
      seasonId: 1,
      leagueId: 1,
      name: '2024-2025 Season',
      startDate: DateTime(2024, 9, 1),
      endDate: DateTime(2025, 5, 31),
      isArchived: false,
    );

    // Create test teams
    final teams = {
      1: Team(
        teamId: 1,
        name: 'South Bucks',
        createdByUserId: 1,
        logoUrl: 'data:image/jpeg;base64,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',
        createdAt: DateTime(2024, 1, 20),
      ),
      2: Team(
        teamId: 2,
        name: 'Ace Volley Warriors',
        createdByUserId: 2,
        logoUrl: null,
        createdAt: DateTime(2024, 1, 21),
      ),
      3: Team(
        teamId: 3,
        name: 'Net Crushers',
        createdByUserId: 3,
        logoUrl: null,
        createdAt: DateTime(2024, 1, 22),
      ),
      4: Team(
        teamId: 4,
        name: 'Spike Masters United',
        createdByUserId: 4,
        logoUrl: null,
        createdAt: DateTime(2024, 1, 23),
      ),
      5: Team(
        teamId: 5,
        name: 'Block Party FC',
        createdByUserId: 5,
        logoUrl: null,
        createdAt: DateTime(2024, 1, 24),
      ),
      6: Team(
        teamId: 6,
        name: 'Serve City Athletics',
        createdByUserId: 6,
        logoUrl: null,
        createdAt: DateTime(2024, 1, 25),
      ),
      7: Team(
        teamId: 7,
        name: 'Rally Raptors',
        createdByUserId: 7,
        logoUrl: null,
        createdAt: DateTime(2024, 1, 26),
      ),
      8: Team(
        teamId: 8,
        name: 'Court Kings',
        createdByUserId: 8,
        logoUrl: null,
        createdAt: DateTime(2024, 1, 27),
      ),
    };

    // Create test standings with realistic data
    final standings = [
      LeagueStanding(
        standingId: 1,
        seasonId: 1,
        teamId: 1,
        matchesPlayed: 14,
        wins: 12,
        losses: 2,
        setsWon: 38,
        setsLost: 12,
        pointsWon: 1056,
        pointsLost: 856,
        leaguePoints: 36, // 3 points per win
      ),
      LeagueStanding(
        standingId: 2,
        seasonId: 1,
        teamId: 3,
        matchesPlayed: 14,
        wins: 11,
        losses: 3,
        setsWon: 35,
        setsLost: 15,
        pointsWon: 1023,
        pointsLost: 889,
        leaguePoints: 33,
      ),
      LeagueStanding(
        standingId: 3,
        seasonId: 1,
        teamId: 2,
        matchesPlayed: 14,
        wins: 10,
        losses: 4,
        setsWon: 33,
        setsLost: 18,
        pointsWon: 998,
        pointsLost: 912,
        leaguePoints: 30,
      ),
      LeagueStanding(
        standingId: 4,
        seasonId: 1,
        teamId: 4,
        matchesPlayed: 14,
        wins: 8,
        losses: 6,
        setsWon: 28,
        setsLost: 22,
        pointsWon: 945,
        pointsLost: 923,
        leaguePoints: 24,
      ),
      LeagueStanding(
        standingId: 5,
        seasonId: 1,
        teamId: 8,
        matchesPlayed: 14,
        wins: 6,
        losses: 8,
        setsWon: 22,
        setsLost: 28,
        pointsWon: 887,
        pointsLost: 956,
        leaguePoints: 18,
      ),
      LeagueStanding(
        standingId: 6,
        seasonId: 1,
        teamId: 5,
        matchesPlayed: 14,
        wins: 4,
        losses: 10,
        setsWon: 18,
        setsLost: 33,
        pointsWon: 834,
        pointsLost: 1012,
        leaguePoints: 12,
      ),
      LeagueStanding(
        standingId: 7,
        seasonId: 1,
        teamId: 7,
        matchesPlayed: 14,
        wins: 3,
        losses: 11,
        setsWon: 14,
        setsLost: 35,
        pointsWon: 789,
        pointsLost: 1067,
        leaguePoints: 9,
      ),
      LeagueStanding(
        standingId: 8,
        seasonId: 1,
        teamId: 6,
        matchesPlayed: 14,
        wins: 2,
        losses: 12,
        setsWon: 10,
        setsLost: 38,
        pointsWon: 756,
        pointsLost: 1123,
        leaguePoints: 6,
      ),
    ];

    return LeagueStandingsScreen(
      season: season,
      league: league,
      standings: standings,
      teams: teams,
    );
  }
}

void main() {
  runApp(const ScreenTestApp());
}

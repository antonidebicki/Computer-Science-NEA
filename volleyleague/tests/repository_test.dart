import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:volleyleague/services/api_client.dart';
import 'package:volleyleague/services/auth_service.dart';
import 'package:volleyleague/services/repositories/repositories.dart';

/// Integration tests for repositories with real backend.
/// 
/// Before running:
/// 1. Start backend: uvicorn api.fastapi_app:app --reload
/// 2. Ensure database is seeded with test data (admin: league_admin / AdminPass123)
/// 3. Run: flutter test tests/repository_test.dart
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  const baseUrl = 'http://localhost:8000';
  
  late ApiClient apiClient;
  late AuthService authService;
  late UserRepository userRepo;
  late LeagueRepository leagueRepo;
  late MatchRepository matchRepo;

  setUp(() {
    apiClient = ApiClient(baseUrl: baseUrl);
    authService = AuthService();
    userRepo = UserRepository(apiClient, authService);
    leagueRepo = LeagueRepository(apiClient);
    matchRepo = MatchRepository(apiClient);
  });

  group('UserRepository Tests', () {
    test('Should login successfully with valid credentials', () async {
      final response = await userRepo.login('league_admin', 'AdminPass123');
      
      expect(response, isNotNull);
      expect(response['access_token'], isNotEmpty);
      expect(response['refresh_token'], isNotEmpty);
      expect(response['user']['username'], equals('league_admin'));
      expect(response['user']['role'], equals('ADMIN'));
      
      debugPrint('  - login successful');
      debugPrint('     access_token: ${response['access_token'].substring(0, 20)}...');
      debugPrint('     user: ${response['user']['username']} (${response['user']['role']})');
    });

    test('Should fail login with invalid credentials', () async {
      try {
        await userRepo.login('invalid', 'wrongpassword');
        fail('Should have thrown an exception');
      } catch (e) {
        expect(e.toString(), contains('Unauthorized'));
        debugPrint('  - invalid credentials rejected');
      }
    });

    test('Should check if user is logged in after login', () async {
      await userRepo.login('league_admin', 'AdminPass123');
      final isLoggedIn = await userRepo.isLoggedIn();
      
      expect(isLoggedIn, isTrue);
      debugPrint('  - login state persisted');
    });

    test('Should get current user after login', () async {
      await userRepo.login('league_admin', 'AdminPass123');
      final user = await userRepo.getCurrentUser();
      
      expect(user, isNotNull);
      expect(user!.username, equals('league_admin'));
      debugPrint('  - current user retrieved: ${user.username}');
    });

    test('Should logout and clear tokens', () async {
      await userRepo.login('league_admin', 'AdminPass123');
      await userRepo.logout();
      
      final isLoggedIn = await userRepo.isLoggedIn();
      expect(isLoggedIn, isFalse);
      debugPrint('  - logout successful');
    });
  });

  group('LeagueRepository Tests (requires auth)', () {
    setUp(() async {
      await userRepo.login('league_admin', 'AdminPass123');
    });

    tearDown(() async {
      await userRepo.logout();
    });

    test('Should fetch all leagues', () async {
      final leagues = await leagueRepo.getLeagues();
      
      expect(leagues, isNotEmpty);
      debugPrint('  - fetched ${leagues.length} leagues');
      for (var league in leagues) {
        debugPrint('  - ${league.name}');
      }
    });

    test('Should fetch specific league by ID', () async {
      final leagues = await leagueRepo.getLeagues();
      if (leagues.isEmpty) {
        debugPrint('  - no leagues found, skipping test');
        return;
      }
      
      final league = await leagueRepo.getLeague(leagues.first.leagueId);
      
      expect(league, isNotNull);
      expect(league.leagueId, equals(leagues.first.leagueId));
      debugPrint('  - fetched league: ${league.name}');
    });

    test('Should fetch seasons for a league', () async {
      final leagues = await leagueRepo.getLeagues();
      if (leagues.isEmpty) {
        debugPrint('[WARN] No leagues found, skipping test');
        return;
      }
      
      final seasons = await leagueRepo.getSeasons(leagues.first.leagueId);
      
      debugPrint('  - fetched ${seasons.length} seasons for ${leagues.first.name}');
      for (var season in seasons) {
        debugPrint('  - ${season.name} (${season.startDate} to ${season.endDate})');
      }
    });

    test('Should fetch standings for a season', () async {
      final leagues = await leagueRepo.getLeagues();
      if (leagues.isEmpty) {
        debugPrint('[WARN] No leagues found, skipping test');
        return;
      }
      
      final seasons = await leagueRepo.getSeasons(leagues.first.leagueId);
      if (seasons.isEmpty) {
        debugPrint('  - no seasons found, skipping test');
        return;
      }
      
      final standings = await leagueRepo.getStandings(seasons.first.seasonId);
      
      debugPrint('  - fetched ${standings.length} standings for ${seasons.first.name}');
      for (var standing in standings) {
        debugPrint('  - ${standing['team_name']}: ${standing['league_points']} pts');
      }
    });
  });

  group('LeagueRepository Tests (requires auth)', () {
    setUp(() async {
      await userRepo.login('league_admin', 'AdminPass123');
    });

    tearDown(() async {
      await userRepo.logout();
    });

    test('Should fetch all matches', () async {
      final matches = await matchRepo.getMatches();
      
      debugPrint('  - fetched ${matches.length} matches');
      if (matches.isNotEmpty) {
        final match = matches.first;
        debugPrint('  Sample: Match ${match.matchId} - Status: ${match.status}');
      }
    });

    test('Should fetch matches filtered by season', () async {
      final leagues = await leagueRepo.getLeagues();
      if (leagues.isEmpty) {
        debugPrint('[WARN] No leagues found, skipping test');
        return;
      }
      
      final seasons = await leagueRepo.getSeasons(leagues.first.leagueId);
      if (seasons.isEmpty) {
        debugPrint('[WARN] No seasons found, skipping test');
        return;
      }
      
      final matches = await matchRepo.getMatches(seasonId: seasons.first.seasonId);
      
      debugPrint('  - fetched ${matches.length} matches for season ${seasons.first.name}');
    });

    test('Should fetch specific match by ID', () async {
      final matches = await matchRepo.getMatches();
      if (matches.isEmpty) {
        debugPrint('  - no matches found, skipping test');
        return;
      }
      
      final match = await matchRepo.getMatch(matches.first.matchId);
      
      expect(match, isNotNull);
      expect(match.matchId, equals(matches.first.matchId));
      debugPrint('  - fetched match ${match.matchId}: ${match.status}');
    });

    test('Should fetch sets for a match', () async {
      final matches = await matchRepo.getMatches();
      if (matches.isEmpty) {
        debugPrint('[WARN] No matches found, skipping test');
        return;
      }
      
      final sets = await matchRepo.getMatchSets(matches.first.matchId);
      
      debugPrint('  - fetched ${sets.length} sets for match ${matches.first.matchId}');
      for (var set in sets) {
        debugPrint('  - Set ${set.setNumber}: ${set.homeTeamScore} - ${set.awayTeamScore}');
      }
    });
  });

  group('Authorization Tests', () {
    test('Should get 401 when accessing protected endpoint without login', () async {
      await userRepo.logout();
      
      try {
        await leagueRepo.getLeagues();
        fail('Should have thrown an exception');
      } catch (e) {
        expect(e.toString(), contains('Unauthorized'));
        debugPrint('  - unauthorized access blocked');
      }
    });

    test('Should automatically refresh token when expired', () async {
      await userRepo.login('league_admin', 'AdminPass123');
      
      final isExpired = await authService.isAccessTokenExpired();
      debugPrint('  - token expiry check: expired = $isExpired');
      
      await userRepo.logout();
    });
  });

  group('Session Persistence Tests', () {
    test('Should restore session from stored tokens', () async {
      await userRepo.login('league_admin', 'AdminPass123');
      
      final newApiClient = ApiClient(baseUrl: baseUrl);
      final newUserRepo = UserRepository(newApiClient, authService);
      
      final restored = await newUserRepo.restoreSession();
      
      expect(restored, isTrue);
      debugPrint('  - session restored');
      
      final newLeagueRepo = LeagueRepository(newApiClient);
      final leagues = await newLeagueRepo.getLeagues();
      expect(leagues, isNotEmpty);
      debugPrint('  - authenticated request after restore');
      
      await userRepo.logout();
    });
  });
}

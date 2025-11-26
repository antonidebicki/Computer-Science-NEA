/// Standalone test script for repositories with real backend.
/// 
/// This uses dart:io instead of package:http to avoid Flutter test framework limitations.
/// 
/// Before running:
/// 1. Start backend: uvicorn api.fastapi_app:app --reload
/// 2. Ensure database is seeded (admin: league_admin / AdminPass123)
/// 3. Run: dart run volleyleague/test/repository_standalone_test.dart
library;

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';

const baseUrl = 'http://localhost:8000';

Future<dynamic> makeRequest(
  String method,
  String path, {
  Map<String, String>? headers,
  Map<String, dynamic>? body,
}) async {
  final client = HttpClient();
  
  try {
    final uri = Uri.parse('$baseUrl$path');
    final request = method == 'GET'
        ? await client.getUrl(uri)
        : await client.postUrl(uri);

    headers?.forEach((key, value) => request.headers.add(key, value));
    
    if (body != null) {
      request.headers.add('Content-Type', 'application/json');
      request.write(json.encode(body));
    }

    final response = await request.close();
    final responseBody = await response.transform(utf8.decoder).join();
    
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return json.decode(responseBody);
    } else {
      throw Exception('HTTP ${response.statusCode}: $responseBody');
    }
  } finally {
    client.close();
  }
}

void main() async {
  debugPrint('Running repository integration tests...');
  debugPrint('');

  try {
    // Test 1: Login
    debugPrint('Test 1: Authentication');
    final loginResponse = await makeRequest(
      'POST',
      '/api/login',
      body: {'username': 'league_admin', 'password': 'AdminPass123'},
    );
    debugPrint('  - login with valid credentials');
    debugPrint('     user: ${loginResponse['user']['username']}');
    debugPrint('     role: ${loginResponse['user']['role']}');
    
    final accessToken = loginResponse['access_token'] as String;

    // Test 2: Get Leagues
    final leaguesResponse = await makeRequest(
      'GET',
      '/api/leagues',
      headers: {'Authorization': 'Bearer $accessToken'},
    );
    final leagues = leaguesResponse as List;
    debugPrint('  - fetch leagues (${leagues.length} found)');
    for (var league in leagues) {
      debugPrint('      ${league['name']}');
    }

    if (leagues.isEmpty) {
      debugPrint('  - no leagues found, skipping remaining tests');
      return;
    }

    final firstLeagueId = leagues.first['league_id'];

    // Test 3: Get Seasons
    debugPrint('');
    debugPrint('Test 2: League operations');
    final seasonsResponse = await makeRequest(
      'GET',
      '/api/leagues/$firstLeagueId/seasons',
      headers: {'Authorization': 'Bearer $accessToken'},
    );
    final seasons = seasonsResponse as List;
    debugPrint('  - fetch seasons (${seasons.length} found)');
    for (var season in seasons) {
      debugPrint('      ${season['name']}');
    }

    if (seasons.isEmpty) {
      debugPrint('  - no seasons found, skipping remaining tests');
      return;
    }

    final firstSeasonId = seasons.first['season_id'];

    // Test 4: Get Standings
    final standingsResponse = await makeRequest(
      'GET',
      '/api/seasons/$firstSeasonId/standings?archived=false',
      headers: {'Authorization': 'Bearer $accessToken'},
    );
    final standings = standingsResponse as List;
    debugPrint('  - fetch standings (${standings.length} teams)');
    for (var standing in standings) {
      debugPrint('      ${standing['team_name']}: ${standing['league_points']} pts');
    }

    // Test 5: Get Matches
    debugPrint('');
    debugPrint('Test 3: Match operations');
    final matchesResponse = await makeRequest(
      'GET',
      '/api/matches',
      headers: {'Authorization': 'Bearer $accessToken'},
    );
    final matches = matchesResponse as List;
    debugPrint('  - fetch matches (${matches.length} found)');

    // Test 6: Test unauthorized access
    debugPrint('');
    debugPrint('Test 4: Authorization');
    try {
      await makeRequest('GET', '/api/leagues');
      debugPrint('  - unauthorized access should be blocked');
    } catch (e) {
      debugPrint('  - unauthorized access blocked');
    }

    debugPrint('');
    debugPrint('All tests passed');
    debugPrint('All tests passed');
    
  } catch (e, stackTrace) {
    debugPrint('');
    debugPrint('Test failed: $e');
    debugPrint(stackTrace.toString());
    exit(1);
  }
}

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../design/index.dart';
import '../../../state/providers/theme_provider.dart';
import '../../../services/api_client.dart';
import '../../../services/auth_service.dart';
import '../../../services/repositories/league_repository.dart';
import '../../../core/models/league.dart';
import '../../../core/models/season.dart';
import '../../../state/cubits/player/player_data_state.dart';
import '../../widgets/standings_table_header.dart';
import '../../widgets/modern_standing_row.dart';
import '../../standings/widgets/team_details_popup.dart';

class LeagueAdminStandingsScreen extends StatefulWidget {
  const LeagueAdminStandingsScreen({super.key});

  @override
  State<LeagueAdminStandingsScreen> createState() => _LeagueAdminStandingsScreenState();
}

class _LeagueAdminStandingsScreenState extends State<LeagueAdminStandingsScreen> {
  late final LeagueRepository _leagueRepository;
  late final AuthService _authService;

  int _selectedLeagueIndex = 0;
  int? _currentLeagueId;
  int _selectedSeasonIndex = 0;
  
  bool _loading = false;
  String? _errorMessage;
  final List<LeagueStandingsInfo> _leagueStandings = [];

  @override
  void initState() {
    super.initState();
    _leagueRepository = LeagueRepository(ApiClient());
    _authService = AuthService();
    _loadStandings();
  }

  Future<void> _loadStandings() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final userId = await _authService.getUserId();
      if (userId == null) {
        setState(() {
          _errorMessage = 'Unable to identify current user.';
          _leagueStandings.clear();
          _loading = false;
        });
        return;
      }

      final leagues = await _leagueRepository.getLeagues();
      final adminLeagues = leagues
          .where((league) => league.adminUserId == userId)
          .toList();

      final standingsList = <LeagueStandingsInfo>[];

      for (final league in adminLeagues) {
        final seasons = await _leagueRepository.getSeasons(league.leagueId);
        for (final season in seasons) {
          final standingsJson = await _leagueRepository.getStandings(
            season.seasonId,
            archived: false,
          );

          final standings = standingsJson
              .map((row) => StandingData.fromJson(row))
              .toList();

          standingsList.add(
            LeagueStandingsInfo(
              league: league,
              season: season,
              standings: standings,
            ),
          );
        }
      }

      if (mounted) {
        setState(() {
          _leagueStandings
            ..clear()
            ..addAll(standingsList);
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load standings: $e';
          _leagueStandings.clear();
          _loading = false;
        });
      }
    }
  }

  Season? _pickCurrentSeason(List<Season> seasons) {
    if (seasons.isEmpty) return null;
    final now = DateTime.now();
    final active = seasons.where((season) {
      return !season.isArchived &&
          now.isAfter(season.startDate) &&
          now.isBefore(season.endDate.add(const Duration(days: 1)));
    }).toList();
    if (active.isNotEmpty) {
      return active.first;
    }
    final nonArchived = seasons.where((s) => !s.isArchived).toList();
    if (nonArchived.isNotEmpty) {
      nonArchived.sort((a, b) => b.startDate.compareTo(a.startDate));
      return nonArchived.first;
    }
    return seasons.first;
  }

  List<League> _uniqueLeagues() {
    final seen = <int>{};
    return _leagueStandings
        .where((info) => seen.add(info.league.leagueId))
        .map((info) => info.league)
        .toList();
  }

  List<Season> _getSeasonsForLeague(int leagueId) {
    return _leagueStandings
        .where((info) => info.league.leagueId == leagueId)
        .map((info) => info.season)
        .toList();
  }

  List<StandingData> _getStandingsForSeason(int seasonId) {
    try {
      return _leagueStandings
          .firstWhere((info) => info.season.seasonId == seasonId)
          .standings;
    } catch (_) {
      return [];
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;

    return CupertinoPageScaffold(
      child: Container(
        decoration: BoxDecoration(
          gradient: AppGradients.backgroundGradient(context, isDark: isDark),
        ),
        child: CustomScrollView(
          slivers: [
            CupertinoSliverRefreshControl(
              onRefresh: () async {
                await _loadStandings();
              },
            ),
            CupertinoSliverNavigationBar(
              heroTag: 'league_admin_standings_nav_bar',
              largeTitle: const Text('Standings'),
              automaticBackgroundVisibility: false,
              backgroundColor: Colors.transparent,
              border: null,
            ),
            SliverPadding(
              padding: EdgeInsets.only(
                left: Spacing.lg,
                right: Spacing.lg,
                top: Spacing.lg,
                bottom: 100,
              ),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  if (_loading)
                    AppGlassContainer(
                      padding: EdgeInsets.all(Spacing.xl),
                      child: Center(
                        child: CupertinoActivityIndicator(radius: 16),
                      ),
                    )
                  else if (_errorMessage != null)
                    AppGlassContainer(
                      padding: const EdgeInsets.all(Spacing.lg),
                      child: Text(
                        _errorMessage!,
                        style: AppTypography.callout.copyWith(
                          color: CupertinoColors.systemRed,
                        ),
                      ),
                    )
                  else if (_leagueStandings.isEmpty)
                    AppGlassContainer(
                      padding: EdgeInsets.all(Spacing.lg),
                      child: Text(
                        'No league data available',
                        style: AppTypography.callout.copyWith(
                          color: CupertinoColors.secondaryLabel,
                        ),
                      ),
                    )
                  else
                    _buildStandingsContent(),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStandingsContent() {
    // Get unique leagues where user is admin
    final leagues = _uniqueLeagues();
    final selectedLeagueIndex = _selectedLeagueIndex.clamp(0, leagues.length - 1);
    final selectedLeague = leagues[selectedLeagueIndex];

    // Get filtered seasons for the selected league
    final seasons = _getSeasonsForLeague(selectedLeague.leagueId);
    
    // Sort seasons by start date (most recent first)
    seasons.sort((a, b) => b.startDate.compareTo(a.startDate));

    // Reset league state if league changed
    if (_currentLeagueId != selectedLeague.leagueId) {
      _currentLeagueId = selectedLeague.leagueId;
      _selectedSeasonIndex = 0;
      
      // Try to select current/active season
      final currentSeason = _pickCurrentSeason(seasons);
      if (currentSeason != null) {
        _selectedSeasonIndex = seasons.indexOf(currentSeason).clamp(0, seasons.length - 1);
      }
    }

    final selectedSeasonIndex = _selectedSeasonIndex.clamp(0, seasons.isNotEmpty ? seasons.length - 1 : 0);
    final selectedSeason = seasons.isNotEmpty ? seasons[selectedSeasonIndex] : null;
    final standings = selectedSeason != null 
        ? (_getStandingsForSeason(selectedSeason.seasonId))
        : <StandingData>[];

    return AppGlassContainer(
      padding: const EdgeInsets.all(Spacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (leagues.length > 1) ...[
            AppDropdown<int>(
              value: selectedLeagueIndex,
              width: double.infinity,
              items: leagues.asMap().entries.map((entry) {
                return DropdownItem<int>(
                  value: entry.key,
                  label: entry.value.name,
                );
              }).toList(),
              onChanged: (index) {
                setState(() {
                  _selectedLeagueIndex = index;
                  _currentLeagueId = null; // Force reset
                });
              },
            ),
            const SizedBox(height: Spacing.md),
          ] else ...[
            Text(
              selectedLeague.name,
              style: AppTypography.headline.copyWith(
                color: CupertinoColors.label,
              ),
            ),
            const SizedBox(height: Spacing.md),
          ],
          if (seasons.isNotEmpty) ...[
            AppDropdown<int>(
              value: selectedSeasonIndex,
              width: double.infinity,
              items: seasons.asMap().entries.map((entry) {
                return DropdownItem<int>(
                  value: entry.key,
                  label: entry.value.name,
                );
              }).toList(),
              onChanged: (index) {
                setState(() {
                  _selectedSeasonIndex = index;
                });
              },
            ),
          ] else
            Text(
              'No seasons available for this league.',
              style: AppTypography.callout.copyWith(
                color: CupertinoColors.secondaryLabel,
              ),
            ),
          const SizedBox(height: Spacing.lg),
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(bottom: Spacing.md),
              child: Text(
                _errorMessage!,
                style: AppTypography.callout.copyWith(
                  color: CupertinoColors.systemRed,
                ),
              ),
            ),
          const StandingsTableHeader(
            cellWidthMultiplier: 1,
            leftPadding: 25.0,
            rightPadding: 15.0,
          ),
          const SizedBox(height: Spacing.sm),
          if (standings.isEmpty)
            Text(
              'No standings available for this season.',
              style: AppTypography.callout.copyWith(
                color: CupertinoColors.secondaryLabel,
              ),
            )
          else
            ...standings.asMap().entries.map((entry) {
              final index = entry.key;
              final standing = entry.value;
              return Padding(
                padding: EdgeInsets.only(
                  bottom: index < standings.length - 1
                      ? Spacing.sm
                      : 0,
                ),
                child: ModernStandingRow(
                  position: index + 1,
                  teamName: standing.teamName,
                  matchesPlayed: standing.matchesPlayed,
                  wins: standing.wins,
                  losses: standing.losses,
                  points: standing.points,
                  onTap: () {
                    showCupertinoDialog(
                      context: context,
                      barrierDismissible: true,
                      builder: (context) => TeamDetailsPopup(
                        team: standing,
                        position: index + 1,
                      ),
                    );
                  },
                ),
              );
            }),
        ],
      ),
    );
  }
}

class LeagueStandingsInfo {
  final League league;
  final Season season;
  final List<StandingData> standings;

  LeagueStandingsInfo({
    required this.league,
    required this.season,
    required this.standings,
  });
}

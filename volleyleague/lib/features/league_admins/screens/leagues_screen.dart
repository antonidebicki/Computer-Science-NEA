import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../../../design/index.dart';
import '../../../state/providers/theme_provider.dart';
import '../../../services/api_client.dart';
import '../../../services/repositories/league_repository.dart';
import '../../../services/auth_service.dart';
import '../../../core/models/league.dart';
import '../../../core/models/season.dart';
import '../../../state/cubits/player/player_data_state.dart';
import '../../widgets/standings_table_header.dart';
import '../../widgets/modern_standing_row.dart';
import '../widgets/league_admin_leagues_header_card.dart';
import '../widgets/new_league.dart';
import 'league_settings_screen.dart';
import '../widgets/app_bar_row.dart';

class LeagueAdminLeaguesScreen extends StatefulWidget {
  const LeagueAdminLeaguesScreen({super.key});

  @override
  State<LeagueAdminLeaguesScreen> createState() =>
      _LeagueAdminLeaguesScreenState();
}

class _LeagueAdminLeaguesScreenState extends State<LeagueAdminLeaguesScreen> {
  late LeagueRepository _leagueRepository;
  late AuthService _authService;
  String? _errorMessage;
  List<League> _leagues = [];
  bool _isLoadingLeagues = false;
  
  // Standings
  int _selectedLeagueIndex = 0;
  int? _currentLeagueId;
  int _selectedSeasonIndex = 0;
  bool _loadingStandings = false;
  String? _standingsErrorMessage;
  final List<LeagueStandingsInfo> _leagueStandings = [];
  
  // Tab state
  int _selectedTabIndex = 0;

  void _setStateIfMounted(VoidCallback fn) {
    if (!mounted) return;
    setState(fn);
  }

  @override
  void initState() {
    super.initState();
    _leagueRepository = LeagueRepository(ApiClient());
    _authService = AuthService();
    _loadLeagues();
    _loadStandings();
  }

  Future<void> _loadLeagues() async {
    _setStateIfMounted(() {
      _isLoadingLeagues = true;
      _errorMessage = null;
    });
    try {
      final userId = await _authService.getUserId();
      if (userId == null) {
        _setStateIfMounted(() {
          _errorMessage = 'Unable to identify current user.';
          _leagues = [];
          _isLoadingLeagues = false;
        });
        return;
      }

      final leagues = await _leagueRepository.getLeagues();
      final adminLeagues = leagues
          .where((league) => league.adminUserId == userId)
          .toList();
      _setStateIfMounted(() {
        _leagues = adminLeagues;
      });
    } catch (e) {
      _setStateIfMounted(() => _errorMessage = 'Failed to load leagues: $e');
    } finally {
      _setStateIfMounted(() => _isLoadingLeagues = false);
    }
  }

  Future<void> _loadStandings() async {
    _setStateIfMounted(() {
      _loadingStandings = true;
      _standingsErrorMessage = null;
    });

    try {
      final userId = await _authService.getUserId();
      if (userId == null) {
        _setStateIfMounted(() {
          _standingsErrorMessage = 'Unable to identify current user.';
          _leagueStandings.clear();
          _loadingStandings = false;
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
        _setStateIfMounted(() {
          _leagueStandings
            ..clear()
            ..addAll(standingsList);
          _loadingStandings = false;
        });
      }
    } catch (e) {
      if (mounted) {
        _setStateIfMounted(() {
          _standingsErrorMessage = 'Failed to load standings: $e';
          _leagueStandings.clear();
          _loadingStandings = false;
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
            CupertinoSliverNavigationBar(
              heroTag: 'league_admin_leagues_nav_bar',
              largeTitle: const Text('My Leagues'),
              automaticBackgroundVisibility: false,
              backgroundColor: CupertinoColors.transparent,
              border: null,
              trailing: CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () {
                  _loadLeagues();
                },
                child: const Icon(CupertinoIcons.refresh),
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(56),
                child: Column(
                  children: [
                    AppBarRow(
                      selectedIndex: _selectedTabIndex,
                      items: const ['Leagues', 'Standings'],
                      onChanged: (index) {
                        setState(() => _selectedTabIndex = index);
                      },
                    ),
                    SizedBox(height: Spacing.sm,),
                    Container(
                      height: 1,
                      color: CupertinoColors.separator.withOpacity(0.1),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(
                horizontal: Spacing.lg,
                vertical: Spacing.lg,
              ),
              sliver: SliverList(
                delegate: SliverChildListDelegate(
                  _selectedTabIndex == 0
                      ? _buildLeaguesContent(context)
                      : _buildStandingsContent(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildLeaguesContent(BuildContext context) {
    return [
      LeaguesHeaderCard(
        leaguesContent: _buildLeagueButtons(context),
      ),
      const SizedBox(height: Spacing.lg),
      if (_errorMessage != null)
        Container(
          padding: const EdgeInsets.all(Spacing.md),
          margin: const EdgeInsets.only(bottom: Spacing.lg),
          decoration: BoxDecoration(
            color: CupertinoColors.systemRed.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: CupertinoColors.systemRed.withOpacity(0.3),
            ),
          ),
          child: Text(
            _errorMessage!,
            style: AppTypography.callout.copyWith(
              color: CupertinoColors.systemRed,
            ),
          ),
        ),
      NewLeague(
        onLeagueCreated: (league) async {
          _setStateIfMounted(() {
            _leagues = [..._leagues, league];
          });
        },
      ),
      const SizedBox(height: Spacing.xxxl * 3),
    ];
  }

  List<Widget> _buildStandingsContent(BuildContext context) {
    if (_loadingStandings) {
      return [
        AppGlassContainer(
          padding: EdgeInsets.all(Spacing.xl),
          child: Center(
            child: CupertinoActivityIndicator(radius: 16),
          ),
        ),
      ];
    }

    if (_standingsErrorMessage != null) {
      return [
        AppGlassContainer(
          padding: const EdgeInsets.all(Spacing.lg),
          child: Text(
            _standingsErrorMessage!,
            style: AppTypography.callout.copyWith(
              color: CupertinoColors.systemRed,
            ),
          ),
        ),
      ];
    }

    if (_leagueStandings.isEmpty) {
      return [
        AppGlassContainer(
          padding: EdgeInsets.all(Spacing.lg),
          child: Text(
            'No league data available',
            style: AppTypography.callout.copyWith(
              color: CupertinoColors.secondaryLabel,
            ),
          ),
        ),
      ];
    }

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

    return [
      AppGlassContainer(
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
                      // the dialog is broken only for this screen, so i removed it
                    },
                  ),
                );
              }),
          ],
        ),
      ),
      const SizedBox(height: Spacing.xxxl * 3),
    ];
  }

  Widget _buildLeagueButtons(BuildContext context) {
    if (_isLoadingLeagues) {
      return const Center(child: CupertinoActivityIndicator());
    }

    if (_leagues.isEmpty) {
      return Text(
        'No leagues available yet. Create your first league below.',
        style: AppTypography.callout.copyWith(
          color: CupertinoColors.secondaryLabel,
        ),
      );
    }

    return Column(
      children: _leagues.map((league) {
        return Padding(
          padding: const EdgeInsets.only(bottom: Spacing.sm),
          child: AppGlassContainer(
            padding: const EdgeInsets.symmetric(
              horizontal: Spacing.md,
              vertical: Spacing.sm,
            ),
            borderRadius: 12,
            child: CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () {
                Navigator.of(context).push(
                  CupertinoPageRoute(
                    builder: (_) =>
                        LeagueAdminLeagueSettingsScreen(league: league),
                  ),
                );
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      league.name,
                      style: AppTypography.body.copyWith(
                        color: CupertinoColors.label,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Icon(
                    CupertinoIcons.chevron_forward,
                    color: CupertinoColors.activeBlue,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

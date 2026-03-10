import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/models/league.dart';
import '../../../core/models/match.dart';
import '../../../core/models/match_data.dart';
import '../../../core/models/season.dart';
import '../../../core/models/enums.dart';
import '../../../design/index.dart';
import '../../../design/widgets/toggle.dart';
import '../../../services/api_client.dart';
import '../../../services/auth_service.dart';
import '../../../services/repositories/league_repository.dart';
import '../../../services/repositories/match_repository.dart';
import '../../../state/providers/theme_provider.dart';
import '../../../state/cubits/player/player_data_cubit.dart';
import '../../../state/cubits/player/player_data_state.dart';
import '../../../state/cubits/coach/team_data_cubit.dart';
import '../../../state/cubits/coach/team_data_state.dart';
import '../../widgets/fixtures_widget.dart';
import '../widgets/fixture_details_popup.dart';
import '../../league_admins/screens/match_score_entry_screen.dart';

enum FixturesUserRole { leagueAdmin, coach, player }

class UnifiedFixturesScreen extends StatefulWidget {
  final FixturesUserRole userRole;
  final bool isActive;

  const UnifiedFixturesScreen({
    super.key,
    required this.userRole,
    this.isActive = false,
  });

  @override
  State<UnifiedFixturesScreen> createState() => _UnifiedFixturesScreenState();
}

class _UnifiedFixturesScreenState extends State<UnifiedFixturesScreen> {
  late final ApiClient _apiClient;
  late final LeagueRepository _leagueRepository;
  late final MatchRepository _matchRepository;
  late final AuthService _authService;

  bool _showPastFixtures = false;
  bool _loadingLeagues = false;
  bool _loadingSeasons = false;
  bool _loadingFixtures = false;

  List<League> _leagues = [];
  List<Season> _seasons = [];
  List<MatchData> _fixtures = [];

  int _selectedLeagueIndex = 0;
  int _selectedSeasonIndex = 0;

  String? _errorMessage;
  int? _userTeamId;

  @override
  void initState() {
    super.initState();
    _apiClient = ApiClient();
    _leagueRepository = LeagueRepository(_apiClient);
    _matchRepository = MatchRepository(_apiClient);
    _authService = AuthService();
    _loadData();
  }

  @override
  void didUpdateWidget(covariant UnifiedFixturesScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _loadData();
    }
  }

  void _setStateIfMounted(VoidCallback fn) {
    if (!mounted) return;
    setState(fn);
  }

  Future<void> _loadData() async {
    if (widget.userRole == FixturesUserRole.player) {
      _loadLeaguesForPlayer();
      return;
    } else if (widget.userRole == FixturesUserRole.coach) {
      _loadLeaguesForCoach();
      return;
    } else {
      await _loadLeaguesForAdmin();
    }
  }

  void _loadLeaguesForPlayer() {
    final playerState = context.read<PlayerDataCubit>().state;
    if (playerState is! PlayerDataLoaded) {
      _setStateIfMounted(() {
        _leagues = [];
        _seasons = [];
        _fixtures = [];
        _userTeamId = null;
      });
      return;
    }

    final leagues = playerState.uniqueLeagues;
    _setStateIfMounted(() {
      _leagues = leagues;
      _selectedLeagueIndex = 0;
      _selectedSeasonIndex = 0;
      _seasons = [];
      _fixtures = [];
    });

    if (leagues.isNotEmpty) {
      _loadSeasonsForLeague(leagues.first.leagueId);
    }
  }

  void _loadLeaguesForCoach() {
    final coachState = context.read<TeamDataCubit>().state;
    if (coachState is! TeamDataLoaded) {
      _setStateIfMounted(() {
        _leagues = [];
        _seasons = [];
        _fixtures = [];
      });
      return;
    }

    final leagues = coachState.uniqueLeagues;
    _setStateIfMounted(() {
      _leagues = leagues;
      _selectedLeagueIndex = 0;
      _selectedSeasonIndex = 0;
      _seasons = [];
      _fixtures = [];
    });

    if (leagues.isNotEmpty) {
      _loadSeasonsForLeague(leagues.first.leagueId);
    }

    // Set user team ID for fixture filtering
    if (coachState.coachTeam != null) {
      _userTeamId = coachState.coachTeam!.teamId;
    }
  }

  Future<void> _refreshCurrent() async {
    if (_leagues.isEmpty) {
      await _loadData();
      return;
    }

    final leagueIndex = _selectedLeagueIndex.clamp(0, _leagues.length - 1);
    await _loadSeasonsForLeague(_leagues[leagueIndex].leagueId);
  }

  Future<void> _loadLeaguesForAdmin() async {
    _setStateIfMounted(() {
      _loadingLeagues = true;
      _errorMessage = null;
    });

    try {
      final currentUserId = await _authService.getUserId();
      if (currentUserId == null) {
        _setStateIfMounted(() {
          _leagues = [];
          _seasons = [];
          _fixtures = [];
          _errorMessage = 'Unable to identify current user.';
        });
        return;
      }

      final leagues = await _leagueRepository.getLeagues();
      final adminLeagues = leagues
          .where((league) => league.adminUserId == currentUserId)
          .toList();

      _setStateIfMounted(() {
        _leagues = adminLeagues;
        _selectedLeagueIndex = 0;
        _selectedSeasonIndex = 0;
        _seasons = [];
        _fixtures = [];
      });

      if (adminLeagues.isNotEmpty) {
        await _loadSeasonsForLeague(adminLeagues.first.leagueId);
      }
    } catch (e) {
      _setStateIfMounted(() {
        _errorMessage = 'Failed to load leagues: $e';
      });
    } finally {
      _setStateIfMounted(() {
        _loadingLeagues = false;
      });
    }
  }

  Future<void> _loadSeasonsForLeague(int leagueId) async {
    _setStateIfMounted(() {
      _loadingSeasons = true;
      _errorMessage = null;
      _seasons = [];
      _selectedSeasonIndex = 0;
      _fixtures = [];
    });

    try {
      List<Season> availableSeasons;

      // For players and coaches, get seasons from cubit
      if (widget.userRole == FixturesUserRole.player) {
        final playerState = context.read<PlayerDataCubit>().state;
        if (playerState is PlayerDataLoaded) {
          availableSeasons = playerState.getSeasonsForLeague(leagueId);
        } else {
          availableSeasons = [];
        }
      } else if (widget.userRole == FixturesUserRole.coach) {
        final coachState = context.read<TeamDataCubit>().state;
        if (coachState is TeamDataLoaded) {
          availableSeasons = coachState.getSeasonsForLeague(leagueId);
        } else {
          availableSeasons = [];
        }
      } else {
        // For league admins, fetch from repository
        final seasons = await _leagueRepository.getSeasons(leagueId);
        availableSeasons = seasons.where((season) {
          return !season.isArchived;
        }).toList()..sort((a, b) => b.startDate.compareTo(a.startDate));
      }

      _setStateIfMounted(() {
        _seasons = availableSeasons;
      });

      final selectedSeason = _pickCurrentSeason(availableSeasons);
      if (selectedSeason != null) {
        final seasonIndex = availableSeasons
            .indexOf(selectedSeason)
            .clamp(0, availableSeasons.length - 1);
        _setStateIfMounted(() {
          _selectedSeasonIndex = seasonIndex;
        });
        await _loadFixturesForSeason(selectedSeason.seasonId);
      } else {
        _setStateIfMounted(() {
          _fixtures = [];
        });
      }
    } catch (e) {
      _setStateIfMounted(() {
        _errorMessage = 'Failed to load seasons: $e';
      });
    } finally {
      _setStateIfMounted(() {
        _loadingSeasons = false;
      });
    }
  }

  Future<void> _loadFixturesForSeason(int seasonId) async {
    // Extract player team IDs before any async calls to avoid context issues
    List<int> playerTeamIds = [];
    if (widget.userRole == FixturesUserRole.player) {
      final playerState = context.read<PlayerDataCubit>().state;
      if (playerState is PlayerDataLoaded) {
        // Use the actual player's team IDs, not all teams in the season
        playerTeamIds = playerState.playerTeamIds;
        debugPrint('Player teams for season $seasonId: $playerTeamIds');
      }
    } else if (widget.userRole == FixturesUserRole.coach &&
        _userTeamId != null) {
      playerTeamIds = [_userTeamId!];
    }

    _setStateIfMounted(() {
      _loadingFixtures = true;
      _errorMessage = null;
    });

    try {
      final seasonTeams = await _leagueRepository.getSeasonTeams(seasonId);
      final teamNames = <int, String>{};
      for (final teamJson in seasonTeams) {
        final rawTeamId = teamJson['team_id'] ?? teamJson['id'];
        final teamId = rawTeamId is int
            ? rawTeamId
            : int.tryParse(rawTeamId?.toString() ?? '');

        if (teamId == null) {
          continue;
        }

        final teamName = _extractTeamName(teamJson, fallbackId: teamId);
        teamNames[teamId] = teamName;
      }

      List<MatchData> fixtures;
      try {
        List<Match> matches;
        if (_userTeamId != null) {
          matches = await _matchRepository.getMatches(
            seasonId: seasonId,
            teamId: _userTeamId,
          );
        } else {
          matches = await _matchRepository.getMatches(seasonId: seasonId);
        }

        // Filter matches to only include teams from the standings
        if (playerTeamIds.isNotEmpty) {
          matches = matches
              .where(
                (match) =>
                    playerTeamIds.contains(match.homeTeamId) ||
                    playerTeamIds.contains(match.awayTeamId),
              )
              .toList();
          debugPrint('Filtered to ${matches.length} matches for player teams');
        }

        fixtures = matches
            .map(
              (match) => MatchData(
                match: match,
                homeTeamName:
                    teamNames[match.homeTeamId] ?? 'Team ${match.homeTeamId}',
                awayTeamName:
                    teamNames[match.awayTeamId] ?? 'Team ${match.awayTeamId}',
              ),
            )
            .toList();
      } catch (_) {
        final rawData = await _apiClient.get(
          '/api/matches?season_id=$seasonId',
        );
        fixtures = _parseFixturesFromRaw(rawData, seasonId, teamNames);

        // Filter fixtures to only include teams from the standings
        if (playerTeamIds.isNotEmpty) {
          fixtures = fixtures
              .where(
                (match) =>
                    playerTeamIds.contains(match.match.homeTeamId) ||
                    playerTeamIds.contains(match.match.awayTeamId),
              )
              .toList();
        }
      }

      _setStateIfMounted(() {
        _fixtures = fixtures;
      });
    } catch (e) {
      debugPrint('Error loading fixtures for season $seasonId: $e');
      _setStateIfMounted(() {
        _errorMessage = 'Failed to load fixtures: $e';
        _fixtures = [];
      });
    } finally {
      _setStateIfMounted(() {
        _loadingFixtures = false;
      });
    }
  }

  String _extractTeamName(
    Map<String, dynamic> teamJson, {
    required int fallbackId,
  }) {
    final candidates = <dynamic>[
      teamJson['name'],
      teamJson['team_name'],
      teamJson['display_name'],
      teamJson['title'],
    ];

    for (final candidate in candidates) {
      if (candidate is String && candidate.trim().isNotEmpty) {
        return candidate;
      }
    }

    return 'Team $fallbackId';
  }

  List<MatchData> _parseFixturesFromRaw(
    dynamic rawData,
    int seasonId,
    Map<int, String> teamNames,
  ) {
    if (rawData is! List) {
      return [];
    }

    final fixtures = <MatchData>[];

    for (var index = 0; index < rawData.length; index++) {
      final item = rawData[index];
      if (item is! Map) {
        continue;
      }

      final map = Map<String, dynamic>.from(item);
      final homeTeamId = _toInt(map['home_team_id']);
      final awayTeamId = _toInt(map['away_team_id']);

      if (homeTeamId == null || awayTeamId == null) {
        continue;
      }

      final match = Match(
        matchId: _toInt(map['match_id']) ?? -(index + 1),
        seasonId: _toInt(map['season_id']) ?? seasonId,
        homeTeamId: homeTeamId,
        awayTeamId: awayTeamId,
        matchDatetime: _toDateTime(map['match_datetime']),
        venue: _toNullableString(map['venue']),
        status: _toGameState(map['status']),
        winnerTeamId: _toInt(map['winner_team_id']),
        homeSetsWon: _toInt(map['home_sets_won']) ?? 0,
        awaySetsWon: _toInt(map['away_sets_won']) ?? 0,
      );

      fixtures.add(
        MatchData(
          match: match,
          homeTeamName: teamNames[homeTeamId] ?? 'Team $homeTeamId',
          awayTeamName: teamNames[awayTeamId] ?? 'Team $awayTeamId',
        ),
      );
    }

    return fixtures;
  }

  int? _toInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return int.tryParse(value?.toString() ?? '');
  }

  DateTime? _toDateTime(dynamic value) {
    if (value is DateTime) return value;
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }

  String? _toNullableString(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  GameState _toGameState(dynamic value) {
    if (value is String && value.trim().isNotEmpty) {
      return GameState.fromString(value);
    }
    return GameState.scheduled;
  }

  Season? _pickCurrentSeason(List<Season> seasons) {
    if (seasons.isEmpty) return null;
    final now = DateTime.now();

    final active = seasons.where((season) {
      return _isActiveSeason(season, now);
    }).toList();

    if (active.isNotEmpty) {
      return active.first;
    }

    final nonArchived = seasons.where((season) => !season.isArchived).toList();
    if (nonArchived.isNotEmpty) {
      nonArchived.sort((a, b) => b.startDate.compareTo(a.startDate));
      return nonArchived.first;
    }

    return seasons.first;
  }

  bool _isActiveSeason(Season season, DateTime now) {
    if (season.isArchived) return false;
    return !now.isBefore(season.startDate) &&
        !now.isAfter(season.endDate.add(const Duration(days: 1)));
  }

  Future<void> _openFixtureDetails(MatchData fixture) async {
    if (widget.userRole == FixturesUserRole.leagueAdmin) {
      final result = await Navigator.of(context).push(
        CupertinoPageRoute(
          builder: (_) => LeagueAdminMatchScoreEntryScreen(fixture: fixture),
        ),
      );
      if (!mounted) return;
      if (result == true) {
        await _refreshCurrent();
      }
      return;
    }

    await showCupertinoDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => FixtureDetailsPopup(fixture: fixture),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Listen for player data changes and auto-reload when data becomes available
    if (widget.userRole == FixturesUserRole.player) {
      return BlocListener<PlayerDataCubit, PlayerDataState>(
        listener: (context, state) {
          if (state is PlayerDataLoaded && _leagues.isEmpty) {
            _loadLeaguesForPlayer();
          }
        },
        child: _buildFixturesContent(context),
      );
    } else if (widget.userRole == FixturesUserRole.coach) {
      return BlocListener<TeamDataCubit, TeamDataState>(
        listener: (context, state) {
          if (state is TeamDataLoaded && _leagues.isEmpty) {
            _loadLeaguesForCoach();
          }
        },
        child: _buildFixturesContent(context),
      );
    } else {
      return _buildFixturesContent(context);
    }
  }

  Widget _buildFixturesContent(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;

    final now = DateTime.now();
    final futureFixtures = _fixtures
        .where(
          (fixture) =>
              fixture.match.matchDatetime != null &&
              fixture.match.matchDatetime!.isAfter(now),
        )
        .toList();
    final pastFixtures = _fixtures
        .where(
          (fixture) =>
              fixture.match.matchDatetime != null &&
              fixture.match.matchDatetime!.isBefore(now),
        )
        .toList();

    futureFixtures.sort((a, b) {
      if (a.match.matchDatetime == null || b.match.matchDatetime == null) {
        return 0;
      }
      return a.match.matchDatetime!.compareTo(b.match.matchDatetime!);
    });

    pastFixtures.sort((a, b) {
      if (a.match.matchDatetime == null || b.match.matchDatetime == null) {
        return 0;
      }
      return b.match.matchDatetime!.compareTo(a.match.matchDatetime!);
    });

    final displayedFixtures = _showPastFixtures ? pastFixtures : futureFixtures;

    return CupertinoPageScaffold(
      child: Container(
        decoration: BoxDecoration(
          gradient: AppGradients.backgroundGradient(context, isDark: isDark),
        ),
        child: CustomScrollView(
          slivers: [
            CupertinoSliverRefreshControl(onRefresh: _refreshCurrent),
            CupertinoSliverNavigationBar(
              heroTag: 'fixtures_nav_bar',
              largeTitle: const Text('Fixtures'),
              automaticBackgroundVisibility: false,
              backgroundColor: CupertinoColors.transparent,
              border: null,
              trailing: CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: _refreshCurrent,
                child: const Icon(CupertinoIcons.refresh),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.only(
                left: Spacing.lg,
                right: Spacing.lg,
                top: Spacing.lg,
                bottom: 100,
              ),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_loadingLeagues)
                        const Center(child: CupertinoActivityIndicator())
                      else if (_leagues.isEmpty)
                        Text(
                          widget.userRole == FixturesUserRole.leagueAdmin
                              ? 'No leagues available for your admin account.'
                              : widget.userRole == FixturesUserRole.coach
                              ? 'Your team is not registered in any leagues.'
                              : 'You are not registered in any leagues.',
                          style: AppTypography.callout.copyWith(
                            color: CupertinoColors.secondaryLabel,
                          ),
                        )
                      else ...[
                        if (_leagues.length > 1) ...[
                          AppDropdown<int>(
                            value: _selectedLeagueIndex.clamp(
                              0,
                              _leagues.length - 1,
                            ),
                            width: double.infinity,
                            items: _leagues.asMap().entries.map((entry) {
                              return DropdownItem<int>(
                                value: entry.key,
                                label: entry.value.name,
                              );
                            }).toList(),
                            onChanged: (index) {
                              setState(() {
                                _selectedLeagueIndex = index;
                              });
                              _loadSeasonsForLeague(_leagues[index].leagueId);
                            },
                          ),
                          const SizedBox(height: Spacing.md),
                        ] else
                          Text(
                            _leagues.first.name,
                            style: AppTypography.headline.copyWith(
                              color: CupertinoColors.label,
                            ),
                          ),
                        if (_loadingSeasons)
                          const Padding(
                            padding: EdgeInsets.only(top: Spacing.md),
                            child: Center(child: CupertinoActivityIndicator()),
                          )
                        else if (_seasons.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: Spacing.md),
                            child: AppDropdown<int>(
                              value: _selectedSeasonIndex.clamp(
                                0,
                                _seasons.length - 1,
                              ),
                              width: double.infinity,
                              items: _seasons.asMap().entries.map((entry) {
                                return DropdownItem<int>(
                                  value: entry.key,
                                  label: entry.value.name,
                                );
                              }).toList(),
                              onChanged: (index) {
                                setState(() {
                                  _selectedSeasonIndex = index;
                                });
                                _loadFixturesForSeason(
                                  _seasons[index].seasonId,
                                );
                              },
                            ),
                          )
                        else
                          Padding(
                            padding: const EdgeInsets.only(top: Spacing.md),
                            child: Text(
                              'No seasons available for this league.',
                              style: AppTypography.callout.copyWith(
                                color: CupertinoColors.secondaryLabel,
                              ),
                            ),
                          ),
                        const SizedBox(height: Spacing.lg),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(50),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x1F000000),
                                blurRadius: 8,
                                spreadRadius: 0,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: LiquidGlassToggle(
                            value: _showPastFixtures,
                            onChanged: (value) {
                              setState(() {
                                _showPastFixtures = value;
                              });
                            },
                            activeLabel: 'Past (${pastFixtures.length})',
                            inactiveLabel:
                                'Upcoming (${futureFixtures.length})',
                          ),
                        ),
                        const SizedBox(height: Spacing.lg),
                        if (_loadingFixtures)
                          const Center(child: CupertinoActivityIndicator())
                        else
                          FixturesWidget(
                            fixtures: displayedFixtures,
                            onFixtureTap: _openFixtureDetails,
                            isAdminView:
                                widget.userRole == FixturesUserRole.leagueAdmin,
                          ),
                      ],
                      if (_errorMessage != null) ...[
                        const SizedBox(height: Spacing.md),
                        Text(
                          _errorMessage!,
                          style: AppTypography.callout.copyWith(
                            color: CupertinoColors.systemRed,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: Spacing.xxxl),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

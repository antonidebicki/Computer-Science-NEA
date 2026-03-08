import 'package:flutter/cupertino.dart';
import '../../../core/models/league.dart';
import '../../../core/models/match_data.dart';
import '../../../core/models/season.dart';
import 'package:provider/provider.dart';
import '../../../design/index.dart';
import '../../../design/widgets/toggle.dart';
import '../../../services/api_client.dart';
import '../../../services/auth_service.dart';
import '../../../services/repositories/league_repository.dart';
import '../../../services/repositories/match_repository.dart';
import '../../../state/providers/theme_provider.dart';
import '../../widgets/fixtures_widget.dart';

class LeagueAdminFixturesScreen extends StatefulWidget {
  const LeagueAdminFixturesScreen({super.key});

  @override
  State<LeagueAdminFixturesScreen> createState() =>
      _LeagueAdminFixturesScreenState();
}

class _LeagueAdminFixturesScreenState extends State<LeagueAdminFixturesScreen> {
  late final LeagueRepository _leagueRepository;
  late final MatchRepository _matchRepository;
  late final AuthService _authService;

  bool _showPastFixtures = false;
  bool _loadingLeagues = false;
  bool _loadingSeasons = false;
  bool _loadingFixtures = false;

  List<League> _adminLeagues = [];
  List<Season> _seasons = [];
  List<MatchData> _fixtures = [];

  int _selectedLeagueIndex = 0;
  int _selectedSeasonIndex = 0;

  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final apiClient = ApiClient();
    _leagueRepository = LeagueRepository(apiClient);
    _matchRepository = MatchRepository(apiClient);
    _authService = AuthService();
    _loadAdminLeagues();
  }

  Future<void> _refreshCurrent() async {
    if (_adminLeagues.isEmpty) {
      await _loadAdminLeagues();
      return;
    }

    final leagueIndex = _selectedLeagueIndex.clamp(0, _adminLeagues.length - 1);
    await _loadSeasonsForLeague(_adminLeagues[leagueIndex].leagueId);
  }

  Future<void> _loadAdminLeagues() async {
    setState(() {
      _loadingLeagues = true;
      _errorMessage = null;
    });

    try {
      final currentUserId = await _authService.getUserId();
      if (currentUserId == null) {
        setState(() {
          _adminLeagues = [];
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

      setState(() {
        _adminLeagues = adminLeagues;
        _selectedLeagueIndex = 0;
        _selectedSeasonIndex = 0;
        _seasons = [];
        _fixtures = [];
      });

      if (adminLeagues.isNotEmpty) {
        await _loadSeasonsForLeague(adminLeagues.first.leagueId);
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load leagues: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _loadingLeagues = false;
        });
      }
    }
  }

  Future<void> _loadSeasonsForLeague(int leagueId) async {
    setState(() {
      _loadingSeasons = true;
      _errorMessage = null;
      _seasons = [];
      _selectedSeasonIndex = 0;
      _fixtures = [];
    });

    try {
      final seasons = await _leagueRepository.getSeasons(leagueId);
      seasons.sort((a, b) => b.startDate.compareTo(a.startDate));

      setState(() {
        _seasons = seasons;
      });

      final selectedSeason = _pickCurrentSeason(seasons);
      if (selectedSeason != null) {
        final seasonIndex = seasons
            .indexOf(selectedSeason)
            .clamp(0, seasons.length - 1);
        setState(() {
          _selectedSeasonIndex = seasonIndex;
        });
        await _loadFixturesForSeason(selectedSeason.seasonId);
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load seasons: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _loadingSeasons = false;
        });
      }
    }
  }

  Future<void> _loadFixturesForSeason(int seasonId) async {
    setState(() {
      _loadingFixtures = true;
      _errorMessage = null;
    });

    try {
      final seasonTeams = await _leagueRepository.getSeasonTeams(seasonId);
      final teamNames = <int, String>{
        for (final teamJson in seasonTeams)
          teamJson['team_id'] as int: teamJson['name'] as String,
      };

      final matches = await _matchRepository.getMatches(seasonId: seasonId);
      final fixtures = matches
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

      setState(() {
        _fixtures = fixtures;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load fixtures: $e';
        _fixtures = [];
      });
    } finally {
      if (mounted) {
        setState(() {
          _loadingFixtures = false;
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

    final nonArchived = seasons.where((season) => !season.isArchived).toList();
    if (nonArchived.isNotEmpty) {
      nonArchived.sort((a, b) => b.startDate.compareTo(a.startDate));
      return nonArchived.first;
    }

    return seasons.first;
  }

  @override
  Widget build(BuildContext context) {
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
              heroTag: 'league_admin_fixtures_nav_bar',
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
                        else if (_adminLeagues.isEmpty)
                          Text(
                            'No leagues available for your admin account.',
                            style: AppTypography.callout.copyWith(
                              color: CupertinoColors.secondaryLabel,
                            ),
                          )
                        else ...[
                          if (_adminLeagues.length > 1) ...[
                            AppDropdown<int>(
                              value: _selectedLeagueIndex.clamp(
                                0,
                                _adminLeagues.length - 1,
                              ),
                              width: double.infinity,
                              items: _adminLeagues.asMap().entries.map((entry) {
                                return DropdownItem<int>(
                                  value: entry.key,
                                  label: entry.value.name,
                                );
                              }).toList(),
                              onChanged: (index) {
                                setState(() {
                                  _selectedLeagueIndex = index;
                                });
                                _loadSeasonsForLeague(
                                  _adminLeagues[index].leagueId,
                                );
                              },
                            ),
                            const SizedBox(height: Spacing.md),
                          ] else
                            Text(
                              _adminLeagues.first.name,
                              style: AppTypography.headline.copyWith(
                                color: CupertinoColors.label,
                              ),
                            ),
                          if (_loadingSeasons)
                            const Padding(
                              padding: EdgeInsets.only(top: Spacing.md),
                              child: Center(
                                child: CupertinoActivityIndicator(),
                              ),
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
                            FixturesWidget(fixtures: displayedFixtures),
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

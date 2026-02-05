import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../design/index.dart';
import '../../../state/cubits/player/player_data_cubit.dart';
import '../../../state/cubits/player/player_data_state.dart';
import '../../../state/providers/theme_provider.dart';
import '../../../services/api_client.dart';
import '../../../services/repositories/league_repository.dart';
import '../../../core/models/season.dart';
import '../../widgets/standings_table_header.dart';
import '../../widgets/modern_standing_row.dart';

class StandingsScreen extends StatefulWidget {
  const StandingsScreen({super.key});

  @override
  State<StandingsScreen> createState() => _StandingsScreenState();
}

class _StandingsScreenState extends State<StandingsScreen> {
  late final LeagueRepository _leagueRepository;
  int _selectedLeagueIndex = 0;
  int? _currentLeagueId;
  bool _loadingSeasons = false;
  bool _loadingStandings = false;
  List<Season> _seasons = [];
  int _selectedSeasonIndex = 0;
  List<StandingData> _standings = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _leagueRepository = LeagueRepository(ApiClient());
  }

  Future<void> _loadSeasonsForLeague(int leagueId) async {
    setState(() {
      _loadingSeasons = true;
      _seasons = [];
      _selectedSeasonIndex = 0;
      _errorMessage = null;
    });

    try {
      final seasons = await _leagueRepository.getSeasons(leagueId);
      seasons.sort((a, b) => b.startDate.compareTo(a.startDate));
      setState(() {
        _seasons = seasons;
      });

      final selected = _pickCurrentSeason(seasons);
      if (selected != null) {
        _selectedSeasonIndex = seasons.indexOf(selected).clamp(0, seasons.length - 1);
        await _loadStandingsForSeason(selected.seasonId);
      } else {
        setState(() {
          _standings = [];
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load seasons: $e';
      });
    } finally {
      if (mounted) {
        setState(() => _loadingSeasons = false);
      }
    }
  }

  Future<void> _loadStandingsForSeason(int seasonId) async {
    setState(() {
      _loadingStandings = true;
      _errorMessage = null;
    });

    try {
      final standingsJson = await _leagueRepository.getStandings(seasonId);
      final standings =
          standingsJson.map((json) => StandingData.fromJson(json)).toList();
      standings.sort((a, b) => b.points.compareTo(a.points));
      setState(() {
        _standings = standings;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load standings: $e';
      });
    } finally {
      if (mounted) {
        setState(() => _loadingStandings = false);
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
                context.read<PlayerDataCubit>().refresh();
              },
            ),
            CupertinoSliverNavigationBar(
              heroTag: 'standings_nav_bar',
              largeTitle: const Text('Standings'),
              automaticBackgroundVisibility: false,
              backgroundColor: Colors.transparent,
              border: null,
            ),
            BlocBuilder<PlayerDataCubit, PlayerDataState>(
              builder: (context, state) {
                if (state is PlayerDataLoading) {
                  return const SliverFillRemaining(
                    child: Center(
                      child: CupertinoActivityIndicator(radius: 16),
                    ),
                  );
                }

                if (state is PlayerDataError) {
                  return SliverFillRemaining(
                    child: Center(child: Text(state.message)),
                  );
                }

                if (state is PlayerDataLoaded) {
                  if (state.leagueStandings.isEmpty) {
                    return const SliverFillRemaining(
                      child: Center(child: Text('No league data available')),
                    );
                  }

                  final leagues = state.leagueStandings.map((info) => info.league).toList();
                  final selectedIndex = _selectedLeagueIndex.clamp(0, leagues.length - 1);
                  final selectedLeague = leagues[selectedIndex];

                  if (_currentLeagueId != selectedLeague.leagueId) {
                    _currentLeagueId = selectedLeague.leagueId;
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _loadSeasonsForLeague(selectedLeague.leagueId);
                    });
                  }

                  return SliverPadding(
                    padding: const EdgeInsets.only(
                      left: Spacing.lg,
                      right: Spacing.lg,
                      top: Spacing.lg,
                      bottom: 100,
                    ),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        AppGlassContainer(
                          padding: const EdgeInsets.all(Spacing.lg),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (leagues.length > 1) ...[
                                AppDropdown<int>(
                                  value: selectedIndex,
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
                                    });
                                    _loadSeasonsForLeague(
                                      leagues[index].leagueId,
                                    );
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
                              if (_loadingSeasons)
                                const Center(
                                  child: CupertinoActivityIndicator(),
                                )
                              else if (_seasons.isNotEmpty) ...[
                                AppDropdown<int>(
                                  value: _selectedSeasonIndex.clamp(0, _seasons.length - 1),
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
                                    _loadStandingsForSeason(
                                      _seasons[index].seasonId,
                                    );
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
                              if (_loadingStandings)
                                const Center(
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(vertical: Spacing.lg),
                                    child: CupertinoActivityIndicator(),
                                  ),
                                )
                              else if (_standings.isEmpty)
                                Text(
                                  'No standings available for this season.',
                                  style: AppTypography.callout.copyWith(
                                    color: CupertinoColors.secondaryLabel,
                                  ),
                                )
                              else
                                ..._standings.asMap().entries.map((entry) {
                                  final index = entry.key;
                                  final standing = entry.value;
                                  return Padding(
                                    padding: EdgeInsets.only(
                                      bottom: index < _standings.length - 1
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
                                    ),
                                  );
                                }),
                            ],
                          ),
                        ),
                      ]),
                    ),
                  );
                }

                return const SliverFillRemaining(
                  child: Center(child: Text('No data available')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../design/index.dart';
import '../../../state/cubits/player/player_data_cubit.dart';
import '../../../state/cubits/player/player_data_state.dart';
import '../../../state/providers/theme_provider.dart';
import '../../../core/models/season.dart';
import '../../widgets/standings_table_header.dart';
import '../../widgets/modern_standing_row.dart';
import '../../standings/widgets/team_details_popup.dart';

class StandingsScreen extends StatefulWidget {
  const StandingsScreen({super.key});

  @override
  State<StandingsScreen> createState() => _StandingsScreenState();
}

class _StandingsScreenState extends State<StandingsScreen> {
  int _selectedLeagueIndex = 0;
  int? _currentLeagueId;
  int _selectedSeasonIndex = 0;
  String? _errorMessage;

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
                await context.read<PlayerDataCubit>().refresh();
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
                  return SliverPadding(
                    padding: EdgeInsets.only(
                      left: Spacing.lg,
                      right: Spacing.lg,
                      top: Spacing.lg,
                      bottom: 100,
                    ),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        AppGlassContainer(
                          padding: EdgeInsets.all(Spacing.xl),
                          child: Center(
                            child: CupertinoActivityIndicator(radius: 16),
                          ),
                        ),
                      ]),
                    ),
                  );
                }

                if (state is PlayerDataError) {
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
                          child: Text(
                            state.message,
                            style: AppTypography.callout.copyWith(
                              color: CupertinoColors.systemRed,
                            ),
                          ),
                        ),
                      ]),
                    ),
                  );
                }

                if (state is PlayerDataLoaded) {
                  if (state.leagueStandings.isEmpty) {
                    return SliverPadding(
                      padding: EdgeInsets.only(
                        left: Spacing.lg,
                        right: Spacing.lg,
                        top: Spacing.lg,
                        bottom: 100,
                      ),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          AppGlassContainer(
                            padding: EdgeInsets.all(Spacing.lg),
                            child: Text('No league data available'),
                          ),
                        ]),
                      ),
                    );
                  }

                  // Get unique leagues where user participates
                  final leagues = state.uniqueLeagues;
                  final selectedLeagueIndex = _selectedLeagueIndex.clamp(0, leagues.length - 1);
                  final selectedLeague = leagues[selectedLeagueIndex];

                  // Get filtered seasons for the selected league where user participates
                  final seasons = state.getSeasonsForLeague(selectedLeague.leagueId);
                  
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
                      ? (state.getStandingsForSeason(selectedSeason.seasonId) ?? [])
                      : <StandingData>[];

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
                                          barrierColor: Colors.black.withValues(alpha: 0.5),
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

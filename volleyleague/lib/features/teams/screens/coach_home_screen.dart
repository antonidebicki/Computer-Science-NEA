import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../design/index.dart';
import '../../../state/cubits/coach/team_data_cubit.dart';
import '../../../state/cubits/coach/team_data_state.dart';
import '../../../state/cubits/auth/auth_cubit.dart';
import '../../../state/cubits/auth/auth_state.dart';
import '../../../state/providers/theme_provider.dart';
import '../../../core/models/season.dart';
import '../../widgets/floating_glass_nav_bar.dart';
import '../../widgets/standings_table_header.dart';
import '../../widgets/modern_standing_row.dart';
import '../../standings/widgets/team_details_popup.dart';
import '../../fixtures/screens/unified_fixtures_screen.dart';
import 'team.dart';
import 'coach_profile_screen.dart';

class CoachHomeScreen extends StatelessWidget {
  const CoachHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthCubit>().state;
    final userId = authState is AuthAuthenticated ? authState.user.userId : 0;

    return BlocProvider(
      create: (_) => TeamDataCubit(
        userId: userId,
      )..loadTeamData(),
      child: const _CoachHomeScreenContent(),
    );
  }
}

class _CoachHomeScreenContent extends StatefulWidget {
  const _CoachHomeScreenContent();

  @override
  State<_CoachHomeScreenContent> createState() =>
      _CoachHomeScreenContentState();
}

class _CoachHomeScreenContentState extends State<_CoachHomeScreenContent> {
  int _currentIndex = 0;

  final List<NavBarItem> _navItems = [
    NavBarItem(icon: AppIcons.home, label: 'Home', symbol: 'house'),
    NavBarItem(icon: AppIcons.match, label: 'Fixtures', symbol: 'calendar'),
    NavBarItem(icon: AppIcons.team, label: 'Team', symbol: 'person.3'),
    NavBarItem(icon: AppIcons.profile, label: 'Profile', symbol: 'person'),
  ];

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        IndexedStack(
          index: _currentIndex,
          children: const [
            _HomeTab(),
            UnifiedFixturesScreen(userRole: FixturesUserRole.coach),
            TeamScreen(),
            CoachProfileScreen(),
          ],
        ),
        FloatingGlassNavBar(
              currentIndex: _currentIndex,
              onTap: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              items: _navItems,
            ),
      ],
    );
  }
}

class _HomeTab extends StatefulWidget {
  const _HomeTab();

  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
  int _selectedLeagueIndex = 0;
  int? _currentLeagueId;
  int _selectedSeasonIndex = 0;

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
                context.read<TeamDataCubit>().refresh();
              },
            ),
            CupertinoSliverNavigationBar(
              heroTag: 'home_nav_bar',
              largeTitle: const Text('Home'),
              automaticBackgroundVisibility: false,
              backgroundColor: Colors.transparent,
              border: null,
              trailing: CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () {
                  context.read<TeamDataCubit>().refresh();
                },
                child: const Icon(CupertinoIcons.refresh),
              ),
            ),

            // Content
            BlocBuilder<TeamDataCubit, TeamDataState>(
              builder: (context, state) {
                if (state is TeamDataLoading) {
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
                          padding: const EdgeInsets.all(Spacing.xl),
                          child: const Center(
                            child: CupertinoActivityIndicator(radius: 16),
                          ),
                        ),
                      ]),
                    ),
                  );
                }

                if (state is TeamDataError) {
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
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                CupertinoIcons.exclamationmark_triangle,
                                size: 48,
                                color: CupertinoColors.systemRed,
                              ),
                              const SizedBox(height: Spacing.lg),
                              Text(
                                'Failed to load data',
                                style: AppTypography.headline,
                              ),
                              const SizedBox(height: Spacing.sm),
                              Text(
                                state.message,
                                style: AppTypography.callout.copyWith(
                                  color: CupertinoColors.secondaryLabel,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: Spacing.xl),
                              CupertinoButton.filled(
                                onPressed: () {
                                  context.read<TeamDataCubit>().refresh();
                                },
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      ]),
                    ),
                  );
                }

                if (state is TeamDataLoaded) {
                  if (state.leagueStandings.isEmpty) {
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
                            child: const Text('No league data available'),
                          ),
                        ]),
                      ),
                    );
                  }

                  // Get unique leagues where coach's team participates
                  final leagues = state.uniqueLeagues;
                  final selectedLeagueIndex = _selectedLeagueIndex.clamp(0, leagues.length - 1);
                  final selectedLeague = leagues[selectedLeagueIndex];

                  // Get filtered seasons for the selected league where coach's team participates
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

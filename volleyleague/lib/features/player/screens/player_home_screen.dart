import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:volleyleague/features/player/screens/fixtures_screen.dart';
import '../../../design/index.dart';
import '../../../state/cubits/player/player_data_cubit.dart';
import '../../../state/cubits/player/player_data_state.dart';
import '../../../state/cubits/auth/auth_cubit.dart';
import '../../../state/cubits/auth/auth_state.dart';
import '../../../state/providers/theme_provider.dart';
import '../../../services/repositories/league_repository.dart';
import '../../../services/repositories/match_repository.dart';
import '../../../services/repositories/team_repository.dart';
import '../../../services/api_client.dart';
import '../widgets/mini_standings_widget.dart';
import '../widgets/mini_fixtures_widget.dart';
import '../widgets/floating_glass_nav_bar.dart';
import 'standings_screen.dart';
import 'profile_tab_screen.dart';

class PlayerHomeScreen extends StatelessWidget {
  const PlayerHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthCubit>().state;
    final userId = authState is AuthAuthenticated ? authState.user.userId : 0;

    final apiClient = ApiClient();
    final leagueRepository = LeagueRepository(apiClient);
    final matchRepository = MatchRepository(apiClient);
    final teamRepository = TeamRepository(apiClient);

    return BlocProvider(
      create: (_) => PlayerDataCubit(
        leagueRepository: leagueRepository,
        matchRepository: matchRepository,
        teamRepository: teamRepository,
        userId: userId,
      )..loadPlayerData(),
      child: const _PlayerHomeScreenContent(),
    );
  }
}

class _PlayerHomeScreenContent extends StatefulWidget {
  const _PlayerHomeScreenContent();

  @override
  State<_PlayerHomeScreenContent> createState() =>
      _PlayerHomeScreenContentState();
}

class _PlayerHomeScreenContentState extends State<_PlayerHomeScreenContent> {
  int _currentIndex = 0;

  final List<NavBarItem> _navItems = [
    NavBarItem(icon: AppIcons.home, label: 'Home'),
    NavBarItem(icon: AppIcons.match, label: 'Fixtures'),
    NavBarItem(icon: AppIcons.league, label: 'Standings'),
    NavBarItem(icon: AppIcons.profile, label: 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        IndexedStack(
          index: _currentIndex,
          children: const [
            _HomeTab(),
            FixturesScreen(),
            StandingsScreen(),
            ProfileTabScreen(),
          ],
        ),

        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: SafeArea(
            child: FloatingGlassNavBar(
              currentIndex: _currentIndex,
              onTap: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              items: _navItems,
            ),
          ),
        ),
      ],
    );
  }
}

class _HomeTab extends StatelessWidget {
  const _HomeTab();

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
              heroTag: 'home_nav_bar',
              largeTitle: const Text('Home'),
              //dont change automaticBackgroundVisibility, took about an hour to find that this makes the background white
              automaticBackgroundVisibility: false,
              backgroundColor: Colors.transparent,
              border: null,
              trailing: CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () {
                  context.read<PlayerDataCubit>().refresh();
                },
                child: const Icon(CupertinoIcons.refresh),
              ),
            ),

            // Content
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
                    child: Center(
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
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: Spacing.xl,
                            ),
                            child: Text(
                              state.message,
                              style: AppTypography.callout.copyWith(
                                color: CupertinoColors.secondaryLabel,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: Spacing.xl),
                          CupertinoButton.filled(
                            onPressed: () {
                              context.read<PlayerDataCubit>().refresh();
                            },
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                if (state is PlayerDataLoaded) {
                  return SliverPadding(
                    padding: const EdgeInsets.only(
                      left: Spacing.lg,
                      right: Spacing.lg,
                      top: Spacing.lg,
                      bottom: 100,
                    ),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        // league standings widget - show first league if available
                        if (state.leagueStandings.isNotEmpty)
                          MiniStandingsWidget(
                            leagueName: state.leagueStandings.first.league.name,
                            standings: state.leagueStandings.first.standings,
                            onViewFullTable: () {
                              debugPrint('View full table tapped');
                            },
                          )
                        else
                          const NoLeagueWidget(),

                        const SizedBox(height: Spacing.lg),
                        // TODO: look below
                        // upcoming fixtures. need to look into the algorithm for this bc not sure if it works as intended
                        MiniFixturesWidget(
                          fixtures: state.upcomingFixtures,
                          onMoreFixtures: () {
                            debugPrint('More fixtures tapped');
                          },
                        ),
                        SizedBox(height: Spacing.xxxl),
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

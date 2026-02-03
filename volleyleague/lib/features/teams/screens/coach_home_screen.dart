import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../design/index.dart';
import '../../../state/cubits/coach/team_data_cubit.dart';
import '../../../state/cubits/coach/team_data_state.dart';
import '../../../state/cubits/auth/auth_cubit.dart';
import '../../../state/cubits/auth/auth_state.dart';
import '../../../state/providers/theme_provider.dart';
import '../../../services/repositories/league_repository.dart';
import '../../../services/repositories/match_repository.dart';
import '../../../services/repositories/team_repository.dart';
import '../../../services/api_client.dart';
import '../../widgets/floating_glass_nav_bar.dart';
import 'team.dart';
import 'coach_fixtures_screen.dart';
import 'coach_profile_screen.dart';

class CoachHomeScreen extends StatelessWidget {
  const CoachHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthCubit>().state;
    final userId = authState is AuthAuthenticated ? authState.user.userId : 0;

    final apiClient = ApiClient();
    final leagueRepository = LeagueRepository(apiClient);
    final matchRepository = MatchRepository(apiClient);
    final teamRepository = TeamRepository(apiClient);

    return BlocProvider(
      create: (_) => TeamDataCubit(
        leagueRepository: leagueRepository,
        matchRepository: matchRepository,
        teamRepository: teamRepository,
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
    NavBarItem(icon: AppIcons.home, label: 'Home'),
    NavBarItem(icon: AppIcons.match, label: 'Fixtures'),
    NavBarItem(icon: AppIcons.team, label: 'Team'),
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
            CoachFixturesScreen(),
            TeamScreen(),
            CoachProfileScreen(),
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
            CupertinoSliverRefreshControl(
              onRefresh: () async {
                context.read<TeamDataCubit>().refresh();
              },
            ),
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
                  context.read<TeamDataCubit>().refresh();
                },
                child: const Icon(CupertinoIcons.refresh),
              ),
            ),

            // Content
            BlocBuilder<TeamDataCubit, TeamDataState>(
              builder: (context, state) {
                if (state is TeamDataLoading) {
                  return const SliverFillRemaining(
                    child: Center(
                      child: CupertinoActivityIndicator(radius: 16),
                    ),
                  );
                }

                if (state is TeamDataError) {
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
                              context.read<TeamDataCubit>().refresh();
                            },
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                if (state is TeamDataLoaded) {
                  return SliverPadding(
                    padding: const EdgeInsets.only(
                      left: Spacing.lg,
                      right: Spacing.lg,
                      top: Spacing.lg,
                      bottom: 100,
                    ),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        // Widgets to be added here later
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

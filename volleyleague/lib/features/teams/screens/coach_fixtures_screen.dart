import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../design/index.dart';
import '../../../state/cubits/coach/team_data_cubit.dart';
import '../../../state/cubits/coach/team_data_state.dart';
import '../../../state/providers/theme_provider.dart';
import '../../widgets/fixtures_widget.dart';
import '../../../design/widgets/toggle.dart';

// this is technically the players screen when its done, so i need to add extra 'coaching' features to it
// the only reason ive done it this way is that in the future i can add extra features without affecting the player, and also because the player
// screen can have multiple teams and leagues
class CoachFixturesScreen extends StatefulWidget {
  const CoachFixturesScreen({super.key});

  @override
  State<CoachFixturesScreen> createState() => _CoachFixturesScreenState();
}

class _CoachFixturesScreenState extends State<CoachFixturesScreen> {
  bool _showPastFixtures = false;

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
              heroTag: 'fixtures_nav_bar',
              largeTitle: const Text('Fixtures'),
              // also dont remove this automaticBackgroundVisibility (or any of them in the codebase) as it make the background ugly
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
                            'Failed to load fixtures',
                            style: AppTypography.headline,
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
                  final now = DateTime.now();

                  final futureFixtures = state.upcomingFixtures
                      .where(
                        (match) =>
                            match.match.matchDatetime != null &&
                            match.match.matchDatetime!.isAfter(now),
                      )
                      .toList();
                  final pastFixtures = state.upcomingFixtures
                      .where(
                        (match) =>
                            match.match.matchDatetime != null &&
                            match.match.matchDatetime!.isBefore(now),
                      )
                      .toList();

                  futureFixtures.sort((a, b) {
                    if (a.match.matchDatetime == null ||
                        b.match.matchDatetime == null) {
                      return 0;
                    }
                    return a.match.matchDatetime!.compareTo(
                      b.match.matchDatetime!,
                    );
                  });

                  pastFixtures.sort((a, b) {
                    if (a.match.matchDatetime == null ||
                        b.match.matchDatetime == null) {
                      return 0;
                    }
                    return b.match.matchDatetime!.compareTo(
                      a.match.matchDatetime!,
                    ); // Most recent first
                  });

                  final displayedFixtures =
                      _showPastFixtures ? pastFixtures : futureFixtures;

                  return SliverPadding(
                    padding: const EdgeInsets.only(
                      left: Spacing.lg,
                      right: Spacing.lg,
                      top: Spacing.lg,
                      bottom: 100,
                    ),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        Padding(
                          padding: const EdgeInsets.only(bottom: Spacing.lg),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(50),
                              boxShadow: [
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
                        ),
                        FixturesWidget(fixtures: displayedFixtures),
                        // massive spacing at the bottom to allow the last fixture to be scrolled past
                        // need to test this w different screen sizes
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

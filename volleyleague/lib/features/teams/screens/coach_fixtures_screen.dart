import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../design/index.dart';
import '../../../state/cubits/coach/team_data_cubit.dart';
import '../../../state/cubits/coach/team_data_state.dart';
import '../../../state/providers/theme_provider.dart';

class CoachFixturesScreen extends StatelessWidget {
  const CoachFixturesScreen({super.key});

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
                  return SliverPadding(
                    padding: const EdgeInsets.only(
                      left: Spacing.lg,
                      right: Spacing.lg,
                      top: Spacing.lg,
                      bottom: 100,
                    ),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        if (state.upcomingFixtures.isEmpty)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: Spacing.xl,
                              ),
                              child: Text(
                                'No upcoming fixtures',
                                style: AppTypography.callout.copyWith(
                                  color: CupertinoColors.secondaryLabel
                                      .resolveFrom(context),
                                ),
                              ),
                            ),
                          )
                        else
                          Text(
                            'Upcoming Fixtures (${state.upcomingFixtures.length})',
                            style: AppTypography.headline,
                          ),
                        const SizedBox(height: Spacing.xxxl),
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

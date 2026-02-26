import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../../../design/index.dart';
import '../../../state/providers/theme_provider.dart';
import '../../widgets/floating_glass_nav_bar.dart';
import '../../fixtures/screens/unified_fixtures_screen.dart';
import 'leagues_screen.dart';
import 'profile_screen.dart';
import '../widgets/quick_action_card.dart';

class LeagueAdminHomeScreen extends StatelessWidget {
  const LeagueAdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _LeagueAdminHomeContent();
  }
}

class _LeagueAdminHomeContent extends StatefulWidget {
  const _LeagueAdminHomeContent();

  @override
  State<_LeagueAdminHomeContent> createState() =>
      _LeagueAdminHomeContentState();
}

class _LeagueAdminHomeContentState extends State<_LeagueAdminHomeContent> {
  int _currentIndex = 0;

  final List<NavBarItem> _navItems = [
    NavBarItem(icon: AppIcons.home, label: 'Home'),
    NavBarItem(icon: AppIcons.calendar, label: 'Fixtures'),
    NavBarItem(icon: AppIcons.league, label: 'Leagues'),
    NavBarItem(icon: AppIcons.profile, label: 'Profile'),
  ];

  void changeTab(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        IndexedStack(
          index: _currentIndex,
          children: [
            _HomeTab(onChangeTab: changeTab),
            UnifiedFixturesScreen(
              userRole: FixturesUserRole.leagueAdmin,
              isActive: _currentIndex == 1,
            ),
            LeagueAdminLeaguesScreen(),
            LeagueAdminProfileScreen(),
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
  const _HomeTab({required this.onChangeTab});

  final ValueChanged<int> onChangeTab;

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
            CupertinoSliverRefreshControl(onRefresh: () async {}),
            CupertinoSliverNavigationBar(
              heroTag: 'league_admin_home_nav_bar',
              largeTitle: const Text('Home'),
              automaticBackgroundVisibility: false,
              backgroundColor: CupertinoColors.transparent,
              border: null,
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(
                horizontal: Spacing.lg,
                vertical: Spacing.lg,
              ),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  AppGlassContainer(
                    padding: const EdgeInsets.all(Spacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'League Admin Dashboard',
                          style: AppTypography.headline.copyWith(
                            color: CupertinoColors.label,
                          ),
                        ),
                        const SizedBox(height: Spacing.sm),
                        Text(
                          'Manage your leagues, teams, and fixtures from one place.',
                          style: AppTypography.callout.copyWith(
                            color: CupertinoColors.secondaryLabel,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: Spacing.lg),
                  QuickActionCard(
                    title: 'My Leagues',
                    description: 'View and manage leagues you oversee.',
                    icon: AppIcons.league,
                    onPressed: () {
                      onChangeTab(2);
                    },
                  ),
                  const SizedBox(height: Spacing.md),
                  QuickActionCard(
                    title: 'Teams',
                    description: 'Review team details and membership.',
                    icon: AppIcons.team,
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

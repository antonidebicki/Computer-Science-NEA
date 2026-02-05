import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../../../design/index.dart';
import '../../../state/providers/theme_provider.dart';
import '../../widgets/floating_glass_nav_bar.dart';
import 'league_admin_leagues_screen.dart';
import 'league_admin_teams_screen.dart';
import 'league_admin_profile_screen.dart';

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
    NavBarItem(icon: AppIcons.league, label: 'My Leagues'),
    NavBarItem(icon: AppIcons.team, label: 'Teams'),
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
          children: const [
            _HomeTab(),
            LeagueAdminLeaguesScreen(),
            LeagueAdminTeamsScreen(),
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
                  _QuickActionCard(
                    title: 'My Leagues',
                    description: 'View and manage leagues you oversee.',
                    icon: AppIcons.league,
                  ),
                  const SizedBox(height: Spacing.md),
                  _QuickActionCard(
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

class _QuickActionCard extends StatelessWidget {
  final String title;
  final String description;
  final Widget Function({double fontSize, Color? color, FontWeight? fontWeight})
      icon;

  const _QuickActionCard({
    required this.title,
    required this.description,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return AppGlassContainer(
      padding: const EdgeInsets.all(Spacing.lg),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: CupertinoColors.activeBlue.withValues(alpha: 0.15),
            ),
            child: Center(
              child: icon(
                fontSize: 24,
                color: CupertinoColors.activeBlue,
              ),
            ),
          ),
          const SizedBox(width: Spacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.headline.copyWith(
                    color: CupertinoColors.label,
                  ),
                ),
                const SizedBox(height: Spacing.xs),
                Text(
                  description,
                  style: AppTypography.callout.copyWith(
                    color: CupertinoColors.secondaryLabel,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

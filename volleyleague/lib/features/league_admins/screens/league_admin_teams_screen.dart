import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../../../design/index.dart';
import '../../../state/providers/theme_provider.dart';

class LeagueAdminTeamsScreen extends StatelessWidget {
  const LeagueAdminTeamsScreen({super.key});

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
              heroTag: 'league_admin_teams_nav_bar',
              largeTitle: const Text('Teams'),
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
                          'Teams',
                          style: AppTypography.headline.copyWith(
                            color: CupertinoColors.label,
                          ),
                        ),
                        const SizedBox(height: Spacing.sm),
                        Text(
                          'Review team rosters and manage league participation.',
                          style: AppTypography.callout.copyWith(
                            color: CupertinoColors.secondaryLabel,
                          ),
                        ),
                      ],
                    ),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

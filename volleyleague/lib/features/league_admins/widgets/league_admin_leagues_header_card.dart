import 'package:flutter/cupertino.dart';
import '../../../design/index.dart';

class LeagueAdminLeaguesHeaderCard extends StatelessWidget {
  final Widget leaguesContent;

  const LeagueAdminLeaguesHeaderCard({
    super.key,
    required this.leaguesContent,
  });

  @override
  Widget build(BuildContext context) {
    return AppGlassContainer(
      padding: const EdgeInsets.all(Spacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'My Leagues',
            style: AppTypography.headline.copyWith(
              color: CupertinoColors.label,
            ),
          ),
          const SizedBox(height: Spacing.sm),
          Text(
            'Manage leagues you administer and review standings.',
            style: AppTypography.callout.copyWith(
              color: CupertinoColors.secondaryLabel,
            ),
          ),
          const SizedBox(height: Spacing.lg),
          leaguesContent,
        ],
      ),
    );
  }
}

import 'package:flutter/cupertino.dart';
import '../../../design/index.dart';

class LeagueAdminLeaguesHeaderCard extends StatelessWidget {
  final Widget leaguePicker;
  final Widget seasonInfo;

  const LeagueAdminLeaguesHeaderCard({
    super.key,
    required this.leaguePicker,
    required this.seasonInfo,
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
          leaguePicker,
          const SizedBox(height: Spacing.sm),
          seasonInfo,
        ],
      ),
    );
  }
}

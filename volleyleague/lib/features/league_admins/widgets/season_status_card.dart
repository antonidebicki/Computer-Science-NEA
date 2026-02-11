import 'package:flutter/cupertino.dart';
import '../../../design/index.dart';

class SeasonStatusCard extends StatelessWidget {
  final bool hasSeason;
  final bool isSeasonStarted;
  final bool isStartingSeason;
  final bool isLoadingTeams;
  final int? teamCount;
  final bool canStartSeason;
  final VoidCallback onStartSeason;

  const SeasonStatusCard({
    super.key,
    required this.hasSeason,
    required this.isSeasonStarted,
    required this.isStartingSeason,
    required this.isLoadingTeams,
    required this.teamCount,
    required this.canStartSeason,
    required this.onStartSeason,
  });

  @override
  Widget build(BuildContext context) {
    return AppGlassContainer(
      padding: const EdgeInsets.all(Spacing.md),
      borderRadius: 14,
      blur: 8,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Season status',
            style: AppTypography.caption.copyWith(
              color: CupertinoColors.secondaryLabel,
            ),
          ),
          const SizedBox(height: Spacing.xs),
          Text(
            isSeasonStarted
                ? 'Started (team invites locked)'
                : 'Not started yet',
            style: AppTypography.body.copyWith(
              color: CupertinoColors.label,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: Spacing.xs),
          _buildTeamHint(),
          const SizedBox(height: Spacing.md),
          SizedBox(
            width: double.infinity,
            child: CupertinoButton.filled(
              onPressed: (!hasSeason || !canStartSeason) ? null : onStartSeason,
              child: isStartingSeason
                  ? const CupertinoActivityIndicator(radius: 8)
                  : const Text('Start Season'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamHint() {
    if (!hasSeason) {
      return Text(
        'Create a season to manage teams.',
        style: AppTypography.caption.copyWith(
          color: CupertinoColors.secondaryLabel,
        ),
      );
    }

    if (isLoadingTeams) {
      return Text(
        'Loading team count...',
        style: AppTypography.caption.copyWith(
          color: CupertinoColors.secondaryLabel,
        ),
      );
    }

    final count = teamCount;
    if (count == null) {
      return Text(
        'Team count unavailable.',
        style: AppTypography.caption.copyWith(
          color: CupertinoColors.secondaryLabel,
        ),
      );
    }

    final meetsRange = count >= 2 && count <= 24;
    final color = meetsRange
        ? CupertinoColors.secondaryLabel
        : CupertinoColors.systemRed;
    return Text(
      'Teams in season: $count (need 2-24 to start)',
      style: AppTypography.caption.copyWith(
        color: color,
      ),
    );
  }
}

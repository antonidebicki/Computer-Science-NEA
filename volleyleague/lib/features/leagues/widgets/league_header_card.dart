import 'package:flutter/cupertino.dart';
import '../../../design/index.dart';
import '../../../core/models/models.dart';

/// Header card displaying league and season information
class LeagueHeaderCard extends StatelessWidget {
  final League league;
  final Season season;

  const LeagueHeaderCard({
    super.key,
    required this.league,
    required this.season,
  });

  @override
  Widget build(BuildContext context) {
    return AppGlassContainer(
      padding: const EdgeInsets.all(Spacing.lg),
      borderRadius: Spacing.xl,
      blur: Spacing.xl,
      color: CupertinoColors.white.withValues(alpha: 0.25),
      borderColor: CupertinoColors.white.withValues(alpha: 0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppIcons.volleyball(
                fontSize: Spacing.xxl,
                color: CupertinoColors.activeBlue,
              ),
              const SizedBox(width: Spacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText(
                      league.name,
                      style: AppTypography.title2.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: Spacing.xs),
                    AppText(
                      season.name,
                      style: AppTypography.callout.copyWith(
                        color: CupertinoColors.systemGrey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacing.sm),
          AppText(
            '${_formatDate(season.startDate)} - ${_formatDate(season.endDate)}',
            style: AppTypography.subhead.copyWith(
              color: CupertinoColors.systemGrey,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}

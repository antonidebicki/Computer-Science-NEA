import 'package:flutter/cupertino.dart';
import '../../../design/index.dart';

/// Legend card explaining standings table abbreviations
class StandingsLegend extends StatelessWidget {
  const StandingsLegend({super.key});

  @override
  Widget build(BuildContext context) {
    return AppGlassContainer(
      padding: const EdgeInsets.all(Spacing.lg),
      borderRadius: 24,
      blur: 20,
      color: CupertinoColors.white.withValues(alpha: 0.25),
      borderColor: CupertinoColors.white.withValues(alpha: 0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText(
            'Legend',
            style: AppTypography.headline,
          ),
          const SizedBox(height: Spacing.sm),
          _buildLegendItem('P', 'Matches Played'),
          _buildLegendItem('W', 'Wins'),
          _buildLegendItem('L', 'Losses'),
          _buildLegendItem('SW', 'Sets Won'),
          _buildLegendItem('SL', 'Sets Lost'),
          _buildLegendItem('SD', 'Set Difference'),
          _buildLegendItem('PTS', 'League Points'),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String abbr, String description) {
    return Padding(
      padding: const EdgeInsets.only(top: Spacing.xs),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: AppText(
              abbr,
              style: AppTypography.subhead.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: Spacing.sm),
          Expanded(
            child: AppText(
              description,
              style: AppTypography.subhead.copyWith(
                color: CupertinoColors.systemGrey,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/cupertino.dart';
import '../../../design/index.dart';

/// Reusable fixture card displaying match information
class FixtureCard extends StatelessWidget {
  final String homeTeam;
  final String awayTeam;
  final DateTime date;
  final String? venue;

  const FixtureCard({
    super.key,
    required this.homeTeam,
    required this.awayTeam,
    required this.date,
    this.venue,
  });

  @override
  Widget build(BuildContext context) {
    // Format date as d/MM/yyyy
    final day = date.day;
    final month = date.month;
    final year = date.year;
    final formattedDate = '$day/$month/$year';

    return Container(
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(Spacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Teams
          Text(
            '$homeTeam vs $awayTeam',
            style: AppTypography.callout.copyWith(
              color: CupertinoColors.label,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: Spacing.sm),

          // Date and venue
          Row(
            children: [
              const Icon(
                CupertinoIcons.calendar,
                size: 14,
                color: CupertinoColors.secondaryLabel,
              ),
              const SizedBox(width: Spacing.xs),
              Text(
                formattedDate,
                style: AppTypography.footnote.copyWith(
                  color: CupertinoColors.secondaryLabel,
                ),
              ),
              if (venue != null) ...[
                const SizedBox(width: Spacing.md),
                const Icon(
                  CupertinoIcons.location_solid,
                  size: 14,
                  color: CupertinoColors.secondaryLabel,
                ),
                const SizedBox(width: Spacing.xs),
                Expanded(
                  child: Text(
                    venue!,
                    style: AppTypography.footnote.copyWith(
                      color: CupertinoColors.secondaryLabel,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

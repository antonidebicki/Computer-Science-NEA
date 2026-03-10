import 'package:flutter/cupertino.dart';
import '../../design/index.dart';

/// Reusable fixture card displaying match information
class FixtureCard extends StatelessWidget {
  final String homeTeam;
  final String awayTeam;
  final DateTime date;
  final String? venue;
  final int? homeSetsWon;
  final int? awaySetsWon;
  final bool showScore;
  final bool isClickable;
  final bool isAdminView;

  const FixtureCard({
    super.key,
    required this.homeTeam,
    required this.awayTeam,
    required this.date,
    this.venue,
    this.homeSetsWon,
    this.awaySetsWon,
    this.showScore = false,
    this.isClickable = false,
    this.isAdminView = false,
  });

  @override
  Widget build(BuildContext context) {
    // format date as dd/MM/yyyy
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year;
    final formattedDate = '$day/$month/$year';

    return Container(
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x5AFFFFFF), width: 2.0),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.black.withValues(alpha: 0.10),
            blurRadius: 14,
            spreadRadius: 0,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: CupertinoColors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            spreadRadius: -1,
            offset: const Offset(0, 3),
          ),
          BoxShadow(
            color: CupertinoColors.white.withValues(alpha: 0.65),
            blurRadius: 5,
            spreadRadius: -2,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      padding: const EdgeInsets.all(Spacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '$homeTeam vs $awayTeam',
                  style: AppTypography.callout.copyWith(
                    color: CupertinoColors.label,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (showScore)
                Text(
                  '${homeSetsWon ?? 0} - ${awaySetsWon ?? 0}',
                  style: AppTypography.callout.copyWith(
                    color: CupertinoColors.label,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              if (isClickable) ...[
                const SizedBox(width: Spacing.sm),
                const Icon(
                  CupertinoIcons.chevron_right,
                  size: 14,
                  color: CupertinoColors.secondaryLabel,
                ),
              ],
            ],
          ),
          const SizedBox(height: Spacing.sm),

          if (isClickable)
            Padding(
              padding: const EdgeInsets.only(bottom: Spacing.sm),
              child: Text(
                isAdminView
                    ? 'Tap to enter or edit score'
                    : 'Tap to view scores',
                style: AppTypography.caption.copyWith(
                  color: CupertinoColors.secondaryLabel,
                ),
              ),
            ),

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

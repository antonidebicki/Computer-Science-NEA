import 'package:flutter/cupertino.dart';
import '../../../design/index.dart';

/// Modern standing row with enhanced visual design
class ModernStandingRow extends StatelessWidget {
  final int position;
  final String teamName;
  final int matchesPlayed;
  final int wins;
  final int losses;
  final int points;

  const ModernStandingRow({
    super.key,
    required this.position,
    required this.teamName,
    required this.matchesPlayed,
    required this.wins,
    required this.losses,
    required this.points,
  });

  @override
  Widget build(BuildContext context) {
    // Determine medal color for top 3 positions
    Color? positionColor;
    if (position == 1) {
      positionColor = const Color(0xFFFFD700); // Gold
    } else if (position == 2) {
      positionColor = const Color(0xFFC0C0C0); // Silver
    } else if (position == 3) {
      positionColor = const Color(0xFFCD7F32); // Bronze
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.md,
        vertical: Spacing.sm,
      ),
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey6.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          // Position with medal for top 3
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: positionColor ?? CupertinoColors.systemGrey5,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$position',
                style: AppTypography.callout.copyWith(
                  color: positionColor != null
                      ? CupertinoColors.black
                      : CupertinoColors.label,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: Spacing.md),
          
          // Team name
          Expanded(
            child: Text(
              teamName,
              style: AppTypography.callout.copyWith(
                color: CupertinoColors.label,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          
          // Stats
          _buildStatCell(matchesPlayed, width: 32),
          _buildStatCell(wins, width: 28, color: CupertinoColors.systemGreen),
          _buildStatCell(losses, width: 28, color: CupertinoColors.systemRed),
          _buildStatCell(points, width: 36, bold: true),
        ],
      ),
    );
  }

  Widget _buildStatCell(
    int value, {
    required double width,
    bool bold = false,
    Color? color,
  }) {
    return SizedBox(
      width: width,
      child: Text(
        value.toString(),
        style: AppTypography.callout.copyWith(
          color: color ?? CupertinoColors.label,
          fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
          fontSize: 14,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

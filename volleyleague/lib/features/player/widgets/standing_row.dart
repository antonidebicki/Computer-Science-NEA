import 'package:flutter/cupertino.dart';
import '../../../design/index.dart';

/// Reusable standing row for displaying team statistics
class StandingRow extends StatelessWidget {
  final int position;
  final String teamName;
  final int matchesPlayed;
  final int wins;
  final int losses;
  final int points;

  const StandingRow({
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
    return Row(
      children: [
        SizedBox(
          width: 24,
          child: Text(
            '$position.',
            style: AppTypography.callout.copyWith(
              color: CupertinoColors.label,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: Spacing.sm),
        Expanded(
          child: Text(
            teamName,
            style: AppTypography.callout.copyWith(
              color: CupertinoColors.label,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        _buildStatCell(matchesPlayed, width: 32),
        _buildStatCell(wins, width: 28),
        _buildStatCell(losses, width: 28),
        _buildStatCell(points, width: 32, bold: true),
      ],
    );
  }

  Widget _buildStatCell(int value, {required double width, bool bold = false}) {
    return SizedBox(
      width: width,
      child: Text(
        value.toString(),
        style: AppTypography.callout.copyWith(
          color: CupertinoColors.label,
          fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

import 'package:flutter/cupertino.dart';
import '../../../design/index.dart';

/// reusable table header for standings tables
class StandingsTableHeader extends StatelessWidget {
  
  const StandingsTableHeader({
    super.key,
    this.cellSpacing = Spacing.sm,
    this.cellWidthMultiplier = 1.0,
    this.leftPadding = 4.0,
    this.rightPadding = 4.0,
  });
  final double cellSpacing;
  final double cellWidthMultiplier;
  final double leftPadding;
  final double rightPadding;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: leftPadding),
        SizedBox(
          width: 24,
          child: Text(
            '#',
            style: AppTypography.footnote.copyWith(
              color: CupertinoColors.secondaryLabel,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        SizedBox(width: cellSpacing),
        Expanded(
          child: Text(
            'Team',
            style: AppTypography.footnote.copyWith(
              color: CupertinoColors.secondaryLabel,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        _buildHeaderCell('MP', width: 32 * cellWidthMultiplier),
        _buildHeaderCell('W', width: 28 * cellWidthMultiplier),
        _buildHeaderCell('L', width: 28 * cellWidthMultiplier),
        _buildHeaderCell('Pts', width: 32 * cellWidthMultiplier),
        SizedBox(width: rightPadding),
      ],
    );
  }

  Widget _buildHeaderCell(String label, {required double width}) {
    return SizedBox(
      width: width,
      child: Text(
        label,
        style: AppTypography.footnote.copyWith(
          color: CupertinoColors.secondaryLabel,
          fontWeight: FontWeight.w600,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

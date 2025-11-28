import 'package:flutter/cupertino.dart';
import '../../../design/index.dart';

/// Reusable table header for standings tables
class StandingsTableHeader extends StatelessWidget {
  const StandingsTableHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
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
        const SizedBox(width: Spacing.sm),
        Expanded(
          child: Text(
            'Team',
            style: AppTypography.footnote.copyWith(
              color: CupertinoColors.secondaryLabel,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        _buildHeaderCell('MP', width: 32),
        _buildHeaderCell('W', width: 28),
        _buildHeaderCell('L', width: 28),
        _buildHeaderCell('Pts', width: 32),
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

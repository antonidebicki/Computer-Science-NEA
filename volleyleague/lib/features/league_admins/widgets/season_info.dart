import 'package:flutter/cupertino.dart';
import '../../../core/models/season.dart';
import '../../../design/index.dart';

class SeasonInfo extends StatelessWidget {
  final Season? season;

  const SeasonInfo({
    super.key,
    required this.season,
  });

  @override
  Widget build(BuildContext context) {
    if (season == null) {
      return Text(
        'No active season found for this league.',
        style: AppTypography.caption.copyWith(
          color: CupertinoColors.secondaryLabel,
        ),
      );
    }

    return Text(
      'Current season: ${season!.name}',
      style: AppTypography.caption.copyWith(
        color: CupertinoColors.secondaryLabel,
      ),
    );
  }
}

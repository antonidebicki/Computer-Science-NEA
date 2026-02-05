import 'package:flutter/cupertino.dart';
import '../../../core/models/league.dart';
import '../../../design/index.dart';

class LeaguePicker extends StatelessWidget {
  final bool isLoading;
  final List<League> leagues;
  final League? selectedLeague;
  final ValueChanged<League> onSelected;

  const LeaguePicker({
    super.key,
    required this.isLoading,
    required this.leagues,
    required this.selectedLeague,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CupertinoActivityIndicator());
    }

    if (leagues.isEmpty) {
      return Text(
        'No leagues available.',
        style: AppTypography.callout.copyWith(
          color: CupertinoColors.secondaryLabel,
        ),
      );
    }

    return AppGlassContainer(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.md,
        vertical: Spacing.sm,
      ),
      borderRadius: 12,
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: () {
          showCupertinoModalPopup(
            context: context,
            builder: (context) => _buildLeaguePickerSheet(context),
          );
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                selectedLeague?.name ?? 'Select League',
                style: AppTypography.body.copyWith(
                  color: CupertinoColors.label,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(
              CupertinoIcons.chevron_down,
              color: CupertinoColors.activeBlue,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeaguePickerSheet(BuildContext context) {
    return CupertinoActionSheet(
      title: const Text('Select League'),
      actions: leagues
          .map(
            (league) => CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(context);
                onSelected(league);
              },
              child: Text(league.name),
            ),
          )
          .toList(),
      cancelButton: CupertinoActionSheetAction(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
    );
  }
}

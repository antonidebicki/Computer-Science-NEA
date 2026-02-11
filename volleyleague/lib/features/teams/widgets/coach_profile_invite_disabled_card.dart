import 'package:flutter/cupertino.dart';
import '../../../design/index.dart';

class CoachProfileInviteDisabledCard extends StatelessWidget {
  final bool isDark;

  const CoachProfileInviteDisabledCard({
    super.key,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final disabledColor = isDark
        ? CupertinoColors.systemGrey2.withOpacity(0.6)
        : CupertinoColors.systemGrey4;

    return AppGlassContainer(
      padding: const EdgeInsets.all(Spacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Invite Players',
            style: AppTypography.headline.copyWith(
              color: CupertinoColors.label,
            ),
          ),
          const SizedBox(height: Spacing.sm),
          Text(
            'You have not created a team yet.',
            style: AppTypography.callout.copyWith(
              color: CupertinoColors.secondaryLabel.resolveFrom(context),
            ),
          ),
          const SizedBox(height: Spacing.lg),
          SizedBox(
            width: double.infinity,
            child: CupertinoButton(
              onPressed: null,
              color: disabledColor,
              disabledColor: disabledColor,
              child: const Text('Invite Players'),
            ),
          ),
        ],
      ),
    );
  }
}

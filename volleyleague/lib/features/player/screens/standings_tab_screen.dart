import 'package:flutter/cupertino.dart';
import '../../../design/index.dart';

/// Placeholder screen for Standings tab in player navigation
class StandingsTabScreen extends StatelessWidget {
  const StandingsTabScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: SafeArea(
        bottom: false, // Don't add bottom padding, nav bar handles it
        child: Padding(
          padding: const EdgeInsets.only(bottom: 100),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
              AppIcons.league(fontSize: 64, color: CupertinoColors.systemGrey),
              const SizedBox(height: Spacing.lg),
              Text(
                'Standings',
                style: AppTypography.title1,
              ),
              const SizedBox(height: Spacing.sm),
              Text(
                'Coming soon...',
                style: AppTypography.body.copyWith(
                  color: CupertinoColors.systemGrey,
                ),
              ),
            ],
            ),
          ),
        ),
      ),
    );
  }
}

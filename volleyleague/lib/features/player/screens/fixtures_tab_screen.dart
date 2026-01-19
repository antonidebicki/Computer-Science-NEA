import 'package:flutter/cupertino.dart';
import '../../../design/index.dart';

/// i made this file to stop errors, it will be deleted when the fixtures tab is (eventually) implemented
class FixturesTabScreen extends StatelessWidget {
  const FixturesTabScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 100),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
              AppIcons.match(fontSize: 64, color: CupertinoColors.systemGrey),
              const SizedBox(height: Spacing.lg),
              Text(
                'Fixtures',
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

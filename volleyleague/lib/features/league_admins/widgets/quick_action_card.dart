import 'package:flutter/cupertino.dart';
import '../../../design/index.dart';

class QuickActionCard extends StatelessWidget {
  final String title;
  final String description;
  final Widget Function({double fontSize, Color? color, FontWeight? fontWeight})
  icon;
  final VoidCallback? onPressed;

  const QuickActionCard({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return AppGlassContainer(
      padding: const EdgeInsets.all(Spacing.xs),
      child: CupertinoButton(
        onPressed: onPressed,
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: CupertinoColors.activeBlue.withValues(alpha: 0.15),
              ),
              child: Center(
                child: icon(fontSize: 24, color: CupertinoColors.activeBlue),
              ),
            ),
            const SizedBox(width: Spacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.headline.copyWith(
                      color: CupertinoColors.label,
                    ),
                  ),
                  const SizedBox(height: Spacing.xs),
                  Text(
                    description,
                    style: AppTypography.callout.copyWith(
                      color: CupertinoColors.secondaryLabel,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

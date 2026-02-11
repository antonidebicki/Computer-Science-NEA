import 'package:flutter/cupertino.dart';
import '../../../design/index.dart';

class BuildDateRow extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;

  const BuildDateRow({
    super.key,
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: AppTypography.caption.copyWith(
              color: CupertinoColors.secondaryLabel,
            ),
          ),
        ),
        CupertinoButton(
          padding: const EdgeInsets.symmetric(
            horizontal: Spacing.md,
            vertical: Spacing.xs,
          ),
          onPressed: onTap,
          child: Text(
            value,
            style: AppTypography.body.copyWith(
              color: CupertinoColors.activeBlue,
            ),
          ),
        ),
      ],
    );
  }
}
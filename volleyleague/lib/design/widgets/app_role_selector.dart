import 'dart:ui';
import 'package:flutter/cupertino.dart';
import '../tokens/spacing.dart';

/// Apple-style liquid glass segmented control for role selection
class AppRoleSelector extends StatelessWidget {
  final String selectedRole;
  final ValueChanged<String> onChanged;
  final List<String> roles;
  
  const AppRoleSelector({
    super.key,
    required this.selectedRole,
    required this.onChanged,
    this.roles = const ['Player', 'Team', 'League'],
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12), // Keeping as 12 - specific to component design
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), // Blur effect - keeping as is
        child: Container(
          decoration: BoxDecoration(
            color: CupertinoColors.systemGrey6.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: CupertinoColors.white.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          padding: const EdgeInsets.all(Spacing.xs),
          child: LayoutBuilder(
            builder: (context, constraints) {
              const double gap = Spacing.xs;
              final int n = roles.length;
              final double totalGaps = gap * (n - 1);
              final double segmentWidth = (constraints.maxWidth - totalGaps) / n;
              final int selectedIndex = roles.indexOf(selectedRole).clamp(0, n - 1);

              return SizedBox(
                height: 44,
                child: Stack(
                  children: [
                    // Squircle highlight (thumb)
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOutCubic,
                      top: 0,
                      bottom: 0,
                      left: (segmentWidth + gap) * selectedIndex,
                      width: segmentWidth,
                      child: DecoratedBox(
                        decoration: ShapeDecoration(
                          color: CupertinoColors.white.withValues(alpha: 0.85),
                          shape: ContinuousRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: CupertinoColors.white.withValues(alpha: 0.35),
                              width: 1.2,
                            ),
                          ),
                          shadows: const [
                            BoxShadow(color: Color(0x1F000000), blurRadius: 8, spreadRadius: 0, offset: Offset(0, 2)),
                          ],
                        ),
                      ),
                    ),
                    // Foreground labels and taps
                    Row(
                      children: [
                        for (int i = 0; i < roles.length; i++) ...[
                          if (i > 0) SizedBox(width: gap),
                          SizedBox(
                            width: segmentWidth,
                            child: CupertinoButton(
                              padding: EdgeInsets.zero,
                              onPressed: () => onChanged(roles[i]),
                              child: DefaultTextStyle.merge(
                                style: TextStyle(
                                  color: i == selectedIndex
                                      ? CupertinoColors.activeBlue
                                      : CupertinoColors.black.withValues(alpha: 0.6),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                                child: Text(roles[i]),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

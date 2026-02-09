import 'package:flutter/cupertino.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';
import '../tokens/spacing.dart';
import '../tokens/colors.dart';

class AppRoleSelector extends StatelessWidget {
  final String selectedRole;
  final ValueChanged<String> onChanged;
  final List<String> roles;
  
  const AppRoleSelector({
    super.key,
    required this.selectedRole,
    required this.onChanged,
    //original showed team intead of coach but i implemented a dumb system where these roles are directly implmented
    //into the json to the database, so now i have to stick w coach for now, i might change later if my 50h time constaint allows
    this.roles = const ['Player', 'Coach', 'League'],
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: FakeGlass(
        shape: LiquidRoundedSuperellipse(borderRadius: 12),
        settings: AppColors.liquidGlassSettings,
        child: Container(
          decoration: BoxDecoration(
            color: CupertinoColors.systemGrey6.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
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

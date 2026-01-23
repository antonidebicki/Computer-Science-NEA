import 'package:flutter/cupertino.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';
import '../tokens/spacing.dart';
import '../tokens/colors.dart';

class ViewFormatSelector extends StatelessWidget {
  final String selectedFormat;
  final ValueChanged<String> onChanged;
  final List<String> formats;
  
  const ViewFormatSelector({
    super.key,
    required this.selectedFormat,
    required this.onChanged,
    this.formats = const ['Short', 'Full', 'Form'],
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
              final int n = formats.length;
              final double totalGaps = gap * (n - 1);
              final double segmentWidth = (constraints.maxWidth - totalGaps) / n;
              final int selectedIndex = formats.indexOf(selectedFormat).clamp(0, n - 1);

              return SizedBox(
                height: 44,
                child: Stack(
                  children: [
                    // Animated highlight background
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
                            BoxShadow(
                              color: Color(0x1F000000),
                              blurRadius: 8,
                              spreadRadius: 0,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Format options with underline indicator
                    Row(
                      children: [
                        for (int i = 0; i < formats.length; i++) ...[
                          if (i > 0) SizedBox(width: gap),
                          SizedBox(
                            width: segmentWidth,
                            child: CupertinoButton(
                              padding: EdgeInsets.zero,
                              onPressed: () => onChanged(formats[i]),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    formats[i],
                                    style: TextStyle(
                                      color: i == selectedIndex
                                          ? CupertinoColors.activeBlue
                                          : CupertinoColors.black.withValues(alpha: 0.6),
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                    ),
                                  ),
                                  if (i == selectedIndex)
                                    Container(
                                      width: 24,
                                      height: 2,
                                      margin: const EdgeInsets.only(top: 2),
                                      decoration: BoxDecoration(
                                        color: CupertinoColors.activeBlue,
                                        borderRadius: BorderRadius.circular(1),
                                      ),
                                    ),
                                ],
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

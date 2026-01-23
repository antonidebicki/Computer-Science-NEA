import 'package:flutter/cupertino.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';
import '../tokens/spacing.dart';

/// Apple-style liquid glass segmented control
class AppSegmentedControl<T> extends StatelessWidget {
  final T selectedValue;
  final ValueChanged<T> onChanged;
  final Map<T, String> segments;

  const AppSegmentedControl({
    super.key,
    required this.selectedValue,
    required this.onChanged,
    required this.segments,
  });

  @override
  Widget build(BuildContext context) {
    final keys = segments.keys.toList();
    final values = segments.values.toList();

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: FakeGlass(
        shape: LiquidRoundedSuperellipse(borderRadius: 12),
        settings: const LiquidGlassSettings(
          blur: 10,
          glassColor: Color(0x80F2F2F7),
          lightIntensity: 1.2,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: CupertinoColors.systemGrey6.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(Spacing.xs),
          child: LayoutBuilder(
            builder: (context, constraints) {
              const double gap = Spacing.xs;
              final int n = keys.length;
              final double totalGaps = gap * (n - 1);
              final double segmentWidth = (constraints.maxWidth - totalGaps) / n;
              final int selectedIndex = keys.indexOf(selectedValue).clamp(0, n - 1);

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
                    // Foreground labels and taps
                    Row(
                      children: [
                        for (int i = 0; i < keys.length; i++) ...[
                          if (i > 0) SizedBox(width: gap),
                          SizedBox(
                            width: segmentWidth,
                            child: CupertinoButton(
                              padding: EdgeInsets.zero,
                              onPressed: () => onChanged(keys[i]),
                              child: DefaultTextStyle.merge(
                                style: TextStyle(
                                  color: i == selectedIndex
                                      ? CupertinoColors.activeBlue
                                      : CupertinoColors.black.withValues(alpha: 0.6),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                                child: Text(values[i]),
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

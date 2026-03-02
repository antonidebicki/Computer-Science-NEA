import 'package:flutter/foundation.dart';
import 'package:flutter/cupertino.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';
import 'package:cupertino_native/cupertino_native.dart';
import '../../../design/index.dart';

/// A data class representing a single app bar item
class AppBarRowItem {
  final String label;
  final ValueChanged<int> onChanged;

  const AppBarRowItem({
    required this.label,
    required this.onChanged,
  });
}

/// A horizontal row of text buttons with animated liquid glass selector
/// The selector moves smoothly behind the selected button
/// 
/// Example:
/// ```dart
/// AppBarRow(
///   selectedIndex: _currentTab,
///   items: [
///     AppBarRowItem(
///       label: 'Leagues',
///       onChanged: (index) => setState(() => _currentTab = index),
///     ),
///     AppBarRowItem(
///       label: 'Standings',
///       onChanged: (index) => setState(() => _currentTab = index),
///     ),
///   ],
/// )
/// ```
class AppBarRow extends StatefulWidget {
  final int selectedIndex;
  final List<String> items;
  final ValueChanged<int> onChanged;
  final EdgeInsetsGeometry padding;
  final double spacing;
  final double borderRadius;
  final double blur;

  const AppBarRow({
    super.key,
    required this.selectedIndex,
    required this.items,
    required this.onChanged,
    this.padding = const EdgeInsets.symmetric(horizontal: Spacing.lg),
    this.spacing = Spacing.md,
    this.borderRadius = 12,
    this.blur = 10,
  });

  @override
  State<AppBarRow> createState() => _AppBarRowState();
}

class _AppBarRowState extends State<AppBarRow> {
  @override
  Widget build(BuildContext context) {
    final isIOS = defaultTargetPlatform == TargetPlatform.iOS;

    if (isIOS) {
      return Padding(
        padding: widget.padding,
        child: CNSegmentedControl(
          labels: widget.items,
          selectedIndex: widget.selectedIndex,
          onValueChanged: widget.onChanged,
        ),
      );
    }

    return _buildFallbackSegmentedControl(context);
  }

  Widget _buildFallbackSegmentedControl(BuildContext context) {
    return Padding(
      padding: widget.padding,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: FakeGlass(
          shape: LiquidRoundedSuperellipse(borderRadius: 12),
          settings: LiquidGlassSettings(
            blur: 10,
            glassColor: const Color(0x4DFFFFFF),
            lightIntensity: 1.5,
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
                final int n = widget.items.length;
                final double totalGaps = gap * (n - 1);
                final double segmentWidth = (constraints.maxWidth - totalGaps) / n;

                return SizedBox(
                  height: 44,
                  child: Stack(
                    children: [
                      AnimatedPositioned(
                        duration: const Duration(milliseconds: 180),
                        curve: Curves.easeOutCubic,
                        top: 0,
                        bottom: 0,
                        left: (segmentWidth + gap) * widget.selectedIndex,
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
                      Row(
                        children: [
                          for (int i = 0; i < widget.items.length; i++) ...[
                            if (i > 0) SizedBox(width: gap),
                            SizedBox(
                              width: segmentWidth,
                              child: CupertinoButton(
                                padding: EdgeInsets.zero,
                                onPressed: () => widget.onChanged(i),
                                child: DefaultTextStyle.merge(
                                  style: TextStyle(
                                    color: i == widget.selectedIndex
                                        ? CupertinoColors.activeBlue
                                        : CupertinoColors.black.withValues(alpha: 0.6),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                  ),
                                  child: Text(widget.items[i]),
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
      ),
    );
  }
}

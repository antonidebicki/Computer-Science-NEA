import 'package:flutter/cupertino.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';
import '../tokens/spacing.dart';
import '../tokens/colors.dart';
import '../tokens/durations.dart';

class LiquidGlassToggle extends StatefulWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final String activeLabel;
  final String inactiveLabel;

  const LiquidGlassToggle({
    super.key,
    required this.value,
    required this.onChanged,
    required this.activeLabel,
    required this.inactiveLabel,
  });

  @override
  State<LiquidGlassToggle> createState() => _LiquidGlassToggleState();
}

class _LiquidGlassToggleState extends State<LiquidGlassToggle>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: AppDurations.slow,
      vsync: this,
      value: widget.value ? 1.0 : 0.0,
    );
  }

  @override
  void didUpdateWidget(LiquidGlassToggle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _animationController.animateTo(
        widget.value ? 1.0 : 0.0,
        duration: AppDurations.fast,
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleToggle() {
    widget.onChanged(!widget.value);
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(50),
      child: FakeGlass(
        shape: LiquidRoundedSuperellipse(borderRadius: 50),
        settings: AppColors.liquidGlassSettings,
        // dont change the gesture detector location, for the best ux experience its easiest if
        //its around the entire shape not just the 'buttons'
        child: GestureDetector(
          onTap: _handleToggle,
          child: Container(
            padding: const EdgeInsets.all(Spacing.sm),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(50),
              border: Border.all(
                color: CupertinoColors.systemGrey.withValues(alpha: 0.3),
                width: 0.5,
              ),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final segmentWidth = constraints.maxWidth / 2;
                
                return Stack(
                  children: [
                    AnimatedPositioned(
                      duration: AppDurations.slow,
                      curve: Curves.easeOutCubic,
                      left: widget.value ? segmentWidth : 0,
                      top: 0,
                      bottom: 0,
                      width: segmentWidth,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(40),
                        child: FakeGlass(
                          shape: LiquidRoundedSuperellipse(borderRadius: 40),
                          settings: AppColors.liquidGlassSettings,
                          child: DecoratedBox(
                            decoration: ShapeDecoration(
                              color: CupertinoColors.systemGrey6.withValues(alpha: 0.5),
                              shape: ContinuousRectangleBorder(
                                borderRadius: BorderRadius.circular(40),
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
                      ),
                    ),
                    // Toggle labels
                    Row(
                      children: [
                        Expanded(
                          child: _buildToggleLabel(
                            label: widget.inactiveLabel,
                            isActive: !widget.value,
                          ),
                        ),
                        Expanded(
                          child: _buildToggleLabel(
                            label: widget.activeLabel,
                            isActive: widget.value,
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildToggleLabel({
    required String label,
    required bool isActive,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.lg,
        vertical: Spacing.md,
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isActive
                ? CupertinoColors.label
                : CupertinoColors.secondaryLabel,
          ),
        ),
      ),
    );
  }
}

import 'dart:io';
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';
import 'package:provider/provider.dart';
import '../../../design/index.dart';
import '../../../state/providers/theme_provider.dart';

/// Floating liquid glass navigation bar with animated sliding selector
/// Matches the design with a capsule-shaped container with icons
class FloatingGlassNavBar extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<NavBarItem> items;

  const FloatingGlassNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  State<FloatingGlassNavBar> createState() => _FloatingGlassNavBarState();
}

class _FloatingGlassNavBarState extends State<FloatingGlassNavBar> 
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  int _previousIndex = 0;

  @override
  void initState() {
    super.initState();
    _previousIndex = widget.currentIndex;
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  void didUpdateWidget(FloatingGlassNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      _previousIndex = oldWidget.currentIndex;
      _animationController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        left: Spacing.xl,
        right: Spacing.xl,
        bottom: Spacing.xl,
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(100),
          boxShadow: [
            BoxShadow(
              color: CupertinoColors.black.withOpacity(0.15),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
            BoxShadow(
              color: CupertinoColors.white.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(100),
          child: FakeGlass(
            shape: LiquidRoundedSuperellipse(borderRadius: 100),
            settings: const LiquidGlassSettings(
              blur: 50,
              glassColor: Color(0x4DFFFFFF),
              lightIntensity: 2.0,
            ),
            child: SizedBox(
              height: 70,
              child: Stack(
                children: [
              // Animated liquid glass selector
              AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  final screenWidth = MediaQuery.of(context).size.width;
                  final navBarWidth = screenWidth - (Spacing.xl * 2);
                  final itemWidth = navBarWidth / widget.items.length;
                  
                  final double fromPosition = _previousIndex * itemWidth;
                  final double toPosition = widget.currentIndex * itemWidth;
                  final double currentPosition = 
                      fromPosition + (toPosition - fromPosition) * _animation.value;
                  
                  const inset = Spacing.xs;
                  return Positioned(
                    left: currentPosition + inset,
                    top: inset,
                    bottom: inset,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(100),
                      child: FakeGlass(
                        shape: LiquidRoundedSuperellipse(borderRadius: 100),
                        settings: const LiquidGlassSettings(
                          blur: 5,
                          glassColor: Color(0x268E8E93),
                          lightIntensity: 0.8,
                        ),
                        child: SizedBox(
                          width: itemWidth - inset * 2,
                          height: double.infinity,
                        ),
                      ),
                    ),
                  );
                },
              ),
              
              // Navigation items
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(
                  widget.items.length,
                  (index) => _buildNavItem(
                    context,
                    widget.items[index],
                    index,
                    widget.currentIndex == index,
                  ),
                ),
              ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    NavBarItem item,
    int index,
    bool isSelected,
  ) {
    final isDark = context.watch<ThemeProvider>().isDark;
    final isIPhone = Platform.isIOS;
    final iconSize = isIPhone ? 22.0 : 24.0;
    
    // Lighter grey for dark mode, regular grey for light mode
    final unselectedColor = isDark 
        ? CupertinoColors.systemGrey2 
        : CupertinoColors.systemGrey;
    
    return Expanded(
      child: GestureDetector(
        onTap: () => widget.onTap(index),
        behavior: HitTestBehavior.opaque,
        child: Container(
          margin: const EdgeInsets.symmetric(
            horizontal: Spacing.xs,
            vertical: Spacing.sm,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedScale(
                scale: isSelected ? 1.1 : 1.0,
                duration: const Duration(milliseconds: 200),
                child: item.icon(
                  fontSize: iconSize,
                  color: isSelected
                      ? CupertinoColors.activeBlue
                      : unselectedColor,
                ),
              ),
              const SizedBox(height: Spacing.xs),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: AppTypography.caption.copyWith(
                  color: isSelected
                      ? CupertinoColors.activeBlue
                      : unselectedColor,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
                child: Text(item.label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Data model for navigation bar items
class NavBarItem {
  final Widget Function({double fontSize, Color? color, FontWeight? fontWeight}) icon;
  final String label;

  const NavBarItem({
    required this.icon,
    required this.label,
  });
}

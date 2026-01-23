import 'package:flutter/material.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

/// Liquid glass container widget for glassmorphism effects using liquid_glass_renderer
class AppGlassContainer extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final double blur;
  final Color color;
  final double borderWidth;
  final Color borderColor;

  const AppGlassContainer({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.borderRadius = 24,
    this.blur = 10,
    this.color = const Color(0x33FFFFFF),
    this.borderWidth = 1.5,
    this.borderColor = const Color(0x44FFFFFF),
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: FakeGlass(
        shape: LiquidRoundedSuperellipse(borderRadius: borderRadius),
        settings: LiquidGlassSettings(
          blur: blur,
          glassColor: color,
          lightIntensity: 1.5,
        ),
        child: Container(
          width: width,
          height: height,
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}

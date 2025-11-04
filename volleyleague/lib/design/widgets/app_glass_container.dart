import 'dart:ui';
import 'package:flutter/material.dart';

/// Liquid glass container widget for glassmorphism effects using BackdropFilter
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
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          width: width,
          height: height,
          padding: padding,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: borderColor,
              width: borderWidth,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

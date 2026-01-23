import 'package:flutter/material.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

/// Brand and semantic colors for the app.
class AppColors {
  AppColors._();

  // Brand
  static const Color primary = Color(0xFF5E35B1); // Deep Purple 700
  static const Color secondary = Color(0xFF00ACC1); // Cyan 600

  // Semantic
  static const Color success = Color(0xFF2E7D32);
  static const Color warning = Color(0xFFF9A825);
  static const Color error = Color(0xFFC62828);

  // Backgrounds
  static const Color background = Color(0xFFF7F7FA);
  static const Color surface = Colors.white;

  // liquid glass
  static const LiquidGlassSettings liquidGlassSettings = LiquidGlassSettings(
          blur: 10,
          glassColor: Color(0x80F2F2F7),
          lightIntensity: 1.2,
        );
}

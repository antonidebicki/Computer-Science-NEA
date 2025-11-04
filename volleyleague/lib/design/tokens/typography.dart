import 'package:flutter/material.dart';

/// Typography tokens and common text styles.
class AppTypography {
  AppTypography._();

  static const String fontFamily = '.SF Pro Text';
  static const List<String> fontFamilyFallback = [
    '.SF Pro Display',
    'SF Pro Text',
    'SF Pro Display',
    'San Francisco',
    'Helvetica Neue',
    'Helvetica',
    'Arial',
    'sans-serif',
  ];

  // Apple HIG: Large Title (34), Title1 (28), Title2 (22), Title3 (20), Headline (17), Body (17), Callout (16), Subhead (15), Footnote (13), Caption (12)
  static const TextStyle largeTitle = TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fontFamilyFallback,
    fontSize: 34,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.41,
    height: 1.2,
  );
  static const TextStyle title1 = TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fontFamilyFallback,
    fontSize: 28,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.36,
    height: 1.22,
  );
  static const TextStyle title2 = TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fontFamilyFallback,
    fontSize: 22,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.35,
    height: 1.22,
  );
  static const TextStyle title3 = TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fontFamilyFallback,
    fontSize: 20,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.38,
    height: 1.22,
  );
  static const TextStyle headline = TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fontFamilyFallback,
    fontSize: 17,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.41,
    height: 1.25,
  );
  static const TextStyle body = TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fontFamilyFallback,
    fontSize: 17,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.41,
    height: 1.47,
  );
  static const TextStyle callout = TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fontFamilyFallback,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.32,
    height: 1.44,
  );
  static const TextStyle subhead = TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fontFamilyFallback,
    fontSize: 15,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.24,
    height: 1.33,
  );
  static const TextStyle footnote = TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fontFamilyFallback,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.08,
    height: 1.23,
  );
  static const TextStyle caption = TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fontFamilyFallback,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.16,
  );
}

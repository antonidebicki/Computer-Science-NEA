import 'package:flutter/cupertino.dart';

/// Reusable text styles for consistent styling throughout the app
class AppTextStyles {
  AppTextStyles._();

  // Active blue text styles with various weights
  static const TextStyle activeBlue = TextStyle(
    color: CupertinoColors.activeBlue,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle activeBlueBold = TextStyle(
    color: CupertinoColors.activeBlue,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle activeBlueRegular = TextStyle(
    color: CupertinoColors.activeBlue,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle activeBlueSemibold = TextStyle(
    color: CupertinoColors.activeBlue,
    fontWeight: FontWeight.w600,
  );

  // White text styles for buttons and overlays
  static const TextStyle whiteBold = TextStyle(
    color: CupertinoColors.white,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle whiteSemibold = TextStyle(
    color: CupertinoColors.white,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle whiteRegular = TextStyle(
    color: CupertinoColors.white,
    fontWeight: FontWeight.w400,
  );

  // Grey text styles for secondary content
  static const TextStyle greyRegular = TextStyle(
    color: CupertinoColors.systemGrey,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle greySemibold = TextStyle(
    color: CupertinoColors.systemGrey,
    fontWeight: FontWeight.w600,
  );

  // Black text styles
  static const TextStyle blackBold = TextStyle(
    color: CupertinoColors.black,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle blackSemibold = TextStyle(
    color: CupertinoColors.black,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle blackRegular = TextStyle(
    color: CupertinoColors.black,
    fontWeight: FontWeight.w400,
  );
}

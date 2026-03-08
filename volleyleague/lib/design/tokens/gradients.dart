import 'package:flutter/cupertino.dart';

class AppGradients {
  AppGradients._();

  // static LinearGradient backgroundGradient(BuildContext context, {bool isDark = false}) {
  //   return LinearGradient(
  //     begin: Alignment.topLeft,
  //     end: Alignment.bottomRight,
  //     colors: isDark
  //         ? [
  //             CupertinoColors.systemBlue.withValues(alpha: 0.4),
  //             CupertinoColors.systemPurple.withValues(alpha: 0.4),
  //           ]
  //         : [
  //             CupertinoColors.systemBlue.darkColor.withValues(alpha: 0.3),
  //             CupertinoColors.systemPurple.darkColor.withValues(alpha: 0.3),
  //           ],
  //   );
  // }
  // i want to see how to app looks with a more professional colour palette
  // still keeping gradient functionality though
  static LinearGradient backgroundGradient(
    BuildContext context, {
    bool isDark = false,
  }) {
    return LinearGradient(
      colors: [
        isDark
            ? const Color(0xFF000000)
            : const Color(0xFFF7F5F2),
        isDark
            ? const Color(0xFF000000)
            : const Color(0xFFF7F5F2),
      ],
    );
  }
}

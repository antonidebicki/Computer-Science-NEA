import 'package:flutter/cupertino.dart';

class AppGradients {
  AppGradients._();

  static LinearGradient backgroundGradient(BuildContext context, {bool isDark = false}) {
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: isDark
          ? [
              CupertinoColors.systemBlue.withValues(alpha: 0.4),
              CupertinoColors.systemPurple.withValues(alpha: 0.4),
            ]
          : [
              CupertinoColors.systemBlue.darkColor.withValues(alpha: 0.3),
              CupertinoColors.systemPurple.darkColor.withValues(alpha: 0.3),
            ],
    );
  }
}

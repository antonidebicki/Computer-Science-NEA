import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../index.dart';
import '../../state/providers/theme_provider.dart';

/// Reusable layout wrapper for authentication screens (login, register, etc.)
/// 
/// This widget provides consistent styling across all auth screens:
/// - Gradient background that responds to light/dark theme
/// - Centered glass-morphism container with blur effect
/// - SafeArea handling for notches and system UI
/// - Automatic scrolling for keyboard/small screens
/// - Standard padding and border radius
/// 
/// Usage:
/// ```dart
/// return AuthScreenLayout(
///   child: Column(
///     children: [
///       // Your form fields, buttons, etc.
///     ],
///   ),
/// );
/// ```
class AuthScreenLayout extends StatelessWidget {
  final Widget child;
  final double? containerWidth;
  final EdgeInsetsGeometry? containerPadding;

  const AuthScreenLayout({
    super.key,
    required this.child,
    this.containerWidth = 370,
    this.containerPadding = const EdgeInsets.symmetric(
      vertical: Spacing.xxl,
      horizontal: Spacing.xl,
    ),
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;

    return CupertinoPageScaffold(
      child: Container(
        decoration: BoxDecoration(
          gradient: AppGradients.backgroundGradient(context, isDark: isDark),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: AppGlassContainer(
                width: containerWidth,
                padding: containerPadding,
                borderRadius: Spacing.xl,
                blur: Spacing.xl,
                color: CupertinoColors.white.withValues(alpha: 0.25),
                borderColor: CupertinoColors.white.withValues(alpha: 0.3),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

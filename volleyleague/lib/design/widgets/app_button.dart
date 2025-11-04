import 'dart:ui';
import 'package:flutter/cupertino.dart';

/// Primary filled button with liquid glass effect (Cupertino style)
class AppPrimaryButton extends StatelessWidget {
  const AppPrimaryButton({super.key, required this.onPressed, required this.child});

  final VoidCallback? onPressed;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  CupertinoColors.activeBlue.withOpacity(0.8),
                  CupertinoColors.activeBlue.withOpacity(0.6),
                ],
              ),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: CupertinoColors.white.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: CupertinoButton(
              padding: const EdgeInsets.symmetric(vertical: 16),
              onPressed: onPressed,
              child: DefaultTextStyle.merge(
                style: const TextStyle(
                  color: CupertinoColors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 17,
                ),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Tonal/ghost button with liquid glass effect (Cupertino style, light background)
class AppTonalButton extends StatelessWidget {
  const AppTonalButton({super.key, required this.onPressed, required this.child});

  final VoidCallback? onPressed;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: CupertinoColors.systemGrey6.withOpacity(0.6),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: CupertinoColors.white.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: CupertinoButton(
              padding: const EdgeInsets.symmetric(vertical: 16),
              onPressed: onPressed,
              child: DefaultTextStyle.merge(
                style: const TextStyle(
                  color: CupertinoColors.activeBlue,
                  fontWeight: FontWeight.w600,
                  fontSize: 17,
                ),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Text/ghost button (Cupertino style, no fill)
class AppTextButtonX extends StatelessWidget {
  const AppTextButtonX({super.key, required this.onPressed, required this.child});

  final VoidCallback? onPressed;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onPressed,
      child: child, minimumSize: Size(0, 0),
    );
  }
}

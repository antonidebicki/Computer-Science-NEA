import 'package:flutter/cupertino.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';
import '../tokens/spacing.dart';

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
        child: FakeGlass(
          shape: LiquidRoundedSuperellipse(borderRadius: 30),
          settings: const LiquidGlassSettings(
            blur: 10,
            glassColor: Color(0x80007AFF),
            lightIntensity: 1.5,
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  CupertinoColors.activeBlue.withValues(alpha: 0.8),
                  CupertinoColors.activeBlue.withValues(alpha: 0.6),
                ],
              ),
              borderRadius: BorderRadius.circular(30),
            ),
            child: CupertinoButton(
              padding: const EdgeInsets.symmetric(vertical: Spacing.lg),
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
        child: FakeGlass(
          shape: LiquidRoundedSuperellipse(borderRadius: 30),
          settings: const LiquidGlassSettings(
            blur: 10,
            glassColor: Color(0x99F2F2F7),
            lightIntensity: 1.2,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: CupertinoColors.systemGrey6.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(30),
            ),
            child: CupertinoButton(
              padding: const EdgeInsets.symmetric(vertical: Spacing.lg),
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
      onPressed: onPressed, minimumSize: Size(0, 0),
      child: child,
    );
  }
}

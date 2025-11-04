import 'package:flutter/material.dart';

/// Primary elevated button
class AppPrimaryButton extends StatelessWidget {
  const AppPrimaryButton({super.key, required this.onPressed, required this.child});

  final VoidCallback? onPressed;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(onPressed: onPressed, child: child);
  }
}

/// Tonal/filled button
class AppTonalButton extends StatelessWidget {
  const AppTonalButton({super.key, required this.onPressed, required this.child});

  final VoidCallback? onPressed;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return FilledButton.tonal(onPressed: onPressed, child: child);
  }
}

/// Text/ghost button
class AppTextButtonX extends StatelessWidget {
  const AppTextButtonX({super.key, required this.onPressed, required this.child});

  final VoidCallback? onPressed;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TextButton(onPressed: onPressed, child: child);
  }
}

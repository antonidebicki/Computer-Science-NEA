import 'package:flutter/cupertino.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';
import '../tokens/spacing.dart';

/// Standard Cupertino text field
class AppTextField extends StatelessWidget {
  final TextEditingController controller;
  final String? placeholder;
  final TextInputType? keyboardType;
  final Widget? suffix;
  
  const AppTextField({
    super.key,
    required this.controller,
    this.placeholder,
    this.keyboardType,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoTextField(
      controller: controller,
      placeholder: placeholder,
      keyboardType: keyboardType,
      padding: const EdgeInsets.symmetric(vertical: Spacing.lg, horizontal: Spacing.lg),
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey6,
        borderRadius: BorderRadius.circular(10),
      ),
      suffix: suffix,
    );
  }
}

/// Password text field with show/hide toggle
class AppPasswordField extends StatefulWidget {
  final TextEditingController controller;
  final String? placeholder;
  
  const AppPasswordField({
    super.key,
    required this.controller,
    this.placeholder,
  });

  @override
  State<AppPasswordField> createState() => _AppPasswordFieldState();
}

class _AppPasswordFieldState extends State<AppPasswordField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return CupertinoTextField(
      controller: widget.controller,
      placeholder: widget.placeholder ?? 'Password',
      obscureText: _obscure,
      padding: const EdgeInsets.symmetric(vertical: Spacing.lg, horizontal: Spacing.lg),
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey6,
        borderRadius: BorderRadius.circular(10),
      ),
      suffix: GestureDetector(
        onTap: () => setState(() => _obscure = !_obscure),
        child: Padding(
          padding: const EdgeInsets.only(right: Spacing.sm),
          child: Icon(
            _obscure ? CupertinoIcons.eye_slash : CupertinoIcons.eye,
            color: CupertinoColors.systemGrey,
          ),
        ),
      ),
    );
  }
}

/// Liquid glass text field with glassmorphism effects
class AppLiquidGlassTextField extends StatelessWidget {
  final TextEditingController controller;
  final String? placeholder;
  final TextInputType? keyboardType;
  final Widget? suffix;
  final double borderRadius;
  final double blur;
  final Color glassColor;
  
  const AppLiquidGlassTextField({
    super.key,
    required this.controller,
    this.placeholder,
    this.keyboardType,
    this.suffix,
    this.borderRadius = 16,
    this.blur = 8,
    this.glassColor = const Color(0x22FFFFFF),
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: FakeGlass(
        shape: LiquidRoundedSuperellipse(borderRadius: borderRadius),
        settings: LiquidGlassSettings(
          blur: blur,
          glassColor: glassColor,
          lightIntensity: 1.5,
        ),
        child: CupertinoTextField(
          controller: controller,
          placeholder: placeholder,
          keyboardType: keyboardType,
          padding: const EdgeInsets.symmetric(vertical: Spacing.lg, horizontal: Spacing.lg),
          decoration: const BoxDecoration(
            color: Color(0x00000000), // Transparent to show glass effect
          ),
          suffix: suffix,
        ),
      ),
    );
  }
}

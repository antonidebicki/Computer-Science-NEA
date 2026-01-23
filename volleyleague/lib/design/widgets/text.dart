import 'package:flutter/material.dart';
import '../tokens/typography.dart';

/// Standard text widget using predefined styles.
class AppText extends StatelessWidget {
  const AppText(this.text, {super.key, this.style, this.textAlign});

  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: style ?? AppTypography.body,
      textAlign: textAlign,
    );
  }
}

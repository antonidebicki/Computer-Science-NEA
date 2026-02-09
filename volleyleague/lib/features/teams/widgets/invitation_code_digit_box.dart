import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import '../../../design/index.dart';

/// old 2fa apple style bc i rly like the design from ios 6 but w liquid glass
class InvitationCodeDigitBox extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final FocusNode? nextFocusNode;
  final FocusNode? previousFocusNode;
  final VoidCallback? onChanged;
  final ValueChanged<String>? onPaste;

  const InvitationCodeDigitBox({
    super.key,
    required this.controller,
    required this.focusNode,
    this.nextFocusNode,
    this.previousFocusNode,
    this.onChanged,
    this.onPaste,
  });

  @override
  State<InvitationCodeDigitBox> createState() => _InvitationCodeDigitBoxState();
}

class _InvitationCodeDigitBoxState extends State<InvitationCodeDigitBox> {
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _hasText = widget.controller.text.isNotEmpty;
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    setState(() {
      _hasText = widget.controller.text.isNotEmpty;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: AppGlassContainer(
        padding: const EdgeInsets.all(Spacing.sm),
        borderRadius: 12,
        child: Center(
          child: CupertinoTextField(
            controller: widget.controller,
            focusNode: widget.focusNode,
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
            ],
            onChanged: (value) {
              if (value.length > 1) {
                widget.onPaste?.call(value);
                return;
              }
              if (value.length == 1) {
                widget.onChanged?.call();
                widget.nextFocusNode?.requestFocus();
              }
              widget.onChanged?.call();
            },
            onSubmitted: (_) {
              widget.nextFocusNode?.requestFocus();
            },
            decoration: const BoxDecoration(),
            padding: const EdgeInsets.symmetric(horizontal: 2),
            prefix: _hasText ? const SizedBox(width: 4.5) : null,
            style: AppTypography.headline.copyWith(fontSize: 24),
            placeholder: '0',
            placeholderStyle: TextStyle(
              color: CupertinoColors.placeholderText.resolveFrom(context),
              fontSize: 24,
            ),
            cursorColor: CupertinoColors.activeBlue,
            cursorHeight: 28,
            cursorWidth: 3,
            cursorRadius: const Radius.circular(2),
          ),
        ),
      ),
    );
  }
}

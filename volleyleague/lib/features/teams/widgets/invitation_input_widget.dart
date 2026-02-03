import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import '../../../design/index.dart';

/// liquid glass box for a single digit
class InvitationCodeDigitBox extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final FocusNode? nextFocusNode;
  final FocusNode? previousFocusNode;
  final VoidCallback? onChanged;

  const InvitationCodeDigitBox({
    super.key,
    required this.controller,
    required this.focusNode,
    this.nextFocusNode,
    this.previousFocusNode,
    this.onChanged,
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
              LengthLimitingTextInputFormatter(1),
            ],
            maxLength: 1,
            onChanged: (value) {
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

class InvitationInputWidget extends StatefulWidget {
  final int teamId;
  final Function(String invitationCode) onSendInvitation;

  const InvitationInputWidget({
    super.key,
    required this.teamId,
    required this.onSendInvitation,
  });

  @override
  State<InvitationInputWidget> createState() => _InvitationInputWidgetState();
}

class _InvitationInputWidgetState extends State<InvitationInputWidget> {
  late List<TextEditingController> _digitControllers;
  late List<FocusNode> _focusNodes;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    _digitControllers = List.generate(6, (_) => TextEditingController());
    _focusNodes = List.generate(6, (_) => FocusNode());
  }

  @override
  void dispose() {
    for (var controller in _digitControllers) {
      controller.dispose();
    }
    for (var focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  String _getInvitationCode() {
    if (_digitControllers.isEmpty) {
      _initializeControllers();
    }
    return _digitControllers.map((c) => c.text).join();
  }

  void _handleSendInvitation() {
    final code = _getInvitationCode();

    if (code.length != 6 || !RegExp(r'^[0-9]{6}$').hasMatch(code)) {
      _showErrorDialog('Invalid Code', 'Please enter a valid 6-digit code');
      return;
    }

    setState(() => _isLoading = true);

    try {
      widget.onSendInvitation(code);
      _clearAllDigits();
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _clearAllDigits() {
    for (var controller in _digitControllers) {
      controller.clear();
    }
    _focusNodes[0].requestFocus();
  }

  void _showErrorDialog(String title, String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppGlassContainer(
      padding: const EdgeInsets.all(Spacing.lg),
      borderRadius: 20,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Invite Players', style: AppTypography.headline),
          const SizedBox(height: Spacing.sm),
          Text(
            'Enter a player\'s 6-digit invitation code to invite them to your team',
            style: AppTypography.callout.copyWith(
              color: CupertinoColors.secondaryLabel.resolveFrom(context),
            ),
          ),
          const SizedBox(height: Spacing.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(6, (index) {
              if (_digitControllers.isEmpty) {
                _initializeControllers();
              }
              return Flexible(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: index < 6 ? Spacing.xs : 0,
                  ),
                  child: InvitationCodeDigitBox(
                    controller: _digitControllers[index],
                    focusNode: _focusNodes[index],
                    nextFocusNode: index < 5 ? _focusNodes[index + 1] : null,
                    previousFocusNode: index > 0
                        ? _focusNodes[index - 1]
                        : null,
                    onChanged: () {
                      setState(() {});
                    },
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: Spacing.lg),
          SizedBox(
            width: double.infinity,
            child: CupertinoButton.filled(
              onPressed: _isLoading ? null : _handleSendInvitation,
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CupertinoActivityIndicator(radius: 8),
                    )
                  : const Text('Send Invitation'),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../design/index.dart';
import 'error_notification_widget.dart';
import 'invitation_code_digit_box.dart';

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
  // dont remove the field for some reason the error message shows its unused but its necessary
  // vs code is js bugged
  String? _errorMessage;

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

  void _showError(String title, String message) {
    setState(() => _errorMessage = message);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: ErrorNotificationWidget(
          title: title,
          message: message,
          onDismiss: () {
            setState(() => _errorMessage = null);
          },
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// make user friendly. i should change these to allow for more exceptions later but good enough for 50h nea
  String _parseErrorMessage(dynamic error) {
    final errorString = error.toString();

    if (errorString.contains('Invalid or expired invitation code')) {
      return 'This invitation code is invalid or has expired, please check the code and try again.';
    }

    if (errorString.contains('already') || errorString.contains('already in team')) {
      return 'This player is already part of this team.';
    }

    if (errorString.contains('not found')) {
      return 'Invitation code not found. Please check and try again.';
    }

    return 'Something went wrong. Please try again.';
  }

  Future<void> _handleSendInvitation() async {
    final code = _getInvitationCode();

    if (code.length != 6 || !RegExp(r'^[0-9]{6}$').hasMatch(code)) {
      _showError(
        'Incomplete Code',
        'Please enter all 6 digits before submitting',
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await widget.onSendInvitation(code);
      if (mounted) {
        _clearAllDigits();
      }
    } catch (error) {
      if (mounted) {
        final userFriendlyMessage = _parseErrorMessage(error);
        _showError(
          'Invitation Failed',
          userFriendlyMessage,
        );
      }
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

  void _clearAllDigitsSilently() {
    for (var controller in _digitControllers) {
      controller.clear();
    }
  }

  void _applyPastedCode(String value, int startIndex) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) {
      return;
    }

    final totalBoxes = _digitControllers.length;
    final fillFromStart = digits.length >= totalBoxes;
    final baseIndex = fillFromStart ? 0 : startIndex;

    if (fillFromStart) {
      _clearAllDigitsSilently();
    }

    for (var i = 0; i < digits.length; i++) {
      final targetIndex = baseIndex + i;
      if (targetIndex >= totalBoxes) {
        break;
      }
      _digitControllers[targetIndex].text = digits[i];
    }

    final focusIndex = (baseIndex + digits.length).clamp(0, totalBoxes - 1);
    _focusNodes[focusIndex].requestFocus();
    setState(() {});
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
                    onPaste: (value) {
                      _applyPastedCode(value, index);
                    },
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

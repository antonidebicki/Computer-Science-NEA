import 'package:flutter/cupertino.dart';
import '../../../design/index.dart';

class LeagueInvitationInputWidget extends StatefulWidget {
  final int? leagueId;
  final int? seasonId;
  final String? leagueName;
  final String? seasonName;
  final Future<void> Function({
    required int leagueId,
    required int seasonId,
    required String invitationCode,
  }) onSendInvitation;

  const LeagueInvitationInputWidget({
    super.key,
    required this.leagueId,
    required this.seasonId,
    required this.leagueName,
    required this.seasonName,
    required this.onSendInvitation,
  });

  @override
  State<LeagueInvitationInputWidget> createState() =>
      _LeagueInvitationInputWidgetState();
}

class _LeagueInvitationInputWidgetState
    extends State<LeagueInvitationInputWidget> {
  final _invitationCodeController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _invitationCodeController.dispose();
    super.dispose();
  }

  Future<void> _handleSend() async {
    final leagueId = widget.leagueId;
    final seasonId = widget.seasonId;
    final invitationCode = _invitationCodeController.text.trim();

    if (leagueId == null || seasonId == null) {
      _showError('Please select a league with an active season.');
      return;
    }

    if (!RegExp(r'^\d{6}$').hasMatch(invitationCode)) {
      _showError('Please enter a valid 6-digit team invitation code.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await widget.onSendInvitation(
        leagueId: leagueId,
        seasonId: seasonId,
        invitationCode: invitationCode,
      );
      _invitationCodeController.clear();
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Invalid Input'),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Invite Team to League',
            style: AppTypography.headline.copyWith(
              color: CupertinoColors.label,
            ),
          ),
          const SizedBox(height: Spacing.sm),
          Text(
            'Use the 6-digit team code to invite a team into the current season.',
            style: AppTypography.callout.copyWith(
              color: CupertinoColors.secondaryLabel,
            ),
          ),
          const SizedBox(height: Spacing.md),
          _buildInfoRow('League', widget.leagueName ?? 'Not selected'),
          const SizedBox(height: Spacing.xs),
          _buildInfoRow('Season', widget.seasonName ?? 'No active season'),
          const SizedBox(height: Spacing.lg),
          _buildTextField(
            controller: _invitationCodeController,
            label: 'Team Invitation Code',
          ),
          const SizedBox(height: Spacing.lg),
          SizedBox(
            width: double.infinity,
            child: CupertinoButton.filled(
              onPressed: _isLoading ? null : _handleSend,
              child: _isLoading
                  ? const CupertinoActivityIndicator(radius: 8)
                  : const Text('Send League Invitation'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.caption.copyWith(
            color: CupertinoColors.secondaryLabel,
          ),
        ),
        const SizedBox(height: Spacing.xs),
        AppGlassContainer(
          padding: const EdgeInsets.symmetric(
            horizontal: Spacing.md,
            vertical: Spacing.sm,
          ),
          borderRadius: 12,
          child: CupertinoTextField(
            controller: controller,
            placeholder: label,
            keyboardType: TextInputType.number,
            decoration: const BoxDecoration(),
            style: AppTypography.body,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      children: [
        Text(
          '$label: ',
          style: AppTypography.caption.copyWith(
            color: CupertinoColors.secondaryLabel,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: AppTypography.caption.copyWith(
              color: CupertinoColors.label,
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

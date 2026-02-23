import 'package:flutter/cupertino.dart';
import '../../../core/models/invitation.dart';
import '../../../design/index.dart';

class LeagueInvitationInputWidget extends StatefulWidget {
  final int? leagueId;
  final int? seasonId;
  final String? leagueName;
  final String? seasonName;
  final List<LeagueJoinRequest> invitedTeams;
  final List<Map<String, dynamic>> seasonTeams;
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
    required this.invitedTeams,
    this.seasonTeams = const [],
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
    final invitedTeamsForSeason = widget.invitedTeams
        .where((inv) {
          final status = inv.status.toUpperCase();
          final isInvited = status == 'PENDING' || status == 'ACCEPTED';
          if (!isInvited) {
            return false;
          }

          if (widget.seasonId == null) {
            return true;
          }

          return inv.seasonId == widget.seasonId;
        })
        .toList();

    final displayedTeams = widget.seasonTeams.isNotEmpty
        ? widget.seasonTeams
            .map(
              (team) =>
                  (team['team_name'] as String?) ??
                  'Team ${team['team_id']}',
            )
            .toList()
        : invitedTeamsForSeason
            .map((team) => team.teamName ?? 'Team ${team.teamId}')
            .toList();

    return AppGlassContainer(
      padding: const EdgeInsets.all(Spacing.lg),
      borderRadius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Invite Team to a Season',
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
          _buildTextFieldWithIcon(
            controller: _invitationCodeController,
            label: 'Team Invitation Code',
          ),
          if (displayedTeams.isNotEmpty) ...[
            const SizedBox(height: Spacing.md),
            Text(
              widget.seasonTeams.isNotEmpty
                  ? 'Teams in this season (${displayedTeams.length})'
                  : 'Teams invited to this season (${displayedTeams.length})',
              style: AppTypography.caption.copyWith(
                color: CupertinoColors.secondaryLabel,
              ),
            ),
            const SizedBox(height: Spacing.sm),
            ListView.separated(
              padding: EdgeInsets.symmetric(vertical: Spacing.sm),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: displayedTeams.length,
              separatorBuilder: (_, __) => const SizedBox(height: Spacing.sm),
              itemBuilder: (context, index) {
                final teamName = displayedTeams[index];
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Spacing.md,
                    vertical: Spacing.sm,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: CupertinoColors.systemGreen.withOpacity(0.3),
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(8),
                    color: CupertinoColors.systemGreen.withOpacity(0.05),
                  ),
                  child: Text(
                    teamName,
                    style: AppTypography.body.copyWith(
                      color: CupertinoColors.label,
                    ),
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTextFieldWithIcon({
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
          padding: EdgeInsets.zero,
          borderRadius: 12,
          child: Row(
            children: [
              Expanded(
                child: CupertinoTextField(
                  controller: controller,
                  placeholder: label,
                  keyboardType: TextInputType.number,
                  decoration: const BoxDecoration(),
                  style: AppTypography.body,
                  padding: const EdgeInsets.symmetric(
                    horizontal: Spacing.md,
                    vertical: Spacing.sm,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: Spacing.xs),
                child: CupertinoButton(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Spacing.sm,
                    vertical: Spacing.xs,
                  ),
                  onPressed: _isLoading ? null : _handleSend,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CupertinoActivityIndicator(radius: 8),
                        )
                      : const Icon(
                          CupertinoIcons.paperplane_fill,
                          size: 18,
                          color: CupertinoColors.activeBlue,
                        ),
                ),
              ),
            ],
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

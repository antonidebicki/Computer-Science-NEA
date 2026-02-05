import 'package:flutter/cupertino.dart';
import '../../../core/models/invitation.dart';
import '../../../design/index.dart';

class LeaguePendingInvitationsWidget extends StatefulWidget {
  final List<LeagueJoinRequest> pendingInvitations;
  final Function(int) onCancelInvitation;

  const LeaguePendingInvitationsWidget({
    super.key,
    required this.pendingInvitations,
    required this.onCancelInvitation,
  });

  @override
  State<LeaguePendingInvitationsWidget> createState() =>
      _LeaguePendingInvitationsWidgetState();
}

class _LeaguePendingInvitationsWidgetState
    extends State<LeaguePendingInvitationsWidget> {
  bool _isExpanded = true;

  @override
  Widget build(BuildContext context) {
    final onlyPending = widget.pendingInvitations
        .where((inv) => inv.status.toLowerCase() == 'pending')
        .toList();

    if (onlyPending.isEmpty) {
      return const SizedBox.shrink();
    }

    return AppGlassContainer(
      padding: const EdgeInsets.all(Spacing.lg),
      borderRadius: 20,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CupertinoButton(
            padding: const EdgeInsets.symmetric(vertical: Spacing.xs),
            onPressed: () {
              setState(() => _isExpanded = !_isExpanded);
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Pending League Invitations (${onlyPending.length})',
                  style: AppTypography.headline,
                ),
                Icon(
                  _isExpanded
                      ? CupertinoIcons.chevron_up
                      : CupertinoIcons.chevron_down,
                  color: CupertinoColors.label.resolveFrom(context),
                ),
              ],
            ),
          ),
          if (_isExpanded) ...[
            const SizedBox(height: Spacing.sm),
            ListView.separated(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: onlyPending.length,
              separatorBuilder: (_, __) => const SizedBox(height: Spacing.md),
              itemBuilder: (context, index) {
                final invitation = onlyPending[index];
                return _InvitationCard(
                  invitation: invitation,
                  onCancel: () =>
                      widget.onCancelInvitation(invitation.joinRequestId),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}

class _InvitationCard extends StatelessWidget {
  final LeagueJoinRequest invitation;
  final VoidCallback onCancel;

  const _InvitationCard({
    required this.invitation,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return AppGlassContainer(
      padding: const EdgeInsets.all(Spacing.md),
      borderRadius: 12,
      blur: 8,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${invitation.teamName ?? 'Team ${invitation.teamId}'} → ${invitation.leagueName ?? 'League ${invitation.leagueId}'}',
                  style: AppTypography.body,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: Spacing.xs),
                Text(
                  'Season: ${invitation.seasonName ?? invitation.seasonId}',
                  style: AppTypography.caption.copyWith(
                    color: CupertinoColors.secondaryLabel.resolveFrom(context),
                  ),
                ),
                const SizedBox(height: Spacing.xs),
                Text(
                  'Status: ${invitation.status}',
                  style: AppTypography.caption.copyWith(
                    color: _getStatusColor(invitation.status),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: Spacing.md),
          CupertinoButton(
            padding: const EdgeInsets.symmetric(
              horizontal: Spacing.md,
              vertical: Spacing.sm,
            ),
            onPressed: onCancel,
            child: const Text(
              'Cancel',
              style: TextStyle(color: CupertinoColors.systemRed),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return CupertinoColors.systemOrange;
      case 'accepted':
        return CupertinoColors.systemGreen;
      case 'rejected':
        return CupertinoColors.systemRed;
      default:
        return CupertinoColors.label;
    }
  }
}

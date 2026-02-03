import 'package:flutter/cupertino.dart';
import '../../../core/models/invitation.dart';
import '../../../design/index.dart';

class PendingInvitationsWidget extends StatefulWidget {
  final List<TeamJoinRequest> pendingInvitations;
  final Function(int) onCancelInvitation;

  const PendingInvitationsWidget({
    super.key,
    required this.pendingInvitations,
    required this.onCancelInvitation,
  });

  @override
  State<PendingInvitationsWidget> createState() =>
      _PendingInvitationsWidgetState();
}

class _PendingInvitationsWidgetState extends State<PendingInvitationsWidget> {
  bool _isExpanded = true;

  @override
  Widget build(BuildContext context) {
    // only pending invitations bc if not then you get a weird error when cancelling an accpented/rejected inv
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
                  'Pending Invitations (${onlyPending.length})',
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
  final TeamJoinRequest invitation;
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
                  'Sent to: ${invitation.username ?? 'User ID ${invitation.userId}'}',
                  style: AppTypography.body,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: Spacing.xs),
                Text(
                  'Status: ${invitation.status}',
                  style: AppTypography.caption.copyWith(
                    color: _getStatusColor(invitation.status),
                  ),
                ),
                const SizedBox(height: Spacing.xs),
                Text(
                  'Created: ${_formatDate(invitation.createdAt)}',
                  style: AppTypography.caption.copyWith(
                    color: CupertinoColors.secondaryLabel.resolveFrom(context),
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

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

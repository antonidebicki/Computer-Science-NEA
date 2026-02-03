import 'package:flutter/cupertino.dart';
import '../../design/index.dart';
import '../../core/models/invitation.dart';
import '../../services/repositories/repositories.dart';
import '../../services/api_client.dart';

class TeamRequestsSection extends StatefulWidget {
  final bool isDark;

  const TeamRequestsSection({
    super.key,
    required this.isDark,
  });

  @override
  State<TeamRequestsSection> createState() => _TeamRequestsSectionState();
}

class _TeamRequestsSectionState extends State<TeamRequestsSection> {
  bool _isExpanded = false;
  bool _isLoading = false;
  List<TeamJoinRequest> _requests = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    loadRequests();
  }

  Future<void> loadRequests() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final apiClient = ApiClient();
      final repository = InvitationRepository(apiClient);
      final requests = await repository.getMyInvitations();
      
      final now = DateTime.now();
      final pendingRequests = requests.where((request) {
        final isPending = request.status == 'PENDING';
        // expire in 2 days bc of what i wrote in report
        final isNotExpired = now.difference(request.createdAt).inDays < 2;
        return isPending && isNotExpired;
      }).toList();

      if (mounted) {
        setState(() {
          _requests = pendingRequests;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load requests: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _respondToRequest({
    required TeamJoinRequest request,
    required bool accept,
  }) async {
    try {
      final apiClient = ApiClient();
      final repository = InvitationRepository(apiClient);
      
      await repository.respondToInvitation(
        joinRequestId: request.joinRequestId,
        response: RespondToInvitationRequest(
          accept: accept,
          playerNumber: null, // can be added later if player wants to change or unsure
          isLibero: false,
        ),
      );

      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: Text(accept ? 'Request Accepted' : 'Request Rejected'),
            content: Text(
              accept
                  ? 'You have joined ${request.teamName ?? "the team"}!'
                  : 'You have declined the invitation.',
            ),
            actions: [
              CupertinoDialogAction(
                child: const Text('OK'),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        );

        await loadRequests();
      }
    } catch (e) {
      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Error'),
            content: Text('Failed to respond to request: $e'),
            actions: [
              CupertinoDialogAction(
                child: const Text('OK'),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppGlassContainer(
      padding: const EdgeInsets.all(Spacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      'Team Requests',
                      style: AppTypography.headline.copyWith(
                        color: CupertinoColors.label,
                      ),
                    ),
                    if (_requests.isNotEmpty) ...[
                      const SizedBox(width: Spacing.sm),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: Spacing.sm,
                          vertical: Spacing.xs,
                        ),
                        decoration: BoxDecoration(
                          color: CupertinoColors.systemRed.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${_requests.length}',
                          style: AppTypography.caption.copyWith(
                            color: CupertinoColors.systemRed,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Icon(
                  _isExpanded
                      ? CupertinoIcons.chevron_up
                      : CupertinoIcons.chevron_down,
                  color: CupertinoColors.activeBlue,
                  size: 20,
                ),
              ],
            ),
          ),

          // Expanded content
          if (_isExpanded) ...[
            const SizedBox(height: Spacing.md),
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(Spacing.lg),
                  child: CupertinoActivityIndicator(),
                ),
              )
            else if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.all(Spacing.md),
                child: Text(
                  _errorMessage!,
                  style: AppTypography.callout.copyWith(
                    color: CupertinoColors.systemRed,
                  ),
                ),
              )
            else if (_requests.isEmpty)
              Padding(
                padding: const EdgeInsets.all(Spacing.md),
                child: Text(
                  'No pending requests',
                  style: AppTypography.callout.copyWith(
                    color: CupertinoColors.secondaryLabel,
                  ),
                ),
              )
            else
              ..._requests.map((request) => _buildRequestItem(request)),
          ],
        ],
      ),
    );
  }

  Widget _buildRequestItem(TeamJoinRequest request) {
    return Container(
      margin: const EdgeInsets.only(bottom: Spacing.md),
      padding: const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(
        border: Border.all(
          color: CupertinoColors.systemGrey3.withValues(alpha: 0.3),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(Spacing.md),
        color: CupertinoColors.systemGrey6.withValues(alpha: 0.3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.teamName ?? 'Unknown Team',
                      style: AppTypography.subhead.copyWith(
                        color: CupertinoColors.label,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: Spacing.xs),
                    Text(
                      'Invited by ${request.invitedByUsername ?? 'Unknown'}',
                      style: AppTypography.caption.copyWith(
                        color: CupertinoColors.secondaryLabel,
                      ),
                    ),
                    const SizedBox(height: Spacing.xs),
                    Text(
                      _formatDate(request.createdAt),
                      style: AppTypography.caption.copyWith(
                        color: CupertinoColors.tertiaryLabel,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacing.md),

          Row(
            children: [
              Expanded(
                child: CupertinoButton(
                  padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
                  color: CupertinoColors.systemGreen,
                  borderRadius: BorderRadius.circular(Spacing.sm),
                  onPressed: () => _respondToRequest(
                    request: request,
                    accept: true,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        CupertinoIcons.check_mark,
                        size: 18,
                        color: CupertinoColors.white,
                      ),
                      const SizedBox(width: Spacing.xs),
                      Text(
                        'Accept',
                        style: AppTypography.subhead.copyWith(
                          color: CupertinoColors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: Spacing.md),
              Expanded(
                child: CupertinoButton(
                  padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
                  color: CupertinoColors.systemRed,
                  borderRadius: BorderRadius.circular(Spacing.sm),
                  onPressed: () => _respondToRequest(
                    request: request,
                    accept: false,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        CupertinoIcons.xmark,
                        size: 18,
                        color: CupertinoColors.white,
                      ),
                      const SizedBox(width: Spacing.xs),
                      Text(
                        'Reject',
                        style: AppTypography.subhead.copyWith(
                          color: CupertinoColors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'Just now';
        }
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '${weeks}w ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

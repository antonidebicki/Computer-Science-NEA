import 'package:flutter/cupertino.dart';
import '../../../design/index.dart';
import '../../../core/models/invitation.dart';
import '../../../services/api_client.dart';
import '../../../services/repositories/invitation_repository.dart';

class LeagueRequestsSection extends StatefulWidget {
  final bool isDark;

  const LeagueRequestsSection({
    super.key,
    required this.isDark,
  });

  @override
  State<LeagueRequestsSection> createState() => _LeagueRequestsSectionState();
}

class _LeagueRequestsSectionState extends State<LeagueRequestsSection> {
  bool _isExpanded = false;
  bool _isLoading = false;
  List<LeagueJoinRequest> _requests = [];
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
      final repository = InvitationRepository(ApiClient());
      final requests = await repository.getReceivedLeagueInvitations();

      final pending = requests
          .where((request) => request.status == 'PENDING')
          .toList();

      if (mounted) {
        setState(() {
          _requests = pending;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load league invitations: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _respondToRequest({
    required LeagueJoinRequest request,
    required bool accept,
  }) async {
    try {
      final repository = InvitationRepository(ApiClient());
      await repository.respondToLeagueInvitation(
        joinRequestId: request.joinRequestId,
        response: RespondToLeagueInvitationRequest(accept: accept),
      );

      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: Text(accept ? 'Invitation Accepted' : 'Invitation Rejected'),
            content: Text(
              accept
                  ? 'Your team has joined ${request.leagueName ?? "the league"}!'
                  : 'You have declined the league invitation.',
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
            content: Text('Failed to respond: $e'),
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
                      'League Invitations',
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
                  'No pending league invitations',
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

  Widget _buildRequestItem(LeagueJoinRequest request) {
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
          Text(
            request.leagueName ?? 'League ${request.leagueId}',
            style: AppTypography.subhead.copyWith(
              color: CupertinoColors.label,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: Spacing.xs),
          Text(
            'Season: ${request.seasonName ?? request.seasonId}',
            style: AppTypography.caption.copyWith(
              color: CupertinoColors.secondaryLabel,
            ),
          ),
          const SizedBox(height: Spacing.xs),
          Text(
            'Invited by ${request.invitedByUsername ?? 'Unknown'}',
            style: AppTypography.caption.copyWith(
              color: CupertinoColors.tertiaryLabel,
            ),
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
}

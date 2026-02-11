import 'package:flutter/cupertino.dart';
import '../../../core/models/invitation.dart';
import '../../../core/models/league.dart';
import '../../../core/models/season.dart';
import '../../../design/index.dart';
import 'league_invitation_input_widget.dart';
import 'league_pending_invitations_widget.dart';

class LeagueInvitationsSection extends StatelessWidget {
  final League league;
  final Season? currentSeason;
  final String? errorMessage;
  final bool isSeasonStarted;
  final bool isLoadingInvitations;
  final List<LeagueJoinRequest> pendingInvitations;
  final Future<void> Function({
    required int leagueId,
    required int seasonId,
    required String invitationCode,
  }) onSendInvitation;
  final void Function(int joinRequestId) onCancelInvitation;

  const LeagueInvitationsSection({
    super.key,
    required this.league,
    required this.currentSeason,
    required this.errorMessage,
    required this.isSeasonStarted,
    required this.isLoadingInvitations,
    required this.pendingInvitations,
    required this.onSendInvitation,
    required this.onCancelInvitation,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (errorMessage != null)
          Container(
            padding: const EdgeInsets.all(Spacing.md),
            margin: const EdgeInsets.only(bottom: Spacing.lg),
            decoration: BoxDecoration(
              color: CupertinoColors.systemRed.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: CupertinoColors.systemRed.withOpacity(0.3),
              ),
            ),
            child: Text(
              errorMessage!,
              style: AppTypography.callout.copyWith(
                color: CupertinoColors.systemRed,
              ),
            ),
          ),
        if (isSeasonStarted)
          AppGlassContainer(
            padding: const EdgeInsets.all(Spacing.md),
            borderRadius: 14,
            blur: 8,
            child: Text(
              'Invitations are locked once the season starts.',
              style: AppTypography.callout.copyWith(
                color: CupertinoColors.secondaryLabel,
              ),
            ),
          )
        else
          LeagueInvitationInputWidget(
            leagueId: league.leagueId,
            seasonId: currentSeason?.seasonId,
            leagueName: league.name,
            seasonName: currentSeason?.name,
            onSendInvitation: onSendInvitation,
          ),
        const SizedBox(height: Spacing.lg),
        if (isLoadingInvitations)
          const Center(
            child: CupertinoActivityIndicator(radius: 16),
          )
        else
          LeaguePendingInvitationsWidget(
            pendingInvitations: pendingInvitations,
            onCancelInvitation: onCancelInvitation,
          ),
      ],
    );
  }
}

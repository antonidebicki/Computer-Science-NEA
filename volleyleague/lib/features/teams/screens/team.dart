import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../design/index.dart';
import '../../../state/cubits/coach/team_data_cubit.dart';
import '../../../state/cubits/coach/team_data_state.dart';
import '../../../state/cubits/auth/auth_cubit.dart';
import '../../../state/cubits/auth/auth_state.dart';
import '../../../state/providers/theme_provider.dart';
import '../../../services/repositories/invitation_repository.dart';
import '../../../services/api_client.dart';
import '../../../core/models/invitation.dart';
import '../widgets/invitation_input_widget.dart';
import '../widgets/pending_invitations_widget.dart';
import '../widgets/players_list.dart';

class TeamScreen extends StatefulWidget {
  const TeamScreen({super.key});
  @override
  State<TeamScreen> createState() => _TeamScreenState();
}

class _TeamScreenState extends State<TeamScreen> {
  late InvitationRepository _invitationRepository;
  List<TeamJoinRequest> _pendingInvitations = [];
  bool _isLoadingInvitations = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _invitationRepository = InvitationRepository(ApiClient());
    _loadPendingInvitations();
  }

  Future<void> _loadPendingInvitations() async {
    setState(() => _isLoadingInvitations = true);
    try {
      final authState = context.read<AuthCubit>().state;
      if (authState is! AuthAuthenticated) {
        _showErrorMessage('Authentication required');
        return;
      }

      final invitations = await _invitationRepository.getSentInvitations();
      setState(() {
        _pendingInvitations = invitations;
        _errorMessage = null;
      });
    } catch (e) {
      _showErrorMessage('Failed to load invitations: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isLoadingInvitations = false);
      }
    }
  }

  Future<void> _handleSendInvitation(String invitationCode) async {
    try {
      final authState = context.read<AuthCubit>().state;
      if (authState is! AuthAuthenticated) {
        _showErrorMessage('Authentication required');
        return;
      }

      final teamDataState = context.read<TeamDataCubit>().state;
      if (teamDataState is! TeamDataLoaded ||
          teamDataState.coachedPlayers.isEmpty) {
        _showErrorMessage('No team data available');
        return;
      }


      //need this for the players widget to work
      final teamId = teamDataState.coachedPlayers.first.teamId;

      final request = CreateTeamInvitationRequest(
        teamId: teamId,
        invitationCode: invitationCode,
      );

      final newInvitation =
          await _invitationRepository.createTeamInvitation(request);

      setState(() {
        _pendingInvitations.add(newInvitation);
        _errorMessage = null;
      });

      _showSuccessMessage('Invitation sent successfully!');
    } catch (e) {
      final parsedError = _parseErrorMessage(e.toString());
      _showErrorMessage(parsedError);
    }
  }

  Future<void> _handleCancelInvitation(int joinRequestId) async {
    try {
      await _invitationRepository.deleteInvitation(joinRequestId);

      setState(() {
        _pendingInvitations
            .removeWhere((inv) => inv.joinRequestId == joinRequestId);
        _errorMessage = null;
      });

      _showSuccessMessage('Invitation cancelled');
    } catch (e) {
      _showErrorMessage('Failed to cancel invitation: ${e.toString()}');
    }
  }

  void _showErrorMessage(String message) {
    setState(() => _errorMessage = message);
    HapticFeedback.vibrate();
  }
  //parsing error messages - replaces the database errors as apiinuknown eerors are ugly and not easy to understand
  //also helps me in debugging
  String _parseErrorMessage(String errorString) {
    if (errorString.contains('Invalid or expired invitation code')) {
      return 'This invitation code is invalid or has expired. Please check the code and try again.';
    }
    if (errorString.contains('already') || errorString.contains('already in team')) {
      return 'This player is already part of the team.';
    }
    if (errorString.contains('not found')) {
      return 'Invitation code not found. Please check and try again.';
    }
    if (errorString.contains('Failed to send invitation:')) {
      return errorString.replaceFirst('Failed to send invitation: ', '').replaceFirst('ApiException(unknown): ', '');
    }
    return errorString.replaceFirst('ApiException(unknown): ', '').replaceFirst('Failed to send invitation: ', '');
  }

  void _showSuccessMessage(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Success'),
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

  int? _getCoachTeamId() {
    try {
      final teamDataState = context.read<TeamDataCubit>().state;
      if (teamDataState is TeamDataLoaded &&
          teamDataState.coachedPlayers.isNotEmpty) {
        return teamDataState.coachedPlayers.first.teamId;
      }
    } catch (e) {
      debugPrint('Error getting team ID: $e');
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;

    return CupertinoPageScaffold(
      child: Container(
        decoration: BoxDecoration(
          gradient: AppGradients.backgroundGradient(context, isDark: isDark),
        ),
        child: CustomScrollView(
          slivers: [
            CupertinoSliverRefreshControl(
              onRefresh: () async {
                _loadPendingInvitations();
              },
            ),
            CupertinoSliverNavigationBar(
              heroTag: 'team_nav_bar',
              largeTitle: const Text('Team'),
              automaticBackgroundVisibility: false,
              backgroundColor: Colors.transparent,
              border: null,
              trailing: CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: _loadPendingInvitations,
                child: const Icon(CupertinoIcons.refresh),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.only(
                left: Spacing.lg,
                right: Spacing.lg,
                top: Spacing.lg,
                bottom: 100,
              ),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  BlocBuilder<TeamDataCubit, TeamDataState>(
                    builder: (context, state) {
                      if (state is TeamDataLoaded) {
                        return PlayersList(players: state.coachedPlayers);
                      }
                      return PlayersList(players: const []);
                    },
                  ),
                  const SizedBox(height: Spacing.lg),
                  if (_errorMessage != null)
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
                        _errorMessage!,
                        style: AppTypography.callout.copyWith(
                          color: CupertinoColors.systemRed,
                        ),
                      ),
                    ),
                  // Invitation input widget
                  InvitationInputWidget(
                    teamId: _getCoachTeamId() ?? 0,
                    onSendInvitation: _handleSendInvitation,
                  ),
                  const SizedBox(height: Spacing.lg),
                  // Pending invitations
                  if (_isLoadingInvitations)
                    const Center(
                      child: CupertinoActivityIndicator(radius: 16),
                    )
                  else
                    PendingInvitationsWidget(
                      pendingInvitations: _pendingInvitations,
                      onCancelInvitation: _handleCancelInvitation,
                    ),
                  const SizedBox(height: Spacing.xxxl),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

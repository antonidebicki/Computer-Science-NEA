import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../settings/settings_widgets.dart';
import '../../../design/index.dart';
import '../../../state/cubits/auth/auth_cubit.dart';
import '../../../state/cubits/auth/auth_state.dart';
import '../../../state/cubits/coach/team_data_cubit.dart';
import '../../../state/cubits/coach/team_data_state.dart';
import '../../../state/providers/theme_provider.dart';
import '../../../design/widgets/logout_button.dart';
import '../widgets/coach_profile_invite_disabled_card.dart';
import '../widgets/league_requests.dart';
import '../widgets/home_ground_editor_card.dart';
import '../../../services/repositories/invitation_repository.dart';
import '../../../services/api_client.dart';

// the exact same as the player profile but without the team requests
// i need to find more to add here
class CoachProfileScreen extends StatefulWidget {
  const CoachProfileScreen({super.key});

  @override
  State<CoachProfileScreen> createState() => _CoachProfileScreenState();
}

class _CoachProfileScreenState extends State<CoachProfileScreen> {
  final InvitationRepository _invitationRepository =
      InvitationRepository(ApiClient());
  bool _showTeamInvitationCode = false;
  String? _teamInvitationCode;
  bool _loadingTeamCode = false;
  bool _teamCodeLoaded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTeamInvitationCode();
    });
  }

  Future<void> _loadTeamInvitationCode({bool force = false}) async {
    if (_teamCodeLoaded && !force) return;
    final teamId = _getCoachTeamId();
    if (teamId == null || teamId == 0) {
      debugPrint('No coach team ID found');
      return;
    }

    debugPrint('Loading team invitation code for team: $teamId');

    try {
      setState(() => _loadingTeamCode = true);
      final code = await _invitationRepository.generateTeamInvitationCode(teamId);
      if (mounted) {
        setState(() {
          _teamInvitationCode = code.invitationCode;
          _teamCodeLoaded = true;
        });
      }
      debugPrint('Team invitation code loaded successfully: ${code.invitationCode}');
    } catch (e) {
      debugPrint('Failed to load team invitation code: $e');
      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Error Loading Code'),
            content: Text('Failed to load team invitation code:\n$e'),
            actions: [
              CupertinoDialogAction(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loadingTeamCode = false);
      }
    }
  }

  Future<void> _reloadTeamInvitationCode() async {
    if (mounted) {
      setState(() {
        _teamCodeLoaded = false;
        _teamInvitationCode = null;
      });
    }
    await _loadTeamInvitationCode(force: true);
  }

  int? _getCoachTeamId() {
    try {
      final teamDataState = context.read<TeamDataCubit>().state;
      if (teamDataState is TeamDataLoaded && teamDataState.coachTeam != null) {
        return teamDataState.coachTeam!.teamId;
      }
    } catch (e) {
      debugPrint('Error getting team ID: $e');
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;
    final authState = context.read<AuthCubit>().state;

    String userName = "coach";
    String userEmail = '';

    if (authState is AuthAuthenticated) {
      //for some reason full name doesnt always show
      userName = authState.user.fullName?.isNotEmpty == true
          ? authState.user.fullName!
          : authState.user.username;
      userEmail = authState.user.email.isNotEmpty == true
          ? authState.user.email
          : '';
    }

    return CupertinoPageScaffold(
      child: Container(
        decoration: BoxDecoration(
          gradient: AppGradients.backgroundGradient(context, isDark: isDark),
        ),
        child: CustomScrollView(
          slivers: [
            CupertinoSliverRefreshControl(onRefresh: () async {}),
            CupertinoSliverNavigationBar(
              heroTag: 'profile_nav_bar',
              largeTitle: const Text('Profile'),
              automaticBackgroundVisibility: false,
              backgroundColor: Colors.transparent,
              border: null,
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(
                horizontal: Spacing.lg,
                vertical: Spacing.lg,
              ),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  AppGlassContainer(
                    padding: const EdgeInsets.all(Spacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: CupertinoColors.activeBlue.withValues(
                                  alpha: 0.2,
                                ),
                              ),
                              child: Center(
                                child: AppIcons.profile(
                                  fontSize: 32,
                                  color: CupertinoColors.activeBlue,
                                ),
                              ),
                            ),
                            const SizedBox(width: Spacing.lg),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    userName,
                                    style: AppTypography.headline.copyWith(
                                      color: CupertinoColors.label,
                                    ),
                                  ),
                                  if (userEmail.isNotEmpty) ...[
                                    const SizedBox(height: Spacing.xs),
                                    Text(
                                      userEmail,
                                      style: AppTypography.callout.copyWith(
                                        color: CupertinoColors.secondaryLabel,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: Spacing.lg),
                  BlocBuilder<TeamDataCubit, TeamDataState>(
                    builder: (context, state) {
                      if (state is TeamDataLoaded && state.coachTeam == null) {
                        return Column(
                          children: [
                            CoachProfileInviteDisabledCard(isDark: isDark),
                            const SizedBox(height: Spacing.lg),
                          ],
                        );
                      }

                      return const SizedBox.shrink();
                    },
                  ),
                  BlocBuilder<TeamDataCubit, TeamDataState>(
                    builder: (context, state) {
                      if (state is TeamDataLoaded && state.coachTeam != null) {
                        return HomeGroundEditorCard(
                          teamId: state.coachTeam!.teamId,
                          homeGround: state.coachTeam!.homeGround,
                        );
                      }

                      return const SizedBox.shrink();
                    },
                  ),
                  const SizedBox(height: Spacing.lg),
                  BlocBuilder<TeamDataCubit, TeamDataState>(
                    builder: (context, state) {
                      if (state is TeamDataLoaded && state.coachTeam != null) {
                        return Column(
                          children: [
                            SettingsWidgets.buildInvitationCodeSection(
                              context: context,
                              isDark: isDark,
                              invitationCode: _teamInvitationCode,
                              showInvitationCode: _showTeamInvitationCode,
                              loadingCode: _loadingTeamCode,
                              onToggleShowCode: () {
                                setState(() {
                                  _showTeamInvitationCode =
                                      !_showTeamInvitationCode;
                                });
                              },
                              onReloadCode: _reloadTeamInvitationCode,
                              helperText:
                                  'Share this code with a league admin to invite your team.',
                            ),
                            const SizedBox(height: Spacing.lg),
                            LeagueRequestsSection(isDark: isDark),
                            const SizedBox(height: Spacing.lg),
                          ],
                        );
                      }

                      return const SizedBox.shrink();
                    },
                  ),

                  Text(
                    'Settings',
                    style: AppTypography.headline.copyWith(
                      color: CupertinoColors.label,
                    ),
                  ),
                  const SizedBox(height: Spacing.md),

                  SettingsWidgets.buildSettingCard(
                    icon: CupertinoIcons.info_circle,
                    title: 'About',
                    subtitle: 'App version and information',
                    isDark: isDark,
                    onTap: () => SettingsWidgets.showAboutDialog(context),
                  ),
                  const SizedBox(height: Spacing.lg),

                  Text(
                    'Account',
                    style: AppTypography.headline.copyWith(
                      color: CupertinoColors.label,
                    ),
                  ),
                  SizedBox(height: Spacing.md),
                  LogoutButton(
                    onPressed: () => SettingsWidgets.showLogoutConfirmation(
                      context,
                      () => context.read<AuthCubit>().logout(),
                    ),
                  ),
                  const SizedBox(height: Spacing.xxxl * 3),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

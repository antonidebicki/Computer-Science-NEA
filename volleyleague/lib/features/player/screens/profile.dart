import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../settings/settings_widgets.dart';
import 'package:provider/provider.dart';
import '../../../design/index.dart';
import '../../../state/cubits/auth/auth_cubit.dart';
import '../../../state/cubits/auth/auth_state.dart';
import '../../../state/providers/theme_provider.dart';
import '../../../services/repositories/repositories.dart';
import '../../../services/api_client.dart';
import '../../widgets/team_requests_section.dart';
import '../../../design/widgets/logout_button.dart';

//screen for players only
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _showInvitationCode = false;
  String? _invitationCode;
  bool _loadingCode = false;
  final _teamRequestsKey = GlobalKey<State>();

  @override
  void initState() {
    super.initState();
    _loadInvitationCode();
  }

  Future<void> _refreshData() async {
    await _loadInvitationCode();
    (_teamRequestsKey.currentState as dynamic)?.loadRequests();
  }

  Future<void> _loadInvitationCode() async {
    try {
      setState(() => _loadingCode = true);
      final apiClient = ApiClient();
      final repository = InvitationRepository(apiClient);
      final code = await repository.generateInvitationCode();
      if (mounted) {
        setState(() => _invitationCode = code.invitationCode);
      }
    } catch (e) {
      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Error'),
            content: Text('Failed to load invitation code: $e'),
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
        setState(() => _loadingCode = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;
    final authState = context.read<AuthCubit>().state;

    String userName = 'Player';
    String userEmail = '';

    if (authState is AuthAuthenticated) {
      userName = authState.user.fullName?.isNotEmpty == true
          ? authState.user.fullName!
          : 'Player';
      userEmail = authState.user.email;
    }

    return CupertinoPageScaffold(
      child: Container(
        decoration: BoxDecoration(
          gradient: AppGradients.backgroundGradient(context, isDark: isDark),
        ),
        child: CustomScrollView(
          slivers: [
            CupertinoSliverRefreshControl(onRefresh: _refreshData),
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

                  SettingsWidgets.buildInvitationCodeSection(
                    context: context,
                    isDark: isDark,
                    invitationCode: _invitationCode,
                    showInvitationCode: _showInvitationCode,
                    loadingCode: _loadingCode,
                    onToggleShowCode: () {
                      setState(() {
                        _showInvitationCode = !_showInvitationCode;
                      });
                    },
                  ),
                  const SizedBox(height: Spacing.lg),

                  TeamRequestsSection(key: _teamRequestsKey, isDark: isDark),
                  const SizedBox(height: Spacing.lg),

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

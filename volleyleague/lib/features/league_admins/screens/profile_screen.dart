import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../../../design/index.dart';
import '../../../state/cubits/auth/auth_cubit.dart';
import '../../../state/cubits/auth/auth_state.dart';
import '../../../state/providers/theme_provider.dart';
import '../../../design/widgets/logout_button.dart';
import '../../settings/settings_widgets.dart';

class LeagueAdminProfileScreen extends StatelessWidget {
  const LeagueAdminProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;
    final authState = context.read<AuthCubit>().state;

    String userName = 'League Admin';
    String userEmail = '';

    if (authState is AuthAuthenticated) {
      userName = authState.user.fullName?.isNotEmpty == true
          ? authState.user.fullName!
          : authState.user.username;
      userEmail = authState.user.email;
    }

    return CupertinoPageScaffold(
      child: Container(
        decoration: BoxDecoration(
          gradient: AppGradients.backgroundGradient(context, isDark: isDark),
        ),
        child: CustomScrollView(
          slivers: [
            CupertinoSliverNavigationBar(
              heroTag: 'league_admin_profile_nav_bar',
              largeTitle: const Text('Profile'),
              automaticBackgroundVisibility: false,
              backgroundColor: CupertinoColors.transparent,
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
                  const SizedBox(height: Spacing.md),
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

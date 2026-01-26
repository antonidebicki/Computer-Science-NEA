import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../design/index.dart';
import '../../../state/cubits/auth/auth_cubit.dart';
import '../../../state/cubits/auth/auth_state.dart';
import '../../../state/providers/theme_provider.dart';

/// Main profile screen with invitation code and app settings
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _showInvitationCode = false;

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
                  // User Info Card
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

                  // Invitation Code Section
                  _buildInvitationCodeSection(isDark),
                  const SizedBox(height: Spacing.lg),

                  // Settings Section
                  Text(
                    'Settings',
                    style: AppTypography.headline.copyWith(
                      color: CupertinoColors.label,
                    ),
                  ),
                  const SizedBox(height: Spacing.md),

                  // Theme Settings
                  _buildThemeSettingCard(isDark),
                  const SizedBox(height: Spacing.md),

                  // Notifications Settings (placeholder)
                  _buildSettingCard(
                    icon: CupertinoIcons.bell,
                    title: 'Notifications',
                    subtitle: 'Manage notification preferences',
                    isDark: isDark,
                  ),
                  const SizedBox(height: Spacing.md),

                  // Privacy Settings (placeholder)
                  _buildSettingCard(
                    icon: CupertinoIcons.lock,
                    title: 'Privacy & Security',
                    subtitle: 'Control your account privacy',
                    isDark: isDark,
                  ),
                  const SizedBox(height: Spacing.lg),

                  // Account Section
                  Text(
                    'Account',
                    style: AppTypography.headline.copyWith(
                      color: CupertinoColors.label,
                    ),
                  ),
                  const SizedBox(height: Spacing.md),

                  // Logout Button
                  SizedBox(
                    width: double.infinity,
                    child: CupertinoButton(
                      color: CupertinoColors.systemRed,
                      onPressed: () {
                        _showLogoutConfirmation(context);
                      },
                      child: const Text('Logout'),
                    ),
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

  Widget _buildInvitationCodeSection(bool isDark) {
    // TODO: Replace with actual invitation code from API
    const invitationCode = 'VB-2024-ALPHA-001';

    return AppGlassContainer(
      padding: const EdgeInsets.all(Spacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Invitation Code',
                style: AppTypography.headline.copyWith(
                  color: CupertinoColors.label,
                ),
              ),
              CupertinoButton(
                padding: const EdgeInsets.symmetric(horizontal: Spacing.sm),
                onPressed: () {
                  setState(() {
                    _showInvitationCode = !_showInvitationCode;
                  });
                },
                child: Text(
                  _showInvitationCode ? 'Hide' : 'Show',
                  style: const TextStyle(
                    color: CupertinoColors.activeBlue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacing.md),
          if (_showInvitationCode) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(Spacing.md),
              decoration: BoxDecoration(
                border: Border.all(
                  color: CupertinoColors.activeBlue.withValues(alpha: 0.3),
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(Spacing.md),
                color: CupertinoColors.activeBlue.withValues(alpha: 0.05),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your Code:',
                    style: AppTypography.callout.copyWith(
                      color: CupertinoColors.secondaryLabel,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: Spacing.sm),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        invitationCode,
                        style: AppTypography.headline.copyWith(
                          color: CupertinoColors.activeBlue,
                          letterSpacing: 1.5,
                        ),
                      ),
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: () {
                          // Copy to clipboard
                          showCupertinoDialog(
                            context: context,
                            builder: (context) => CupertinoAlertDialog(
                              title: const Text('Copied'),
                              content: const Text('Invitation code copied to clipboard'),
                              actions: [
                                CupertinoDialogAction(
                                  child: const Text('OK'),
                                  onPressed: () => Navigator.pop(context),
                                ),
                              ],
                            ),
                          );
                        },
                        child: const Icon(
                          CupertinoIcons.doc_on_doc,
                          color: CupertinoColors.activeBlue,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: Spacing.md),
            Text(
              'Share this code to invite new players to join your league',
              style: AppTypography.callout.copyWith(
                color: CupertinoColors.secondaryLabel,
              ),
            ),
          ] else ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(Spacing.md),
              decoration: BoxDecoration(
                border: Border.all(
                  color: CupertinoColors.systemGrey3.withValues(alpha: 0.3),
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(Spacing.md),
                color: CupertinoColors.systemGrey5.withValues(alpha: 0.3),
              ),
              child: Center(
                child: Text(
                  '••••••••••••••••',
                  style: AppTypography.headline.copyWith(
                    color: CupertinoColors.secondaryLabel,
                    letterSpacing: 2.0,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildThemeSettingCard(bool isDark) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return AppGlassContainer(
      padding: const EdgeInsets.all(Spacing.lg),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: CupertinoColors.activeBlue.withValues(alpha: 0.2),
                ),
                child: Center(
                  child: Icon(
                    isDark ? CupertinoIcons.moon : CupertinoIcons.sun_max,
                    color: CupertinoColors.activeBlue,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: Spacing.md),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Appearance',
                    style: AppTypography.subhead.copyWith(
                      color: CupertinoColors.label,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: Spacing.xs),
                  Text(
                    isDark ? 'Dark Mode' : 'Light Mode',
                    style: AppTypography.caption.copyWith(
                      color: CupertinoColors.secondaryLabel,
                    ),
                  ),
                ],
              ),
            ],
          ),
          CupertinoSwitch(
            value: isDark,
            onChanged: (value) {
              themeProvider.setBrightness(
                value ? Brightness.dark : Brightness.light,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSettingCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isDark,
  }) {
    return AppGlassContainer(
      padding: const EdgeInsets.all(Spacing.lg),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: CupertinoColors.activeBlue.withValues(alpha: 0.2),
                ),
                child: Center(
                  child: Icon(
                    icon,
                    color: CupertinoColors.activeBlue,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: Spacing.md),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.subhead.copyWith(
                      color: CupertinoColors.label,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: Spacing.xs),
                  Text(
                    subtitle,
                    style: AppTypography.caption.copyWith(
                      color: CupertinoColors.secondaryLabel,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Icon(
            CupertinoIcons.chevron_right,
            color: CupertinoColors.secondaryLabel,
            size: 18,
          ),
        ],
      ),
    );
  }

  void _showLogoutConfirmation(BuildContext context) {
    showCupertinoDialog(
      context: context,
      builder: (BuildContext context) => CupertinoAlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.pop(context);
              context.read<AuthCubit>().logout();
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}

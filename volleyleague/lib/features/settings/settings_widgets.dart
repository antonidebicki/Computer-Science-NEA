import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../design/index.dart';
import '../../state/providers/theme_provider.dart';

class SettingsWidgets {
  static Widget buildInvitationCodeSection({
    required BuildContext context,
    required bool isDark,
    required String? invitationCode,
    required bool showInvitationCode,
    required bool loadingCode,
    required VoidCallback onToggleShowCode,
  }) {
    final displayCode = invitationCode ?? 'Loading...';
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
                onPressed: loadingCode ? null : onToggleShowCode,
                child: Text(
                  showInvitationCode ? 'Hide' : 'Show',
                  style: const TextStyle(
                    color: CupertinoColors.activeBlue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacing.md),
          if (showInvitationCode) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(Spacing.md),
              decoration: BoxDecoration(
                border: Border.all(
                  color: CupertinoColors.activeBlue.withOpacity(0.3),
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(Spacing.md),
                color: CupertinoColors.activeBlue.withOpacity(0.05),
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
                        displayCode,
                        style: AppTypography.headline.copyWith(
                          color: CupertinoColors.activeBlue,
                          letterSpacing: 1.5,
                        ),
                      ),
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: () async {
                          final code = invitationCode;
                          if (loadingCode || code == null || code.isEmpty) {
                            if (!context.mounted) {
                              return;
                            }
                            showCupertinoDialog(
                              context: context,
                              builder: (context) => CupertinoAlertDialog(
                                title: const Text('Code not ready'),
                                content: const Text(
                                  'Please wait for the invitation code to load.',
                                ),
                                actions: [
                                  CupertinoDialogAction(
                                    child: const Text('OK'),
                                    onPressed: () => Navigator.pop(context),
                                  ),
                                ],
                              ),
                            );
                            return;
                          }

                          await Clipboard.setData(
                            ClipboardData(text: code),
                          );

                          final data = await Clipboard.getData(
                            Clipboard.kTextPlain,
                          );
                          final copied = data?.text == code;

                          if (!context.mounted) {
                            return;
                          }

                          showCupertinoDialog(
                            context: context,
                            builder: (context) => CupertinoAlertDialog(
                              title: Text(copied ? 'Copied' : 'Copy failed'),
                              content: Text(
                                copied
                                    ? 'Invitation code copied to clipboard'
                                    : 'Clipboard access failed. Try again.',
                              ),
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
              'Share this code to your team admin to join a team',
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
                  color: CupertinoColors.systemGrey3.withOpacity(0.3),
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(Spacing.md),
                color: CupertinoColors.systemGrey5.withOpacity(0.3),
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

  static Widget buildThemeSettingCard({
    required BuildContext context,
    required bool isDark,
  }) {
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
                  color: CupertinoColors.activeBlue.withOpacity(0.2),
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

  static void showLogoutConfirmation(
    BuildContext context,
    VoidCallback onLogout,
  ) {
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
              onLogout();
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  static void showAboutDialog(BuildContext context) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('About VolleyLeague'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            Text(
              'Version: 0.7.0',
              style: AppTypography.callout.copyWith(
                color: CupertinoColors.label,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'A comprehensive volleyball league management system for teams and players.',
              style: AppTypography.callout.copyWith(
                color: CupertinoColors.secondaryLabel,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '\u00a9 2026 VolleyLeague',
              style: AppTypography.caption.copyWith(
                color: CupertinoColors.secondaryLabel,
              ),
            ),
          ],
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  static Widget buildSettingCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isDark,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AppGlassContainer(
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
      ),
    );
  }
}

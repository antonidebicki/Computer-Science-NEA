import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../design/index.dart';
import '../../../state/cubits/auth/auth_cubit.dart';
import '../../../state/cubits/auth/auth_state.dart';
import '../../../state/providers/theme_provider.dart';

class CoachProfileScreen extends StatelessWidget {
  const CoachProfileScreen({super.key});

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
                // Refresh profile data if needed
              },
            ),
            CupertinoSliverNavigationBar(
              heroTag: 'profile_nav_bar',
              largeTitle: const Text('Profile'),
              automaticBackgroundVisibility: false,
              backgroundColor: Colors.transparent,
              border: null,
            ),
            BlocBuilder<AuthCubit, AuthState>(
              builder: (context, state) {
                if (state is AuthAuthenticated) {
                  return SliverPadding(
                    padding: const EdgeInsets.only(
                      left: Spacing.lg,
                      right: Spacing.lg,
                      top: Spacing.lg,
                      bottom: 100,
                    ),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        AppGlassContainer(
                          padding: const EdgeInsets.all(Spacing.lg),
                          borderRadius: 20,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Profile Information',
                                style: AppTypography.headline,
                              ),
                              const SizedBox(height: Spacing.lg),
                              _ProfileField(
                                label: 'Username',
                                value: state.user.username,
                              ),
                              const SizedBox(height: Spacing.md),
                              _ProfileField(
                                label: 'Email',
                                value: state.user.email,
                              ),
                              const SizedBox(height: Spacing.md),
                              _ProfileField(
                                label: 'User ID',
                                value: state.user.userId.toString(),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: Spacing.lg),
                        CupertinoButton(
                          onPressed: () {
                            context.read<AuthCubit>().logout();
                          },
                          child: const Text(
                            'Logout',
                            style:
                                TextStyle(color: CupertinoColors.systemRed),
                          ),
                        ),
                        const SizedBox(height: Spacing.xxxl),
                      ]),
                    ),
                  );
                }

                return const SliverFillRemaining(
                  child: Center(
                    child: Text('Not authenticated'),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileField extends StatelessWidget {
  final String label;
  final String value;

  const _ProfileField({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.caption.copyWith(
            color: CupertinoColors.secondaryLabel.resolveFrom(context),
          ),
        ),
        const SizedBox(height: Spacing.xs),
        Text(
          value,
          style: AppTypography.body,
        ),
      ],
    );
  }
}

import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../design/index.dart';
import '../../../state/cubits/auth/auth_cubit.dart';

class ProfileTabScreen extends StatelessWidget {
  const ProfileTabScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: SafeArea(
        bottom: false, 
        child: Padding(
          padding: const EdgeInsets.only(bottom: 100),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
              AppIcons.profile(fontSize: 64, color: CupertinoColors.systemGrey),
              const SizedBox(height: Spacing.lg),
              Text(
                'Profile',
                style: AppTypography.title1,
              ),
              const SizedBox(height: Spacing.sm),
              Text(
                'Coming soon...',
                style: AppTypography.body.copyWith(
                  color: CupertinoColors.systemGrey,
                ),
              ),
              const SizedBox(height: Spacing.xxl),
              CupertinoButton.filled(
                child: const Text('Logout'),
                onPressed: () {
                  context.read<AuthCubit>().logout();
                },
              ),
            ],
            ),
          ),
        ),
      ),
    );
  }
}

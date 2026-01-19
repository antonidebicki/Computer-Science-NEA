import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../design/index.dart';
import '../../../state/cubits/auth/auth_cubit.dart';
import '../../../state/cubits/auth/auth_state.dart';
import '../../../core/routing/app_router.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  String? errorMessage;

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() {
    setState(() {
      errorMessage = null;
    });

    final username = usernameController.text.trim();
    final password = passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      setState(() {
        errorMessage = 'Please enter username and password';
      });
      return;
    }

    context.read<AuthCubit>().login(username, password);
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          final homeRoute = AppRouter.getHomeRouteForRole(state.user.role);
          Navigator.of(context).pushNamedAndRemoveUntil(
            homeRoute,
            (route) => false,
          );
        } else if (state is AuthError) {
          setState(() {
            errorMessage = state.message;
          });
        }
      },
      child: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, state) {
          final isLoading = state is AuthLoading;

          return AuthScreenLayout(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: Spacing.lg),
                Center(
                  child: AppIcons.volleyball(fontSize: 40, color: CupertinoColors.activeBlue),
                ),
                const SizedBox(height: Spacing.xl),
                Text(
                  'Sign in to your\nAccount',
                  style: CupertinoTheme.of(context).textTheme.navLargeTitleTextStyle.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: Spacing.sm),
                Text(
                  'Enter your username and password to log in',
                  style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(color: CupertinoColors.systemGrey),
                ),
                const SizedBox(height: Spacing.xxl),
                IgnorePointer(
                  ignoring: isLoading,
                  child: Opacity(
                    opacity: isLoading ? 0.5 : 1.0,
                    child: AppTextField(
                      controller: usernameController,
                      placeholder: 'Username',
                    ),
                  ),
                ),
                const SizedBox(height: Spacing.lg),
                IgnorePointer(
                  ignoring: isLoading,
                  child: Opacity(
                    opacity: isLoading ? 0.5 : 1.0,
                    child: AppPasswordField(
                      controller: passwordController,
                    ),
                  ),
                ),
                if (errorMessage != null) ...[
                  const SizedBox(height: Spacing.md),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Spacing.md,
                      vertical: Spacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemRed.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: CupertinoColors.systemRed.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          CupertinoIcons.exclamationmark_circle_fill,
                          color: CupertinoColors.systemRed,
                          size: 16,
                        ),
                        const SizedBox(width: Spacing.sm),
                        Flexible(
                          child: Text(
                            errorMessage!,
                            style: const TextStyle(
                              color: CupertinoColors.systemRed,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: Spacing.lg),
                Align(
                  alignment: Alignment.center,
                  child: GestureDetector(
                    onTap: isLoading ? null : () {
                      // TODO: implement the forgot password (this could take ages)
                    },
                    child: Text(
                      'Forgot Password?',
                      style: AppTextStyles.activeBlueRegular.copyWith(
                        color: isLoading ? CupertinoColors.systemGrey : null,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: Spacing.xl),
                AppPrimaryButton(
                  onPressed: isLoading ? null : _handleLogin,
                  child: isLoading
                      ? const CupertinoActivityIndicator(color: CupertinoColors.white)
                      : const Text('Login'),
                ),
                const SizedBox(height: Spacing.xl),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have an account? ",
                      style: AppTextStyles.greyRegular,
                    ),
                    AppTextButtonX(
                      onPressed: isLoading
                          ? null
                          : () => Navigator.of(context).pushNamed(AppRouter.register),
                      child: Text(
                        'Sign Up',
                        style: AppTextStyles.activeBlueSemibold.copyWith(
                          color: isLoading ? CupertinoColors.systemGrey : null,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

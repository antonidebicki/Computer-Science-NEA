import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../../../design/index.dart';
import '../../../state/providers/theme_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;
    
    return CupertinoPageScaffold(
      child: Container(
        decoration: BoxDecoration(
          gradient: AppGradients.backgroundGradient(context, isDark: isDark),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: AppGlassContainer(
                width: 370,
                padding: const EdgeInsets.symmetric(vertical: Spacing.xxl, horizontal: Spacing.xl),
                borderRadius: Spacing.xl,
                blur: Spacing.xl,
                color: CupertinoColors.white.withValues(alpha: 0.25),
                borderColor: CupertinoColors.white.withValues(alpha: 0.3),
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
                    'Enter your email and password to log in',
                    style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(color: CupertinoColors.systemGrey),
                  ),
                  const SizedBox(height: Spacing.xxl),
                  AppTextField(
                    controller: emailController,
                    placeholder: 'Email',
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: Spacing.lg),
                  AppPasswordField(controller: passwordController),
                  const SizedBox(height: Spacing.lg),
                  Align(
                    alignment: Alignment.center,
                    child: GestureDetector(
                      onTap: () {},
                      child: Text(
                        'Forgot Password?',
                        style: AppTextStyles.activeBlueRegular,
                      ),
                    ),
                  ),
                  const SizedBox(height: Spacing.xl),
                  AppPrimaryButton(onPressed: () {}, child: const Text('Login')),
                  const SizedBox(height: Spacing.xl),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Don't have an account? ",
                        style: AppTextStyles.greyRegular,
                      ),
                      AppTextButtonX(
                        onPressed: () {},
                        child: const Text(
                          'Sign Up',
                          style: AppTextStyles.activeBlueSemibold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            ),
          ),
        ),
      ),
    );
  }
}

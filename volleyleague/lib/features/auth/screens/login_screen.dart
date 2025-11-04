import 'package:flutter/cupertino.dart';
import '../../../design/index.dart';

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
    return CupertinoPageScaffold(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              CupertinoColors.systemBlue.withOpacity(0.4),
              CupertinoColors.systemPurple.withOpacity(0.4),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: AppGlassContainer(
                width: 370,
                padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
                borderRadius: 24,
                blur: 20,
                color: CupertinoColors.white.withOpacity(0.25),
                borderColor: CupertinoColors.white.withOpacity(0.3),
                child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 16),
                  // Logo
                  Center(
                    child: AppIcons.volleyball(fontSize: 40, color: CupertinoColors.activeBlue),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Sign in to your\nAccount',
                    style: CupertinoTheme.of(context).textTheme.navLargeTitleTextStyle.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Enter your email and password to log in',
                    style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(color: CupertinoColors.systemGrey),
                  ),
                  const SizedBox(height: 32),
                  AppTextField(
                    controller: emailController,
                    placeholder: 'Email',
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),
                  AppPasswordField(controller: passwordController),
                  const SizedBox(height: 16),
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
                  const SizedBox(height: 24),
                  AppPrimaryButton(onPressed: () {}, child: const Text('Login')),
                  const SizedBox(height: 24),
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

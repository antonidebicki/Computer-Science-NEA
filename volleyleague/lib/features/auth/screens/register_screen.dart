import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../design/index.dart';
import '../../../state/cubits/auth/auth_cubit.dart';
import '../../../state/cubits/auth/auth_state.dart';
import '../../../core/routing/app_router.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final emailController = TextEditingController();
  final dobController = TextEditingController();
  final passwordController = TextEditingController();
  String selectedRole = 'Player';

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    emailController.dispose();
    dobController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void _handleRegister() {
    final firstName = firstNameController.text.trim();
    final lastName = lastNameController.text.trim();
    final email = emailController.text.trim();
    final dob = dobController.text.trim();
    final password = passwordController.text.trim();

    // Validation
    if (firstName.isEmpty || lastName.isEmpty || email.isEmpty || dob.isEmpty || password.isEmpty) {
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('Missing Information'),
          content: const Text('Please fill in all fields'),
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

    if (password.length < 6) {
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('Invalid Password'),
          content: const Text('Password must be at least 6 characters'),
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

    // Use email as username for now
    final username = email.split('@')[0];
    final fullName = '$firstName $lastName';

    context.read<AuthCubit>().register(
      username: username,
      password: password,
      email: email,
      fullName: fullName,
      role: selectedRole.toUpperCase(),
    );
  }

  void _pickDate() async {
    final now = DateTime.now();
    DateTime selectedDate = DateTime(now.year - 16, now.month, now.day);
    
    await showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: 300,
          decoration: BoxDecoration(
            color: CupertinoColors.systemBackground.resolveFrom(context),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(Spacing.md)),
          ),
          child: Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: CupertinoColors.systemBackground.resolveFrom(context),
                  border: Border(
                    bottom: BorderSide(
                      color: CupertinoColors.separator.resolveFrom(context),
                      width: 0.5,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CupertinoButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    CupertinoButton(
                      onPressed: () {
                        dobController.text = "${selectedDate.day.toString().padLeft(2, '0')}/${selectedDate.month.toString().padLeft(2, '0')}/${selectedDate.year}";
                        Navigator.of(context).pop();
                      },
                      child: Text('Done', style: AppTextStyles.activeBlueSemibold),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.date,
                  initialDateTime: selectedDate,
                  minimumDate: DateTime(1900),
                  maximumDate: now,
                  onDateTimeChanged: (DateTime newDate) {
                    selectedDate = newDate;
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthUnauthenticated) {
          // Registration successful, show success and navigate to login
          showCupertinoDialog(
            context: context,
            builder: (context) => CupertinoAlertDialog(
              title: const Text('Success'),
              content: const Text('Account created successfully! Please log in.'),
              actions: [
                CupertinoDialogAction(
                  child: const Text('OK'),
                  onPressed: () {
                    Navigator.pop(context); // Close dialog
                    Navigator.of(context).pushNamedAndRemoveUntil(
                      AppRouter.login,
                      (route) => false,
                    );
                  },
                ),
              ],
            ),
          );
        } else if (state is AuthError) {
          // Show error dialog
          showCupertinoDialog(
            context: context,
            builder: (context) => CupertinoAlertDialog(
              title: const Text('Registration Failed'),
              content: Text(state.message),
              actions: [
                CupertinoDialogAction(
                  child: const Text('OK'),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          );
        }
      },
      child: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, state) {
          final isLoading = state is AuthLoading;

          return AuthScreenLayout(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: Spacing.sm),
                Row(
                  children: [
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: isLoading ? null : () => Navigator.of(context).maybePop(),
                      minSize: 0,
                      child: Icon(
                        CupertinoIcons.back,
                        size: 28,
                        color: isLoading ? CupertinoColors.systemGrey : null,
                      ),
                    ),
                    const Spacer(),
                  ],
                ),
                const SizedBox(height: Spacing.sm),
                Text(
                  'Register',
                  style: CupertinoTheme.of(context).textTheme.navLargeTitleTextStyle.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: Spacing.xs),
                Text(
                  'Create an account to continue!',
                  style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(color: CupertinoColors.systemGrey),
                ),
                const SizedBox(height: Spacing.xl),
                IgnorePointer(
                  ignoring: isLoading,
                  child: Opacity(
                    opacity: isLoading ? 0.5 : 1.0,
                    child: Column(
                      children: [
                        AppTextField(
                          controller: firstNameController,
                          placeholder: 'First Name',
                        ),
                        const SizedBox(height: Spacing.md),
                        AppTextField(
                          controller: lastNameController,
                          placeholder: 'Last Name',
                        ),
                        const SizedBox(height: Spacing.md),
                        AppTextField(
                          controller: emailController,
                          placeholder: 'Email',
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: Spacing.md),
                        GestureDetector(
                          onTap: _pickDate,
                          child: AbsorbPointer(
                            child: AppTextField(
                              controller: dobController,
                              placeholder: 'DD/MM/YYYY',
                              suffix: const Padding(
                                padding: EdgeInsets.only(right: Spacing.sm),
                                child: Icon(
                                  CupertinoIcons.calendar,
                                  color: CupertinoColors.systemGrey,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: Spacing.md),
                        AppPasswordField(
                          controller: passwordController,
                        ),
                        const SizedBox(height: Spacing.lg),
                        AppRoleSelector(
                          selectedRole: selectedRole,
                          onChanged: (role) => setState(() => selectedRole = role),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: Spacing.xl),
                AppPrimaryButton(
                  onPressed: isLoading ? null : _handleRegister,
                  child: isLoading
                      ? const CupertinoActivityIndicator(color: CupertinoColors.white)
                      : const Text('Register'),
                ),
                const SizedBox(height: Spacing.xl),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Already have an account? ",
                      style: AppTextStyles.greyRegular,
                    ),
                    AppTextButtonX(
                      onPressed: isLoading
                          ? null
                          : () => Navigator.of(context).pushNamedAndRemoveUntil(
                                AppRouter.login,
                                (route) => false,
                              ),
                      child: Text(
                        'Log in',
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

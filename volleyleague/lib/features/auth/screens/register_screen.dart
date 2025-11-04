import 'package:flutter/cupertino.dart';
import '../../../design/index.dart';

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
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
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
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: () => Navigator.of(context).maybePop(),
                        child: const Icon(CupertinoIcons.back, size: 28), minimumSize: Size(0, 0),
                      ),
                      const Spacer(),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Register',
                    style: CupertinoTheme.of(context).textTheme.navLargeTitleTextStyle.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Create an account to continue!',
                    style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(color: CupertinoColors.systemGrey),
                  ),
                  const SizedBox(height: 24),
                  AppTextField(
                    controller: firstNameController,
                    placeholder: 'First Name',
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    controller: lastNameController,
                    placeholder: 'Last Name',
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    controller: emailController,
                    placeholder: 'Email',
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: _pickDate,
                    child: AbsorbPointer(
                      child: AppTextField(
                        controller: dobController,
                        placeholder: 'DD/MM/YYYY',
                        suffix: const Padding(
                          padding: EdgeInsets.only(right: 8.0),
                          child: Icon(CupertinoIcons.calendar, color: CupertinoColors.systemGrey),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  AppPasswordField(controller: passwordController),
                  const SizedBox(height: 16),
                  AppRoleSelector(
                    selectedRole: selectedRole,
                    onChanged: (role) => setState(() => selectedRole = role),
                  ),
                  const SizedBox(height: 24),
                  AppPrimaryButton(onPressed: () {}, child: const Text('Register')),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Already have an account? ",
                        style: AppTextStyles.greyRegular,
                      ),
                      AppTextButtonX(
                        onPressed: () {},
                        child: const Text(
                          'Log in',
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

import 'package:flutter/cupertino.dart';

class LogoutButton extends StatelessWidget {
  const LogoutButton({super.key, this.onPressed});
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: CupertinoButton(
        color: CupertinoColors.systemRed,
        onPressed: onPressed,
        child: const Text(
          'Logout',
          style: TextStyle(color: CupertinoColors.white),
        ),
      ),
    );
  }
}

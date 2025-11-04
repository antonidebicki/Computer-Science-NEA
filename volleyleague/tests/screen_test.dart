import 'package:flutter/cupertino.dart';
import 'package:volleyleague/features/auth/screens/login_screen.dart';
import 'package:volleyleague/features/auth/screens/register_screen.dart';

/// Screen selector for testing individual screens
class ScreenTestApp extends StatelessWidget {
  const ScreenTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const CupertinoApp(
      title: 'Screen Test',
      home: ScreenSelector(),
    );
  }
}

class ScreenSelector extends StatelessWidget {
  const ScreenSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Select Screen to Test'),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildScreenButton(
              context,
              'Login Screen',
              const LoginScreen(),
            ),
            const SizedBox(height: 12),
            _buildScreenButton(
              context,
              'Register Screen',
              const RegisterScreen(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScreenButton(BuildContext context, String title, Widget screen) {
    return CupertinoButton.filled(
      onPressed: () {
        Navigator.of(context).push(
          CupertinoPageRoute(builder: (_) => screen),
        );
      },
      child: Text(title),
    );
  }
}

void main() {
  runApp(const ScreenTestApp());
}

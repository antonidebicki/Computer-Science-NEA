import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:volleyleague/core/models/enums.dart';
import 'package:volleyleague/features/auth/screens/login_screen.dart';
import 'package:volleyleague/features/auth/screens/register_screen.dart';
import 'package:volleyleague/features/player/screens/player_home_screen.dart';
import 'package:volleyleague/state/cubits/auth/auth_cubit.dart';

/// Central router for the application
/// Manages all navigation routes and role-based home screen selection
class AppRouter {
  // Route names
  static const String login = '/login';
  static const String register = '/register';
  static const String playerHome = '/player-home';
  static const String coachHome = '/coach-home';
  static const String adminHome = '/admin-home';
  static const String refereeHome = '/referee-home';

  /// Generate routes based on route settings
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case login:
        return CupertinoPageRoute(builder: (_) => const LoginScreen());
      
      case register:
        return CupertinoPageRoute(builder: (_) => const RegisterScreen());
      
      case playerHome:
        return CupertinoPageRoute(
          builder: (_) => const PlayerHomeScreen(),
        );
      
      case coachHome:
        // TODO: Create CoachHomeScreen
        return CupertinoPageRoute(
          builder: (_) => _createPlaceholderScreen('Coach Home'),
        );
      
      case adminHome:
        // TODO: Create AdminHomeScreen
        return CupertinoPageRoute(
          builder: (_) => _createPlaceholderScreen('Admin Home'),
        );
      
      case refereeHome:
        // TODO: Create RefereeHomeScreen
        return CupertinoPageRoute(
          builder: (_) => _createPlaceholderScreen('Referee Home'),
        );
      
      default:
        return CupertinoPageRoute(
          builder: (_) => const LoginScreen(),
        );
    }
  }

  /// Get the appropriate home route based on user role
  static String getHomeRouteForRole(UserRole role) {
    switch (role) {
      case UserRole.player:
        return playerHome;
      case UserRole.coach:
        return coachHome;
      case UserRole.admin:
        return adminHome;
      case UserRole.referee:
        return refereeHome;
    }
  }

  /// Get a widget for the home screen based on user role
  /// Used for direct navigation without named routes
  static Widget getHomeScreenForRole(UserRole role) {
    switch (role) {
      case UserRole.player:
        return const PlayerHomeScreen();
      case UserRole.coach:
        return _createPlaceholderScreen('Coach Home');
      case UserRole.admin:
        return _createPlaceholderScreen('Admin Home');
      case UserRole.referee:
        return _createPlaceholderScreen('Referee Home');
    }
  }

  /// Create a simple placeholder screen for roles
  /// TODO: Replace with actual home screens
  static Widget _createPlaceholderScreen(String title) {
    return Builder(
      builder: (context) {
        return CupertinoPageScaffold(
          navigationBar: CupertinoNavigationBar(
            middle: Text(title),
            trailing: CupertinoButton(
              padding: EdgeInsets.zero,
              child: const Icon(CupertinoIcons.square_arrow_right),
              onPressed: () {
                context.read<AuthCubit>().logout();
              },
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  CupertinoIcons.home,
                  size: 64,
                  color: CupertinoColors.systemGrey,
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Coming soon...',
                  style: TextStyle(
                    color: CupertinoColors.systemGrey,
                  ),
                ),
                const SizedBox(height: 32),
                CupertinoButton.filled(
                  child: const Text('Logout'),
                  onPressed: () {
                    context.read<AuthCubit>().logout();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

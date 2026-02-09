import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:volleyleague/core/models/enums.dart';
import 'package:volleyleague/features/auth/screens/login_screen.dart';
import 'package:volleyleague/features/auth/screens/register_screen.dart';
import 'package:volleyleague/features/player/screens/player_home_screen.dart';
import 'package:volleyleague/features/teams/screens/coach_home_screen.dart';
import 'package:volleyleague/features/league_admins/screens/home_screen.dart';
import 'package:volleyleague/state/cubits/auth/auth_cubit.dart';

/// routes for the app
class AppRouter {
  static const String login = '/login';
  static const String register = '/register';
  static const String playerHome = '/player-home';
  static const String coachHome = '/coach-home';
  static const String adminHome = '/admin-home';
  static const String refereeHome = '/referee-home';

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
        return CupertinoPageRoute(
          builder: (_) => const CoachHomeScreen(),
        );
      
      case adminHome:
        return CupertinoPageRoute(
          builder: (_) => const LeagueAdminHomeScreen(),
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

  /// for now creates placeholders 
  /// will be changed when the home screens are implemented - probably in like a week or smth
  static Widget getHomeScreenForRole(UserRole role) {
    switch (role) {
      case UserRole.player:
        return const PlayerHomeScreen();
      case UserRole.coach:
        return const CoachHomeScreen();
      case UserRole.admin:
        return const LeagueAdminHomeScreen();
      case UserRole.referee:
        return _createPlaceholderScreen('Referee Home');
    }
  }

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

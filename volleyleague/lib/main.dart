import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:volleyleague/core/routing/app_router.dart';
import 'package:volleyleague/services/api_client.dart';
import 'package:volleyleague/services/auth_service.dart';
import 'package:volleyleague/services/repositories/user_repository.dart';
import 'package:volleyleague/state/cubits/auth/auth_cubit.dart';
import 'package:volleyleague/state/cubits/auth/auth_state.dart';
import 'package:volleyleague/state/providers/theme_provider.dart';
import 'package:volleyleague/features/auth/screens/login_screen.dart';

void main() {
  // Initialize dependencies
  final apiClient = ApiClient();
  final authService = AuthService();
  final userRepository = UserRepository(apiClient, authService);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        BlocProvider(
          create: (_) => AuthCubit(userRepository, authService)
            ..checkAuthStatus(), // Check if user is already logged in on startup
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        // When user logs out or session expires, navigate to login
        if (state is AuthUnauthenticated) {
          _navigatorKey.currentState?.pushNamedAndRemoveUntil(
            AppRouter.login,
            (route) => false,
          );
        }
      },
      child: CupertinoApp(
        navigatorKey: _navigatorKey,
        title: 'VolleyLeague',
        theme: const CupertinoThemeData(
          primaryColor: CupertinoColors.activeBlue,
        ),
        home: BlocBuilder<AuthCubit, AuthState>(
          builder: (context, state) {
            return _getHomeScreen(state);
          },
        ),
        onGenerateRoute: AppRouter.generateRoute,
        debugShowCheckedModeBanner: false,
      ),
    );
  }

  /// Determine which screen to show based on authentication state
  Widget _getHomeScreen(AuthState state) {
    if (state is AuthAuthenticated) {
      return AppRouter.getHomeScreenForRole(state.user.role);
    } else {
      // Show login screen for all other states:
      // - AuthUnauthenticated: user logged out or session expired
      // - AuthInitial: app just started
      // - AuthError: login/register failed (error shown inline)
      // - AuthLoading: login in progress (loading shown inline)
      return const LoginScreen();
    }
  }
}

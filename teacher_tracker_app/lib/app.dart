import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/design.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/register_screen.dart';
import 'features/auth/state/auth_controller.dart';
import 'features/home/home_screen.dart';
import 'features/student/screens/student_shell.dart';

/// Router that redirects based on auth state. It refreshes whenever the auth
/// session changes (login, logout, token expiry).
final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier(0);
  ref.listen(authControllerProvider, (_, _) => refresh.value++);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: refresh,
    redirect: (context, state) {
      final auth = ref.read(authControllerProvider);
      final loc = state.matchedLocation;

      // Still restoring a saved token at startup.
      if (auth.isLoading || !auth.hasValue) {
        return loc == '/' ? null : '/';
      }

      final session = auth.value;
      final loggedIn = session != null;
      if (!loggedIn) {
        return (loc == '/login' || loc == '/register') ? null : '/login';
      }

      // Signed in: route to the shell matching the account's role.
      final home = session.isStudent ? '/student' : '/home';
      // Keep users out of the auth/splash pages and the other role's shell.
      if (loc == '/' || loc == '/login' || loc == '/register') return home;
      if (session.isStudent && loc == '/home') return '/student';
      if (!session.isStudent && loc == '/student') return '/home';
      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (_, _) => const _SplashScreen()),
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, _) => const RegisterScreen()),
      GoRoute(path: '/home', builder: (_, _) => const HomeScreen()),
      GoRoute(path: '/student', builder: (_, _) => const StudentShell()),
    ],
  );
});

class TeacherTrackerApp extends ConsumerWidget {
  const TeacherTrackerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Teacher Tracker',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: ref.watch(routerProvider),
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const GlassScaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

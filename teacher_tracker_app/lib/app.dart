import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/design.dart';
import 'core/locale/locale_controller.dart';
import 'core/onboarding/onboarding_controller.dart';
import 'l10n/app_localizations.dart';
import 'features/auth/screens/forgot_password_screen.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/register_screen.dart';
import 'features/auth/screens/reset_password_screen.dart';
import 'features/admin/screens/admin_shell.dart';
import 'features/auth/state/auth_controller.dart';
import 'features/feed/screens/post_detail_screen.dart';
import 'features/home/home_screen.dart';
import 'features/onboarding/screens/onboarding_screen.dart';
import 'features/student/screens/student_shell.dart';

/// A `/post/:id` deep link that arrived before the user was signed in. Held until
/// auth completes, then navigated to (see [_DeepLinkListener]).
final _pendingDeepLink = ValueNotifier<String?>(null);

/// Router that redirects based on auth state. It refreshes whenever the auth
/// session changes (login, logout, token expiry).
final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier(0);
  ref.listen(authControllerProvider, (_, _) => refresh.value++);
  ref.listen(onboardingControllerProvider, (_, _) => refresh.value++);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: refresh,
    redirect: (context, state) {
      final auth = ref.read(authControllerProvider);
      final loc = state.matchedLocation;
      final isPost = loc.startsWith('/post/');

      // Still restoring a saved token at startup.
      if (auth.isLoading || !auth.hasValue) {
        return loc == '/' ? null : '/';
      }

      final session = auth.value;
      final loggedIn = session != null;
      if (!loggedIn) {
        // Remember a deep-linked post so we can land on it after login.
        if (isPost) {
          _pendingDeepLink.value = loc;
          return '/login';
        }
        const signedOutAllowed = {
          '/login',
          '/register',
          '/forgot-password',
          '/reset-password',
        };
        return signedOutAllowed.contains(loc) ? null : '/login';
      }

      // Signed in: a shared post opens directly, regardless of the role shell.
      if (isPost) return null;

      // Route to the shell matching the account's role.
      final home = session.isStudent
          ? '/student'
          : session.isAdmin
              ? '/admin'
              : '/home';

      // First-login onboarding gate (teachers only).
      if (session.isTeacher) {
        final onboarding = ref.read(onboardingControllerProvider);
        if (onboarding.isLoading || !onboarding.hasValue) {
          return loc == '/' ? null : '/';
        }
        final needsOnboarding = !onboarding.value!;
        if (needsOnboarding && loc != '/onboarding') return '/onboarding';
        if (!needsOnboarding && loc == '/onboarding') return home;
      }

      // Keep users out of the auth/splash pages and other roles' shells.
      const authOnlyPages = {
        '/',
        '/login',
        '/register',
        '/forgot-password',
        '/reset-password',
      };
      if (authOnlyPages.contains(loc)) return home;
      const shells = {'/home', '/student', '/admin'};
      if (shells.contains(loc) && loc != home) return home;
      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (_, _) => const _SplashScreen()),
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, _) => const RegisterScreen()),
      GoRoute(
          path: '/forgot-password',
          builder: (_, _) => const ForgotPasswordScreen()),
      GoRoute(
          path: '/reset-password',
          builder: (_, _) => const ResetPasswordScreen()),
      GoRoute(path: '/home', builder: (_, _) => const HomeScreen()),
      GoRoute(path: '/onboarding', builder: (_, _) => const OnboardingScreen()),
      GoRoute(path: '/student', builder: (_, _) => const StudentShell()),
      GoRoute(path: '/admin', builder: (_, _) => const AdminShell()),
      GoRoute(
        path: '/post/:id',
        builder: (_, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
          return PostDetailScreen(postId: id);
        },
      ),
    ],
  );
});

class TeacherTrackerApp extends ConsumerWidget {
  const TeacherTrackerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeControllerProvider).value;
    return _DeepLinkListener(
      child: MaterialApp.router(
        title: 'Teacher Tracker',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: ref.watch(routerProvider),
      ),
    );
  }
}

/// Listens for incoming Universal/App Links (and the custom scheme) and routes
/// `…/post/:id` links to the post. Links that arrive while signed out are parked
/// in [pendingDeepLinkPathProvider] and flushed once the session is ready.
class _DeepLinkListener extends ConsumerStatefulWidget {
  const _DeepLinkListener({required this.child});
  final Widget child;

  @override
  ConsumerState<_DeepLinkListener> createState() => _DeepLinkListenerState();
}

class _DeepLinkListenerState extends ConsumerState<_DeepLinkListener> {
  StreamSubscription<Uri>? _sub;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) return; // app_links targets native platforms
    final links = AppLinks();
    unawaited(links.getInitialLink().then((uri) {
      if (uri != null) _onUri(uri);
    }));
    _sub = links.uriLinkStream.listen(_onUri);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  void _onUri(Uri uri) {
    final path = _postPath(uri);
    if (path == null) return;
    _pendingDeepLink.value = path;
    _flushPending();
  }

  // Navigate to a parked deep link once a session exists.
  void _flushPending() {
    final pending = _pendingDeepLink.value;
    if (pending == null) return;
    if (ref.read(authControllerProvider).value != null) {
      _pendingDeepLink.value = null;
      ref.read(routerProvider).go(pending);
    }
  }

  // Extracts `/post/:id` from either an https link or the custom scheme
  // (`teachertracker://post/42`); returns null for anything else.
  static String? _postPath(Uri uri) {
    final segs = <String>[
      if (uri.host.isNotEmpty) uri.host,
      ...uri.pathSegments,
    ].where((s) => s.isNotEmpty).toList();
    for (var i = 0; i < segs.length - 1; i++) {
      if (segs[i] == 'post') {
        final id = int.tryParse(segs[i + 1]);
        if (id != null) return '/post/$id';
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    // Flush a parked link the moment auth resolves to a signed-in session.
    ref.listen(authControllerProvider, (_, _) => _flushPending());
    return widget.child;
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

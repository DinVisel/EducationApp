import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/connectivity/connectivity_controller.dart';
import 'core/design.dart';
import 'core/locale/locale_controller.dart';
import 'core/onboarding/onboarding_controller.dart';
import 'l10n/app_localizations.dart';
import 'features/auth/screens/forgot_password_screen.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/register_screen.dart';
import 'features/auth/screens/reset_password_screen.dart';
import 'features/auth/screens/change_password_screen.dart';
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

      // First-login gate (any role): a provisioned account must set its own
      // password before it can go anywhere else.
      if (session.mustChangePassword) {
        return loc == '/change-password' ? null : '/change-password';
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
        // Once the first-login gate is cleared, don't linger here.
        '/change-password',
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
      GoRoute(
          path: '/change-password',
          builder: (_, _) => const ChangePasswordScreen(forced: true)),
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
    final themeMode = ref.watch(themeControllerProvider).value ?? ThemeMode.system;
    return _DeepLinkListener(
      child: MaterialApp.router(
        title: 'Teacher Tracker',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: themeMode,
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: ref.watch(routerProvider),
        builder: (context, child) => _ConnectivityBanner(
          child: child ?? const SizedBox.shrink(),
        ),
      ),
    );
  }
}

/// A slim status bar shown above the app when the network drops, plus a brief
/// "Back online" confirmation when it returns. Driven by [isOnlineProvider].
class _ConnectivityBanner extends ConsumerStatefulWidget {
  const _ConnectivityBanner({required this.child});
  final Widget child;

  @override
  ConsumerState<_ConnectivityBanner> createState() =>
      _ConnectivityBannerState();
}

class _ConnectivityBannerState extends ConsumerState<_ConnectivityBanner> {
  bool _showBackOnline = false;
  Timer? _backOnlineTimer;

  @override
  void dispose() {
    _backOnlineTimer?.cancel();
    super.dispose();
  }

  void _onConnectivityChanged(bool? previous, bool current) {
    if (previous == false && current == true) {
      setState(() => _showBackOnline = true);
      _backOnlineTimer?.cancel();
      _backOnlineTimer = Timer(const Duration(seconds: 2), () {
        if (mounted) setState(() => _showBackOnline = false);
      });
    } else if (!current) {
      _backOnlineTimer?.cancel();
      if (_showBackOnline) setState(() => _showBackOnline = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<bool>>(isOnlineProvider, (prev, next) {
      _onConnectivityChanged(prev?.value, next.value ?? true);
    });

    final online = ref.watch(isOnlineProvider).value ?? true;
    final loc = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;

    Widget? bar;
    if (!online) {
      bar = _StatusBar(
        key: const ValueKey('offline'),
        icon: Icons.cloud_off,
        label: loc.connectivityOffline,
        background: scheme.errorContainer,
        foreground: scheme.onErrorContainer,
      );
    } else if (_showBackOnline) {
      bar = _StatusBar(
        key: const ValueKey('online'),
        icon: Icons.cloud_done,
        label: loc.connectivityBackOnline,
        background: scheme.primaryContainer,
        foreground: scheme.onPrimaryContainer,
      );
    }

    return Column(
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          transitionBuilder: (c, a) => SizeTransition(sizeFactor: a, child: c),
          child: bar ?? const SizedBox.shrink(),
        ),
        Expanded(child: widget.child),
      ],
    );
  }
}

class _StatusBar extends StatelessWidget {
  const _StatusBar({
    super.key,
    required this.icon,
    required this.label,
    required this.background,
    required this.foreground,
  });

  final IconData icon;
  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: foreground),
              const SizedBox(width: 8),
              Text(label,
                  style: TextStyle(
                      color: foreground, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
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

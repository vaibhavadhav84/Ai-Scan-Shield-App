import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/providers.dart';
import '../features/account/help_screen.dart';
import '../features/account/profile_screen.dart';
import '../features/authentication/auth_screen.dart';
import '../features/dashboard/home_screen.dart';
import '../features/history/history_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/reports/reports_screen.dart';
import '../features/results/result_screen.dart';
import '../features/scan/scan_screen.dart';
import '../shared/widgets.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final api = ref.read(apiProvider);
  final router = GoRouter(
    initialLocation: '/home',
    refreshListenable: api.changed,
    redirect: (context, state) {
      final route = state.matchedLocation;
      if (route == '/help') return null;
      if (!api.onboarded) return route == '/onboarding' ? null : '/onboarding';
      if (api.access == null) return route == '/auth' ? null : '/auth';
      if (api.sharedText != null && route != '/scan') {
        return '/scan?channel=sms';
      }
      if (route == '/auth' || route == '/onboarding') return '/home';
      return null;
    },
    routes: [
      GoRoute(path: '/onboarding', builder: (_, _) => const OnboardingScreen()),
      GoRoute(path: '/auth', builder: (_, _) => const AuthScreen()),
      GoRoute(path: '/help', builder: (_, _) => const HelpScreen()),
      GoRoute(
        path: '/alerts',
        builder: (_, _) => const ReportsScreen(alerts: true),
      ),
      GoRoute(
        path: '/result/:id',
        builder: (_, state) => ResultScreen(
          id: state.pathParameters['id']!,
          result: state.extra is Map
              ? Map<String, dynamic>.from(state.extra as Map)
              : null,
        ),
      ),
      ShellRoute(
        builder: (context, state, child) =>
            AppShell(location: state.uri.path, child: child),
        routes: [
          GoRoute(path: '/home', builder: (_, _) => const HomeScreen()),
          GoRoute(
            path: '/scan',
            builder: (_, state) => ScanScreen(
              key: ValueKey(state.uri.queryParameters['channel']),
              initialChannel:
                  [
                    'sms',
                    'email',
                    'url',
                    'voice',
                    'call',
                  ].contains(state.uri.queryParameters['channel'])
                  ? state.uri.queryParameters['channel']!
                  : 'sms',
            ),
          ),
          GoRoute(path: '/history', builder: (_, _) => const HistoryScreen()),
          GoRoute(path: '/reports', builder: (_, _) => const ReportsScreen()),
          GoRoute(path: '/profile', builder: (_, _) => const ProfileScreen()),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: FilledButton(
          onPressed: () => context.go('/home'),
          child: const Text('Return home'),
        ),
      ),
    ),
  );
  ref.onDispose(router.dispose);
  return router;
});

ThemeData appTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final colors = ColorScheme.fromSeed(
    seedColor: const Color(0xff2478f5),
    brightness: brightness,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: colors,
    scaffoldBackgroundColor: dark
        ? const Color(0xff0b1526)
        : const Color(0xfff4f7fc),
    appBarTheme: AppBarTheme(
      backgroundColor: dark ? const Color(0xff0b1526) : const Color(0xfff4f7fc),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      contentPadding: const EdgeInsets.all(16),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(48, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(minimumSize: const Size(48, 48)),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
  );
}

class ShieldApp extends ConsumerWidget {
  const ShieldApp({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => MaterialApp.router(
    title: 'Scan Shield',
    debugShowCheckedModeBanner: false,
    theme: appTheme(Brightness.light),
    darkTheme: appTheme(Brightness.dark),
    themeMode: ref.watch(themeProvider),
    routerConfig: ref.watch(routerProvider),
  );
}

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.location, required this.child});
  final String location;
  final Widget child;
  static const routes = ['/home', '/scan', '/history', '/reports', '/profile'];
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Brand(),
      actions: [
        IconButton(
          tooltip: 'Help',
          onPressed: () => context.push('/help'),
          icon: const Icon(Icons.help_outline),
        ),
      ],
    ),
    body: child,
    bottomNavigationBar: NavigationBar(
      selectedIndex: routes.indexOf(location).clamp(0, 4),
      onDestinationSelected: (index) => context.go(routes[index]),
      destinations: const [
        NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
        NavigationDestination(icon: Icon(Icons.shield_outlined), label: 'Scan'),
        NavigationDestination(icon: Icon(Icons.history), label: 'History'),
        NavigationDestination(
          icon: Icon(Icons.flag_outlined),
          label: 'Reports',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline),
          label: 'Profile',
        ),
      ],
    ),
  );
}

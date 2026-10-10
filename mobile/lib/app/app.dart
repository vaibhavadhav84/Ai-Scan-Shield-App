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
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/home', builder: (_, _) => const HomeScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/scan',
                builder: (_, state) => ScanScreen(
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
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/history',
                builder: (_, _) => const HistoryScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/reports',
                builder: (_, _) => const ReportsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (_, _) => const ProfileScreen(),
              ),
            ],
          ),
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

ThemeData appTheme(Brightness brightness) => shieldTheme(brightness);

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

class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.navigationShell});
  final StatefulNavigationShell navigationShell;
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int refresh = 0;
  @override
  void didUpdateWidget(AppShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    refresh++;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Brand(),
      actions: [
        IconButton(
          tooltip: 'Security alerts',
          onPressed: () => context.push('/alerts'),
          icon: const Icon(Icons.notifications_none_rounded),
        ),
        IconButton(
          tooltip: 'Help',
          onPressed: () => context.push('/help'),
          icon: const Icon(Icons.help_outline_rounded),
        ),
      ],
    ),
    body: ViewRefreshScope(
      revision: refresh,
      activeIndex: widget.navigationShell.currentIndex,
      child: widget.navigationShell,
    ),
    bottomNavigationBar: DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
        ),
      ),
      child: NavigationBar(
        selectedIndex: widget.navigationShell.currentIndex,
        labelBehavior: MediaQuery.textScalerOf(context).scale(14) > 20
            ? NavigationDestinationLabelBehavior.alwaysHide
            : NavigationDestinationLabelBehavior.alwaysShow,
        onDestinationSelected: (index) {
          setState(() => refresh++);
          widget.navigationShell.goBranch(index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
            tooltip: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.shield_outlined),
            selectedIcon: Icon(Icons.shield_rounded),
            label: 'Scan',
            tooltip: 'Scan',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_rounded),
            label: 'History',
            tooltip: 'History',
          ),
          NavigationDestination(
            icon: Icon(Icons.flag_outlined),
            selectedIcon: Icon(Icons.flag_rounded),
            label: 'Reports',
            tooltip: 'Reports',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profile',
            tooltip: 'Profile',
          ),
        ],
      ),
    ),
  );
}

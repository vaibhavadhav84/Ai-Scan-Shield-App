"""Apply the coordinated theme/navigation integration to existing app entry points."""

from pathlib import Path

path = Path(__file__).resolve().parents[1] / "mobile/lib/app/app.dart"
source = path.read_text(encoding="utf-8")
start = source.index("ThemeData appTheme(")
end = source.index("class ShieldApp", start)
source = (
    source[:start]
    + "ThemeData appTheme(Brightness brightness) => shieldTheme(brightness);\n\n"
    + source[end:]
)
source = source.replace(
    "ShellRoute(\n        builder: (context, state, child) =>\n            AppShell(location: state.uri.path, child: child),\n        routes: [",
    "StatefulShellRoute.indexedStack(\n        builder: (context, state, navigationShell) => AppShell(navigationShell: navigationShell),\n        branches: [",
)
start = source.index("        branches: [")
end = source.index("\n      ),\n    ],", start)
source = (
    source[:start]
    + """        branches: [
          StatefulShellBranch(routes: [GoRoute(path: '/home', builder: (_, _) => const HomeScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/scan', builder: (_, state) => ScanScreen(
            initialChannel: ['sms', 'email', 'url', 'voice', 'call'].contains(state.uri.queryParameters['channel']) ? state.uri.queryParameters['channel']! : 'sms',
          ))]),
          StatefulShellBranch(routes: [GoRoute(path: '/history', builder: (_, _) => const HistoryScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/reports', builder: (_, _) => const ReportsScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/profile', builder: (_, _) => const ProfileScreen())]),
        ],"""
    + source[end:]
)
start = source.index("class AppShell")
source = (
    source[:start]
    + """class AppShell extends StatefulWidget {
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
    appBar: AppBar(title: const Brand(), actions: [
      IconButton(tooltip: 'Security alerts', onPressed: () => context.push('/alerts'), icon: const Icon(Icons.notifications_none_rounded)),
      IconButton(tooltip: 'Help', onPressed: () => context.push('/help'), icon: const Icon(Icons.help_outline_rounded)),
    ]),
    body: ViewRefreshScope(revision: refresh, child: widget.navigationShell),
    bottomNavigationBar: DecoratedBox(
      decoration: BoxDecoration(border: Border(top: BorderSide(color: Theme.of(context).colorScheme.outlineVariant))),
      child: NavigationBar(
        selectedIndex: widget.navigationShell.currentIndex,
        labelBehavior: MediaQuery.textScalerOf(context).scale(14) > 20 ? NavigationDestinationLabelBehavior.alwaysHide : NavigationDestinationLabelBehavior.alwaysShow,
        onDestinationSelected: (index) {
          setState(() => refresh++);
          widget.navigationShell.goBranch(index);
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded), label: 'Home', tooltip: 'Home'),
          NavigationDestination(icon: Icon(Icons.shield_outlined), selectedIcon: Icon(Icons.shield_rounded), label: 'Scan', tooltip: 'Scan'),
          NavigationDestination(icon: Icon(Icons.history_rounded), label: 'History', tooltip: 'History'),
          NavigationDestination(icon: Icon(Icons.flag_outlined), selectedIcon: Icon(Icons.flag_rounded), label: 'Reports', tooltip: 'Reports'),
          NavigationDestination(icon: Icon(Icons.person_outline_rounded), selectedIcon: Icon(Icons.person_rounded), label: 'Profile', tooltip: 'Profile'),
        ],
      ),
    ),
  );
}
"""
)
path.write_text(source, encoding="utf-8")

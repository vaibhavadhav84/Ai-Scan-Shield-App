import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:scan_shield/app/app.dart';
import 'package:scan_shield/core/api.dart';
import 'package:scan_shield/core/providers.dart';
import 'package:scan_shield/features/account/help_screen.dart';
import 'package:scan_shield/features/account/profile_screen.dart';
import 'package:scan_shield/features/authentication/auth_screen.dart';
import 'package:scan_shield/features/dashboard/home_screen.dart';
import 'package:scan_shield/features/history/history_screen.dart';
import 'package:scan_shield/features/reports/reports_screen.dart';
import 'package:scan_shield/features/results/result_screen.dart';
import 'package:scan_shield/features/scan/scan_screen.dart';
import 'package:scan_shield/shared/widgets.dart';
import 'support/design_fixtures.dart';

void main() => registerDesignTests();

typedef DesignCapture = Future<void> Function(WidgetTester tester, String name);

Future<void> settleDesign(WidgetTester tester) async {
  // Bounded pumps deliberately work even when a genuine request is pending.
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> mountDesign(
  WidgetTester tester,
  Widget screen, {
  DesignApi? api,
  double width = 390,
  double scale = 1,
  Brightness brightness = Brightness.light,
  bool scaffold = true,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(width, 844);
  final service = api ?? DesignApi();
  final router = GoRouter(
    initialLocation: '/case',
    routes: [
      GoRoute(
        path: '/case',
        builder: (_, _) => scaffold
            ? Scaffold(
                appBar: AppBar(title: const Brand()),
                body: screen,
              )
            : screen,
      ),
      GoRoute(
        path: '/home',
        builder: (_, _) => const Scaffold(body: HomeScreen()),
      ),
      GoRoute(
        path: '/scan',
        builder: (_, state) => Scaffold(
          body: ScanScreen(
            initialChannel: state.uri.queryParameters['channel'] ?? 'sms',
          ),
        ),
      ),
      GoRoute(
        path: '/history',
        builder: (_, _) => const Scaffold(body: HistoryScreen()),
      ),
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
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [apiProvider.overrideWithValue(service)],
      child: MaterialApp.router(
        theme: appTheme(brightness),
        routerConfig: router,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(scale),
            disableAnimations: true,
          ),
          child: child!,
        ),
      ),
    ),
  );
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    router.dispose();
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await settleDesign(tester);
}

Future<void> tapDesign(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder.first);
  await tester.pump();
  await tester.tap(finder.first);
  await settleDesign(tester);
}

Future<void> assertScrollableLayout(WidgetTester tester) async {
  expect(tester.takeException(), isNull);
  final scrollable = find.byType(Scrollable);
  if (scrollable.evaluate().isNotEmpty) {
    await tester.drag(scrollable.first, const Offset(0, -550));
    await settleDesign(tester);
    expect(tester.takeException(), isNull);
  }
}

void registerDesignTests({DesignCapture? capture}) {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    installDesignPlatformFakes();
  });

  testWidgets('design home presents actual fixture activity and scan actions', (
    tester,
  ) async {
    final api = DesignApi();
    await mountDesign(tester, const HomeScreen(), api: api);
    expect(find.byType(ScanTile), findsNWidgets(3));
    expect(
      api.calls.where((call) => call.route == '/scans/summary'),
      hasLength(1),
    );
    expect(find.textContaining('scan', findRichText: true), findsWidgets);
    expect(tester.takeException(), isNull);
    await capture?.call(tester, 'home-390-light-1x');
  });

  testWidgets('design home first use offers a real scan destination', (
    tester,
  ) async {
    await mountDesign(tester, const HomeScreen(), api: DesignApi(empty: true));
    expect(find.byType(ScanTile), findsNothing);
    expect(find.byType(EmptyState), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  for (final channel in ['sms', 'email', 'url', 'voice', 'call']) {
    testWidgets(
      'design $channel scanner has labeled input and empty validation',
      (tester) async {
        final api = DesignApi();
        await mountDesign(
          tester,
          ScanScreen(initialChannel: channel),
          api: api,
        );
        final input = find.byKey(ValueKey('scan-input-$channel'));
        expect(input, findsOneWidget);
        final label = switch (channel) {
          'url' => 'Check link',
          'voice' => 'Analyze transcript',
          'call' => 'Analyze call details',
          _ => 'Analyze message',
        };
        if (['email', 'url', 'voice'].contains(channel)) {
          await capture?.call(tester, 'scan-$channel-390-light-1x');
        }
        await tapDesign(tester, find.text(label));
        expect(find.textContaining('Enter content'), findsOneWidget);
        expect(
          api.calls.where(
            (call) => call.method == 'POST' && call.route == '/scans',
          ),
          isEmpty,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'design text paste clear and failed submission preserve the draft',
    (tester) async {
      final api = DesignApi()..failures['/scans'] = offlineFixture();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            SystemChannels.platform,
            (call) async => call.method == 'Clipboard.getData'
                ? {'text': 'A test-only message to review.'}
                : null,
          );
      await mountDesign(tester, const ScanScreen(), api: api);
      await tapDesign(tester, find.text('Paste'));
      final input = find.byKey(const ValueKey('scan-input-sms'));
      expect(
        tester.widget<TextField>(input).controller!.text,
        'A test-only message to review.',
      );
      await tapDesign(tester, find.text('Clear'));
      expect(tester.widget<TextField>(input).controller!.text, isEmpty);
      await tester.enterText(input, 'Please review this test-only message.');
      await tapDesign(tester, find.text('Analyze message'));
      expect(find.textContaining('Cannot reach'), findsOneWidget);
      expect(
        tester.widget<TextField>(input).controller!.text,
        'Please review this test-only message.',
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'design URL validates locally and provider consent starts unchecked',
    (tester) async {
      final api = DesignApi();
      await mountDesign(
        tester,
        const ScanScreen(initialChannel: 'url'),
        api: api,
      );
      final input = find.byKey(const ValueKey('scan-input-url'));
      expect(
        tester.widget<CheckboxListTile>(find.byType(CheckboxListTile)).value,
        isFalse,
      );
      await tester.enterText(input, 'not a valid link');
      await tapDesign(tester, find.text('Check link'));
      expect(find.textContaining('complete http://'), findsOneWidget);
      expect(api.calls.where((call) => call.route == '/scans'), isEmpty);
      await tester.enterText(input, 'https://example.test/a-very-long-path');
      await settleDesign(tester);
      expect(find.text('example.test'), findsOneWidget);
      await tapDesign(tester, find.text('Check link'));
      final submitted = api.calls.singleWhere(
        (call) => call.method == 'POST' && call.route == '/scans',
      );
      expect((submitted.data as Json)['allow_external_reputation'], isFalse);
      expect(find.text('Scan result'), findsOneWidget);
    },
  );

  testWidgets('design channel changes preserve independent in-memory drafts', (
    tester,
  ) async {
    await mountDesign(tester, const ScanScreen());
    await tester.enterText(
      find.byKey(const ValueKey('scan-input-sms')),
      'Text draft',
    );
    final emailChip = find.byWidgetPredicate(
      (widget) =>
          widget is ChoiceChip &&
          widget.label is Text &&
          (widget.label as Text).data == 'Email',
    );
    await tapDesign(tester, emailChip);
    await tester.enterText(
      find.byKey(const ValueKey('scan-input-email')),
      'Email draft',
    );
    final smsChip = find.byWidgetPredicate(
      (widget) =>
          widget is ChoiceChip &&
          widget.label is Text &&
          ((widget.label as Text).data ?? '').contains('Text'),
    );
    await tapDesign(tester, smsChip);
    expect(
      tester
          .widget<TextField>(find.byKey(const ValueKey('scan-input-sms')))
          .controller!
          .text,
      'Text draft',
    );
  });

  for (final risk in ['Safe', 'Suspicious', 'High Risk']) {
    testWidgets('design $risk result communicates score advice and limits', (
      tester,
    ) async {
      final scan = designScan(risk: risk);
      await mountDesign(
        tester,
        ResultScreen(id: scan['id'], result: scan),
        scaffold: false,
      );
      expect(find.text(risk), findsWidgets);
      expect(find.text(scan['summary']), findsOneWidget);
      expect(
        find.text((scan['recommendations'] as List).first),
        findsOneWidget,
      );
      expect(find.textContaining('probability'), findsWidgets);
      if (risk != 'Safe') {
        expect(find.text('Request for sensitive information'), findsOneWidget);
      }
      expect(
        find.text('Unavailable · provider did not complete this check'),
        findsOneWidget,
      );
      expect(find.textContaining('guaranteed legitimate'), findsNothing);
      expect(tester.takeException(), isNull);
      await capture?.call(
        tester,
        'result-${risk.toLowerCase().replaceAll(' ', '-')}-390-light-1x',
      );
    });
  }

  testWidgets(
    'design result feedback failure retains comment and permits retry',
    (tester) async {
      final api = DesignApi()
        ..failures['/scans/fixture-scan-001/feedback'] = offlineFixture();
      await mountDesign(
        tester,
        ResultScreen(id: 'fixture-scan-001', result: designScan()),
        api: api,
        scaffold: false,
      );
      await tapDesign(tester, find.text('Give feedback'));
      final input = find.byWidgetPredicate(
        (widget) =>
            widget is TextField &&
            widget.decoration?.labelText == 'Comment (optional)',
      );
      await tester.enterText(input, 'Test-only review comment');
      await tapDesign(tester, find.text('Save feedback'));
      expect(find.textContaining('Cannot reach'), findsOneWidget);
      expect(
        tester.widget<TextField>(input).controller!.text,
        'Test-only review comment',
      );
      api.failures.clear();
      await tapDesign(tester, find.text('Save feedback'));
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.text('Feedback saved. Thank you.'), findsOneWidget);
    },
  );

  testWidgets(
    'design history filters update real query and reset empty search',
    (tester) async {
      final api = DesignApi();
      await mountDesign(tester, const HistoryScreen(), api: api);
      await capture?.call(tester, 'history-390-light-1x');
      final search = find.byWidgetPredicate(
        (widget) =>
            widget is TextField &&
            widget.decoration?.labelText == 'Search scan ID',
      );
      await tester.enterText(search, 'no-matching-reference');
      await tapDesign(tester, find.byTooltip('Search history'));
      expect(api.calls.last.query?['search'], 'no-matching-reference');
      expect(find.text('No matching scans'), findsOneWidget);
      await tapDesign(tester, find.text('Reset filters'));
      expect(api.calls.last.query?['search'], '');
      expect(find.byType(ScanTile), findsNWidgets(3));
    },
  );

  testWidgets(
    'design settings preserve retention when confirmation is cancelled',
    (tester) async {
      final api = DesignApi();
      await mountDesign(tester, const ProfileScreen(), api: api);
      await capture?.call(tester, 'settings-390-light-1x');
      final dropdown = find.byWidgetPredicate(
        (widget) => widget is DropdownButtonFormField<int>,
      );
      await tapDesign(tester, dropdown);
      await tapDesign(tester, find.text('7 days').last);
      expect(find.text('Change history retention?'), findsOneWidget);
      await tapDesign(tester, find.text('Cancel'));
      expect(api.user['retention_days'], 30);
      expect(api.calls.where((call) => call.method == 'PATCH'), isEmpty);
      expect(find.text('30 days'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'design auth validation and focused recovery avoid duplicate actions',
    (tester) async {
      final api = DesignApi();
      await mountDesign(tester, const AuthScreen(), api: api, scaffold: false);
      await capture?.call(tester, 'auth-390-light-1x');
      expect(find.text('Recovery code'), findsNothing);
      await tapDesign(tester, find.text('Sign in'));
      expect(find.text('Enter a valid email address.'), findsOneWidget);
      expect(find.text('Enter your password.'), findsOneWidget);
      expect(api.calls, isEmpty);
      await tapDesign(tester, find.byTooltip('Show password'));
      expect(find.byTooltip('Hide password'), findsOneWidget);
      await tapDesign(tester, find.text('Forgot password?'));
      expect(find.text('Reset your password'), findsOneWidget);
      expect(find.text('Password'), findsNothing);
      expect(find.text('Send recovery instructions'), findsOneWidget);
    },
  );

  testWidgets('design reports state internal review and alerts mark read', (
    tester,
  ) async {
    final api = DesignApi();
    await mountDesign(tester, const ReportsScreen(), api: api);
    expect(find.text('Credential theft'), findsOneWidget);
    expect(find.text('Submitted'), findsOneWidget);
    expect(find.textContaining('Government and cybercrime'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('design unread alert updates only after API acknowledgement', (
    tester,
  ) async {
    final api = DesignApi();
    await mountDesign(
      tester,
      const ReportsScreen(alerts: true),
      api: api,
      scaffold: false,
    );
    expect(find.text('Unread'), findsOneWidget);
    await tapDesign(tester, find.text('Mark read'));
    expect(api.alertRead, isTrue);
    expect(find.text('Read'), findsOneWidget);
    expect(find.text('Mark read'), findsNothing);
  });

  testWidgets(
    'design loading error and retry states are truthful and recoverable',
    (tester) async {
      var attempts = 0;
      final pending = Completer<Json>();
      await mountDesign(
        tester,
        ApiPanel(
          load: () {
            attempts++;
            return attempts == 1 ? pending.future : Future.value({'ok': true});
          },
          builder: (_) => const Text('Recovered content'),
        ),
      );
      expect(find.text('Recovered content'), findsNothing);
      expect(find.byType(LoadingSkeleton), findsOneWidget);
      pending.completeError(offlineFixture());
      await settleDesign(tester);
      expect(find.textContaining('Cannot reach'), findsOneWidget);
      await tapDesign(tester, find.text('Retry'));
      expect(find.text('Recovered content'), findsOneWidget);
      expect(attempts, 2);
    },
  );

  for (final brightness in Brightness.values) {
    for (final risk in ['Safe', 'Suspicious', 'High Risk']) {
      testWidgets(
        'design $risk badge contrast and non-color semantics ${brightness.name}',
        (tester) async {
          final semantics = tester.ensureSemantics();
          try {
            await mountDesign(
              tester,
              Center(child: RiskBadge(risk)),
              brightness: brightness,
            );
            expect(find.text(risk), findsOneWidget);
            expect(find.byType(Icon), findsWidgets);
            await expectLater(tester, meetsGuideline(textContrastGuideline));
            expect(tester.takeException(), isNull);
          } finally {
            semantics.dispose();
          }
        },
      );
    }
  }

  testWidgets('design authentication touch targets and icon labels', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      await mountDesign(tester, const AuthScreen(), scaffold: false);
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    } finally {
      semantics.dispose();
    }
  });

  final layouts = <({String name, Widget Function() screen, bool scaffold})>[
    (name: 'home', screen: () => const HomeScreen(), scaffold: true),
    (name: 'text', screen: () => const ScanScreen(), scaffold: true),
    (
      name: 'email',
      screen: () => const ScanScreen(initialChannel: 'email'),
      scaffold: true,
    ),
    (
      name: 'url',
      screen: () => const ScanScreen(initialChannel: 'url'),
      scaffold: true,
    ),
    (
      name: 'voice',
      screen: () => const ScanScreen(initialChannel: 'voice'),
      scaffold: true,
    ),
    (
      name: 'call',
      screen: () => const ScanScreen(initialChannel: 'call'),
      scaffold: true,
    ),
    (
      name: 'result',
      screen: () => ResultScreen(id: 'fixture-scan-001', result: designScan()),
      scaffold: false,
    ),
    (name: 'history', screen: () => const HistoryScreen(), scaffold: true),
    (name: 'settings', screen: () => const ProfileScreen(), scaffold: true),
    (name: 'auth', screen: () => const AuthScreen(), scaffold: false),
    (name: 'help', screen: () => const HelpScreen(), scaffold: false),
    (name: 'reports', screen: () => const ReportsScreen(), scaffold: true),
  ];
  for (final layout in layouts) {
    for (final variant in [
      (320.0, Brightness.dark),
      (430.0, Brightness.light),
    ]) {
      testWidgets(
        'design ${layout.name} layout ${variant.$1.toInt()} ${variant.$2.name} 2x',
        (tester) async {
          await mountDesign(
            tester,
            layout.screen(),
            width: variant.$1,
            brightness: variant.$2,
            scale: 2,
            scaffold: layout.scaffold,
          );
          if (layout.name == 'home' && variant.$1 == 320) {
            await capture?.call(tester, 'home-320-dark-2x');
          }
          await assertScrollableLayout(tester);
        },
      );
    }
  }
}

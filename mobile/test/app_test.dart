import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:scan_shield/app/app.dart';
import 'package:scan_shield/core/api.dart';
import 'package:scan_shield/core/providers.dart';
import 'package:scan_shield/shared/widgets.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test('safe error messages distinguish offline and server input errors', () {
    expect(
      errorMessage(
        DioException(requestOptions: RequestOptions(path: '/scans')),
      ),
      contains('Cannot reach'),
    );
    expect(riskColor('High Risk'), isNot(riskColor('Safe')));
    expect(timestamp(0).length, 16);
  });
  testWidgets('first-use onboarding leads to sign-in without permissions', (
    tester,
  ) async {
    final api = Api();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [apiProvider.overrideWithValue(api)],
        child: const ShieldApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('A moment to check.\nA safer next step.'), findsOneWidget);
    await tester.ensureVisible(find.text('Get started'));
    await tester.tap(find.text('Get started'));
    await tester.pumpAndSettle();
    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
  });
  testWidgets('result label conveys risk without color', (tester) async {
    final semantics = tester.ensureSemantics();
    try {
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: RiskBadge('High Risk'))),
      );
      expect(find.text('High Risk'), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber), findsOneWidget);
      await expectLater(tester, meetsGuideline(textContrastGuideline));
    } finally {
      semantics.dispose();
    }
  });
  testWidgets('help navigation is available before sign-in', (tester) async {
    final api = Api()..onboarded = true;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [apiProvider.overrideWithValue(api)],
        child: const ShieldApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Privacy, terms & help'));
    await tester.tap(find.text('Privacy, terms & help'));
    await tester.pumpAndSettle();
    expect(find.text('Help & privacy'), findsOneWidget);
    expect(find.text('Terms — owner review required'), findsOneWidget);
  });
}

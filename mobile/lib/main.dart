import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/app.dart';
import 'core/api.dart';
import 'core/providers.dart';
import 'shared/widgets.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final api = Api();
  try {
    await api.initialize();
    runApp(
      ProviderScope(
        overrides: [apiProvider.overrideWithValue(api)],
        child: const ShieldApp(),
      ),
    );
  } catch (_) {
    runApp(
      MaterialApp(
        theme: appTheme(Brightness.light),
        darkTheme: appTheme(Brightness.dark),
        home: Scaffold(
          appBar: AppBar(title: const Brand()),
          body: PageBody(
            children: [
              EmptyState(
                icon: Icons.lock_outline_rounded,
                title: 'Couldn’t open secure storage',
                body:
                    'Check the available storage on your device, then try again.',
                actionLabel: 'Retry',
                onAction: main,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api.dart';

final apiProvider = Provider<Api>(
  (ref) => throw StateError('Api must be initialized'),
);
final themeProvider = NotifierProvider<ThemePreference, ThemeMode>(
  ThemePreference.new,
);

class ThemePreference extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    _load();
    return ThemeMode.system;
  }

  Future<void> _load() async {
    final name = (await SharedPreferences.getInstance()).getString('theme');
    state = ThemeMode.values.firstWhere(
      (v) => v.name == name,
      orElse: () => ThemeMode.system,
    );
  }

  Future<void> set(ThemeMode value) async {
    state = value;
    await (await SharedPreferences.getInstance()).setString(
      'theme',
      value.name,
    );
  }
}

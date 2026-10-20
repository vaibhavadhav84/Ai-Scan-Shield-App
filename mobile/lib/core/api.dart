import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path;

typedef Json = Map<String, dynamic>;

class Api {
  Api({Dio? client, FlutterSecureStorage? storage})
    : dio =
          client ??
          Dio(
            BaseOptions(
              baseUrl: const String.fromEnvironment(
                'API_BASE_URL',
                defaultValue: 'http://10.0.2.2:8000/api/v1',
              ),
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 45),
            ),
          ),
      storage = storage ?? const FlutterSecureStorage();
  final Dio dio;
  final FlutterSecureStorage storage;
  final changed = ValueNotifier(0);
  String? access;
  String? refresh;
  bool onboarded = false;
  Database? cache;
  Future<void>? refreshing;
  String? sharedText;
  static const shareChannel = MethodChannel('dev.scanshield/share');

  Future<void> initialize() async {
    access = await storage.read(key: 'access');
    refresh = await storage.read(key: 'refresh');
    onboarded =
        (await SharedPreferences.getInstance()).getBool('onboarded') ?? false;
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      shareChannel.setMethodCallHandler((call) async {
        if (call.method == 'sharedText' && call.arguments is String) {
          receiveSharedText(call.arguments as String);
        }
      });
      final initial = await shareChannel.invokeMethod<String>(
        'consumeSharedText',
      );
      if (initial != null) receiveSharedText(initial);
    }
    if (!kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS)) {
      cache = await openDatabase(
        path.join(await getDatabasesPath(), 'scan_shield_cache.db'),
        version: 1,
        onCreate: (db, _) => db.execute(
          'CREATE TABLE cache (key TEXT PRIMARY KEY, value TEXT NOT NULL)',
        ),
      );
    }
  }

  Future<void> finishOnboarding() async {
    await (await SharedPreferences.getInstance()).setBool('onboarded', true);
    onboarded = true;
    changed.value++;
  }

  void receiveSharedText(String value) {
    if (value.trim().isEmpty) return;
    sharedText = value.length > 20000 ? value.substring(0, 20000) : value;
    changed.value++;
  }

  String? consumeSharedText() {
    final value = sharedText;
    sharedText = null;
    return value;
  }

  Future<dynamic> request(
    String method,
    String route, {
    dynamic data,
    Json? query,
    bool retry = true,
    void Function(int, int)? onProgress,
  }) async {
    try {
      final response = await dio.request<dynamic>(
        route,
        data: data,
        queryParameters: query,
        onSendProgress: onProgress,
        options: Options(
          method: method,
          headers: access == null ? {} : {'Authorization': 'Bearer $access'},
        ),
      );
      return response.data;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401 &&
          retry &&
          refresh != null &&
          (!route.startsWith('/auth/') ||
              route == '/auth/logout' ||
              route == '/auth/revoke-all')) {
        await (refreshing ??= _refresh().whenComplete(() => refreshing = null));
        return request(
          method,
          route,
          data: data is FormData ? data.clone() : data,
          query: query,
          retry: false,
          onProgress: onProgress,
        );
      }
      rethrow;
    }
  }

  Future<void> _refresh() async {
    try {
      final tokens = await dio.post<Json>(
        '/auth/refresh',
        data: {'token': refresh},
      );
      await saveTokens(tokens.data!);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) await clearSession();
      rethrow;
    }
  }

  Future<void> saveTokens(Json tokens) async {
    access = tokens['access_token'] as String;
    refresh = tokens['refresh_token'] as String;
    await storage.write(key: 'access', value: access);
    await storage.write(key: 'refresh', value: refresh);
    changed.value++;
  }

  Future<void> login(String email, String password) async {
    final data = await request(
      'POST',
      '/auth/login',
      data: {'email': email.trim(), 'password': password},
    );
    await clearCache();
    await saveTokens(Map<String, dynamic>.from(data));
  }

  Future<void> clearCache() async {
    await cache?.delete('cache');
  }

  Future<void> clearSession() async {
    sharedText = null;
    access = refresh = null;
    await storage.delete(key: 'access');
    await storage.delete(key: 'refresh');
    await clearCache();
    changed.value++;
  }

  Future<void> logout() async {
    await request('POST', '/auth/logout');
    await clearSession();
  }

  Future<Json> get(String route, {Json? query, bool allowCache = false}) async {
    final key = '$route:${jsonEncode(query)}';
    try {
      final data = Map<String, dynamic>.from(
        await request('GET', route, query: query),
      );
      if (allowCache && cache != null) {
        await cache!.insert('cache', {
          'key': key,
          'value': jsonEncode({
            'data': data,
            'cached_at': DateTime.now().millisecondsSinceEpoch,
          }),
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
      return data;
    } on DioException catch (e) {
      if (allowCache && cache != null && e.response == null) {
        final rows = await cache!.query(
          'cache',
          where: 'key = ?',
          whereArgs: [key],
        );
        if (rows.isNotEmpty) {
          final saved = jsonDecode(rows.first['value'] as String) as Json;
          final age =
              DateTime.now().millisecondsSinceEpoch -
              (saved['cached_at'] as int);
          if (age <= const Duration(hours: 24).inMilliseconds) {
            return {
              ...Map<String, dynamic>.from(saved['data']),
              'offline_cache': true,
            };
          }
        }
      }
      rethrow;
    }
  }

  Future<Json> scan(Json input) async =>
      Map<String, dynamic>.from(await request('POST', '/scans', data: input));

  Future<void> deleteScan(String id) async {
    await request('DELETE', '/scans/$id');
    await clearCache();
  }
}

String errorMessage(Object error) {
  if (error is StateError && error.message == 'File too large') {
    return 'This file is too large. Choose a WAV up to 10 MB or an email file up to 512 KB.';
  }
  if (error is DioException) {
    if ({
      DioExceptionType.connectionTimeout,
      DioExceptionType.sendTimeout,
      DioExceptionType.receiveTimeout,
    }.contains(error.type)) {
      return 'The service took too long to respond. Your input is still available; check your connection and try again.';
    }
    final data = error.response?.data;
    if (data is Map && data['detail'] is String) {
      return data['detail'] as String;
    }
    if (error.response?.statusCode == 422) {
      return 'Check the input and try again.';
    }
    if (error.response == null) {
      return 'Cannot reach the service. Check your connection and retry.';
    }
    return 'Service request failed (${error.response?.statusCode}). Please retry.';
  }
  return 'This action could not finish. Check permissions and configuration, then retry.';
}

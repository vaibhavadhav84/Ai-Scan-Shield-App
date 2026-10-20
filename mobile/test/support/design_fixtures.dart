// Explicit, deterministic test fixtures. Never imported by production code.
import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scan_shield/core/api.dart';

Json designScan({
  String risk = 'High Risk',
  String channel = 'url',
  String id = 'fixture-scan-001',
}) {
  final score = switch (risk) {
    'Safe' => 12,
    'Suspicious' => 54,
    _ => 86,
  };
  return {
    'id': id,
    'channel': channel,
    'created_at': 1791541800.0,
    'score': score,
    'risk_level': risk,
    'summary': switch (risk) {
      'Safe' =>
        'Few supported risk indicators were found. This does not guarantee safety.',
      'Suspicious' => 'Some indicators deserve a closer look before you act.',
      _ =>
        'The request combines pressure with a request for sensitive information.',
    },
    'recommendations': [
      risk == 'Safe'
          ? 'Verify unfamiliar requests independently.'
          : 'Pause and contact the sender through a trusted channel.',
      'Keep passwords and one-time codes private.',
    ],
    'score_explanation':
        'This score combines supported indicators. It is not a probability of fraud.',
    'indicators': risk == 'Safe'
        ? <Json>[]
        : <Json>[
            {
              'code': 'fixture_sensitive_request',
              'title': 'Request for sensitive information',
              'points': 40,
              'evidence': 'The submitted content requests a private code.',
            },
            {
              'code': 'fixture_pressure',
              'title': 'Pressure to act quickly',
              'points': 20,
              'evidence': 'The request uses an urgent deadline.',
            },
          ],
    'rule_version': 'test-fixture-rules',
    'model_version': null,
    'model_signal': null,
    'reputation': {'status': 'unavailable', 'listed': false},
    'limitations': [
      'Test fixture: no live provider was contacted.',
      'A low score cannot guarantee that a request is legitimate.',
    ],
  };
}

class DesignApi extends Api {
  DesignApi({bool empty = false}) {
    onboarded = true;
    access = 'test-only-session';
    scans = empty
        ? []
        : [
            designScan(),
            designScan(
              risk: 'Suspicious',
              channel: 'email',
              id: 'fixture-scan-002',
            ),
            designScan(risk: 'Safe', channel: 'sms', id: 'fixture-scan-003'),
          ];
  }
  late List<Json> scans;
  final List<({String method, String route, dynamic data, Json? query})> calls =
      [];
  final Map<String, Object> failures = {};
  final Map<String, Completer<Json>> pending = {};
  Json user = {
    'email': 'preview@example.test',
    'display_name': 'Your account',
    'verified': true,
    'alerts_enabled': true,
    'retention_days': 30,
  };
  bool alertRead = false;
  int cacheClears = 0;

  @override
  Future<dynamic> request(
    String method,
    String route, {
    dynamic data,
    Json? query,
    bool retry = true,
    void Function(int, int)? onProgress,
  }) async {
    calls.add((method: method, route: route, data: data, query: query));
    if (failures.containsKey(route)) throw failures[route]!;
    if (pending.containsKey(route)) return pending[route]!.future;
    if (route == '/scans/summary') {
      return {
        'total': scans.length,
        'risk_distribution': {
          for (final level in ['Safe', 'Suspicious', 'High Risk'])
            level: scans.where((scan) => scan['risk_level'] == level).length,
        },
        'channels': {'sms': 1, 'url': 1, 'email': 1},
      };
    }
    if (route == '/capabilities') {
      return {
        'engine': 'rule-baseline',
        'model_version': null,
        'speech': false,
        'reputation': false,
        'email_delivery': false,
        'automatic_monitoring': false,
      };
    }
    if (route == '/scans' && method == 'GET') {
      final filtered = scans
          .where(
            (scan) =>
                (query?['channel'] == null ||
                    query!['channel'] == scan['channel']) &&
                (query?['risk'] == null ||
                    query!['risk'] == scan['risk_level']) &&
                (query?['search'] == null ||
                    scan['id'].toString().contains(
                      query!['search'].toString(),
                    )),
          )
          .toList();
      final offset = query?['offset'] as int? ?? 0;
      final limit = query?['limit'] as int? ?? 20;
      return {
        'total': filtered.length,
        'items': filtered.skip(offset).take(limit).toList(),
      };
    }
    if (route == '/scans' && method == 'POST') {
      return designScan(channel: (data as Json)['channel']);
    }
    if (route == '/scans' && method == 'DELETE') {
      scans.clear();
      return {'message': 'Deleted'};
    }
    if (route.startsWith('/scans/') && method == 'GET') {
      return designScan(id: route.split('/').last);
    }
    if (route == '/users/me' && method == 'GET') return {...user};
    if (route == '/users/me' && method == 'PATCH') {
      user.addAll(Map<String, dynamic>.from(data as Map));
      return {...user};
    }
    if (route == '/alerts' && method == 'GET') {
      return {
        'items': scans.isEmpty
            ? []
            : [
                {
                  'id': 'fixture-alert-001',
                  'scan_id': scans.first['id'],
                  'severity': 'High Risk',
                  'message': 'Review the guidance for this scan.',
                  'read': alertRead,
                  'created_at': 1791541800.0,
                },
              ],
      };
    }
    if (route.endsWith('/read') && method == 'PATCH') {
      alertRead = true;
      return {'message': 'Read'};
    }
    if (route == '/reports' && method == 'GET') {
      return {
        'items': scans.isEmpty
            ? []
            : [
                {
                  'id': 'fixture-report-001',
                  'scan_id': scans.first['id'],
                  'category': 'credentials',
                  'status': 'submitted',
                  'created_at': 1791541800.0,
                },
              ],
      };
    }
    return {'message': 'Request completed.', 'delivery': 'Test delivery only'};
  }

  @override
  Future<void> login(String email, String password) async {
    await request(
      'POST',
      '/auth/login',
      data: {'email': email, 'password': password},
    );
    access = 'test-only-session';
    changed.value++;
  }

  @override
  Future<void> clearCache() async {
    cacheClears++;
  }

  @override
  Future<void> clearSession() async {
    access = null;
    sharedText = null;
    changed.value++;
  }
}

DioException offlineFixture() => DioException(
  requestOptions: RequestOptions(path: '/test-only'),
  type: DioExceptionType.connectionError,
);

// Platform transports are isolated here; these tests do not claim microphone,
// audio playback, native file pickers, or clipboard permission validation.
void installDesignPlatformFakes({
  Future<bool> Function()? microphonePermission,
  void Function()? onRecordingStart,
  void Function()? onRecordingStop,
}) {
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  void emptyEvents(String channel) => messenger.setMockMethodCallHandler(
    MethodChannel(channel),
    (_) async => null,
  );
  emptyEvents('xyz.luan/audioplayers.global/events');
  messenger.setMockMethodCallHandler(
    const MethodChannel('xyz.luan/audioplayers.global'),
    (_) async => null,
  );
  messenger.setMockMethodCallHandler(
    const MethodChannel('xyz.luan/audioplayers'),
    (call) async {
      final args = call.arguments;
      if (call.method == 'create' && args is Map) {
        emptyEvents('xyz.luan/audioplayers/events/${args['playerId']}');
      }
      return null;
    },
  );
  messenger.setMockMethodCallHandler(
    const MethodChannel('com.llfbandit.record/messages'),
    (call) async {
      final args = call.arguments;
      if (call.method == 'create' && args is Map) {
        emptyEvents('com.llfbandit.record/events/${args['recorderId']}');
      }
      if (call.method == 'hasPermission') {
        return microphonePermission == null
            ? false
            : await microphonePermission();
      }
      if (call.method == 'start') onRecordingStart?.call();
      if (call.method == 'stop') onRecordingStop?.call();
      if (call.method == 'isRecording' || call.method == 'isPaused') {
        return false;
      }
      return null;
    },
  );
}

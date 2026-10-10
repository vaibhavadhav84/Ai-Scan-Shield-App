import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:scan_shield/core/api.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('configured backend scan lifecycle', (tester) async {
    // Dedicated integration account created and deleted during the journey.
    final api = Api();
    await api.initialize();
    final email =
        'integration-${DateTime.now().millisecondsSinceEpoch}@example.com';
    const password = 'integration-password-strong';
    await api.request(
      'POST',
      '/auth/register',
      data: {'email': email, 'password': password},
    );
    await api.login(email, password);
    try {
      final scan = await api.scan({
        'channel': 'sms',
        'content':
            'Send your OTP immediately or your bank account will be blocked.',
      });
      expect(scan['risk_level'], 'High Risk');
      final history = await api.get('/scans');
      expect(
        (history['items'] as List).any((s) => s['id'] == scan['id']),
        true,
      );
      await api.request(
        'PUT',
        '/scans/${scan['id']}/feedback',
        data: {'verdict': 'correct'},
      );
      await api.request(
        'POST',
        '/reports',
        data: {'scan_id': scan['id'], 'category': 'credentials'},
      );
      await api.deleteScan(scan['id']);
      expect((await api.get('/scans'))['total'], 0);
    } finally {
      await api.request('DELETE', '/users/me', data: {'password': password});
      await api.clearSession();
    }
  });
}

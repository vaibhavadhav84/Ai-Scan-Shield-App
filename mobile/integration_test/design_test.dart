import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import '../test/design_screens_test.dart';
import '../test/app_test.dart' as existing;
import 'backend_journey_test.dart' as backend;

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  group('Real backend journey', backend.main);
  group('Existing application checks', existing.main);
  group('Design screen verification', () {
    registerDesignTests(
      capture: (tester, name) async {
        await binding.convertFlutterSurfaceToImage();
        await tester.pump();
        await binding.takeScreenshot(name);
      },
    );
  });
}

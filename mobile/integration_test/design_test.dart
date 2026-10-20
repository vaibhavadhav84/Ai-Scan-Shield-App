import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
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
        await tester.pump();
        // Capture the actual Flutter render tree at the test viewport size.
        // Android's surface-to-image callback stalls on this emulator.
        final boundary =
            designCaptureKey.currentContext!.findRenderObject()!
                as RenderRepaintBoundary;
        final image = await boundary.toImage(pixelRatio: 1);
        try {
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          binding.reportData ??= {};
          final screenshots =
              binding.reportData!.putIfAbsent(
                    'screenshots',
                    () => <Map<String, dynamic>>[],
                  )
                  as List<Map<String, dynamic>>;
          screenshots.add({
            'screenshotName': name,
            'bytes': bytes!.buffer.asUint8List().toList(),
          });
        } finally {
          image.dispose();
        }
      },
    );
  });
}

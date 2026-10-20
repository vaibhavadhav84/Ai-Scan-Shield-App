import 'dart:io';
import 'package:integration_test/integration_test_driver_extended.dart';

Future<void> main() async {
  final output = Directory('../artifacts/design');
  await output.create(recursive: true);
  await integrationDriver(
    writeResponseOnFailure: true,
    onScreenshot: (name, bytes, [args]) async {
      await File('${output.path}/$name.png').writeAsBytes(bytes);
      return true;
    },
    responseDataCallback: (data) async {
      final summary = <String, dynamic>{...?data};
      final screenshots = summary['screenshots'];
      if (screenshots is List) {
        summary['screenshots'] = [
          for (final entry in screenshots)
            {
              'name': entry['screenshotName'],
              'bytes': (entry['bytes'] as List).length,
            },
        ];
      }
      await writeResponseData(
        summary,
        destinationDirectory: output.path,
        testOutputFilename: 'integration-response',
      );
    },
  );
}

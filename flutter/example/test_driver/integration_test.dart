import 'dart:convert';
import 'dart:io';
import 'package:integration_test/integration_test_driver_extended.dart';
Future<void> main() => integrationDriver(
  onScreenshot: (String name, List<int> bytes, [Map<String, Object?>? args]) async {
    final folder = Directory('build/android-motion'); await folder.create(recursive: true);
    await File('${folder.path}/$name.png').writeAsBytes(bytes);
    return true;
  },
  responseDataCallback: (data) async {
    final folder = Directory('build/android-motion'); await folder.create(recursive: true);
    await File('${folder.path}/timings.json').writeAsString(const JsonEncoder.withIndent('  ').convert(data));
  },
);

import 'dart:convert';
import 'dart:io';
import 'package:integration_test/integration_test_driver.dart';
Future<void> main() => integrationDriver(responseDataCallback: (data) async {
  final folder = Directory('build/android-motion'); await folder.create(recursive: true);
  await File('${folder.path}/timings.json').writeAsString(const JsonEncoder.withIndent('  ').convert(data));
});

import 'dart:io';
import 'package:test/test.dart';

void main() {
  test('unpub_next --help includes override-uploader-email option', () async {
    final result = await Process.run(Platform.executable, [
      'bin/unpub_next.dart',
      '--help',
    ]);
    expect(result.exitCode, 0);
    expect(result.stdout, contains('Usage: unpub_next [options]'));
    expect(result.stdout, contains('--override-uploader-email'));
    expect(result.stdout, contains('-e,'));
  });

  test('unpub --help backward-compatibility forwarding', () async {
    final result = await Process.run(Platform.executable, [
      'bin/unpub.dart',
      '--help',
    ]);
    expect(result.exitCode, 0);
    expect(result.stdout, contains('--override-uploader-email'));
  });
}

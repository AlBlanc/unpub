import 'dart:io';
import 'package:test/test.dart';
import '../bin/unpub_next.dart';

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

  group('resolveMongoUri', () {
    test('uses default when no cli and no env', () {
      final uri = resolveMongoUri(
        defaultUri: defaultDbUri,
        cliUri: defaultDbUri,
        env: {},
      );
      expect(uri, defaultDbUri);
    });

    test('prefers custom cli argument', () {
      final uri = resolveMongoUri(
        defaultUri: defaultDbUri,
        cliUri: 'mongodb://custom:27017/db',
        env: {'MONGO_URL': 'mongodb://env:27017/db'},
      );
      expect(uri, 'mongodb://custom:27017/db');
    });

    test('uses DB_URL or MONGO_URL when cli is default', () {
      final uri = resolveMongoUri(
        defaultUri: defaultDbUri,
        cliUri: defaultDbUri,
        env: {'MONGO_URL': 'mongodb://mongo-host:27017/unpub_db'},
      );
      expect(uri, 'mongodb://mongo-host:27017/unpub_db');
    });

    test('constructs URI from user and password credentials', () {
      final uri = resolveMongoUri(
        defaultUri: defaultDbUri,
        cliUri: defaultDbUri,
        env: {
          'MONGO_HOST': 'db.example.com',
          'MONGO_PORT': '27018',
          'MONGO_USER': 'admin',
          'MONGO_PASSWORD': 'secret@password',
          'MONGO_DB': 'prod_pub',
          'MONGO_AUTH_SOURCE': 'admin',
        },
      );
      expect(
        uri,
        'mongodb://admin:secret%40password@db.example.com:27018/prod_pub?authSource=admin',
      );
    });
  });
}

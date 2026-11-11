import 'dart:io';
import 'dart:convert';
import 'package:path/path.dart' as path;
import 'package:http/http.dart' as http;
import 'package:unpub_next/unpub.dart' as unpub;
import 'package:mongo_dart/mongo_dart.dart';

final notExistingPacakge = 'not_existing_package';
final baseDir = path.absolute('unpub-packages');
final testPort =
    int.tryParse(Platform.environment['UNPUB_TEST_PORT'] ?? '4000') ?? 4000;
final pubHostedUrl = 'http://localhost:$testPort';
final baseUri = Uri.parse(pubHostedUrl);

final package0 = 'package_0';
final package1 = 'package_1';
final email0 = 'email0@example.com';
final email1 = 'email1@example.com';
final email2 = 'email2@example.com';
final email3 = 'email3@example.com';

createServer(String opEmail) async {
  final db = Db('mongodb://localhost:27017/dart_pub_test');
  await db.open();
  var mongoStore = unpub.MongoStore(db);

  var app = unpub.App(
    metaStore: mongoStore,
    packageStore: unpub.FileStore(baseDir),
    overrideUploaderEmail: opEmail,
  );

  var server = await app.serve('0.0.0.0', testPort);
  return server;
}

Future<http.Response> getVersions(String package) {
  package = Uri.encodeComponent(package);
  return http.get(baseUri.resolve('/api/packages/$package'));
}

Future<http.Response> getSpecificVersion(String package, String version) {
  package = Uri.encodeComponent(package);
  version = Uri.encodeComponent(version);
  return http.get(baseUri.resolve('/api/packages/$package/versions/$version'));
}

Future<ProcessResult> pubPublish(String name, String version) {
  return Process.run(
    'dart',
    ['pub', 'publish', '--force'],
    workingDirectory: path.absolute('test/fixtures', name, version),
    environment: {'PUB_HOSTED_URL': pubHostedUrl},
  );
}

Future<ProcessResult> pubUploader(
  String name,
  String operation,
  String email,
) async {
  assert(['add', 'remove'].contains(operation), 'operation error');

  http.Response res;
  if (operation == 'add') {
    res = await http.post(
      baseUri.resolve('/api/packages/$name/uploaders'),
      headers: {
        HttpHeaders.contentTypeHeader: 'application/x-www-form-urlencoded',
      },
      body: {'email': email},
    );
  } else {
    res = await http.delete(
      baseUri.resolve(
        '/api/packages/$name/uploaders/${Uri.encodeComponent(email)}',
      ),
    );
  }

  String stderr = '';
  String stdout = '';
  if (res.statusCode >= 400) {
    try {
      var data = json.decode(res.body);
      stderr = data['error']?['message'] ?? res.body;
    } catch (_) {
      stderr = res.body;
    }
  } else {
    stdout = res.body;
  }

  return ProcessResult(0, res.statusCode, stdout, stderr);
}

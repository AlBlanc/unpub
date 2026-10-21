import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:args/args.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:unpub_next/unpub_next.dart' as unpub;

Future<void> main(List<String> args) async {
  final parser = ArgParser()
    ..addFlag('help', negatable: false, help: 'Print this usage information.')
    ..addOption('host', abbr: 'h', defaultsTo: '0.0.0.0')
    ..addOption('port', abbr: 'p', defaultsTo: '4000')
    ..addOption(
      'database',
      abbr: 'd',
      defaultsTo: 'mongodb://localhost:27017/dart_pub',
    )
    ..addOption('proxy-origin', abbr: 'o', defaultsTo: '')
    ..addOption(
      'override-uploader-email',
      abbr: 'e',
      help: 'Override the uploader email address for published packages.',
    );

  final results = parser.parse(args);

  if (results['help'] as bool) {
    print('Usage: unpub_next [options]\n');
    print(parser.usage);
    exit(0);
  }

  if (results.rest.isNotEmpty) {
    print('Got unexpected arguments: "${results.rest.join(' ')}".\n\nUsage:\n');
    print(parser.usage);
    exit(1);
  }

  final host = results['host'] as String;
  final port = int.parse(results['port'] as String);
  final dbUri = results['database'] as String;
  final proxyOrigin = results['proxy-origin'] as String;
  final overrideUploaderEmailOption =
      (results['override-uploader-email'] as String?)?.trim();
  final overrideUploaderEmail = overrideUploaderEmailOption?.isEmpty ?? true
      ? null
      : overrideUploaderEmailOption;

  final db = Db(dbUri);
  await db.open();

  final baseDir = path.absolute('unpub-packages');

  final app = unpub.App(
    metaStore: unpub.MongoStore(db),
    packageStore: unpub.FileStore(baseDir),
    proxy_origin: proxyOrigin.trim().isEmpty ? null : Uri.parse(proxyOrigin),
    overrideUploaderEmail: overrideUploaderEmail,
  );

  final server = await app.serve(host, port);
  print('Serving at http://${server.address.host}:${server.port}');
}

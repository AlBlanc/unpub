import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:args/args.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:unpub_next/unpub_next.dart' as unpub;

const defaultDbUri = 'mongodb://localhost:27017/dart_pub';

String resolveMongoUri({
  required String defaultUri,
  String? cliUri,
  Map<String, String>? env,
}) {
  env ??= Platform.environment;

  // 1. If explicit CLI argument was provided and is not the default value
  if (cliUri != null && cliUri != defaultUri) {
    return cliUri;
  }

  // 2. Check full URI environment variables
  final envUri =
      env['MONGODB_URI'] ?? env['MONGO_URL'] ?? env['UNPUB_DATABASE'];
  if (envUri != null && envUri.trim().isNotEmpty) {
    return envUri.trim();
  }

  // 3. Check individual components
  final user =
      env['MONGO_USER'] ?? env['MONGODB_USER'] ?? env['MONGO_USERNAME'];
  final password = env['MONGO_PASSWORD'] ?? env['MONGODB_PASSWORD'];
  final host = env['MONGO_HOST'] ?? env['MONGODB_HOST'] ?? 'localhost';
  final port = env['MONGO_PORT'] ?? env['MONGODB_PORT'] ?? '27017';
  final dbName = env['MONGO_DB'] ?? env['MONGODB_DATABASE'] ?? 'dart_pub';
  final authSource = env['MONGO_AUTH_SOURCE'] ?? env['MONGODB_AUTH_SOURCE'];

  if (user != null && password != null && user.isNotEmpty) {
    final encUser = Uri.encodeComponent(user);
    final encPass = Uri.encodeComponent(password);
    var uri = 'mongodb://$encUser:$encPass@$host:$port/$dbName';
    if (authSource != null && authSource.isNotEmpty) {
      uri += '?authSource=$authSource';
    }
    return uri;
  }

  // 4. If host or port was provided in ENV without credentials
  if (env['MONGO_HOST'] != null || env['MONGODB_HOST'] != null) {
    return 'mongodb://$host:$port/$dbName';
  }

  // 5. Fallback to CLI option or default
  return cliUri ?? defaultUri;
}

Future<void> main(List<String> args) async {
  final env = Platform.environment;

  final defaultHost = env['UNPUB_HOST'] ?? env['HOST'] ?? '0.0.0.0';
  final defaultPort = env['UNPUB_PORT'] ?? env['PORT'] ?? '4000';
  final defaultProxyOrigin =
      env['UNPUB_PROXY_ORIGIN'] ?? env['PROXY_ORIGIN'] ?? '';
  final defaultEmail =
      env['OVERRIDE_UPLOADER_EMAIL'] ??
      env['UNPUB_OVERRIDE_UPLOADER_EMAIL'] ??
      '';

  final parser = ArgParser()
    ..addFlag('help', negatable: false, help: 'Print this usage information.')
    ..addOption('host', abbr: 'h', defaultsTo: defaultHost)
    ..addOption('port', abbr: 'p', defaultsTo: defaultPort)
    ..addOption(
      'database',
      abbr: 'd',
      defaultsTo: defaultDbUri,
      help:
          'MongoDB connection URI. Can also be set via MONGO_URL, MONGODB_URI or MONGO_USER/MONGO_PASSWORD env vars.',
    )
    ..addOption(
      'proxy-origin',
      abbr: 'o',
      defaultsTo: defaultProxyOrigin,
      help: 'Base URL if served behind a reverse proxy.',
    )
    ..addOption(
      'override-uploader-email',
      abbr: 'e',
      defaultsTo: defaultEmail.isEmpty ? null : defaultEmail,
      help:
          'Override the uploader email address for published packages. Can also be set via OVERRIDE_UPLOADER_EMAIL env var.',
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
  final cliDbUri = results['database'] as String;
  final dbUri = resolveMongoUri(
    defaultUri: defaultDbUri,
    cliUri: cliDbUri,
    env: env,
  );

  final proxyOrigin = results['proxy-origin'] as String;
  final overrideUploaderEmailOption =
      (results['override-uploader-email'] as String?)?.trim();
  final overrideUploaderEmail = overrideUploaderEmailOption?.isEmpty ?? true
      ? null
      : overrideUploaderEmailOption;

  final db = Db(dbUri);
  var retries = 15;
  while (true) {
    try {
      await db.open();
      break;
    } catch (e) {
      retries--;
      if (retries <= 0) {
        print('Failed to connect to MongoDB at $dbUri: $e');
        rethrow;
      }
      print('Waiting for MongoDB to be ready... ($retries attempts left)');
      await Future<void>.delayed(const Duration(seconds: 2));
    }
  }

  final dataDir = env['UNPUB_DATA_DIR'] ?? 'unpub-packages';
  final baseDir = path.absolute(dataDir);

  final app = unpub.App(
    metaStore: unpub.MongoStore(db),
    packageStore: unpub.FileStore(baseDir),
    proxy_origin: proxyOrigin.trim().isEmpty ? null : Uri.parse(proxyOrigin),
    overrideUploaderEmail: overrideUploaderEmail,
  );

  final server = await app.serve(host, port);
  print('Serving at http://${server.address.host}:${server.port}');
}

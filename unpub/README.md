# unpub_next

[![pub](https://img.shields.io/pub/v/unpub_next.svg)](https://pub.dev/packages/unpub_next)

> [!NOTE]
> **Fork Notice**: `unpub_next` is an actively maintained fork of [`pd4d10/unpub`](https://github.com/pd4d10/unpub) (which was no longer actively maintained).
> All dependencies have been updated to modern versions and the codebase has been modernized to leverage Dart 3 features.

`unpub_next` is a self-hosted private Dart Pub server for Enterprise, with a simple web interface to search and view packages information.

## Screenshots

![Screenshot](https://raw.githubusercontent.com/bytedance/unpub/master/assets/screenshot.png)

## Usage

### Docker & Docker Compose (Recommended for local / production)

You can run `unpub_next` alongside a MongoDB container with a single command:

```sh
docker compose up -d
```

Access the server and web UI at: **`http://localhost:4000`**.

#### Environment Variables

You can configure the deployment via environment variables or a `.env` file (see `.env.example`):

| Variable | Description | Default |
| --- | --- | --- |
| `MONGO_URL` / `MONGODB_URI` | Full MongoDB connection URI | - |
| `MONGO_HOST` | MongoDB hostname | `mongo` (or `localhost`) |
| `MONGO_PORT` | MongoDB port | `27017` |
| `MONGO_DB` | MongoDB database name | `dart_pub` |
| `MONGO_USER` | MongoDB username (optional) | `admin` |
| `MONGO_PASSWORD` | MongoDB password (optional) | `secretpassword` |
| `MONGO_AUTH_SOURCE` | MongoDB auth source database | `admin` |
| `OVERRIDE_UPLOADER_EMAIL` | Override uploader email for published packages | - |
| `UNPUB_PORT` | Port to expose | `4000` |
| `UNPUB_HOST` | Host address to bind | `0.0.0.0` |
| `UNPUB_PROXY_ORIGIN` | Public base URL (for reverse proxies) | `http://localhost:4000` |
| `UNPUB_DATA_DIR` | Directory for tarball packages storage | `/app/data` |

#### Dockerfile

Build and run the standalone container directly:

```sh
docker build -t unpub_next .
docker run -d -p 4000:4000 \
  -e MONGO_URL="mongodb://host.docker.internal:27017/dart_pub" \
  -e OVERRIDE_UPLOADER_EMAIL="admin@example.com" \
  -v unpub_data:/app/data \
  unpub_next
```

---

### Command Line

```sh
dart pub global activate unpub_next
unpub_next --database mongodb://localhost:27017/dart_pub # Replace this with production database uri
```

> The command `unpub` is also available as an alias for backwards compatibility.

Options:
- `--help`: Print CLI usage options.
- `-h, --host`: Host to bind to (default: `0.0.0.0`).
- `-p, --port`: Port to listen on (default: `4000`).
- `-d, --database`: MongoDB connection URI (default: `mongodb://localhost:27017/dart_pub` or `MONGO_URL`).
- `-o, --proxy-origin`: Base URL if served behind a reverse proxy.
- `-e, --override-uploader-email`: Override the uploader email address for published packages.

`unpub_next` uses MongoDB as meta information store and the file system as package (tarball) store by default.

Dart API is also available for further customization.

### Dart API

```dart
import 'package:mongo_dart/mongo_dart.dart';
import 'package:unpub_next/unpub_next.dart' as unpub;

Future<void> main(List<String> args) async {
  final db = Db('mongodb://localhost:27017/dart_pub');
  await db.open(); // make sure the MongoDB connection opened

  final app = unpub.App(
    metaStore: unpub.MongoStore(db),
    packageStore: unpub.FileStore('./unpub-packages'),
  );

  final server = await app.serve('0.0.0.0', 4000);
  print('Serving at http://${server.address.host}:${server.port}');
}
```

### Options

| Option | Description | Default |
| --- | --- | --- |
| `metaStore` (Required) | Meta information store | - |
| `packageStore` (Required) | Package(tarball) store | - |
| `upstream` | Upstream url | https://pub.dev |
| `googleapisProxy` | Http(s) proxy to call googleapis (to get uploader email) | - |
| `overrideUploaderEmail` | Override uploader email address | - |
| `uploadValidator` | See [Package validator](#package-validator) | - |


### Usage behind reverse-proxy

Using unpub behind reverse proxy(nginx or another), ensure you have necessary headers
```sh
proxy_set_header X-Forwarded-Host $host;
proxy_set_header X-Forwarded-Server $host;
proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
proxy_set_header X-Forwarded-Proto $scheme;

# Workaround for: 
# Asynchronous error HttpException: 
# Trying to set 'Transfer-Encoding: Chunked' on HTTP 1.0 headers
proxy_http_version 1.1;
```

### Package validator

Naming conflicts is a common issue for private registry. A reasonable solution is to add prefix to reduce conflict probability.

With `uploadValidator` you could check if uploaded package is valid.

```dart
var app = unpub.App(
  // ...
  uploadValidator: (Map<String, dynamic> pubspec, String uploaderEmail) {
    // Only allow packages with some specified prefixes to be uploaded
    var prefix = 'my_awesome_prefix_';
    var name = pubspec['name'] as String;
    if (!name.startsWith(prefix)) {
      throw 'Package name should starts with $prefix';
    }

    // Also, you can check if uploader email is valid
    if (!uploaderEmail.endsWith('@your-company.com')) {
      throw 'Uploader email invalid';
    }
  }
);
```

### Customize meta and package store

`unpub_next` is designed to be extensible. It is quite easy to customize your own meta store and package store.

```dart
import 'package:unpub_next/unpub_next.dart' as unpub;

class MyAwesomeMetaStore extends unpub.MetaStore {
  // Implement methods of MetaStore abstract class
  // ...
}

class MyAwesomePackageStore extends unpub.PackageStore {
  // Implement methods of PackageStore abstract class
  // ...
}

// Then use it
var app = unpub.App(
  metaStore: MyAwesomeMetaStore(),
  packageStore: MyAwesomePackageStore(),
);
```

#### Available Package Stores

1. [unpub_next_aws](https://github.com/bytedance/unpub/tree/master/unpub_next_aws): AWS S3 package store.

## Badges

| URL | Badge |
| --- | --- |
| `/badge/v/{package_name}` | ![badge example](https://img.shields.io/static/v1?label=unpub&message=0.1.0&color=orange) ![badge example](https://img.shields.io/static/v1?label=unpub&message=1.0.0&color=blue) |
| `/badge/d/{package_name}` | ![badge example](https://img.shields.io/static/v1?label=downloads&message=123&color=blue) |

## Alternatives

- [pub-dev](https://github.com/dart-lang/pub-dev): Source code of [pub.dev](https://pub.dev), which should be deployed at Google Cloud Platform.
- [pub_server](https://github.com/dart-lang/pub_server): An alpha version of pub server provided by Dart team.

## Credits

- [pd4d10/unpub](https://github.com/pd4d10/unpub): Original unpub project.
- [pub-dev](https://github.com/dart-lang/pub-dev): Web page styles are mostly imported from https://pub.dev directly.
- [shields](https://shields.io): Badges generation.

## License

MIT

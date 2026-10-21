# unpub_aws

A collection of modules to use for deploying `unpub` / `unpub_next` into AWS infrastructure.

> [!NOTE]
> **Fork Notice**: This is part of the `unpub_next` fork from [`pd4d10/unpub`](https://github.com/pd4d10/unpub) (which was no longer actively maintained).
> All dependencies have been updated to modern versions and the code has been modernized with Dart 3 support (including non-blocking streams and removal of deprecated `dart:cli`/`waitFor`).

# Available Features
### 1. [S3 File Storage](#s3-file-storage)


## S3 File Storage

Use AWS S3 or another S3 API compatible endpoint as your package file storage.

```dart
import 'package:unpub_next/unpub_next.dart' as unpub;
import 'package:unpub_aws/unpub_aws.dart' as unpub_aws;

var app = unpub.App(
  // ...
  packageStore: unpub_aws.S3Store('your-bucket-name'),
);
```

### What you need:
- An S3 bucket created in AWS
- AWS access credentials

Authentication for AWS can be handled in 1 of 2 ways: Environment variables or during the `S3Store` class construction.

#### Environment Variables
```dotenv
AWS_ACCESS_KEY_ID=xxxxxxxxxxxxxxxxxxx
AWS_SECRET_ACCESS_KEY=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
AWS_DEFAULT_REGION=us-west-2
AWS_S3_ENDPOINT=s3.amazonaws.com
```


Kitchen Sink Example:

```dart
import 'package:mongo_dart/mongo_dart.dart';
import 'package:unpub_next/unpub_next.dart' as unpub;
import 'package:unpub_aws/unpub_aws.dart' as unpub_aws;

Future<void> main(List<String> args) async {
  final db = Db('mongodb://localhost:27017/dart_pub');
  await db.open(); // make sure the MongoDB connection opened

  final app = unpub.App(
    metaStore: unpub.MongoStore(db),
    packageStore: unpub_aws.S3Store(
      'your-bucket-name',
      endpoint: 's3.amazonaws.com',
      region: 'us-west-2',
      credentials: unpub_aws.AwsCredentials(
        awsAccessKeyId: 'xxxxxxxxxxxxxxxxxxx',
        awsSecretAccessKey: 'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx',
      ),
    ),
  );

  final server = await app.serve('0.0.0.0', 4000);
  print('Serving at http://${server.address.host}:${server.port}');
}
```

## License

MIT

# unpub_auth

An authentication CLI tool for `unpub` / `unpub_next`.

> [!NOTE]
> **Fork Notice**: This is part of the `unpub_next` fork of [`pd4d10/unpub`](https://github.com/pd4d10/unpub) (which was no longer actively maintained).
> All dependencies have been updated to modern versions and the code has been modernized with Dart 3 support.

Since Dart 2.15:

1. The `accessToken` is only sent to https://pub.dev and https://pub.dartlang.org. See [dart-lang/pub #3007](https://github.com/dart-lang/pub/pull/3007) for details.
2. The third-party pub server token is stored in the user's config directory (e.g. `pub-tokens.json`).

So the self-hosted pub server (`unpub_next`) needs its own auth flow. `unpub_next` uses Google OAuth2 by default.

- `unpub_auth login` will generate `unpub-credentials.json` locally after developer login.
- Before calling `dart pub publish` or `flutter pub publish`, call `unpub_auth get | dart pub token add <self-hosted-pub-server>`.
- `unpub_auth get` refreshes the token so you can always use a valid accessToken.

## Usage

### Overview

`unpub_next` uses Google OAuth2 by default. There are two situations where `unpub_auth` can be used:

- **Login locally, and publish packages locally:**
  1. Call `unpub_auth login` when you first use it, which saves credentials locally.
  2. Before calling `dart pub publish` or `flutter pub publish`, call `unpub_auth get | dart pub token add <self-hosted-pub-server>`.

- **Login locally, and publish packages from CI/CD:**
  1. Locally, call `unpub_auth login` to generate the credentials file.
  2. Copy or migrate the credentials file to the CI/CD device using `unpub_auth migrate <credentials-file-path>`.
  3. In the CI/CD pipeline, call `unpub_auth get | dart pub token add <self-hosted-pub-server>` before publishing.

```
Usage: unpub_auth <command> [arguments]

Available commands:
  get             Refresh and get accessToken. Must login first.
  login           Login unpub_auth on Google APIs.
  logout          Delete local credentials file.
  migrate <path>  Migrate existed credentials file from path.
```

### Install and run

```bash
dart pub global activate unpub_auth
```

## License

MIT

# unpub_next Docker Documentation

This directory contains the Docker configuration for **`unpub_next`**, a self-hosted private Dart Pub server.

The container image is built with a multi-stage process:
1. **Build stage**: Compiles `unpub_next` into a native standalone AOT binary (`dart compile exe`) with Dart 3.
2. **Runtime stage**: A lightweight, secure `debian:bookworm-slim` base image containing only CA certificates and the native binary.
3. **Readiness control**: Includes a built-in TCP wait mechanism powered by [`docker-compose-wait`](https://github.com/ufoscout/docker-compose-wait) (similar to [`trevorwang/docker-unpub`](https://github.com/trevorwang/docker-unpub)), ensuring MongoDB is ready to accept connections before `unpub_next` boots.

---

## Quick Start

### 1. Using Docker Compose (Recommended)

From the root of the repository:

```sh
# Start MongoDB and unpub_next
docker compose up -d

# View logs
docker compose logs -f unpub
```

The server and web interface will be accessible at **`http://localhost:4000`**.

### 2. Standalone Docker Build & Run

From the repository root:

```sh
# Build the Docker image
docker build -f docker/Dockerfile -t unpub_next .

# Run with an existing MongoDB instance
docker run -d \
  --name unpub_server \
  -p 4000:4000 \
  -e MONGO_URL="mongodb://mongodb.example.com:27017/dart_pub" \
  -e WAIT_HOSTS="mongodb.example.com:27017" \
  -e UNPUB_OVERRIDE_UPLOADER_EMAIL="admin@example.com" \
  -v unpub_packages:/app/data \
  unpub_next
```

---

## MongoDB Readiness & Wait Mechanism

When running alongside MongoDB, `unpub_next` needs MongoDB to be initialized and actively listening on its port. Relying solely on standard container dependencies (`depends_on`) only waits for container creation, not database readiness.

Following the architecture of `trevorwang/docker-unpub`, this image embeds [`ufoscout/docker-compose-wait`](https://github.com/ufoscout/docker-compose-wait) inside `/wait` and executes it before launching `unpub_next`:

- **Automatic default**: If `WAIT_HOSTS` is not explicitly set but `MONGO_HOST` and `MONGO_PORT` are defined, [`docker/entrypoint.sh`](entrypoint.sh) automatically sets `WAIT_HOSTS="${MONGO_HOST}:${MONGO_PORT}"`.
- **Custom wait targets**: You can wait for multiple hosts or custom timeouts via standard wait environment variables.

### Wait Configuration Options

| Variable | Description | Default |
| --- | --- | --- |
| `WAIT_HOSTS` | Comma-separated list of `host:port` pairs to wait for before starting `unpub_next` (e.g. `mongo:27017`). | Automatically inferred from `MONGO_HOST:MONGO_PORT` |
| `WAIT_HOSTS_TIMEOUT` | Max seconds to wait for targets to open before aborting. | `30` |
| `WAIT_BEFORE` | Seconds to sleep before beginning the first connection check. | `0` |
| `WAIT_AFTER` | Seconds to wait after all ports are confirmed open before executing the app. | `0` |
| `WAIT_SLEEP_INTERVAL` | Seconds between connection attempts. | `1` |

---

## Environment Variables Reference

`unpub_next` supports granular configuration through environment variables or a `.env` file:

### Database Connection

You can provide either a full connection URI or individual connection parameters:

| Variable | Aliases | Description | Default |
| --- | --- | --- | --- |
| `MONGO_URL` | `MONGODB_URI`, `DB_URL`, `UNPUB_DATABASE` | Full MongoDB connection string (e.g. `mongodb://user:pass@mongo:27017/dart_pub?authSource=admin`). Overrides individual parameters if specified. | - |
| `MONGO_HOST` | `MONGODB_HOST` | MongoDB host / IP address. | `mongo` |
| `MONGO_PORT` | `MONGODB_PORT` | MongoDB port. | `27017` |
| `MONGO_DB` | `MONGODB_DATABASE` | MongoDB database name. | `dart_pub` |
| `MONGO_USER` | `MONGO_USERNAME`, `MONGODB_USER` | MongoDB username (optional). | - |
| `MONGO_PASSWORD` | `MONGODB_PASSWORD` | MongoDB password (optional). | - |
| `MONGO_AUTH_SOURCE` | `MONGODB_AUTH_SOURCE` | Authentication source database in MongoDB. | `admin` (if user is provided) |

### Server Configuration

| Variable | Aliases | Description | Default |
| --- | --- | --- | --- |
| `UNPUB_HOST` | `HOST` | Host address to bind the HTTP server to. | `0.0.0.0` |
| `UNPUB_PORT` | `PORT` | Port the server listens on inside the container. | `4000` |
| `UNPUB_PROXY_ORIGIN` | `PROXY_ORIGIN` | Public base URL when deployed behind a reverse proxy (e.g. `https://pub.mycompany.com`). | `http://localhost:4000` |
| `UNPUB_DATA_DIR` | - | Container path for storing uploaded package tarballs. | `/app/data` |

### Package Publishing & Uploaders

| Variable | Aliases | Description | Default |
| --- | --- | --- | --- |
| `UNPUB_OVERRIDE_UPLOADER_EMAIL` | `OVERRIDE_UPLOADER_EMAIL` | Overrides the uploader email on package upload. Essential when publishing without Google OAuth or in automated CI/CD pipelines. | - |

---

## Data Persistence & Volumes

The container exposes a persistent volume:

- **`/app/data`**: Stores package `.tar.gz` tarballs and metadata files created by `unpub.FileStore`.

In `docker-compose.yml`, this volume is mapped to named volume `unpub_data`. To persist packages to a host directory instead, use:

```yaml
volumes:
  - /var/unpub-packages:/app/data
```

---

## Publishing Packages to unpub_next

Once your container is running, developers or CI pipelines can publish Dart/Flutter packages using:

```sh
# Configure pub hosted URL
export PUB_HOSTED_URL="http://localhost:4000"

# Publish the package
dart pub publish
# or for Flutter:
flutter pub publish
```

To consume packages from `unpub_next`, add the hosted URL in `pubspec.yaml`:

```yaml
dependencies:
  my_package:
    hosted:
      name: my_package
      url: http://localhost:4000
    version: ^1.0.0
```

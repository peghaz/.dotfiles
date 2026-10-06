---
name: docker
description: Create or update Docker and Docker Compose setups for application repositories, especially Python or Django services with shared dotenv configuration, databases, reusable builder images, and optional private certificate authorities. Apply for containerization and local multi-service deployment, not ordinary application code changes.
---

# Docker and Docker Compose

Build reproducible application images while keeping secrets and developer-only state outside image layers. Use Docker Compose to describe local or single-host service dependencies, and keep expensive system and Python dependency installation in a deliberately versioned builder image when the repository uses that pattern.

## Repository Layout

Use this layout unless the repository already has an established equivalent:

```text
project-root/
├── .env                    # real local/deployment values; never committed
├── .env.example            # committed variable contract with dummy values
├── .gitignore
├── .dockerignore
├── docker-compose.yaml
└── docker/
    ├── Dockerfile          # application/runtime image
    ├── Dockerfile.builder  # reusable system and Python dependency image
    └── certs/              # optional public CA certificates only
```

Keep the Compose file at the project root so its default project directory, `.env`, paths, and developer commands are predictable. Keep Dockerfiles and Docker-only resources under `docker/`. Do not move existing deployment files merely to enforce naming when that would break an established workflow; update all callers if the user explicitly requests the migration.

## Environment Contract

- Use one root `.env` as the local Compose environment. Add it to both `.gitignore` and `.dockerignore`; never bake it into an image with `COPY`, `ADD`, build arguments, or `ENV` instructions.
- Commit `.env.example`. It must enumerate all required variables with safe dummy values and useful non-secret defaults. Keep it synchronized with application settings and Compose services.
- Understand the two distinct Compose behaviors: root `.env` supplies `${VARIABLE}` interpolation in `docker-compose.yaml`, while a service's `env_file: .env` passes variables into the running container. Use both when the same values are needed by Compose and the process.
- Values under a service's `environment:` override `env_file`. Use that intentionally for non-secret container-topology values such as `POSTGRES_HOST=db`; do not duplicate credentials there.
- The application must validate its environment through its configuration class. For Python, use the sibling [`Python configuration reference`](../python/references/configuration.md).
- Do not print the resolved Compose configuration in logs or CI where substituted secrets could be exposed.
- Build-time secrets must use BuildKit secret mounts or another dedicated secret mechanism. They must not become image layers, build arguments, or committed files.

A useful `.env.example` for a Django service with PostgreSQL and an external LLM can resemble:

```dotenv
COMPOSE_PROJECT_NAME=example-project
BUILDER_IMAGE=example-project-builder
BUILDER_TAG=python3.12-v1
APP_PORT=8000

POSTGRES_DB=example
POSTGRES_USER=example
POSTGRES_PASSWORD=replace-me
POSTGRES_HOST=db
POSTGRES_PORT=5432

DJANGO_SECRET_KEY=replace-me
LLM_ENDPOINT=https://llm.example.invalid/v1
LLM_API_KEY=replace-me
```

If developers also run the application directly on the host, document the network difference: a Compose service reaches PostgreSQL at `db`, while a host process normally reaches it at `localhost`. Prefer a debugger or shell override for the non-secret hostname rather than maintaining two independent secret files. If the application and database always run in Compose, keep `POSTGRES_HOST=db` in `.env`.

## Compose Services

Define services explicitly and keep their responsibilities narrow. A Django/PostgreSQL starting point is:

```yaml
services:
  app:
    build:
      context: .
      dockerfile: docker/Dockerfile
      args:
        BUILDER_IMAGE: ${BUILDER_IMAGE}
        BUILDER_TAG: ${BUILDER_TAG}
    env_file:
      - .env
    environment:
      POSTGRES_HOST: db
    depends_on:
      db:
        condition: service_healthy
    ports:
      - "${APP_PORT:-8000}:8000"
    restart: unless-stopped

  db:
    image: postgres:17
    env_file:
      - .env
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U $$POSTGRES_USER -d $$POSTGRES_DB"]
      interval: 5s
      timeout: 5s
      retries: 12
    volumes:
      - postgres-data:/var/lib/postgresql/data
    restart: unless-stopped

volumes:
  postgres-data:
```

Adapt image versions, health checks, commands, ports, and volumes to the project. Pin production-relevant image versions; do not use `latest`. Do not publish database, Redis, or broker ports to the host unless host access is actually required. A health-based `depends_on` controls startup ordering but does not replace application retry and reconnect behavior.

Use the same application image for Django web, Celery worker, and scheduler services when their dependencies are identical; vary their commands rather than maintaining nearly identical Dockerfiles. Keep database migrations as an explicit one-shot deployment command or service so multiple replicas do not race to run them.

## Reusable Builder Image

`docker/Dockerfile.builder` is a stable dependency image, not an automatic guarantee that Docker never repeats work. Build and tag it separately, then make `docker/Dockerfile` inherit that exact tag. Rebuild it when its base image, operating-system packages, certificates, Python version, `pyproject.toml`, or `uv.lock` changes. Version the tag so the application Dockerfile cannot silently use an unrelated local image.

For a Debian-based Python project, use this shape:

```dockerfile
# syntax=docker/dockerfile:1
FROM ghcr.io/astral-sh/uv:0.9.5 AS uv
FROM python:3.12-slim-bookworm

ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    UV_PROJECT_ENVIRONMENT=/opt/venv \
    UV_LINK_MODE=copy

RUN apt-get update \
    && apt-get install --yes --no-install-recommends \
        build-essential \
        ca-certificates \
        libpq-dev \
    && rm -rf /var/lib/apt/lists/*

COPY --from=uv /uv /uvx /usr/local/bin/
WORKDIR /opt/project

COPY pyproject.toml uv.lock ./
RUN --mount=type=cache,target=/root/.cache/uv \
    uv sync --locked --no-dev --no-install-project

ENV PATH="/opt/venv/bin:$PATH"
```

Pin the actual Python, distribution, and `uv` versions chosen by the project. Install only the system packages required to build or run its dependencies. Keep `apt-get update`, installation, and package-list cleanup in the same layer; do not run a broad operating-system upgrade during an image build.

Build the reusable image first and give it the values documented in `.env`, for example:

```text
docker build --file docker/Dockerfile.builder --tag example-project-builder:python3.12-v1 .
```

The application Dockerfile then installs the current project without repeating the base dependency work:

```dockerfile
# syntax=docker/dockerfile:1
ARG BUILDER_IMAGE
ARG BUILDER_TAG
FROM ${BUILDER_IMAGE}:${BUILDER_TAG}

WORKDIR /opt/project
COPY pyproject.toml uv.lock ./
COPY src/ ./src/
RUN --mount=type=cache,target=/root/.cache/uv \
    uv sync --locked --no-dev

RUN useradd --create-home --uid 10001 app
USER app

CMD ["python", "-m", "project_name"]
```

Copy only files needed at runtime. Adapt the source copy and command for a Django repository, which may require `manage.py`, Django project packages, templates, and static resources rather than a `src/` package. Run the service as a non-root user. Use Gunicorn, Uvicorn, or the project's production ASGI/WSGI server for deployed Django containers; never use `manage.py runserver` as the production command.

If the repository prefers one multi-stage Dockerfile instead of publishing a reusable builder image, preserve that choice unless the user asks for this separate-builder pattern. In either form, copy lock and metadata files before frequently changing source so source edits do not invalidate dependency layers.

## Certificate Authorities

Use `docker/certs/` only for public CA certificates that containers must trust, such as an organization's TLS inspection or internal service CA. Never put private keys, client-identity bundles, passwords, or general credentials there. Require PEM-encoded X.509 certificates with a `.crt` suffix. If a CA is supplied as `.cer`, inspect whether it is PEM or DER and deliberately convert it to the required PEM `.crt` form; renaming alone is not conversion.

Only add certificate instructions when certificate files actually exist. A wildcard `COPY docker/certs/*.crt ...` fails for an empty optional directory.

For Debian or Ubuntu builder images:

```dockerfile
RUN apt-get update \
    && apt-get install --yes --no-install-recommends ca-certificates \
    && rm -rf /var/lib/apt/lists/*
COPY docker/certs/*.crt /usr/local/share/ca-certificates/
RUN update-ca-certificates
```

For RHEL, Rocky Linux, AlmaLinux, or UBI builder images:

```dockerfile
RUN dnf install --assumeyes ca-certificates \
    && dnf clean all
COPY docker/certs/*.crt /etc/pki/ca-trust/source/anchors/
RUN update-ca-trust
```

When the application Dockerfile inherits directly from the prepared builder image, it inherits that trust store. When the final runtime stage starts from another base image, install the CA in that final stage as well. Verify trust from the final runtime image, not only from the builder.

## Ignore Files

At minimum, `.gitignore` must contain:

```gitignore
.env
```

At minimum, `.dockerignore` should exclude secret and developer-only state while retaining files intentionally required by the build:

```dockerignore
.env
.git
.venv
.pytest_cache
.ruff_cache
__pycache__/
*.py[oc]
build/
dist/
datasets/
artifacts/
**/*.key
**/*.pem
```

Do not ignore `.env.example`. Do not ignore intentional public `.crt` files when the builder needs them. Add project-specific local data, generated output, IDE files, and test caches so they cannot invalidate build cache or leak into build context.

## Verification

Before considering the container setup complete:

1. Confirm `.env` is ignored by both Git and the Docker build context, while `.env.example` is tracked and complete.
2. Render the Compose model with its expected environment and inspect service wiring without publishing the resulting secret-expanded output.
3. Build the tagged builder image, then build the application image from it. Confirm a source-only change reuses dependency layers.
4. Start the stack and verify service health, application startup, database persistence, and graceful restart behavior.
5. Run migrations explicitly and verify concurrent application replicas do not each attempt them.
6. If custom CAs are present, make an authenticated TLS request from the final runtime container and verify the intended certificate chain succeeds.
7. Inspect the final image and build history for accidentally copied dotenv files, credentials, development data, or private keys.

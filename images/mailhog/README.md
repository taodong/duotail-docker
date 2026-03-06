MailHog Docker image
====================

This folder contains a modernized Dockerfile to build MailHog using Go 1.26 and produce multi-arch images (including an image suitable for mac/Apple Silicon - linux/arm64).

Quick summary
- Builder: golang:1.26-alpine (uses Alpine 3.23)
- Final image: alpine:3.23 (kept to match the builder for compatibility)
- Default MailHog version: `latest` (changeable via build-arg)

Prerequisites
- Docker (with BuildKit enabled) — Docker Desktop on macOS includes BuildKit by default.
- For multi-arch image manifests: Docker Buildx configured and a registry to push to.

Files
- `Dockerfile` - multi-stage Dockerfile that builds MailHog using Go 1.26 and copies the binary into a small Alpine final image.

How to build

1) Build using the repository script (recommended)

The repo includes `images/image-build.sh`. To build the "mac" variant (linux/arm64) the script appends a `-mac` tag for you:

```bash
cd images
./image-build.sh mailhog --mac
```

2) Build manually with BuildKit (linux/arm64 - Apple Silicon)

```bash
cd images
DOCKER_BUILDKIT=1 docker build --platform=linux/arm64 \
  --build-arg MAILHOG_VERSION=latest \
  -t taojdcn/duotail-mailhog:latest-mac \
  -f mailhog/Dockerfile ./mailhog
```

3) Build for amd64

```bash
DOCKER_BUILDKIT=1 docker build --platform=linux/amd64 \
  --build-arg MAILHOG_VERSION=latest \
  -t taojdcn/duotail-mailhog:latest \
  -f mailhog/Dockerfile ./mailhog
```

4) Build and push a multi-arch image (requires buildx)

```bash
# create or use a buildx builder
docker buildx create --use --name mybuilder || true

# build & push for both amd64 and arm64
docker buildx build --push --platform linux/amd64,linux/arm64 \
  --build-arg MAILHOG_VERSION=latest \
  -t your-registry/your-repo/mailhog:latest \
  -f mailhog/Dockerfile ./mailhog
```

Testing the image

Start the container and test the HTTP UI and SMTP ports:

```bash
# run and map ports
docker run --rm -p 8025:8025 -p 1025:1025 taojdcn/duotail-mailhog:latest-mac

# Then open http://localhost:8025 in your browser to view the MailHog UI
# or curl it:
curl -sS http://localhost:8025/ | head -n 20
```

Verify the binary inside the image (quick check)

```bash
# print help / run the binary inside the image (the container will run MailHog by default)
docker run --rm taojdcn/duotail-mailhog:latest-mac MailHog -h
```

Build args and customization
- `MAILHOG_VERSION` — default: `latest`. Pin a version by passing `--build-arg MAILHOG_VERSION=v1.0.1` (example).
- `TARGETOS` and `TARGETARCH` — supported via Docker BuildKit `--platform` option. Dockerfile defaults to linux/amd64.

Why `alpine:3.23` in the final stage?
- `golang:1.26-alpine` (the builder) is built on Alpine 3.23 (verified in the build environment). Using the same Alpine release in the final stage reduces the risk of runtime incompatibilities caused by differing musl/OS-level files and ensures artifacts produced in the builder run as expected in the final image.
- We still set `CGO_ENABLED=0` to prefer a static Go binary; however, matching base images is a conservative compatibility choice.

Troubleshooting
- "cannot install cross-compiled binaries when GOBIN is set": when building for a different platform, `go install` may fail if `GOBIN` is explicitly set. The Dockerfile unsets `GOBIN` for the install step (RUN GOBIN= go install ...) so the binary lands in `/go/bin`.
- If the copy from builder stage fails (binary not found): ensure the build stage completed successfully and the binary was placed under `/go/bin`. Use `DOCKER_BUILDKIT=1` and `--no-cache` to get fresh results.






#
# MailHog Dockerfile
#

# Modernized MailHog Dockerfile
# - Multi-arch friendly using BuildKit args (TARGETOS/TARGETARCH)
# - Uses a modern Go base image and disables CGO for a static binary

ARG TARGETOS=linux
ARG TARGETARCH=amd64

FROM golang:1.26-alpine AS builder

# Install minimal build tools needed to fetch the module
RUN apk add --no-cache git

# Allow callers to pin a MailHog version (defaults to latest)
ARG MAILHOG_VERSION=latest
ARG TARGETOS
ARG TARGETARCH

# Build environment: produce a static binary suitable for copying into a tiny final image
ENV CGO_ENABLED=0 \
    GOOS=${TARGETOS} \
    GOARCH=${TARGETARCH} \
    GOPATH=/go

# Use module-aware install to place the binary in /go/bin
RUN GOBIN= go install github.com/mailhog/MailHog@${MAILHOG_VERSION}

FROM alpine:3.23
# Add mailhog user/group with uid/gid 1000 (keeps original behavior)
RUN adduser -D -u 1000 mailhog

COPY --from=builder /go/bin/* /usr/local/bin/

USER mailhog

WORKDIR /home/mailhog

ENTRYPOINT ["MailHog"]

# Expose the SMTP and HTTP ports:
EXPOSE 1025 8025
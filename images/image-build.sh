#!/bin/bash

# This script accepts three arguments:
# 1. the product name, which is the name of the directory containing the Dockerfile
# 2. [optional] The tag of the image to build (default: latest) using the -t flag
# 3. [optional]  If the image is build for mac using the --mac flag
# Example usage:
# ./image-build.sh haraka -t 1.0.0 --mac [--build-arg BUILD_ARG=value] [--build-arg BUILD_ARG2=value]
# If no platform is provided, the default platform is linux/amd64, otherwise the platform is linux/arm64
# The default image tag is latest if no tag is provided, however if the platform is mac, the default tag is latest-mac
# Same logic applies when tag is provided, 1.0.0-mac will be used if the platform is mac

if [ -z "$1" ]; then
    echo "Product name is required."
    exit 1
fi

PRODUCT="$1"
shift

if [ ! -d "$PRODUCT" ]; then
    echo "Product directory $PRODUCT does not exist."
    exit 1
fi

IMAGE_TAG="latest"
PLATFORM="linux/amd64"
BUILD_ARGS=()
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -t|--tag) IMAGE_TAG="$2"; shift ;;
        --mac) PLATFORM="linux/arm64" ;;
        --build-arg) BUILD_ARGS+=("$1 $2"); shift ;;
        *) echo "Unknown parameter passed: $1"; exit 1 ;;
    esac
    shift
done

if [ "$PLATFORM" == "linux/arm64" ]; then
    IMAGE_TAG="${IMAGE_TAG}-mac"
fi

# Build the docker image using the Dockerfile under ${PRODUCT} directory
export COMPOSE_DOCKER_CLI_BUILD=0

IMAGE_NAME="taojdcn/duotail-${PRODUCT}:${IMAGE_TAG}"
echo "docker build --platform=\"${PLATFORM}\" -t \"${IMAGE_NAME}\" ${BUILD_ARGS[*]} \"${PRODUCT}\""
docker build --platform="${PLATFORM}" -t "${IMAGE_NAME}" ${BUILD_ARGS[*]} "${PRODUCT}"

echo "Docker image ${IMAGE_NAME} built completed."
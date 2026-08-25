#!/bin/bash

# Exit if any command errors
set -e

if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ]; then
    echo "Usage: $0 <dockerfile-path> <image-tag> <dotnet-version>"
    echo "Example: $0 dockerfiles/abcpdf14.Dockerfile abcpdf14-rc:14 10.0"
    exit 1
fi

DOCKERFILE_PATH="$1"
IMAGE_TAG="$2"
DOTNET_VERSION="$3"

echo "#####################################################
# Build Parameters
# DOCKERFILE_PATH:    ${DOCKERFILE_PATH}
# IMAGE_TAG:          ${IMAGE_TAG}
# DOTNET_VERSION:     ${DOTNET_VERSION}
#####################################################"

echo "Building from: ${DOCKERFILE_PATH}"
echo "Building image: ${IMAGE_TAG}..."
docker build -f "${DOCKERFILE_PATH}" \
    --build-arg DOTNET_VERSION="${DOTNET_VERSION}" \
    -t "${IMAGE_TAG}" \
    ./dockerfiles
echo "Build succeeded for ${IMAGE_TAG}"

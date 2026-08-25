#!/bin/bash

# Orchestrates build + test by calling build-base-image.sh then run-test-app.sh

set -e

if [ -z "$1" ] || [ -z "$2" ]; then
    echo "Usage: $0 <dockerfile-path> <dotnet-version> [abcpdf-version]"
    echo "Example: $0 dockerfiles/abcpdf14.Dockerfile 10 14"
    exit 1
fi

DOCKERFILE_PATH="$1"
DOTNET_MAJOR="$2"
ABCPDF_VERSION="${3:-14}"
DOTNET_VERSION="${DOTNET_MAJOR}.0"

RC_BASE_IMAGE="abcpdf14-rc:$(basename "${DOCKERFILE_PATH}" .Dockerfile)"

DIR="$(cd "$(dirname "$0")" && pwd)"

# Build
bash "${DIR}/build-base-image.sh" "${DOCKERFILE_PATH}" "${RC_BASE_IMAGE}" "${DOTNET_VERSION}"

# Test
bash "${DIR}/run-test-app.sh" "${RC_BASE_IMAGE}" "${DOTNET_MAJOR}" "${ABCPDF_VERSION}"

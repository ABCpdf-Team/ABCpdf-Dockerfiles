#!/bin/bash

# Exit if any command errors
set -e

if [ -z "$1" ] || [ -z "$2" ]; then
    echo "Usage: $0 <dockerfile-path> <dotnet-version> [abcpdf-version]"
    echo "Example: $0 dockerfiles/abcpdf14.Dockerfile 10.0 14"
    exit 1
fi

if [ -z "${ABCPDF_LICENSE_KEY}" ]; then
    echo "Environment variable ABCPDF_LICENSE_KEY must be set."
    exit 1
fi

DOCKERFILE_PATH="$1"
DOTNET_VERSION="$2"
ABCPDF_VERSION="${3:-14}"
TARGET_FWK="net${DOTNET_VERSION}"

BUILD_CONFIGURATION=Release
DOTNET_BUILD_SYMBOLS="ABCPDF_${ABCPDF_VERSION%%.*}"

echo \
"#####################################################
# Test Parameters
# DOCKERFILE_PATH:      ${DOCKERFILE_PATH}
# TARGET_FWK:           ${TARGET_FWK}
# DOTNET_VERSION:       ${DOTNET_VERSION}
# ABCPDF_VERSION:       ${ABCPDF_VERSION}
# DOTNET_BUILD_SYMBOLS: ${DOTNET_BUILD_SYMBOLS}
# BUILD_CONFIGURATION:  ${BUILD_CONFIGURATION}
#####################################################"

RC_BASE_IMAGE="abcpdf14-rc:$(basename "${DOCKERFILE_PATH}" .Dockerfile)"
TEST_APP_IMAGE_TAG="abcpdf_test_app:${TARGET_FWK}-$(basename "${DOCKERFILE_PATH}" .Dockerfile)-abcpdf${ABCPDF_VERSION}"

echo "Building from: ${DOCKERFILE_PATH}"
echo Building release candidate image: ${RC_BASE_IMAGE}...
docker build -f "${DOCKERFILE_PATH}" --build-arg DOTNET_VERSION="${DOTNET_VERSION}" -t "${RC_BASE_IMAGE}" ./dockerfiles
echo Build succeeded for ${RC_BASE_IMAGE}

echo Building test application image: ${TEST_APP_IMAGE_TAG}...
docker build -f ./TestApplication/Dockerfile \
    --build-arg BASE_IMAGE=${RC_BASE_IMAGE} \
    --build-arg TARGET_FWK=${TARGET_FWK} \
    --build-arg ABCPDF_VERSION=${ABCPDF_VERSION}.* \
    --build-arg BUILD_CONFIGURATION=${BUILD_CONFIGURATION} \
    --build-arg SYMBOLS=${DOTNET_BUILD_SYMBOLS} \
    --tag ${TEST_APP_IMAGE_TAG} \
    ./TestApplication
echo Build succeeded for ${TEST_APP_IMAGE_TAG}...


TEST_DESC="$(basename "${DOCKERFILE_PATH}" .Dockerfile) and .NET ${DOTNET_VERSION} using ABCPDF ${ABCPDF_VERSION}"
TEST_APP_CONTAINER_NAME="TestABCpdf-${ABCPDF_VERSION}-${DOTNET_VERSION}-$(basename "${DOCKERFILE_PATH}" .Dockerfile)"

# Remove any previous container with the same name
docker rm --force ${TEST_APP_CONTAINER_NAME} || true # ignore errors

echo Running test image with: ${TEST_APP_CONTAINER_NAME}
docker run --rm --env ABCPDF_LICENSE_KEY=${ABCPDF_LICENSE_KEY} --name ${TEST_APP_CONTAINER_NAME} ${TEST_APP_IMAGE_TAG}
echo "Test succeeded for ${TEST_DESC}"

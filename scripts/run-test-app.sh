#!/bin/bash

# Exit if any command errors
set -e

if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ]; then
    echo "Usage: $0 <base-image-tag> <dotnet-major> <abcpdf-version>"
    echo "Example: $0 abcpdf14-rc:14 10 14"
    exit 1
fi

if [ -z "${ABCPDF_LICENSE_KEY}" ]; then
    echo "Error: ABCPDF_LICENSE_KEY is not set."
    exit 1
fi

BASE_IMAGE_TAG="$1"
DOTNET_MAJOR="$2"
ABCPDF_VERSION="${3:-14}"

DISTRO_PART="${BASE_IMAGE_TAG##*:}"
TEST_APP_IMAGE_TAG="abcpdf_test_app:net${DOTNET_MAJOR}-${DISTRO_PART}-abcpdf${ABCPDF_VERSION}"
TARGET_FWK="net${DOTNET_MAJOR}.0"
BUILD_CONFIGURATION=Release
DOTNET_BUILD_SYMBOLS="ABCPDF_${ABCPDF_VERSION%%.*}"

echo "#####################################################
# Test Parameters
# BASE_IMAGE_TAG:         ${BASE_IMAGE_TAG}
# TEST_APP_IMAGE_TAG:     ${TEST_APP_IMAGE_TAG}
# ABCPDF_VERSION:         ${ABCPDF_VERSION}
# TARGET_FWK:             ${TARGET_FWK}
# DOTNET_BUILD_SYMBOLS:   ${DOTNET_BUILD_SYMBOLS}
# BUILD_CONFIGURATION:    ${BUILD_CONFIGURATION}
#####################################################"

echo "Building test application image: ${TEST_APP_IMAGE_TAG}..."
docker build -f ./TestApplication/Dockerfile \
    --build-arg BASE_IMAGE=${BASE_IMAGE_TAG} \
    --build-arg TARGET_FWK=${TARGET_FWK} \
    --build-arg ABCPDF_VERSION=${ABCPDF_VERSION}.* \
    --build-arg BUILD_CONFIGURATION=${BUILD_CONFIGURATION} \
    --build-arg SYMBOLS=${DOTNET_BUILD_SYMBOLS} \
    --tag ${TEST_APP_IMAGE_TAG} \
    ./TestApplication
echo "Build succeeded for ${TEST_APP_IMAGE_TAG}..."

TEST_DESC="${DISTRO_PART} and .NET ${DOTNET_MAJOR} using ABCPDF ${ABCPDF_VERSION}"
TEST_APP_CONTAINER_NAME="TestABCpdf-${ABCPDF_VERSION}-${DOTNET_MAJOR}-${DISTRO_PART}"

# Remove any previous container with the same name
docker rm --force ${TEST_APP_CONTAINER_NAME} || true # ignore errors

echo "Running test image with: ${TEST_APP_CONTAINER_NAME}"
docker run --rm --env ABCPDF_LICENSE_KEY=${ABCPDF_LICENSE_KEY} --name ${TEST_APP_CONTAINER_NAME} ${TEST_APP_IMAGE_TAG}
echo "Test succeeded for ${TEST_DESC}"

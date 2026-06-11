#!/bin/bash

# Exit if any command errors
set -e

if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ] || [ -z "$4" ]; then
    echo "Usage: $0 <distro-name> <dotnet-version> <abcpdf-version> <rc-image-name:tag>"
    echo "Example: $0 26.04-resolute 10.0 14 abcpdf14-10.0-resolute-rc"
    exit 1
fi

if [ -z "${ABCPDF_LICENSE_KEY}" ]; then
    echo "Environment variable ABCPDF_LICENSE_KEY must be set."
    exit 1
fi

DISTRO=$1
DOTNET_VERSION=$2
ABCPDF_VERSION=$3
RC_BASE_IMAGE=$4

BUILD_CONFIGURATION=Release
DOTNET_BUILD_SYMBOLS="ABCPDF_${ABCPDF_VERSION%%.*}"

echo \
"#####################################################
# Test Parameters
# DISTRO:               ${DISTRO}
# DOTNET_VERSION:       ${DOTNET_VERSION}
# ABCPDF_VERSION:       ${ABCPDF_VERSION}
# DOTNET_BUILD_SYMBOLS: ${DOTNET_BUILD_SYMBOLS}
# BUILD_CONFIGURATION:  ${BUILD_CONFIGURATION}
#####################################################"

TEST_APP_IMAGE_TAG="abcpdf_test_app:${DOTNET_VERSION}-${DISTRO}-abcpdf${ABCPDF_VERSION}"

# Build abcpd/mcr-aspnet RC base image
echo Building release candidate image: ${RC_BASE_IMAGE}...
docker build -f dockerfiles/mcr-aspnet-${DISTRO}.Dockerfile --build-arg DOTNET_VERSION=${DOTNET_VERSION} -t ${RC_BASE_IMAGE} ./dockerfiles
echo Build succeeded for ${RC_BASE_IMAGE}

docker build -f ./TestApplication/Dockerfile \
    --no-cache \
    --progress=plain \
    --build-arg BASE_IMAGE=${RC_BASE_IMAGE} \
    --build-arg TARGET_FWK=net${DOTNET_VERSION} \
    --build-arg ABCPDF_VERSION=${ABCPDF_VERSION}.* \
    --build-arg BUILD_CONFIGURATION=${BUILD_CONFIGURATION} \
    --build-arg SYMBOLS=${DOTNET_BUILD_SYMBOLS} \
    --tag ${TEST_APP_IMAGE_TAG} \
    ./TestApplication

echo Build succeeded for test application

TEST_DESC="${DISTRO} and .NET ${DOTNET_VERSION} using ABCPDF ${ABCPDF_VERSION}"
TEST_APP_CONTAINER_NAME="TestABCpdf-${ABCPDF_VERSION}-${DOTNET_VERSION}-${DISTRO}"

# Remove any previous container with the same name
docker rm --force ${TEST_APP_CONTAINER_NAME} || true # ignore errors

echo Running test for: ${TEST_DESC}

docker run --env ABCPDF_LICENSE_KEY=${ABCPDF_LICENSE_KEY} --name ${TEST_APP_CONTAINER_NAME} ${TEST_APP_IMAGE_TAG}

echo "Test succeeded for ${TEST_DESC}"

#!/bin/bash
set -e

if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ] || [ -z "$4" ] || [ -z "$5" ]; then
    echo "Usage: $0 <distro> <dotnet-version> <abcpdf-version> <abcpdf-chromeversion> <abcpdf-license-key>"
    echo "Example: $0 24.04-noble 10.0 <abcpdf-version> <abcpdf-chromeversion> <abcpdf-license-key>"
    exit 1
fi

# Base image parameters
DISTRO=$1
DOTNET_VERSION=$2

DOCKER_REPO="abcpd/mcr-aspnet"
RC_BASE_IMAGE="${DOCKER_REPO}:${DOTNET_VERSION}-${DISTRO}-rc"
TEST_APPLICATION_IMAGE_TAG="abcpdf_test_app_container:${DOTNET_VERSION}-${DISTRO}"

# Build abcpd/mcr-aspnet RC base image 
echo Building release candidate image for ${DISTRO} / .NET ${DOTNET_VERSION}...
docker build -f dockerfiles/mcr-aspnet-${DISTRO}.Dockerfile --progress=plain --build-arg DOTNET_VERSION=${DOTNET_VERSION} -t ${RC_BASE_IMAGE} ./dockerfiles

if [ $? -ne 0 ]; then
    echo "Error: docker build failed for ${DISTRO} / .NET ${DOTNET_VERSION}" >&2
    exit 1
fi

echo Build succeeded for ${RC_BASE_IMAGE}

# Test application parameters
ABCPDF_VERSION=$3
ABCCHROME_VERSION=$4
ABCPDF_LICENSE_KEY=$5
SYMBOLS="ABCPDF_VERSION${ABCPDF_VERSION%%.*}"
echo SYMBOLS set to ${SYMBOLS}
TEST_APP_IMAGE_TAG="abcpdf_test_app_container:${DOTNET_VERSION}-${DISTRO}-abcpdf${ABCPDF_VERSION}-chrome${ABCCHROME_VERSION}"

echo building docker container for test application using base image ${RC_BASE_IMAGE}...

docker build -f ./TestApplication/Dockerfile \
    --progress=plain \
    --build-arg BASE_IMAGE=${RC_BASE_IMAGE} \
    --build-arg TARGET_FWK=net${DOTNET_VERSION} \
    --build-arg ABCPDF_VERSION=${ABCPDF_VERSION}.* \
    --build-arg ABCCHROME_VERSION=${ABCCHROME_VERSION} \
    --tag ${TEST_APP_IMAGE_TAG} \
    ./TestApplication
    
if [ $? -ne 0 ]; then
    echo "Error: docker build failed for test application image with base ${DISTRO} and .NET ${DOTNET_VERSION}" >&2
    exit 2
fi

echo Build succeeded for test application
TEST_DESC="${DISTRO} and .NET ${DOTNET_VERSION} using ABCPDF ${ABCPDF_VERSION} with Chrome ${ABCCHROME_VERSION}"
docker run --rm --env ABCPDF_LICENSE_KEY=${ABCPDF_LICENSE_KEY} ${TEST_APP_IMAGE_TAG}     

if [ $? -ne 0 ]; then
    echo "Error: Test failed for ${TEST_DESC}" >&2
    exit 3
fi

echo "Test succeeded for ${TEST_DESC}"

# echo Running tests in container using TestContainers.NET ${TEST_APPLICATION_IMAGE_TAG}...
# export TEST_APP_IMAGE_TAG="${TEST_APPLICATION_IMAGE_TAG}"
# export ABCPDF_LICENSE_KEY="[X/VKS0cJn5FgsCJaa6qGaI/wNrdyZOFn/8TBy+LwCl030VOTKXGCDeQ6PTc3hRVyW4oh/T5EojAUyKghTL58y0NBBhegPRp9gVFrEeTQKnzH803sxftUaIT+LGG1bmosUMMRdcdWqD0xSxF6pjLVAFBVH0S7UnLwn6ob91cuDsDOxrUpvTmAjkXNpOlSh25RQ04t7ltZ0SmXJSQIWqlzkk5n8hs=]"
# cd IntegrationTests
# #dotnet restore
# #dotnet build --no-restore
# dotnet test --no-build
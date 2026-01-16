# Testing locally from repository root directory

```bash
# noble 10.0
# Base image
docker build . --file Runtimes/mcr-aspnet-noble.Dockerfile --build-arg DOTNET_VERSION=10.0 -t abcpdf/mcr-aspnet:10.0 -t abcpdf/mcr-aspnet:10.0-noble
# Build and run test app
docker build -f ./Testing/IntegrationTests/Dockerfile --build-arg BASE_IMAGE=abcpdf/mcr-aspnet:10.0-noble --build-arg TARGET_FRAMEWORK=net10.0 --tag abcpdf_test_app_container:10.0-noble ./Testing
docker run abcpdf_test_app_container:10.0-noble -d -p 8888:8080 -e ABCPDF_LICENSE_KEY=[YOUR_LICENSE_KEY_HERE]

# jammy 8.0
# Base image
docker build . --file Runtimes/mcr-aspnet-noble.Dockerfile --build-arg DOTNET_VERSION=8.0 -t abcpdf/mcr-aspnet:8.0 -t abcpdf/mcr-aspnet8.0-jammy
# Build and run test app
docker build -f ./Testing/IntegrationTests/Dockerfile --build-arg BASE_IMAGE=abcpdf/mcr-aspnet:8.0-jammy --build-arg TARGET_FRAMEWORK=net8.0 --tag abcpdf_test_app_container:8.0-jammy ./Testing
docker run abcpdf_test_app_container:8.0-jammy -e ABCPDF_LICENSE_KEY=[YOUR_LICENSE_KEY_HERE]

# bookworm-slim 8.0
# Base image
docker build . --file Runtimes/mcr-aspnet-bookworm-slim.Dockerfile --build-arg DOTNET_VERSION=8.0 -t abcpdf/mcr-aspnet:8.0-bookworm-slim
# Build and run test app
docker build -f ./Testing/IntegrationTests/Dockerfile --build-arg BASE_IMAGE=abcpdf/mcr-aspnet:8.0-bookworm-slim --build-arg TARGET_FRAMEWORK=net8.0 --tag abcpdf_test_app_container:8.0-bookworm-slim ./Testing
docker run abcpdf_test_app_container:8.0-bookworm-slim -e ABCPDF_LICENSE_KEY=[YOUR_LICENSE_KEY_HERE]

# Out-of-support base images
docker build . --file Runtimes/mcr-aspnet-jammy.Dockerfile --build-arg DOTNET_VERSION=6.0 -t abcpdf/mcr-aspnet:6.0 -t abcpdf/mcr-aspnet:6.0-jammy
docker build . --file Runtimes/mcr-aspnet-jammy.Dockerfile --build-arg DOTNET_VERSION=7.0 -t abcpdf/mcr-aspnet:7.0 -t abcpdf/mcr-aspnet:7.0-jammy

docker build . --file Runtimes/mcr-aspnet-bookworm-slim.Dockerfile --build-arg DOTNET_VERSION=6.0 -t abcpdf/mcr-aspnet:6.0-bookworm-slim
docker build . --file Runtimes/mcr-aspnet-bookworm-slim.Dockerfile --build-arg DOTNET_VERSION=7.0 -t abcpdf/mcr-aspnet:7.0-bookworm-slim
```

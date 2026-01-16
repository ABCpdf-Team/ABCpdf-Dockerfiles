# Testing locally

```bash
# Build and push base images: 

# noble 10
docker build . --file Runtimes/mcr-aspnet-noble.Dockerfile --build-arg DOTNET_VERSION=10.0 -t abcpdf/mcr-aspnet:10.0 -t abcpdf/mcr-aspnet:10.0-noble
docker push abcpdf/mcr-aspnet:10.0
docker push abcpdf/mcr-aspnet:10.0-noble

# Build and run test app
docker build -f ./IntegrationTests/Dockerfile --build-arg BASE_IMAGE_RC=abcpdf/mcr-aspnet:10.0-noble --build-arg TARGET_FRAMEWORK=net10.0 --tag abcpdf_test_app_container:10.0-noble .
docker run abcpdf_test_app_container:10.0-noble -d -p8888:8080 -e ABCPDF_LICENSE_KEY=YOUR_LICENSE_KEY_HERE

# noble 9

cd Testing
docker build -f ./IntegrationTests/Dockerfile --build-arg BASE_IMAGE_RC=abcpdf/mcr-aspnet:8.0-jammy --build-arg TARGET_FRAMEWORK=net8.0 --tag abcpdf_test_app_container:8.0-jammy .
docker run abcpdf_test_app_container:8.0-jammy -e ABCPDF_LICENSE_KEY=YOUR_LICENSE_KEY_HERE


docker build -f ./IntegrationTests/Dockerfile --build-arg BASE_IMAGE_RC=abcpdf/mcr-aspnet:8.0-bookworm-slim --build-arg TARGET_FRAMEWORK=net8.0 --tag abcpdf_test_app_container:8.0-bookworm-slim .
docker run abcpdf_test_app_container:8.0-bookworm-slim -e ABCPDF_LICENSE_KEY=YOUR_LICENSE_KEY_HERE



docker build -f ./IntegrationTests/Dockerfile --build-arg BASE_IMAGE_RC=abcpdf/mcr-aspnet:10.0-trixie-slim --build-arg TARGET_FRAMEWORK=net10.0 --tag abcpdf_test_app_container:10.0-trixie-slim .
```

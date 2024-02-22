# docker build . --file ubuntu-22.04-aspnet-8.0.Dockerfile -t abcpdf/ubuntu-22.04-aspnet:8.0
FROM abcpdf/ubuntu-22.04-abcpdf-runtime-deps:latest
RUN apt-get update && apt-get install -y aspnetcore-runtime-8.0
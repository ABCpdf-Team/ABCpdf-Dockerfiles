# docker build . --file ubuntu-22.04-aspnet-7.0.Dockerfile -t abcpdf/ubuntu-22.04-aspnet:7.0
FROM abcpdf/ubuntu-22.04-abcpdf-runtime-deps:latest
RUN apt-get update && apt-get install -y aspnetcore-runtime-7.0
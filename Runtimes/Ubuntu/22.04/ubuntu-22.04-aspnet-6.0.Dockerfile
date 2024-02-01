# docker build . --file ubuntu-22.04-aspnet-6.0.Dockerfile -t abcpdf/ubuntu-22.04-aspnet:6.0
FROM ubuntu:22.04
ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y ca-certificates aspnetcore-runtime-6.0
# Libraries required for ABCpdf native linux components
RUN apt-get install -y libx11-6 libgtk-3-0 libnss3 libdrm2 libgbm1 libasound2 libegl1
# Install a reasonable set of fonts
RUN apt-get install -y fonts-noto-core fonts-noto-mono fonts-noto-color-emoji
RUN fc-cache -f -v
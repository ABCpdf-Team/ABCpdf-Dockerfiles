# docker build . --file ubuntu-22.04-aspnet-7.0.Dockerfile -t abcpdf/ubuntu-22.04-aspnet:7.0
FROM ubuntu:22.04
ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y ca-certificates && apt-get upgrade -y
RUN apt-get install -y aspnetcore-runtime-7.0
# Libraries required for ABCpdf native linux components
RUN apt-get install -y libx11-6 libgtk-3-0 libnss3 libdrm2 libgbm1 libasound2 libegl1
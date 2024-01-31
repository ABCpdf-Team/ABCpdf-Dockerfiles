# docker build . --file ubuntu-22.04-aspnet-8.0.Dockerfile -t abcpdf/ubuntu-22.04-aspnet:8.0
FROM ubuntu:22.04
ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y ca-certificates && apt-get upgrade -y
# As of February 2024 we need to get .NET8 from the Microsoft package repository
RUN apt-get install -y wget
RUN wget https://packages.microsoft.com/config/ubuntu/22.04/packages-microsoft-prod.deb -O packages-microsoft-prod.deb
RUN dpkg -i packages-microsoft-prod.deb
RUN rm packages-microsoft-prod.deb
RUN apt-get remove -y wget
# Remove the above when aspnetcore 8.0 is available from standard sources
RUN apt-get update && apt-get install -y aspnetcore-runtime-8.0 
# Libraries required for ABCpdf native linux components
RUN apt-get install -y libx11-6 libgtk-3-0 libnss3 libdrm2 libgbm1 libasound2 libegl1

# BASE_IMAGE must be specified at build time using --build-arg or in visual studio project properties 
# when using the Docker Tools in VS. 
# The base image should be the runtime image under test built from the Dockerfiles in the dockerfiles folder of this repo.
# NB we get a docker build warning if we don't specify a default value for the BASE_IMAGE ARG 
ARG BASE_IMAGE=invalid-image:invalid-tag 
ARG TARGET_FWK=invalid-target-framework
ARG ABCPDF_VERSION=invalid-version
ARG ABCCHROME_VERSION=invalid-chrome-version

FROM ${BASE_IMAGE} AS base
USER $APP_UID
WORKDIR /app

# This stage is used to build the service project
FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
ARG BUILD_CONFIGURATION=Release
ARG TARGET_FWK
ARG ABCPDF_VERSION
ARG ABCCHROME_VERSION
WORKDIR /src
COPY ["TestApplication.csproj", "."]
RUN dotnet restore "./TestApplication.csproj"
COPY . .
WORKDIR "/src/."
RUN dotnet build "./TestApplication.csproj" -c $BUILD_CONFIGURATION -o /app/build

# This stage is used to publish the service project to be copied to the final stage
FROM build AS publish
ARG BUILD_CONFIGURATION=Release
ARG ABCCHROME_VERSION
RUN dotnet publish "./TestApplication.csproj" -c $BUILD_CONFIGURATION -o /app/publish /p:UseAppHost=false
# This is required to ensure ABCChrome can be launched by user "app" in production
RUN echo "Setting execute permissions for ABCChrome${ABCCHROME_VERSION}..."
RUN chmod o+x /app/publish/ABCChrome${ABCCHROME_VERSION}/ABCChrome${ABCCHROME_VERSION}
# Required for Chrome's setuid sandbox fallback on distros that restrict unprivileged user namespaces
# (Ubuntu 24.04+ / 26.04 via AppArmor). NuGet strips the setuid bit on extraction so it must be restored here.
RUN chown root:root /app/publish/ABCChrome${ABCCHROME_VERSION}/chrome-sandbox \
    && chmod 4755 /app/publish/ABCChrome${ABCCHROME_VERSION}/chrome-sandbox

######################################################################################################################################
# In Docker debug mode the /app folder points to the local project folder. This means linux-native components will not be found. 
# As a workaround for debugging only - we need copy ABCChrome from the 'publish' stage and copy them somewhere in the PATH such as 
# /usr/local/bin.
#
# IMPORTANT
#
#    * For the following debug stage to be used the following property must be set the project file:
#           <PropertyGroup>
#               <DockerfileFastModeStage>debug</DockerfileFastModeStage>
#           </PropertyGroup>
#
#    * The ABCChrome version number WILL need to be changed when later versions of ABCpdf update ABCChrome.
#
#    * The path you copy the native ABCChrome folder must be locatable in the container's PATH.
#
# For more information on debugging in Docker with Visual Studio see:
# https://learn.microsoft.com/en-gb/visualstudio/containers/container-build?view=vs-2022#modify-container-image-only-for-debugging
######################################################################################################################################

FROM base AS debug
ARG ABCCHROME_VERSION
WORKDIR /app
COPY --from=publish /app/publish/ABCChrome${ABCCHROME_VERSION} /usr/local/bin/ABCChrome${ABCCHROME_VERSION}

# This stage is used in production or when running from VS in regular mode (Default when not using the Debug configuration)
FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .
ENTRYPOINT ["dotnet", "TestApplication.dll"]
#SHELL ["/bin/bash", "-c"]
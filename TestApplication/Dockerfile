# BASE_IMAGE must be specified at build time using --build-arg or in visual studio project properties 
# when using the Docker Tools in VS. 
# The base image should be the runtime image under test built from the Dockerfiles in the dockerfiles folder of this repo.
# NB we get a docker build warning if we don't specify a default value for the BASE_IMAGE ARG 
ARG BASE_IMAGE=base-image-not-set
ARG TARGET_FWK=TARGET_FWK_NOT_SET
ARG ABCPDF_VERSION=ABCPDF_VERSION_NOT_SET
ARG BUILD_CONFIGURATION=Release

FROM $BASE_IMAGE AS base
ARG BASE_IMAGE
RUN echo "Using BASE_IMAGE: $BASE_IMAGE"
USER $APP_UID
WORKDIR /app

# NB: ARGs are not properly global and need to be re-referenced in each stage used.
# This stage is used to build the project
FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
ARG BUILD_CONFIGURATION=Release
# Used in Directory.Build.props...
ARG TARGET_FWK
ARG ABCPDF_VERSION
ARG SYMBOLS
RUN echo ${BUILD_CONFIGURATION}
RUN echo "TARGET_FWK: $TARGET_FWK\nABCPDF_VERSION: $ABCPDF_VERSION\nBUILD_CONFIGURATION: $BUILD_CONFIGURATION"
WORKDIR /src
COPY ["TestApplication.csproj", "Directory.Build.props", "./"]
RUN dotnet restore "./TestApplication.csproj"
COPY . .
WORKDIR "/src/."
RUN dotnet build "./TestApplication.csproj" -c $BUILD_CONFIGURATION -o /app/build

# This stage is used to publish the project files to be copied to the final stage
FROM build AS publish
ARG BUILD_CONFIGURATION=Release
RUN dotnet publish "./TestApplication.csproj" -c $BUILD_CONFIGURATION -o /app/publish /p:UseAppHost=false
# This is required to ensure ABCChrome can be launched by user "app" in production
RUN echo "Setting execute permissions for ABCChrome..."
RUN if [ -f /app/publish/ABCChrome123/ABCChrome123 ]; then chmod o+x /app/publish/ABCChrome123/ABCChrome123; fi
RUN if [ -f /app/publish/ABCChrome146/ABCChrome146 ]; then chmod o+x /app/publish/ABCChrome146/ABCChrome146; fi

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
WORKDIR /app
COPY --from=publish /app/publish/ABCChrome123 /usr/local/bin/ABCChrome123
COPY --from=publish /app/publish/ABCChrome146 /usr/local/bin/ABCChrome146

# This stage is used in production or when running from VS in regular mode (Default when not using the Debug configuration)
FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .
ENTRYPOINT [ "dotnet", "TestApplication.dll" ]
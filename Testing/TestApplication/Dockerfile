# See https://aka.ms/customizecontainer to learn how to customize your debug container and how Visual Studio uses this Dockerfile to build your images for faster debugging.
# This stage is used when running from VS in fast mode (Default for Debug configuration)
FROM abcpdf/mcr-aspnet:10.0 AS base
USER $APP_UID
WORKDIR /app
EXPOSE 8080
EXPOSE 8081


# This stage is used to build the service project
FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
ARG BUILD_CONFIGURATION=Release
WORKDIR /src
COPY ["TestApplication/TestApplication.csproj", "TestApplication/"]
RUN dotnet restore "./TestApplication/TestApplication.csproj"
COPY . .
WORKDIR "/src/TestApplication"
RUN dotnet build "./TestApplication.csproj" -c $BUILD_CONFIGURATION -o /app/build

# This stage is used to publish the service project to be copied to the final stage
FROM build AS publish
ARG BUILD_CONFIGURATION=Release
RUN dotnet publish "./TestApplication.csproj" -c $BUILD_CONFIGURATION -o /app/publish /p:UseAppHost=false
# This is required to ensure ABCChrome can be launched by user "app" in production
RUN chmod o+x /app/publish/ABCChrome123/ABCChrome123

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

# This stage is used in production or when running from VS in regular mode (Default when not using the Debug configuration)
FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .
ENTRYPOINT ["dotnet", "TestApplication.dll"]
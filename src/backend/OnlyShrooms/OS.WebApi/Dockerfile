# Build context is the repository root (see DockerfileContext in OS.WebApi.csproj).
# docker build -f src/backend/OnlyShrooms/OS.WebApi/Dockerfile -t onlyshrooms .

# Runtime base image (also used by Visual Studio fast mode)
FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS base
USER root
RUN mkdir -p /data && chown -R $APP_UID:$APP_UID /data
USER $APP_UID
WORKDIR /app
EXPOSE 8080

# Flutter web build
FROM ghcr.io/cirruslabs/flutter:stable AS frontend
WORKDIR /src/frontend
COPY src/frontend/pubspec.yaml src/frontend/pubspec.lock ./
RUN flutter pub get
COPY src/frontend/ ./
RUN flutter build web --release

# .NET build
FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
ARG BUILD_CONFIGURATION=Release
WORKDIR /src/backend/OnlyShrooms
COPY src/backend/OnlyShrooms/ ./
RUN dotnet restore "OS.WebApi/OS.WebApi.csproj"
RUN dotnet build "OS.WebApi/OS.WebApi.csproj" -c $BUILD_CONFIGURATION --no-restore

FROM build AS publish
ARG BUILD_CONFIGURATION=Release
RUN dotnet publish "OS.WebApi/OS.WebApi.csproj" -c $BUILD_CONFIGURATION -o /app/publish --no-build /p:UseAppHost=false

# Final image: API + Flutter web in wwwroot
FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .
COPY --from=frontend /src/frontend/build/web ./wwwroot
VOLUME ["/data"]
ENTRYPOINT ["dotnet", "OS.WebApi.dll"]

# syntax=docker/dockerfile:1

# --- Build stage -----------------------------------------------------------
# Build context is this directory (TeacherTracker.Api/); the API references no
# projects outside its own folder, so we don't need the repo root.
FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /src

# Restore first (cached until the csproj changes).
COPY TeacherTracker.Api.csproj .
RUN dotnet restore TeacherTracker.Api.csproj

# Then the rest of the source and publish a framework-dependent build.
COPY . .
RUN dotnet publish TeacherTracker.Api.csproj \
    -c Release \
    -o /app/publish \
    --no-restore \
    /p:UseAppHost=false

# --- Runtime stage ---------------------------------------------------------
FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS runtime
WORKDIR /app

# Kestrel listens on 8080 (the .NET 8+ container default; no root needed).
ENV ASPNETCORE_HTTP_PORTS=8080 \
    ASPNETCORE_ENVIRONMENT=Production \
    DOTNET_RUNNING_IN_CONTAINER=true

EXPOSE 8080

# Run as the non-root user shipped with the aspnet image.
USER $APP_UID

COPY --from=build /app/publish .

# Health is exposed at GET /health (unversioned, anonymous). Container platforms
# and the docker-compose below probe it directly — there's no HEALTHCHECK here
# because the runtime image ships without curl/wget.
ENTRYPOINT ["dotnet", "TeacherTracker.Api.dll"]

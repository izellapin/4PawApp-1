# Multi-stage Dockerfile for Veterinary Clinic API
# Based on FIT-RS2-2025 eCommerce project pattern

# Base runtime image
FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS base
WORKDIR /app
EXPOSE 8080


# Install curl for health checks
RUN apt-get update && apt-get install -y curl && rm -rf /var/lib/apt/lists/*

# Create non-root user for security
RUN addgroup --system --gid 1001 dotnet && \
    adduser --system --uid 1001 --group dotnet


# Build stage
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
ARG BUILD_CONFIGURATION=Release
WORKDIR /src

# Copy project files for better layer caching
COPY ["veterinarskaStanica.WebAPI/veterinarskaStanica.WebAPI.csproj", "veterinarskaStanica.WebAPI/"]
COPY ["eVeterinarskaStanicaServices/eVeterinarskaStanicaServices.csproj", "eVeterinarskaStanicaServices/"]
COPY ["eVeterinarskaStanicaModel/eVeterinarskaStanicaModel.csproj", "eVeterinarskaStanicaModel/"]

# Restore dependencies
RUN dotnet restore "veterinarskaStanica.WebAPI/veterinarskaStanica.WebAPI.csproj" --disable-parallel

# Copy source code
COPY . .

# Build the application
WORKDIR "/src/veterinarskaStanica.WebAPI"
RUN dotnet build "veterinarskaStanica.WebAPI.csproj" -c $BUILD_CONFIGURATION -o /app/build

# Publish stage
FROM build AS publish
ARG BUILD_CONFIGURATION=Release
RUN dotnet publish "veterinarskaStanica.WebAPI.csproj" -c $BUILD_CONFIGURATION -o /app/publish

# Final stage
FROM base AS final
WORKDIR /app

# Create logs directory
RUN mkdir -p /app/logs && chown -R dotnet:dotnet /app/logs

# Copy published app
COPY --from=publish /app/publish .

# Switch to non-root user
USER dotnet

# Health check endpoint
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
    CMD curl -f http://localhost:8080/health || exit 1

ENTRYPOINT ["dotnet", "veterinarskaStanica.WebAPI.dll"]
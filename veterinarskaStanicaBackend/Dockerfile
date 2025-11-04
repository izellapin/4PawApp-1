# Multi-stage Dockerfile for Veterinary Clinic API
# Based on CineVibe project pattern and .NET best practices

# Base runtime image
FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS base
WORKDIR /app
EXPOSE 5160
ENV ASPNETCORE_URLS=http://+:5160

# Install curl for health checks
RUN apt-get update && apt-get install -y curl && rm -rf /var/lib/apt/lists/*

# Create non-root user for security
RUN addgroup --system --gid 1001 dotnet && \
    adduser --system --uid 1001 --group dotnet

# Build stage
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src

# Copy project files for better layer caching (CineVibe pattern)
COPY ["veterinarskaStanica.WebAPI/veterinarskaStanica.WebAPI.csproj", "veterinarskaStanica.WebAPI/"]
COPY ["eVeterinarskaStanicaServices/eVeterinarskaStanicaServices.csproj", "eVeterinarskaStanicaServices/"]
COPY ["eVeterinarskaStanicaModel/eVeterinarskaStanicaModel.csproj", "eVeterinarskaStanicaModel/"]

# Restore dependencies
RUN dotnet restore "veterinarskaStanica.WebAPI/veterinarskaStanica.WebAPI.csproj"

# Copy all source code (CineVibe pattern)
COPY . .

# Publish stage (CineVibe pattern - direct publish)
FROM build AS publish
RUN dotnet publish "veterinarskaStanica.WebAPI/veterinarskaStanica.WebAPI.csproj" -c Release -o /app

# Final stage
FROM base AS final
WORKDIR /app

# Create necessary directories
RUN mkdir -p /app/logs && \
    mkdir -p /app/uploads && \
    mkdir -p /app/Assets && \
    chown -R dotnet:dotnet /app/logs && \
    chown -R dotnet:dotnet /app/uploads && \
    chown -R dotnet:dotnet /app/Assets

# Copy published application
COPY --from=publish /app .

# Copy static assets 
COPY --from=build /src/veterinarskaStanica.WebAPI/Assets ./Assets

# Switch to non-root user for security
USER dotnet

# Health check endpoint
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
    CMD curl -f http://localhost:5160/health || exit 1

ENTRYPOINT ["dotnet", "veterinarskaStanica.WebAPI.dll"]

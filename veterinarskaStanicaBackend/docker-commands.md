# Docker Commands for Veterinary Clinic Application
*Following FIT-RS2-2025 eCommerce Project Pattern*

## Environment-Specific Commands

### Development Environment
```bash
# Build and start development environment
docker-compose -f docker-compose.yml -f docker-compose.override.yml up --build

# Run in detached mode (background)
docker-compose up -d --build

# Stop all services
docker-compose down

# Stop and remove volumes (deletes database data)
docker-compose down -v
```

### Production Environment
```bash
# Build and start production environment
docker-compose -f docker-compose.yml -f docker-compose.prod.yml up --build -d

# Stop production environment
docker-compose -f docker-compose.yml -f docker-compose.prod.yml down

# View production logs
docker-compose -f docker-compose.yml -f docker-compose.prod.yml logs -f
```

### Individual Container Management
```bash
# Build the API image manually
docker build -t veterinary-api -f veterinarskaStanica.WebAPI/Dockerfile .

# Run just the API container (requires external database)
docker run -p 8080:8080 -e ASPNETCORE_ENVIRONMENT=Development veterinary-api

# Run SQL Server container separately
docker run -e "ACCEPT_EULA=Y" -e "SA_PASSWORD=VeterinaryApp123!" -p 1433:1433 --name veterinary-db -d mcr.microsoft.com/mssql/server:2022-latest
```

### Useful Docker Commands
```bash
# List running containers
docker ps

# List all containers (including stopped)
docker ps -a

# View container logs
docker logs veterinary-api
docker logs veterinary-db

# Execute commands inside running container
docker exec -it veterinary-api bash
docker exec -it veterinary-db /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P VeterinaryApp123!

# Remove containers
docker rm veterinary-api veterinary-db

# Remove images
docker rmi veterinary-api

# View images
docker images

# Clean up unused containers, networks, images
docker system prune

# Clean up everything including volumes
docker system prune -a --volumes
```

### Database Management
```bash
# Access SQL Server inside container
docker exec -it veterinary-db /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P "VeterinaryApp123!"

# Backup database
docker exec veterinary-db /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P "VeterinaryApp123!" -Q "BACKUP DATABASE eVeterinarskaStanica TO DISK = N'/var/opt/mssql/data/eVeterinarskaStanica.bak'"

# Copy backup file from container to host
docker cp veterinary-db:/var/opt/mssql/data/eVeterinarskaStanica.bak ./eVeterinarskaStanica.bak
```

### Development Commands
```bash
# Rebuild only the API service
docker-compose build webapi

# View real-time logs
docker-compose logs -f webapi

# Restart specific service
docker-compose restart webapi

# Scale services (if needed)
docker-compose up -d --scale webapi=2
```

### Network and Volume Commands
```bash
# List networks
docker network ls

# Inspect network
docker network inspect veterinarska_veterinary-network

# List volumes
docker volume ls

# Inspect volume
docker volume inspect veterinarska_sqlserver_data

# Remove unused volumes
docker volume prune
```

## Environment Variables

### For API Container
- `ASPNETCORE_ENVIRONMENT`: Development/Production
- `ASPNETCORE_URLS`: http://+:8080
- `ConnectionStrings__DefaultConnection`: Database connection string

### For SQL Server Container
- `ACCEPT_EULA`: Y (required)
- `SA_PASSWORD`: Strong password for SA user
- `MSSQL_PID`: Express/Developer/Standard

## Ports
- **API**: 8080 (mapped to host:8080)
- **Database**: 1433 (mapped to host:1433)
- **Swagger UI**: http://localhost:8080/swagger

## Troubleshooting
```bash
# Check container health
docker inspect veterinary-api | grep -i health
docker inspect veterinary-db | grep -i health

# View detailed container information
docker inspect veterinary-api

# Check network connectivity
docker exec veterinary-api ping veterinary-db

# Test database connection
docker exec veterinary-api dotnet --version
```

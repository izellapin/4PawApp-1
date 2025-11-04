# Makefile for Veterinary Clinic Application
# Following FIT-RS2-2025 eCommerce pattern

.PHONY: help build up down logs clean test

# Default target
help:
	@echo "Available commands:"
	@echo "  build     - Build all Docker images"
	@echo "  up        - Start development environment"
	@echo "  up-prod   - Start production environment"
	@echo "  down      - Stop all services"
	@echo "  logs      - View application logs"
	@echo "  clean     - Clean up Docker resources"
	@echo "  test      - Run tests"
	@echo "  migrate   - Run database migrations"

# Build images
build:
	docker-compose build

# Development environment
up:
	docker-compose up -d --build

# Production environment
up-prod:
	docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d --build

# Stop services
down:
	docker-compose down

# View logs
logs:
	docker-compose logs -f api

# Clean up
clean:
	docker-compose down -v
	docker system prune -f
	docker volume prune -f

# Run tests (when implemented)
test:
	docker-compose exec api dotnet test

# Run database migrations
migrate:
	docker-compose exec api dotnet ef database update

# Health check
health:
	curl -f http://localhost:8080/health || echo "API is not healthy"

# Database backup
backup:
	docker exec veterinary-database /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P "VeterinaryApp123!" -Q "BACKUP DATABASE eVeterinarskaStanica TO DISK = N'/var/opt/mssql/data/backup.bak'"
	docker cp veterinary-database:/var/opt/mssql/data/backup.bak ./backup_$(shell date +%Y%m%d_%H%M%S).bak

# Development helpers
dev-logs:
	docker-compose logs -f

dev-shell:
	docker-compose exec api bash

db-shell:
	docker-compose exec database /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P "VeterinaryApp123!"

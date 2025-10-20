# Open Deep Research - Docker Management Makefile

.PHONY: help build up down logs test clean restart status

# Default target
help:
	@echo "Open Deep Research - Docker Management"
	@echo "====================================="
	@echo ""
	@echo "Available commands:"
	@echo "  make build     - Build the Docker image"
	@echo "  make up        - Start the services"
	@echo "  make down      - Stop the services"
	@echo "  make restart   - Restart the services"
	@echo "  make logs      - Show service logs"
	@echo "  make test      - Run Docker deployment tests"
	@echo "  make status    - Show service status"
	@echo "  make clean     - Clean up containers and images"
	@echo "  make help      - Show this help message"
	@echo ""
	@echo "Production commands:"
	@echo "  make prod      - Start with production profile (includes Nginx)"
	@echo "  make prod-down - Stop production services"
	@echo ""

# Build the Docker image
build:
	@echo "🔨 Building Docker image..."
	docker-compose build

# Start services
up:
	@echo "🚀 Starting services..."
	docker-compose up -d

# Start services with build
up-build:
	@echo "🚀 Building and starting services..."
	docker-compose up --build -d

# Stop services
down:
	@echo "🛑 Stopping services..."
	docker-compose down

# Restart services
restart: down up

# Show logs
logs:
	@echo "📋 Showing service logs..."
	docker-compose logs -f

# Run tests
test:
	@echo "🧪 Running Docker deployment tests..."
	pytest -q

# Show service status
status:
	@echo "📊 Service status:"
	docker-compose ps

# Clean up
clean:
	@echo "🧹 Cleaning up containers and images..."
	docker-compose down --rmi all --volumes --remove-orphans
	docker system prune -f

# Production deployment
prod:
	@echo "🏭 Starting production services with Nginx..."
	docker-compose --profile production up --build -d

# Stop production services
prod-down:
	@echo "🛑 Stopping production services..."
	docker-compose --profile production down

# Development with live reload
dev:
	@echo "🔧 Starting development environment..."
	docker-compose up --build

# Show environment info
env-info:
	@echo "🔧 Environment Information:"
	@echo "Docker version: $$(docker --version)"
	@echo "Docker Compose version: $$(docker-compose --version)"
	@echo "Current directory: $$(pwd)"
	@echo "Environment file exists: $$(test -f .env && echo 'Yes' || echo 'No')"

# Quick setup for new users
setup:
	@echo "⚙️  Setting up Open Deep Research..."
	@if [ ! -f .env ]; then \
		echo "📝 Creating .env file from template..."; \
		cp env.example .env; \
		echo "⚠️  Please edit .env file with your API keys"; \
	else \
		echo "✅ .env file already exists"; \
	fi
	@echo "🔨 Building Docker image..."
	docker-compose build
	@echo "✅ Setup complete! Run 'make up' to start the services."

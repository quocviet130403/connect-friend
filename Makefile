.PHONY: dev up down build logs clean

# Start all services (MongoDB + Redis + Server)
up:
	docker compose up -d

# Start all services with build
up-build:
	docker compose up -d --build

# Stop all services
down:
	docker compose down

# Rebuild server only
build:
	docker compose build server

# View logs
logs:
	docker compose logs -f

# View server logs only
logs-server:
	docker compose logs -f server

# Stop and remove volumes (clean data)
clean:
	docker compose down -v

# Run server locally (without Docker, needs MongoDB + Redis running)
dev:
	cd server && go run ./cmd/api

# Run go mod tidy
tidy:
	cd server && go mod tidy

# Open Mongo Express (DB admin panel)
mongo-ui:
	start http://localhost:8081

# Test API health
health:
	curl -s http://localhost:8080/health | python -m json.tool

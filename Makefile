.PHONY: dev up down build logs clean client client-web client-ios

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

# ---------- Client (Flutter) ----------

# Run Flutter client on Android
client:
	cd client && flutter run

# Run Flutter client on Chrome (web)
client-web:
	cd client && flutter run -d chrome

# Run Flutter client on iOS
client-ios:
	cd client && flutter run -d ios

# Install client dependencies
client-deps:
	cd client && flutter pub get

# Build APK for Android (sideload, no Play Store needed)
build-apk:
	cd client && flutter build apk --release

# Build iOS (requires Mac + Apple Developer Account)
build-ios:
	cd client && flutter build ios --release

# ---------- Utilities ----------

# Open Mongo Express (DB admin panel)
mongo-ui:
	start http://localhost:8082

# Test API health
health:
	curl -s http://localhost:8090/health | python -m json.tool

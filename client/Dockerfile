# ===== Build stage =====
FROM ghcr.io/cirruslabs/flutter:3.29.2 AS build

WORKDIR /app
COPY pubspec.* ./
RUN flutter pub get

COPY . .
RUN flutter build web --release --web-renderer html

# ===== Serve stage =====
FROM nginx:alpine

COPY --from=build /app/build/web /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

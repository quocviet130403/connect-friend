# ===== Build stage =====
FROM ghcr.io/cirruslabs/flutter:3.38.5 AS build

WORKDIR /app
COPY pubspec.* ./
RUN flutter pub get

COPY . .
RUN flutter build web --release

# ===== Serve stage =====
FROM nginx:alpine

COPY --from=build /app/build/web /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

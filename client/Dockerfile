# Lightweight: serve pre-built Flutter web files
# Build locally first: flutter build web --release
FROM nginx:alpine

COPY build/web /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

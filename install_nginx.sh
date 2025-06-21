#!/bin/bash
set -e

NGINX_SITE="/etc/nginx/sites-available/default"
BACKUP="${NGINX_SITE}.bak.$(date +%Y%m%d%H%M%S)"

echo "Sichere originale Nginx-Config nach $BACKUP"
sudo cp "$NGINX_SITE" "$BACKUP"

echo "Schreibe neue Server-Definition in $NGINX_SITE"
sudo tee "$NGINX_SITE" > /dev/null <<'EOF'
server {
    listen 80 default_server;
    root /var/www/html;
    index index.html;

    location / {
        try_files $uri /index.html;
    }

    # Stream als MJPEG-Proxy
    location /stream {
        proxy_pass http://127.0.0.1:8080/?action=stream;
        proxy_http_version 1.1;
        proxy_set_header Connection "";
    }

    # API-Pfade später an Flask weiterleiten
    location /api/ {
        proxy_pass http://127.0.0.1:5000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
    }
}
EOF

echo "Prüfe Nginx-Konfiguration"
sudo nginx -t

echo "Lade Nginx neu"
sudo systemctl reload nginx

echo "Fertig. Deine neue Nginx-Config ist aktiv."

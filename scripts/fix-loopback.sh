#!/usr/bin/env bash
# Quick fix for loopback request issues on existing WordPress installation

echo "=== Fixing WordPress Loopback Request Issues ==="

WP_PATH=/var/www/html

# Fix loopback request issues
echo "Adding WordPress configuration constants..."
docker compose exec wpcli wp config set WP_HTTP_BLOCK_EXTERNAL false --raw --allow-root --path=$WP_PATH
docker compose exec wpcli wp config set WP_ACCESSIBLE_HOSTS 'localhost,127.0.0.1' --allow-root --path=$WP_PATH
docker compose exec wpcli wp config set AUTOMATIC_UPDATER_DISABLED false --raw --allow-root --path=$WP_PATH

echo "Flushing rewrite rules..."
docker compose exec wpcli wp rewrite flush --allow-root --path=$WP_PATH

echo ""
echo "Done! Please refresh WordPress Site Health page."
echo "Note: Some warnings may persist in Docker development environment."

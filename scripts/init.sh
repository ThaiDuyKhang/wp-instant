#!/usr/bin/env bash
set -e

echo "=== WP Instant Init ==="

echo "Waiting for MySQL..."
until docker compose exec db mysqladmin ping -uroot -proot --silent; do
  sleep 2
done

# Nếu WordPress đã cài (có DB) → thoát
if docker compose exec wpcli wp core is-installed --allow-root >/dev/null 2>&1; then
  echo "WordPress already installed. Skipping."
  exit 0
fi

# Nếu chưa có core → download
if ! docker compose exec wpcli wp core is-installed --allow-root >/dev/null 2>&1 \
   && ! docker compose exec wpcli test -f /var/www/html/wp-settings.php; then
  echo "Downloading WordPress core..."
  docker compose exec wpcli wp core download --allow-root
else
  echo "WordPress core already exists. Skipping download."
fi

echo "Creating wp-config.php..."
docker compose exec wpcli wp config create \
  --dbname="$DB_NAME" \
  --dbuser="$DB_USER" \
  --dbpass="$DB_PASS" \
  --dbhost="db" \
  --skip-check \
  --allow-root

echo "Installing WordPress..."
docker compose exec wpcli wp core install \
  --url="$SITE_URL" \
  --title="$SITE_TITLE" \
  --admin_user="$ADMIN_USER" \
  --admin_password="$ADMIN_PASS" \
  --admin_email="$ADMIN_EMAIL" \
  --skip-email \
  --allow-root

echo "DONE"

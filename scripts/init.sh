#!/usr/bin/env bash
set -e

echo "=== WP Instant Init ==="

echo "Waiting for MySQL..."
until docker compose exec db mysqladmin ping -uroot -proot --silent; do
  sleep 2
done

# Nếu WP đã cài DB → thoát
if docker compose exec wpcli wp core is-installed --allow-root >/dev/null 2>&1; then
  echo "WordPress already installed. Skipping."
  exit 0
fi

# Tạo wp-config.php nếu CHƯA có
if docker compose exec wpcli test -f /var/www/html/wp-config.php; then
  echo "wp-config.php already exists. Skipping config creation."
else
  echo "Creating wp-config.php..."
  docker compose exec wpcli wp config create \
    --dbname="$DB_NAME" \
    --dbuser="$DB_USER" \
    --dbpass="$DB_PASS" \
    --dbhost="db" \
    --skip-check \
    --allow-root
fi

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
